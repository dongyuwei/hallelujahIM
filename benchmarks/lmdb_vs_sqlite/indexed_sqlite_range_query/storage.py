#!/usr/bin/env python3
"""Compare SQLite and LMDB with Hallelujah's real dictionary workload."""

import argparse
import math
import platform
from pathlib import Path
import sqlite3
import statistics
import struct
import tempfile
import time

try:
    import lmdb
except ImportError as error:
    requirements = Path(__file__).resolve().with_name("requirements.txt")
    raise SystemExit(
        f"python-lmdb is required; run: python3 -m pip install -r {requirements}"
    ) from error


def find_repository_root():
    for candidate in Path(__file__).resolve().parents:
        database = (
            candidate
            / "dictionary"
            / "words_with_frequency_and_translation_and_ipa.sqlite3"
        )
        if database.is_file():
            return candidate
    raise RuntimeError("could not find the Hallelujah repository root")


REPOSITORY_ROOT = find_repository_root()
DEFAULT_DATABASE = (
    REPOSITORY_ROOT
    / "dictionary"
    / "words_with_frequency_and_translation_and_ipa.sqlite3"
)
DEFAULT_PREFIXES = (
    "a",
    "th",
    "tes",
    "apple",
    "psych",
    "z",
    "xyl",
    "algorithm",
    "notaword",
)
DEFAULT_EXACT_WORDS = (
    "the",
    "test",
    "algorithm",
    "hallelujah",
    "psychology",
    "xylophone",
    "zyzzyva",
    "not-in-the-dictionary",
)
FREQUENCY_SIZE = struct.calcsize(">Q")


def parse_arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--database",
        type=Path,
        default=DEFAULT_DATABASE,
        help="source SQLite dictionary (default: repository dictionary)",
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=100,
        help="timed repetitions per input (default: 100)",
    )
    parser.add_argument(
        "--warmup",
        type=int,
        default=10,
        help="untimed repetitions per input (default: 10)",
    )
    parser.add_argument(
        "--prefixes",
        default=",".join(DEFAULT_PREFIXES),
        help="comma-separated prefixes",
    )
    return parser.parse_args()


def load_rows(database_path):
    with sqlite3.connect(str(database_path)) as connection:
        rows = connection.execute(
            "SELECT word, frequency, translation, ipa FROM words ORDER BY word"
        ).fetchall()
        ngram_table = connection.execute(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'ngrams'"
        ).fetchone()
        ngram_count = (
            connection.execute("SELECT count(*) FROM ngrams").fetchone()[0]
            if ngram_table
            else 0
        )
    return rows, ngram_count


def build_sqlite(database_path, rows):
    started = time.perf_counter()
    with sqlite3.connect(str(database_path)) as connection:
        connection.execute(
            """
            CREATE TABLE words (
                word TEXT PRIMARY KEY,
                frequency INTEGER,
                translation TEXT,
                ipa TEXT
            )
            """
        )
        connection.executemany(
            "INSERT INTO words (word, frequency, translation, ipa) VALUES (?, ?, ?, ?)",
            rows,
        )
        # Mirror the bundled database schema, including its explicit word
        # index, so the size comparison does not assume a schema migration.
        connection.execute("CREATE INDEX idx_word ON words(word)")
    return time.perf_counter() - started


def encode_value(frequency, translation, ipa):
    translation_bytes = (translation or "").encode("utf-8")
    ipa_bytes = (ipa or "").encode("utf-8")
    return (
        struct.pack(">Q", frequency)
        + struct.pack(">I", len(translation_bytes))
        + translation_bytes
        + ipa_bytes
    )


def decode_value(value):
    value = bytes(value)
    frequency = struct.unpack(">Q", value[:FREQUENCY_SIZE])[0]
    translation_size = struct.unpack(
        ">I", value[FREQUENCY_SIZE : FREQUENCY_SIZE + 4]
    )[0]
    translation_start = FREQUENCY_SIZE + 4
    translation_end = translation_start + translation_size
    return (
        frequency,
        value[translation_start:translation_end].decode("utf-8"),
        value[translation_end:].decode("utf-8"),
    )


def build_lmdb(database_path, rows):
    started = time.perf_counter()
    environment = lmdb.open(
        str(database_path),
        map_size=256 * 1024 * 1024,
        subdir=True,
        max_dbs=1,
    )
    with environment.begin(write=True) as transaction:
        for word, frequency, translation, ipa in rows:
            inserted = transaction.put(
                word.encode("utf-8"),
                encode_value(frequency, translation, ipa),
                append=True,
            )
            if not inserted:
                raise RuntimeError(f"failed to append LMDB key {word!r}")
    environment.sync()
    environment.close()
    return time.perf_counter() - started


def sqlite_prefix_like(connection, prefix):
    return connection.execute(
        """
        SELECT word, frequency
        FROM words
        WHERE word LIKE ?
        ORDER BY frequency DESC, word ASC
        """,
        (prefix + "%",),
    ).fetchall()


