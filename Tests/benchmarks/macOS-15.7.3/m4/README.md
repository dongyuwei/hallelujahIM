# 词库存储基准测试

本基准测试使用哈利路亚输入法实际的 140,402 词词库和真实访问模式，回答
[issue #191](https://github.com/dongyuwei/hallelujahIM/issues/191) 中 SQLite 与 LMDB 的性能及体积问题。

[中文](README.md) | [EN](README-En.md)

测试从三个层级运行相同的工作负载：Python、经过优化编译的原生 C benchmark，
以及使用应用现有 FMDB 依赖和 Foundation 结果对象的 Objective-C benchmark。三者
使用相同的查询负载，对比：

- 当前 SQLite `LIKE prefix%` 查询；
- 等价的 SQLite B-tree 范围查询；
- LMDB 游标前缀扫描；
- 单词及注释的精确查询。

Python 与原生 C 实验还会记录数据库构建时间、逻辑文件大小和实际占用空间。

C benchmark 直接调用 `sqlite3` 和 `liblmdb`；Objective-C benchmark 的 SQLite
路径使用 FMDB，LMDB 路径使用 C API。两边最终均返回相同的有序单词数组，并在每次操作
中清理 autorelease pool。SQLite 直接返回已由 SQL 排序的单词；LMDB 临时生成单词及
词频对象、排序后再生成最终单词数组。精确查询会复制词频、翻译及国际音标。计时前，每个
程序都会验证所有后端返回完全相同的结果。

## 实验汇总

三次实验均使用同一份 140,402 词词库、9 个前缀、8 个精确查询词，每个输入预热 10 次
并计时 100 次。下表每格均为 `p50 / p95`，单位为毫秒；前缀数据汇总全部 9 个输入，
精确查询数据汇总全部 8 个输入。

| 实现 | SQLite 当前 `LIKE` | SQLite 索引范围 | LMDB 前缀 | SQLite 精确 | LMDB 精确 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Python | 5.406 / 7.979 | 0.026 / 2.896 | 0.032 / 5.850 | 0.005 / 0.005 | 0.001 / 0.001 |
| C | 5.5558 / 7.2420 | 0.0161 / 1.8716 | 0.0053 / 0.8729 | 0.0042 / 0.0046 | 0.0002 / 0.0003 |
| Objective-C | 5.6397 / 7.5174 | 0.0215 / 2.0707 | 0.0145 / 2.7701 | 0.0062 / 0.0067 | 0.0007 / 0.0008 |

三个代表性前缀更清楚地展示了实现层开销对结论的影响。每格依次为
`SQLite 索引范围 / LMDB` 的 p50，单位为毫秒，加粗值为该实验中更快的方案。

| 实现 | `a`（9,242 项） | `th`（852 项） | `tes`（64 项） |
| --- | ---: | ---: | ---: |
| Python | **2.892** / 5.847 | **0.238** / 0.462 | **0.026** / 0.032 |
| C | 1.8685 / **0.8702** | 0.1612 / **0.0721** | 0.0160 / **0.0053** |
| Objective-C | **2.0686** / 2.7691 | **0.1854** / 0.2196 | 0.0215 / **0.0145** |

综合三次实验：

- 当前 `LIKE` 查询在三种实现中的 p50 都约为 5.4–5.6 ms，是最慢的前缀查询方案。
- Python 中 SQLite range 在三个代表性前缀上都更快；原生 C 中 LMDB 分别快约
  2.1、2.2 和 3.0 倍，说明 Python 的 LMDB 游标迭代与排序开销会改变结果。
- 最接近应用实际路径的 Objective-C 实验中，FMDB range 在 `a` 和 `th` 上分别快约
  1.34 和 1.18 倍，LMDB 在 `tes` 上快约 1.48 倍。LMDB 精确查询约快 8.9 倍，但两者
  的绝对耗时都低于 0.01 ms。

### 实验环境与依赖版本

三次实验均在 macOS 15.7.3（24G419）、Apple M4（arm64）上运行，使用已预热的操作系统
页缓存。C 与 Objective-C 使用 macOS SDK 15.5；各实验的语言环境和依赖版本如下：

| 实验 | 日期 | 语言环境 / 工具链 | SQLite | LMDB | 其他依赖 |
| --- | --- | --- | --- | --- | --- |
| Python | 2026-09-03 | Python 3.9.6 | Python `sqlite3` / SQLite 3.43.2 | python-lmdb 1.8.1 / LMDB 0.9.35 | — |
| C | 2026-09-04 | Apple Clang 17.0.0、C11、`-O3` | 系统 `libsqlite3` 3.43.2 | Homebrew `liblmdb` 1.0.1 | — |
| Objective-C | 2026-09-04 | Apple Clang 17.0.0、ARC、Blocks、`-O3` | FMDB 2.7.12 / SQLite 3.43.2 | Homebrew `liblmdb` 1.0.1 | Foundation |

## C & Objective-C

安装仅用于 benchmark 的 LMDB 库并运行包装脚本：

```bash
brew install lmdb
bash Tests/benchmarks/macOS-15.7.3/m4/run_native_benchmark.sh
bash Tests/benchmarks/macOS-15.7.3/m4/run_objective_c_benchmark.sh
```

可通过 `--iterations` 或 `--warmup` 调整测试负载。包装脚本使用
`clang -O3` 编译，直接链接 SQLite 和 LMDB，从仓库根目录运行，并在结束后删除临时
可执行文件。LMDB 和 benchmark 都不会成为应用的运行时依赖。

由于 SQLite 和 LMDB 都无法以可移植方式清除操作系统缓存，查询使用已预热的操作系统
页缓存。请在系统空闲时运行，并只比较同一台机器产生的结果。

## Python

```bash
python3 -m venv /tmp/hallelujah-benchmark-venv
/tmp/hallelujah-benchmark-venv/bin/pip install -r Tests/benchmarks/macOS-15.7.3/m4/requirements.txt
/tmp/hallelujah-benchmark-venv/bin/python Tests/benchmarks/macOS-15.7.3/m4/storage_benchmark.py
```
