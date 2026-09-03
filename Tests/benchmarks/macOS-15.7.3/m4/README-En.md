# Dictionary Storage Benchmark

This benchmark uses Hallelujah Input Method's actual 140,402-word dictionary and real access patterns to answer the performance and size questions about SQLite and LMDB raised in [issue #191](https://github.com/dongyuwei/hallelujahIM/issues/191).

[中文版](README.md) | [EN](README-En.md)

It compares:

- the current SQLite `LIKE prefix%` query;
- an equivalent SQLite B-tree range query;
- an LMDB cursor prefix scan;
- exact word and annotation lookups;
- database build time, logical file size, and actual allocated space.

All backends store the same words, frequencies, translations, and IPA values. Prefix queries fully read the matching results and sort them by frequency. Before timing, the script verifies that all backends return exactly the same results.

## Running

Use a disposable virtual environment so the application itself gains no Python dependency:

```bash
python3 -m venv /tmp/hallelujah-benchmark-venv
/tmp/hallelujah-benchmark-venv/bin/pip install -r Tests/benchmarks/macOS-15.7.3/m4/requirements.txt
/tmp/hallelujah-benchmark-venv/bin/python Tests/benchmarks/macOS-15.7.3/m4/storage_benchmark.py
```

You can adjust the workload with `--iterations`, `--warmup`, or `--prefixes`.

Because neither SQLite nor LMDB can portably clear the operating system cache, query data is tested with a warm OS page cache. Run the benchmark on an otherwise idle machine and compare results produced by the same machine.

## Reference Results

- Test date: 2026-09-03
- Test system: macOS 15.7.3
- Test CPU: Apple Silicon M4
- 100 timed iterations per input
- Latencies use a warm OS page cache and include reading all prefix matches and sorting them by frequency

| Operation | p50 (ms) | p95 (ms) |
| --- | ---: | ---: |
| SQLite prefix query (current `LIKE`) | 5.406 | 7.979 |
| SQLite prefix query (indexed range query) | 0.026 | 2.896 |
| LMDB cursor prefix query | 0.032 | 5.850 |
| SQLite exact query | 0.005 | 0.005 |
| LMDB exact query | 0.001 | 0.001 |

For several representative prefixes, the experimental SQLite range query took 2.892 ms for 9,242 `a` matches, 0.238 ms for 852 `th` matches, and 0.026 ms for 64 `tes` matches. LMDB took 5.847, 0.462, and 0.032 ms respectively. LMDB is faster for very small result sets and exact-key queries, while SQLite's range query is faster as the prefix result set grows.

| Format | Words | File size (MiB) |
| --- | ---: | ---: |
| Current bundled SQLite (words and n-grams) | 140,402 | 14.42 |
| SQLite (words only, current schema) | 140,402 | 13.63 |
| LMDB | 140,402 | 10.04 |

When comparing the same word data only, the LMDB file in this run is about 26.3% smaller than the SQLite file using the current schema. The bundled SQLite n-gram data is excluded from this percentage calculation. Exact values may vary with SQLite and LMDB versions and filesystem page allocation, so use the script output as the source of truth in new environments.

## Results Discussion

The results show that LMDB exact-key queries and cursor prefix scans are both faster than the SQLite `LIKE` query currently used by the application. When storing only word data, the LMDB file is also smaller.

The benchmark additionally includes an SQLite indexed range query for reference. It can use the existing index and is faster than LMDB for larger result sets.

The bundled SQLite file contains 140,402 word rows and 9,955 n-gram rows, and the benchmark preserves the source file in full. For a fair comparison of dictionary storage size, the script reads only the `words` data.