def prefix_upper_bound(prefix):
    # Dictionary keys and user-entered English prefixes are ASCII. Incrementing
    # the last byte gives the exclusive end of the matching B-tree range.
    encoded = bytearray(prefix.encode("ascii"))
    for index in range(len(encoded) - 1, -1, -1):
        if encoded[index] < 0x7F:
            encoded[index] += 1
            return bytes(encoded[: index + 1]).decode("ascii")
    raise ValueError("prefix must contain at least one ASCII byte below 0x7f")


def sqlite_prefix_range(connection, prefix):
    return connection.execute(
        """
        SELECT word, frequency
        FROM words
        WHERE word >= ? AND word < ?
        ORDER BY frequency DESC, word ASC
        """,
        (prefix, prefix_upper_bound(prefix)),
    ).fetchall()


def lmdb_prefix(environment, prefix):
    prefix_bytes = prefix.encode("utf-8")
    matches = []
    with environment.begin(buffers=True) as transaction:
        cursor = transaction.cursor()
        if cursor.set_range(prefix_bytes):
            for key, value in cursor:
                key_bytes = bytes(key)
                if not key_bytes.startswith(prefix_bytes):
                    break
                frequency = struct.unpack(">Q", value[:FREQUENCY_SIZE])[0]
                matches.append((key_bytes.decode("utf-8"), frequency))
    matches.sort(key=lambda item: (-item[1], item[0]))
    return matches


def sqlite_exact(connection, word):
    return connection.execute(
        "SELECT frequency, translation, ipa FROM words WHERE word = ?", (word,)
    ).fetchone()


def lmdb_exact(environment, word):
    with environment.begin(buffers=True) as transaction:
        value = transaction.get(word.encode("utf-8"))
        return decode_value(value) if value is not None else None


def percentile(samples, percentage):
    ordered = sorted(samples)
    index = max(0, math.ceil(len(ordered) * percentage) - 1)
    return ordered[index]


def measure(operation, inputs, iterations, warmup):
    for _ in range(warmup):
        for value in inputs:
            operation(value)

    samples = {value: [] for value in inputs}
    for _ in range(iterations):
        for value in inputs:
            started = time.perf_counter_ns()
            operation(value)
            samples[value].append((time.perf_counter_ns() - started) / 1_000_000)
    return samples


def combined_stats(samples):
    values = [duration for group in samples.values() for duration in group]
    return statistics.median(values), percentile(values, 0.95)


def logical_and_allocated_size(path):
    paths = [path] if path.is_file() else list(path.iterdir())
    logical = sum(item.stat().st_size for item in paths if item.is_file())
    allocated = sum(item.stat().st_blocks * 512 for item in paths if item.is_file())
    return logical, allocated


def mib(byte_count):
    return byte_count / (1024 * 1024)


def query_plan(connection, sql, parameters):
    rows = connection.execute("EXPLAIN QUERY PLAN " + sql, parameters).fetchall()
    return "; ".join(row[3] for row in rows)


def print_measurement(name, samples):
    median, p95 = combined_stats(samples)
    print(f"| {name} | {median:.3f} | {p95:.3f} |")


