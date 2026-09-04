# Dictionary Storage Benchmark

This benchmark uses Hallelujah Input Method's actual 140,402-word dictionary and
real access patterns to answer the SQLite and LMDB performance and size questions
raised in [issue #191](https://github.com/dongyuwei/hallelujahIM/issues/191).

[中文版](README.md) | [EN](README-En.md)

The suite runs the same workload at three levels: Python, an optimized
native C benchmark, and an Objective-C benchmark that uses the application's FMDB
dependency and Foundation result objects. All three use the same query workload
to compare:

- the current SQLite `LIKE prefix%` query;
- an equivalent SQLite B-tree range query;
- an LMDB cursor prefix scan;
- exact word and annotation lookups.

The Python and native C experiments also report database build time, logical file
size, and actual allocated space.

The C benchmark calls `sqlite3` and `liblmdb` directly. The Objective-C benchmark
uses FMDB for SQLite and the LMDB C API. Both paths return the same final ordered
word array and drain an autorelease pool for every operation. SQLite returns words
already ordered by SQL. LMDB temporarily materializes words and frequencies,
sorts them, and then produces the final word array. Exact queries copy the
frequency, translation, and IPA values. Before timing, each executable verifies
that every backend returns identical results.

## Experiment Summary

All three experiments use the same 140,402-word dictionary, nine prefixes, eight
exact-query words, ten warm-up iterations, and 100 timed iterations per input.
Each cell below is `p50 / p95` in milliseconds. Prefix values aggregate all nine
inputs, while exact-query values aggregate all eight inputs.

| Implementation | Current SQLite `LIKE` | SQLite indexed range | LMDB prefix | SQLite exact | LMDB exact |
| --- | ---: | ---: | ---: | ---: | ---: |
| Python | 5.406 / 7.979 | 0.026 / 2.896 | 0.032 / 5.850 | 0.005 / 0.005 | 0.001 / 0.001 |
| C | 5.5558 / 7.2420 | 0.0161 / 1.8716 | 0.0053 / 0.8729 | 0.0042 / 0.0046 | 0.0002 / 0.0003 |
| Objective-C | 5.6397 / 7.5174 | 0.0215 / 2.0707 | 0.0145 / 2.7701 | 0.0062 / 0.0067 | 0.0007 / 0.0008 |

The three representative prefixes show more clearly how implementation-layer
overhead changes the result. Each cell is
`SQLite indexed range / LMDB` p50 in milliseconds; the faster result in each
experiment is bold.

| Implementation | `a` (9,242 results) | `th` (852 results) | `tes` (64 results) |
| --- | ---: | ---: | ---: |
| Python | **2.892** / 5.847 | **0.238** / 0.462 | **0.026** / 0.032 |
| C | 1.8685 / **0.8702** | 0.1612 / **0.0721** | 0.0160 / **0.0053** |
| Objective-C | **2.0686** / 2.7691 | **0.1854** / 0.2196 | 0.0215 / **0.0145** |

Taken together, the three experiments show:

- The current `LIKE` query has a p50 of about 5.4–5.6 ms in every implementation
  and is consistently the slowest prefix-query option.
- Python favors SQLite range for all three representative prefixes.
  Native C favors LMDB by about 2.1x, 2.2x, and 3.0x respectively, showing that
  Python LMDB cursor iteration and sorting overhead changes the result.
- In the application-representative Objective-C experiment, FMDB range is about
  1.34x and 1.18x faster for `a` and `th`, while LMDB is about 1.48x faster for
  `tes`. LMDB exact lookup is about 8.9x faster, but both backends remain below
  0.01 ms in absolute terms.

### Experiment Environments and Dependency Versions

All three experiments ran on macOS 15.7.3 (24G419) on an Apple M4 (arm64), using
a warm operating-system page cache. The C and Objective-C experiments used the
macOS 15.5 SDK. Their language environments and dependency versions were:

| Experiment | Date | Language / toolchain | SQLite | LMDB | Other dependency |
| --- | --- | --- | --- | --- | --- |
| Python | 2026-09-03 | Python 3.9.6 | Python `sqlite3` / SQLite 3.43.2 | python-lmdb 1.8.1 / LMDB 0.9.35 | — |
| C | 2026-09-04 | Apple Clang 17.0.0, C11, `-O3` | System `libsqlite3` 3.43.2 | Homebrew `liblmdb` 1.0.1 | — |
| Objective-C | 2026-09-04 | Apple Clang 17.0.0, ARC, Blocks, `-O3` | FMDB 2.7.12 / SQLite 3.43.2 | Homebrew `liblmdb` 1.0.1 | Foundation |

## C & Objective-C

Install the benchmark-only LMDB library and run the wrapper:

```bash
brew install lmdb
bash Tests/benchmarks/macOS-15.7.3/m4/run_native_benchmark.sh
bash Tests/benchmarks/macOS-15.7.3/m4/run_objective_c_benchmark.sh
```

Use `--iterations` or `--warmup` to adjust the workload. The wrappers compile both
benchmarks with `clang -O3`, link SQLite and LMDB directly, run them from the
repository root, and remove the temporary executables afterward. Neither LMDB nor
the benchmarks become application runtime dependencies.

Because neither SQLite nor LMDB can portably clear the operating-system cache,
queries use a warm OS page cache. Run the benchmarks on an otherwise idle machine
and compare only results produced on the same machine.

## Python

```bash
python3 -m venv /tmp/hallelujah-benchmark-venv
/tmp/hallelujah-benchmark-venv/bin/pip install -r Tests/benchmarks/macOS-15.7.3/m4/requirements.txt
/tmp/hallelujah-benchmark-venv/bin/python Tests/benchmarks/macOS-15.7.3/m4/storage_benchmark.py
```
