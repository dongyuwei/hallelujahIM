# 词库存储基准测试

本基准测试使用哈利路亚输入法实际的 140,402 词词库和真实访问模式，回答 [issue #191](https://github.com/dongyuwei/hallelujahIM/issues/191) 中 SQLite 与 LMDB 的性能及体积问题。

[中文](README.md) | [EN](README-En.md)

测试对比：

- 当前 SQLite `LIKE prefix%` 查询；
- 等价的 SQLite B-tree 范围查询；
- LMDB 游标前缀扫描；
- 单词及注释的精确查询；
- 数据库构建时间、逻辑文件大小和实际占用空间。

所有后端均存储相同的单词、词频、翻译和国际音标。前缀查询会完整读取匹配结果并按词频排序。计时前，脚本会验证所有后端返回完全相同的结果。

## 运行方法
```bash
python3 -m venv /tmp/hallelujah-benchmark-venv
/tmp/hallelujah-benchmark-venv/bin/pip install -r Tests/benchmarks/macOS-15.7.3/m4/requirements.txt
/tmp/hallelujah-benchmark-venv/bin/python Tests/benchmarks/macOS-15.7.3/m4/storage_benchmark.py
```

可通过 `--iterations`、`--warmup` 或 `--prefixes` 调整测试负载。

由于 SQLite 和 LMDB 都无法以可移植方式清除操作系统缓存，查询数据使用已预热的操作系统页缓存。

## 参考结果

- 测试时间: 2026-09-03
- 测试系统: macOS 15.7.3
- 测试CPU: Apple Silicon M4
- 每个输入执行100次计时
- 延迟数据使用已预热的操作系统页缓存，并包含读取所有前缀匹配项及按词频排序的开销

| 操作 | p50（毫秒） | p95（毫秒） |
| --- | ---: | ---: |
| SQLite 前缀查询（当前 `LIKE`） | 5.406 | 7.979 |
| SQLite 前缀查询（索引范围查询） | 0.026 | 2.896 |
| LMDB 游标前缀查询 | 0.032 | 5.850 |
| SQLite 精确查询 | 0.005 | 0.005 |
| LMDB 精确查询 | 0.001 | 0.001 |

对于几个有代表性的前缀，实验性 SQLite 范围查询 9,242 个 `a` 匹配项耗时 2.892 毫秒，查询 852 个 `th` 匹配项耗时 0.238 毫秒，查询 64 个 `tes` 匹配项耗时 0.026 毫秒；LMDB 分别耗时 5.847、0.462 和 0.032 毫秒。LMDB 在结果集很小及精确键查询时更快，而随着前缀结果集增大，SQLite 范围查询更快。

| 格式 | 单词数 | 文件大小（MiB） |
| --- | ---: | ---: |
| 当前内置 SQLite（单词及 n-gram） | 140,402 | 14.42 |
| SQLite（仅单词，当前表结构） | 140,402 | 13.63 |
| LMDB | 140,402 | 10.04 |

在仅比较相同单词数据时，本次 LMDB 文件比采用当前表结构的 SQLite 文件小约 26.3%。内置 SQLite 的 n-gram 数据不参与该百分比计算。具体数值可能随 SQLite、LMDB 版本和文件系统页面分配方式变化，因此在新的运行环境中应以脚本输出为准。


## 结果讨论

测试结果显示，LMDB 的精确键查询和游标前缀扫描都快于应用当前使用的 SQLite `LIKE` 查询，并且同样只保存单词数据时，LMDB 文件更小。

测试中额外加入了 SQLite 索引范围查询作为参考：它可以使用现有索引，并且在结果集较大时快于 LMDB。

内置 SQLite 文件同时包含 140,402 条单词数据和 9,955 条 n-gram 数据，本次测试会完整保留源文件。为公平比较词库存储体积，脚本只读取其中的 `words` 数据。