def main():
    arguments = parse_arguments()
    if arguments.iterations < 1 or arguments.warmup < 0:
        raise SystemExit("iterations must be positive and warmup must be non-negative")
    prefixes = tuple(
        item.strip().lower()
        for item in arguments.prefixes.split(",")
        if item.strip()
    )
    if not prefixes:
        raise SystemExit("at least one prefix is required")
    for prefix in prefixes:
        prefix.encode("ascii")

    source_database = arguments.database.resolve()
    if not source_database.is_file():
        raise SystemExit(f"database not found: {source_database}")
    rows, ngram_count = load_rows(source_database)

    with tempfile.TemporaryDirectory(prefix="hallelujah-storage-") as temporary:
        temporary_path = Path(temporary)
        sqlite_path = temporary_path / "words.sqlite3"
        lmdb_path = temporary_path / "words.lmdb"
        sqlite_build_time = build_sqlite(sqlite_path, rows)
        lmdb_build_time = build_lmdb(lmdb_path, rows)

        sqlite_connection = sqlite3.connect(str(sqlite_path))
        lmdb_environment = lmdb.open(
            str(lmdb_path),
            readonly=True,
            lock=False,
            readahead=True,
            max_dbs=1,
        )
        if lmdb_environment.stat()["entries"] != len(rows):
            raise RuntimeError("LMDB row count differs from the SQLite source")

        for prefix in prefixes:
            like_result = sqlite_prefix_like(sqlite_connection, prefix)
            range_result = sqlite_prefix_range(sqlite_connection, prefix)
            lmdb_result = lmdb_prefix(lmdb_environment, prefix)
            if like_result != range_result or range_result != lmdb_result:
                raise RuntimeError(f"backend results differ for prefix {prefix!r}")
        for word in DEFAULT_EXACT_WORDS:
            if sqlite_exact(sqlite_connection, word) != lmdb_exact(
                lmdb_environment, word
            ):
                raise RuntimeError(f"backend results differ for exact word {word!r}")

        like_samples = measure(
            lambda prefix: sqlite_prefix_like(sqlite_connection, prefix),
            prefixes,
            arguments.iterations,
            arguments.warmup,
        )
        range_samples = measure(
            lambda prefix: sqlite_prefix_range(sqlite_connection, prefix),
            prefixes,
            arguments.iterations,
            arguments.warmup,
        )
        lmdb_prefix_samples = measure(
            lambda prefix: lmdb_prefix(lmdb_environment, prefix),
            prefixes,
            arguments.iterations,
            arguments.warmup,
        )
        sqlite_exact_samples = measure(
            lambda word: sqlite_exact(sqlite_connection, word),
            DEFAULT_EXACT_WORDS,
            arguments.iterations,
            arguments.warmup,
        )
        lmdb_exact_samples = measure(
            lambda word: lmdb_exact(lmdb_environment, word),
            DEFAULT_EXACT_WORDS,
            arguments.iterations,
            arguments.warmup,
        )

        source_size = logical_and_allocated_size(source_database)
        sqlite_size = logical_and_allocated_size(sqlite_path)
        lmdb_size = logical_and_allocated_size(lmdb_path)
        result_counts = {
            prefix: len(sqlite_prefix_range(sqlite_connection, prefix))
            for prefix in prefixes
        }
        like_plan = query_plan(
            sqlite_connection,
            "SELECT word FROM words WHERE word LIKE ? ORDER BY frequency DESC",
            ("tes%",),
        )
        range_plan = query_plan(
            sqlite_connection,
            "SELECT word FROM words WHERE word >= ? AND word < ? ORDER BY frequency DESC",
            ("tes", "tet"),
        )

        print("# Hallelujah SQLite vs LMDB benchmark")
        print()
        print(f"- Platform: {platform.platform()} ({platform.machine()})")
        print(f"- Python: {platform.python_version()}")
        print(f"- SQLite: {sqlite3.sqlite_version}")
        print(f"- python-lmdb: {lmdb.__version__}")
        print(f"- LMDB: {'.'.join(str(item) for item in lmdb.version())}")
        print(f"- Words: {len(rows):,}")
        print(f"- N-grams present in source SQLite file: {ngram_count:,}")
        print(f"- Iterations per input: {arguments.iterations}")
        print("- Cache state: warm OS page cache; one persistent connection/environment")
        print()
        print("## Build and on-disk size")
        print()
        print("| Backend | Build (s) | Logical (MiB) | Allocated (MiB) |")
        print("| --- | ---: | ---: | ---: |")
        print(
            "| Bundled SQLite source | n/a | "
            f"{mib(source_size[0]):.2f} | {mib(source_size[1]):.2f} |"
        )
        print(
            f"| SQLite (words only, current schema) | {sqlite_build_time:.3f} | "
            f"{mib(sqlite_size[0]):.2f} | {mib(sqlite_size[1]):.2f} |"
        )
        print(
            f"| LMDB (words only) | {lmdb_build_time:.3f} | "
            f"{mib(lmdb_size[0]):.2f} | {mib(lmdb_size[1]):.2f} |"
        )
        print()
        print("## Warm query latency")
        print()
        print("| Operation | p50 (ms) | p95 (ms) |")
        print("| --- | ---: | ---: |")
        print_measurement("SQLite prefix (`LIKE`, current)", like_samples)
        print_measurement("SQLite prefix (indexed range)", range_samples)
        print_measurement("LMDB prefix cursor", lmdb_prefix_samples)
        print_measurement("SQLite exact lookup", sqlite_exact_samples)
        print_measurement("LMDB exact lookup", lmdb_exact_samples)
        print()
        print("## Prefix detail (median latency)")
        print()
        print("| Prefix | Matches | SQLite `LIKE` (ms) | SQLite range (ms) | LMDB (ms) |")
        print("| --- | ---: | ---: | ---: | ---: |")
        for prefix in prefixes:
            print(
                f"| `{prefix}` | {result_counts[prefix]:,} | "
                f"{statistics.median(like_samples[prefix]):.3f} | "
                f"{statistics.median(range_samples[prefix]):.3f} | "
                f"{statistics.median(lmdb_prefix_samples[prefix]):.3f} |"
            )
        print()
        print("## SQLite query plans")
        print()
        print(f"- Current `LIKE`: `{like_plan}`")
        print(f"- Indexed range: `{range_plan}`")

        sqlite_connection.close()
        lmdb_environment.close()


if __name__ == "__main__":
    main()
