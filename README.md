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
7. 按键盘右侧`shift` 键可以在智能英语输入模式与传统英语输入模式间切换。
8. 选词方式：数字键 1~9 及 `Enter` 回车键和 `Space` 空格键均可选词提交。`Space` 空格键选词默认会自动附加一个空格在单词后面，可以在配置页面关闭自动附加空格功能。`Enter` 回车键选词则不会附加空格。
9. **上下文预测(Next-Word Prediction)**：基于 Google Books Ngram Corpus (2010-2019) 英语语料库的 n-gram 频率数据，在用户输入时根据前文预测下一个单词。例如输入"i do not"后，输入法会优先推荐"know"、"think"、"want"等高频后续词。目前默认关闭这个功能，需要在输入法配置中手动打开。
10. **拼音输入中文(Pinyin to Chinese)**：按`右Command` 键切换到拼音输入模式，输入拼音（或首字母缩写）即可打出中文汉字。例如输入 `niha` 或首字母 `nh`，候选词会显示"你好"、"你还"等。再次按`右Command` 切回智能英语输入模式。

# 下载与安装

1. 下载编译好的输入法应用（注意：不要点击 "Clone or download"，要从下面的链接下载 pkg 文件或者 exe 文件）

- macOS 10.12 及以上版本： 下载 **最新版** : https://github.com/dongyuwei/hallelujahIM/releases/latest 下载 pkg 自动安装文件
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

1. **英文词库数据库**: `~/Library/Application Support/hallelujah/words_with_frequency_and_translation_and_ipa.sqlite3`
   - 包含约 140,402 个英文单词的词频、中文释义和国际音标
   - 包含约 9,955 条英语 n-gram (2~5 词短语) 频率数据，用于上下文预测
   - 安装时从 app bundle 自动复制到用户目录
   - 通过前缀匹配查询候选词

   表结构：

   ```sql
   -- 单词表：存储英文单词、词频、中文释义、国际音标
   CREATE TABLE words (
       word TEXT PRIMARY KEY,
       frequency INT,
       translation TEXT,
       ipa TEXT
   );
   CREATE INDEX idx_word ON words(word);

   -- n-gram 表：存储 2~5 词短语频率，用于上下文预测下一个词
   -- n: 短语长度 (2~5)
   -- context: 前缀（除最后一个词外的所有词），如 "i do not"
   -- next_word: 最后一个词，即预测的目标词，如 "know"
   -- frequency: 该短语在 Google Books 语料库中的出现次数
   CREATE TABLE ngrams (
       n INTEGER NOT NULL,
       context TEXT NOT NULL,
       next_word TEXT NOT NULL,
       frequency INTEGER NOT NULL,
       PRIMARY KEY (n, context, next_word)
   );
   CREATE INDEX idx_ngrams_context ON ngrams(n, context);
   ```

2. **拼音数据库**: `~/Library/Application Support/hallelujah/pinyin_data.sqlite3`
   - 包含约 55,320 条拼音→汉字映射，基于 Google 拼音词库
   - 通过右 Command 键切换到拼音输入模式
   - 支持完整拼音和首字母缩写两种输入方式
   - 候选项按词频排序
   - 安装时从 app bundle 自动复制到用户目录

   表结构：

   ```sql
   CREATE TABLE pinyin_data (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       hz TEXT NOT NULL,      -- 汉字
       py TEXT NOT NULL,      -- 完整拼音
       abbr TEXT NOT NULL,    -- 拼音首字母缩写
       freq REAL NOT NULL     -- 词频
   );
   CREATE INDEX idx_pinyin ON pinyin_data(py);
   CREATE INDEX idx_abbr ON pinyin_data(abbr);
   ```

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
2. dictionary/cedict.json is transformed from [cc-cedict](https://cc-cedict.org/wiki/)，拼音-英语词库。
3. dictionary/pinyin_data.sqlite3 基于 Google 拼音词库 (65,105 条原始数据)，拼音-汉字映射。
4. [cmudict](http://www.speech.cs.cmu.edu/cgi-bin/cmudict) and https://github.com/mphilli/English-to-IPA， 国际音标。
4. [GCDWebServer](https://github.com/swisspol/GCDWebServer)，用于用户使用偏好配置。
5. [talisman](https://github.com/Yomguithereal/talisman)，使用其中的 phonex 算法，实现模糊近似音输入。
6. [MDCDamerauLevenshtein](https://github.com/modocache/MDCDamerauLevenshtein)，配合 talisman 的 phonex 算法，在音似词中按 Damerau Levenshtein 编辑距离筛选最接近的候选词。
7. [Google Books Ngram Corpus](https://github.com/nicolas-ivanov/google-books-ngram-frequency)，提供英语 n-gram (2~5 词短语) 频率数据，用于上下文预测功能。
8. [鼠鬚管 squirrel 输入法](https://github.com/rime/squirrel) 哈利路亚输入法安装包 pkg 的制作 copy/参考了 squirrel 的实现。

## 贡献代码

提交 PR 之前请执行 `sh format-code.sh` 格式化代码。

## 问题反馈，意见和建议

请提交问题单到 https://github.com/dongyuwei/hallelujahIM/issues

## 咨询服务

提供输入法功能定制开发。联系方式：

- 微信: dongyuwei
- gmail: newdongyuwei

### 一些截图

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
