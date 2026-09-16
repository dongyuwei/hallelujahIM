![Platform:macOS](https://img.shields.io/badge/platform-macOS-blue)
![Platform:windows](https://img.shields.io/badge/platform-windows-blue)
![Platform:linux](https://img.shields.io/badge/platform-linux-blue)
![github actions](https://github.com/dongyuwei/hallelujahIM/actions/workflows/github-actions-ci.yml/badge.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)
[![GitHub downloads](https://img.shields.io/github/downloads/dongyuwei/hallelujahIM/total?label=Downloads&labelColor=27303D&color=0D1117&logo=github&logoColor=FFFFFF&style=flat)](https://github.com/dongyuwei/hallelujahIM/releases)

**中文版** | [English Version](README-En.md)

# 哈利路亚英文输入法

哈利路亚英文输入法 是 Mac(10.9+ OSX)及 Windows 平台上一款智能英语输入法。其特性如下：

1. 离线词库较大较全，词频精准。参见 Google's [1/3 million most frequent English words](http://norvig.com/ngrams/count_1w.txt).
2. 内置拼写校正功能。不用担心拼写错误，能记住大概字形、发音，本输入法就会自动显示最可能的候选词。
3. 具备 Text-Expander 功能(可在偏好设置Web页面 http://localhost:62718 中添加/删除)。 用户可以定义自己常用的词组，比如 `{"yem":"you expand me"}`，那么当输入 `yem` 时会显示 `you expand me`。
4. 即时翻译功能(显示音标，及英文单词的中文释义)。
5. 支持按拼音来输出对应英文。如输入`suanfa`，输入法会候选词中会显示 `algorithm`。
6. 支持按英文单词的模糊音来输入。 如输入 `cerrage` 或者 `kerrage` 可以得到 `courage` 候选词，也可以输入 `aosome` 或者 `ausome` 来得到 `awesome` 候选词。
7. 按键盘右侧`Command` 键可在 **智能英语**、**拼音**、**传统英语** 三种输入模式间循环切换（智能英语 → 拼音 → 传统英语 → 智能英语）。传统英语模式下按键直接透传给系统；智能英语模式提供英文候选与翻译；拼音模式下输入拼音即可打出中文。
8. 选词方式：数字键 1~9 及 `Enter` 回车键和 `Space` 空格键均可选词提交。`Space` 空格键选词默认会自动附加一个空格在单词后面，可以在配置页面关闭自动附加空格功能。`Enter` 回车键选词则不会附加空格。
9. **拼音输入中文(Pinyin to Chinese)**：按`右Command` 键循环到拼音输入模式，输入拼音即可打出中文汉字，`空格` 或数字键提交高亮候选，`Enter` 回车键提交高亮候选（不附加空格）。再次按`右Command` 循环到智能英语模式。
10. **自绘候选面板（竖排 + 网格）**：候选面板由输入法自身实现（`CandidatePanel` + `CandidatePanelState`），默认竖排候选列表，可在偏好设置中切换为网格布局并配置列数（5–9 列，默认 5 列）。网格布局参考了 [SwiftType](https://github.com/mgxv/SwiftType/) 输入法的 Grid Panel 实现：方向键导航，首次按 `↓` 展开网格，之后上下左右均可导航，在第一行再按 `↑` 收起；`←`/`→` 在当前行内循环移动；空格/回车/数字键提交高亮候选。
11. **翻译集成到候选面板（取代独立翻译窗口）**：高亮词的音标与翻译直接绘制在候选面板内，不再使用独立的悬浮窗口。竖排布局在右侧展开一列显示音标与词义（无翻译时自动收拢为单列）；网格布局在底部显示一行紧凑的释义。选中不同候选即时刷新。

# 下载与安装

1. 下载编译好的输入法应用（注意：不要点击 "Clone or download"，要从下面的链接下载 pkg 文件或者 exe 文件）

- macOS 26.6.2(Tahoe) 及以上版本：https://github.com/dongyuwei/hallelujahIM/releases/tag/build-a7c9a55 下载 pkg 自动安装文件
- macOS 10.12 ~ 15.x 老版本：https://github.com/dongyuwei/hallelujahIM/releases/tag/v1.7.2 下载 pkg 自动安装文件
- macOS 10.9 ~ 10.11 老版本（Deprecated version）: https://github.com/dongyuwei/hallelujahIM/releases/tag/v1.1.1 需要手动安装 app 文件
- **Windows 版本**: 基于 PIME 移植到 Windows 平台，https://github.com/dongyuwei/Hallelujah-Windows 下载 exe 安装文件
- Linux：https://github.com/fcitx-contrib/fcitx5-hallelujah 感谢[Qijia Liu](https://github.com/eagleoflqj)！
- Android: https://github.com/dongyuwei/Hallelujah-Android 测试版
- iOS: https://github.com/my-private-code/Luckey-SimpleKeyboard 测试版

2. 打开下载后的 hallelujah .pkg 文件，会自动安装、注册、激活哈利路亚输入法。

> **⚠️ Attention:** Mac系统如果本输入法不能正常使用，请退出当前用户重新登录，在 Input source 中手动删除再重新添加 Hallelujah 输入法.

> **⚠️ Attention:** macOS 14 以上系统用户需要在 Input source 中手动添加 Hallelujah 输入法：
<img width="651" alt="image" src="https://github.com/user-attachments/assets/f68fbe99-f62b-496d-9233-3de6f1ad2f87" />
<img width="550" height="373" alt="image" src="https://github.com/user-attachments/assets/0f5bb3d1-82f5-4759-a8e7-b91e5f3865d7" />

> **⚠️ Attention:** 重启之后如果输入法没有自动添加，请前往 设置 → 键盘 → 文字输入 手动添加。





注意：因为本程序不是通过 App Store 发布的，也没有做 Developer ID 签名和公证（notarization），macOS 会有下面的安全警告。不同系统版本的绕过方式不同：

- macOS 14 及更早版本：选中 hallelujah pkg 安装程序，右键点击 `Open` 来打开，即可开始安装输入法。
- macOS 15 (Sequoia) 及以上版本：右键 `Open` 已不再生效。需要打开 `系统设置` → `隐私与安全性`（Privacy & Security），向下滚动找到被拦截的提示，点击 `仍要打开`（Open Anyway）。
- 也可以在终端中移除隔离属性后直接双击安装：`xattr -d com.apple.quarantine ~/Downloads/hallelujah-*.pkg`

![unidentified](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/unidentified.png?raw=true)

# 为什么叫 hallelujah 这个名字?

主要是受这篇文章启发： [hallelujah_autocompletion](https://daringfireball.net/2006/10/hallelujah_autocompletion).

# 少数派网友（@北堂岚舞）测评

[英文拼写心里「没底」？这个输入法能把拼音补全为英文：哈利路亚输入法](https://sspai.com/post/56572)

# 偏好设置

点击输入法的 `Preferences` 或者直接访问本地 HTTP 服务: http://localhost:62718/index.html
![preference](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/preference.png)

<img width="724" height="496" alt="image" src="https://github.com/user-attachments/assets/93fa771f-e896-4afc-bb66-50858a596830" />

- **Use grid candidate panel（网格候选面板）**：默认关闭。开启后候选以网格显示，列数可在偏好设置里配置（5–9 列，默认 5 列；数字键只能选到 9，故上限为 9，少于 5 列不如用竖排列表）。列宽按「当前屏幕上的行」自适应：收起时只按首行排版（保持紧凑），展开时按可见的那几行排版（不会为滚出屏幕的词预留宽度）；因此展开/收起是一次有意的重排，滚动到下一屏时列宽会重新适配，而同一屏内导航列不会移动；每列都预留等宽的数字槽位，所以有数字的行和没数字的行单词左边缘对齐（首次按 `↓` 展开全部行列，之后方向键导航，`←`/`→` 在行内循环，行首再按 `↑` 收起，空格/回车/数字键提交高亮候选）；关闭时保持默认的竖排候选列表。两种布局均由输入法自绘；无论哪种布局，高亮词的音标与翻译都直接显示在候选面板内（竖排在右侧按最宽释义动态展开一列，网格在底部显示一行释义），无翻译时自动隐藏。

## 候选面板实现

候选面板为自绘实现，不再使用系统 `IMKCandidates`：

- `src/CandidatePanelState`：纯导航状态机（无 AppKit），竖排 9 行浮动窗口、网格展开/收起、列循环、行窗口滚动等逻辑全部可单测覆盖；
- `src/CandidatePanel`：`NSPanel` 封装 + `drawRect` 渲染，负责定位（光标下方、屏幕内钳制）、高亮、鼠标点击提交，并将高亮词的音标/翻译（`ConversionEngine` 的 `getAnnotation`）绘制为内置的释义列或底部释义行。

网格布局的导航语义（首次按下展开、上下左右导航、行内循环）参考了 [SwiftType](https://github.com/mgxv/SwiftType/) 输入法的 Grid Panel 实现，感谢 [mgxv](https://github.com/mgxv) 的优秀工作！


## 编译本输入法

1. `open hallelujah.xcworkspace` 使用 Xcode 打开 `hallelujah.xcworkspace` 工程，注意不是打开 `hallelujah.xcodeproj`。
2. `command + b` 构建.
3. 构建编译后的输入法可以拷贝到 `/Library/Input\ Methods/` 目录内测试。

## 如何调试输入法？

1. 使用 `NSLog()` 在关键或可疑处打 log 日志。
2. 没有 log 输出时，可以查看崩溃日志，位置可通过 `ls -l ~/Library/Logs/DiagnosticReports/ | grep hallelujah` 命令来查找。
3. 深思熟虑。
4. 使用 debug 版 build，在 Xcode 中 `Debug` -> `Attach to Process By PID or Name...` 。这个流程可以 work，但 Xcode 反应会较慢，需要在合适的地方加断点。大杀器，不得已而用之。
5. 自动化测试（后续重构目标就是可测试性要加强）。

## 格式化代码

- `sh format-code.sh`

## CI build

`sh build.sh`

## local dev script

`sh dev.sh`

## 构建安装包 pkg

`bash package/build-package.bash`

## DeepWiki
https://www.deepwiki.com/dongyuwei/hallelujahIM

## 开源协议

GPL3(GNU GENERAL PUBLIC LICENSE Version 3)

## 数据存储

本输入法使用两个 SQLite 数据库，基于 FMDB (SQLite wrapper) 进行查询：

1. **英文与拼音词库数据库**: `~/Library/Application Support/hallelujah/words_with_frequency_and_translation_and_ipa.sqlite3`
   - `words` 表：约 140,402 个英文单词的词频、中文释义和国际音标
   - `cedict_pinyin` 表：拼音到候选词的映射（中文词条与英文释义），英文模式下输入拼音时按需查询
   - 安装时从 app bundle 复制到用户目录。库内记有 `PRAGMA user_version`：当用户目录里的副本版本与 app bundle 内的不一致时（例如升级后新增了表），启动时会自动重新复制一份，并清理旧的 `-wal`/`-shm`
   - 英文前缀匹配走 `word` 主键的 B-tree 范围查询（`word >= 前缀 AND word < 前缀 + U+10FFFF`，并限制返回条数）；`word` 是 `PRIMARY KEY`，其隐式索引 `sqlite_autoindex_words_1` 已经够用，因此不再额外建 `idx_word`。刻意不用 `LIKE 'prefix%'`——索引是 BINARY 排序规则，用不上，会对 14 万行做全表扫描
   - 拼音候选同样只走 `cedict_pinyin` 主键的一次索引查询，且每个拼音最多存放 50 条（与候选面板上限一致），只物化真正能显示的字符串。这替代了早期把 17 MB 的 `cedict.json` 全部解析成 Objective-C 对象（实测约 49 MB 常驻内存）的做法

   表结构：

   ```sql
   -- 单词表：存储英文单词、词频、中文释义、国际音标
   CREATE TABLE words (
       word TEXT PRIMARY KEY,
       frequency INT,
       translation TEXT,
       ipa TEXT
   );

   -- 拼音表：拼音 -> 候选词（换行分隔，每个拼音最多 50 条）
   CREATE TABLE cedict_pinyin (
       pinyin TEXT PRIMARY KEY,
       words TEXT
   );
   ```

   数据库由 `python3 dictionary/build-sqlite.py` 生成：它从 `dictionary/cedict.json` 构建 `cedict_pinyin` 表，并删除不再使用的表和索引。`cedict.json` 只作为该脚本的输入，不再打进 app bundle。

   改动数据库结构或数据后，请同时提升 `dictionary/build-sqlite.py` 的 `SCHEMA_VERSION` 与 `src/ConversionEngine.mm` 的 `kWordsDatabaseSchemaVersion`，并重新生成数据库：两者必须相等，否则已有用户不会替换旧库，针对新表/新数据的查询会静默返回空结果。

2. **拼音引擎（librime）**: 拼音输入模式由 [librime](https://github.com/rime/librime) 驱动
   - 使用「朙月拼音」(luna_pinyin) 方案，默认输出简体中文（OpenCC t2s 转换）
   - 通过右 Command 键循环到拼音输入模式
   - 方案与词典数据位于 app bundle 内 `Contents/SharedSupport/rime-data/`
   - 首次启动时自动部署（编译产物写入 `~/Library/Application Support/hallelujah/rime/`）
   - librime 为预编译 universal 库，通过 `scripts/get-librime.sh` 下载并嵌入 app bundle

3. **自定义替换数据库**: `~/Library/Application Support/hallelujah/substitutions.sqlite3`
   - 存储用户自定义的 Text-Expander 替换规则
   - 可在偏好设置页面 (http://localhost:62718) 中添加/删除
   - 安装和更新时保留（不会被覆盖）

   表结构：

   ```sql
   CREATE TABLE substitutions (
       key TEXT PRIMARY KEY,
       value TEXT
   );
   ```

## 感谢以下开源项目:

1. [FMDB](https://github.com/ccgus/fmdb)，SQLite 数据库封装库，用于高效的前缀匹配查询。
2. [cc-cedict](https://cc-cedict.org/wiki/)：`dictionary/cedict.json` 由它转换而来，是拼音-英语词库，用于生成数据库中的 `cedict_pinyin` 表。
3. [librime](https://github.com/rime/librime)，中州韵输入法引擎，拼音输入模式的核心；配套的 [rime-prelude](https://github.com/rime/rime-prelude)、[rime-luna-pinyin](https://github.com/rime/rime-luna-pinyin)（朙月拼音方案与词典）、[rime-stroke](https://github.com/rime/rime-stroke)（笔画反查）、[rime-essay](https://github.com/rime/rime-essay)（八股文词频）与 [OpenCC](https://github.com/BYVoid/OpenCC)（简繁转换）一同构成了拼音模式的完整数据。
4. [cmudict](http://www.speech.cs.cmu.edu/cgi-bin/cmudict) and https://github.com/mphilli/English-to-IPA， 国际音标。
5. [GCDWebServer](https://github.com/swisspol/GCDWebServer)，用于用户使用偏好配置。
6. [talisman](https://github.com/Yomguithereal/talisman)，使用其中的 phonex 算法，实现模糊近似音输入。
7. [MDCDamerauLevenshtein](https://github.com/modocache/MDCDamerauLevenshtein)，配合 talisman 的 phonex 算法，在音似词中按 Damerau Levenshtein 编辑距离筛选最接近的候选词。
8. [鼠鬚管 squirrel 输入法](https://github.com/rime/squirrel) 哈利路亚输入法安装包 pkg 的制作 copy/参考了 squirrel 的实现。
9. [SwiftType](https://github.com/mgxv/SwiftType/)，网格候选面板的导航语义（首次按下展开、四向导航、行内循环）参考了其 Grid Panel 实现，感谢 [mgxv](https://github.com/mgxv)！

## 贡献代码

提交 PR 之前请执行 `sh format-code.sh` 格式化代码。

## 数据库性能对比
[benchmarks目录](benchmarks/)

1. [LMDB VS SQLite 性能对比](benchmarks/lmdb_vs_sqlite/indexed_sqlite_range_query/)

## 问题反馈，意见和建议

请提交问题单到 https://github.com/dongyuwei/hallelujahIM/issues

## 咨询服务

提供输入法功能定制开发。联系方式：

- 微信: dongyuwei
- gmail: newdongyuwei

### 一些截图

#### New UI

![english-grid-h-closed](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/english-grid-h-closed.png)
![english-grid-h](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/english-grid-h.png)
![english-grid-v](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/english-grid-v.png)
![pinyin-grid-h](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/pinyin-grid-h.png)
![pinyin-grid-v](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/pinyin-grid-v.png)

#### Old UI

auto suggestion from local dictionary:<br/>
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions.png)
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions2.png)
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions3.png)

Text Expander: <br/>
![Text Expander](https://github.com/dongyuwei/hallelujahIM/blob/textExpander/snapshots/text_expander1.png)
![Text Expander](https://github.com/dongyuwei/hallelujahIM/blob/textExpander/snapshots/text_expander2.png)

translation(inspired by [MacUIM](https://github.com/uim/uim/wiki/What%27s-uim%3F)):<br/>
![translation](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/translation.png)

spell check:<br/>
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check2.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check3.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check4.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check5.png)

pinyin in, English out: <br/>
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/gaoji.png)
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/binmayong.png)
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/kexikehe.png)
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/laozi.png)
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/roujiamo.png)
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/xiangbudao.png)

## Star History

[![Star History Chart](https://star-history.dera.page/svg?repos=dongyuwei/hallelujahIM&type=Date)](https://star-history.dera.page/#dongyuwei/hallelujahIM&Date)
