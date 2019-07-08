[![Build Status](https://travis-ci.com/dongyuwei/hallelujahIM.svg?branch=master)](https://travis-ci.com/dongyuwei/hallelujahIM)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)
[English Readme](https://github.com/dongyuwei/hallelujahIM/blob/master/README-En.md)

# 哈利路亚英文输入法

哈利路亚英文输入法 是 Mac(10.9+ OSX)平台上一款智能英语输入法。其特性如下：

1. 离线词库较大较全，词频精准。参见 Google's [1/3 million most frequent English words](http://norvig.com/ngrams/count_1w.txt).
2. 内置拼写校正功能。不要担心拼写错误，能记住大概字形、发音，本输入法就会自动显示最接近的候选词。
3. 具备 Text-Expander 功能。 本输入法会自动读取定义在用户目录下的`~/.you_expand_me.json` 文件，你可以定义自己常用的词组，比如 `{"yem":"you expand me"}`，那么当输入 `yem` 时会显示 `you expand me` 。
4. 即时翻译功能(音标及英文到中文的翻译释义)。不喜欢的话也可以通过配置窗口关闭此功能。
5. 支持按拼音来输出对应英文。如输入`suanfa`，输入法会候选词中会显示 `algorithm`。
6. 支持按英文单词的模糊音来输入。 如可以输入 `cerrage` 或者 `kerrage` 来得到 `courage` 候选词，也可以输入 `aosome` 或者 `ausome` 来得到 `awesome` 候选词。
7. 按 `shift` 键可以在智能英语输入模式与传统英语输入模式中切换。

# 下载与安装

1. 下载编译好的输入法应用（注意：不要点击 "Clone or download"，要从下面的链接下载 app 压缩包）

- macOS 10.12 ~ 10.14 下载 **最新版** : https://github.com/dongyuwei/hallelujahIM/releases/latest
- macOS 10.9 ~ 10.11 老版本: https://github.com/dongyuwei/hallelujahIM/releases/tag/v1.1.1

2. 解压压缩包，复制解压后的 hallelujah.app 到 `/Library/Input\ Methods/` 目录内。
3. 通过 `System Preferences` --> `Input Sources` --> 点击 `+` --> 选中 `English` --> 选中 `hallelujah`
   ![setup](https://github.com/dongyuwei/NumberInput_IMKit_Sample/blob/master/object-c/hallelujahIM/snapshots/setup.png?raw=true)
4. 切换到 hallelujah 输入法即可使用，如果不能正常使用，建议退出当前用户重新登录或者重启系统，毕竟输入法是比较特殊的程序。

注意：因为本程序不是通过 App store 发布的，Macos 会有下面的安全警告。选中 hallelujah.app，右键点击 `Open` 来打开输入法，即可正常使用。

![unidentified](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/unidentified.png?raw=true)

# 升级或重新安装

1. 从 `Input Sources` 中删除 hallelujah 输入法。
2. 杀死旧的 hallelujah 进程 (启动 `Terminal.app`，执行 `pkill -9 hallelujah` 命令，一次杀不死可以多杀几次，因为操作系统会试图重启输入法进程 )
3. 替换 `/Library/Input Methods/` 目录中的 hallelujah.app
4. 重新添加 hallelujah 到 `Input Sources` 中。

# 为什么叫 hallelujah 这个名字?

主要是受这篇文章启发： [hallelujah_autocompletion](https://daringfireball.net/2006/10/hallelujah_autocompletion).

# 偏好设置

点击输入法的 `Preferences` 或者直接访问本地 HTTP 服务: http://localhost:62718/index.html
![preference](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/preference.png)

一些截图：<br/>
auto suggestion from local dictionary:<br/>
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions.png)
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions2.png)
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions3.png)

Text Expander: <br/>
![Text Expander](https://github.com/dongyuwei/hallelujahIM/blob/textExpander/snapshots/text_expander1.png)
![Text Expander](https://github.com/dongyuwei/hallelujahIM/blob/textExpander/snapshots/text_expander2.png)

translation(inspired by [MacUIM](https://github.com/uim/uim/wiki/WhatsUim)):<br/>
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

## 编译本输入法

1. `open hallelujah.xcworkspace` 使用 Xcode 打开 `hallelujah.xcworkspace` 工程，注意不是打开 `hallelujah.xcodeproj`。
2. `control + r` 构建.
3. 构建编译后的输入法可以拷贝到 `/Library/Input\ Methods/` 目录内测试。

## 如何调试输入法？

1. 使用 `NSLog()` 在关键或可疑处打 log 日志。
2. 没有 log 输出时，可以查看崩溃日志，位置可通过 `ls -l ~/Library/Logs/DiagnosticReports/ | grep hallelujah` 命令来查找。
3. 深思熟虑。
4. 自动化测试（后续重构目标就是可测试性要加强）。

## 开源协议

GPL3(GNU GENERAL PUBLIC LICENSE Version 3)

## 构建 libmarisa.a

1. the static `libmarisa.a` lib was built from [marisa-trie](https://github.com/s-yata/marisa-trie) @`59e410597981475bae94d9d9eb252c1d9790dc2f`
2. to build the `libmarisa.a` lib, run:

```bash
git clone git://github.com/s-yata/marisa-trie.git
cd marisa-trie
autoreconf -i
./configure --enable-static
make
```

## 感谢以下开源项目:

1. [marisa-trie](https://github.com/s-yata/marisa-trie)，输入时前缀匹配的数据结构及算法实现，特定是高性能、节省空间，可以预先构建好 trie 树再反序列化到内存中。
2. dictionary/cedict.json is transformed from [cc-cedict](https://cc-cedict.org/wiki/)，拼音-英语词库。
3. [cmudict](http://www.speech.cs.cmu.edu/cgi-bin/cmudict) and https://github.com/mphilli/English-to-IPA， 国际音标。
4. [GCDWebServer](https://github.com/swisspol/GCDWebServer)，用于用户使用偏好配置。
5. [talisman](https://github.com/Yomguithereal/talisman)，使用其中的 phonex 算法，实现模糊近似音输入。
6. [MDCDamerauLevenshtein](https://github.com/modocache/MDCDamerauLevenshtein)，配合 talisman 的 phonex 算法，在音似词中按 Damerau Levenshtein 编辑距离筛选最接近的候选词。

## 问题反馈，意见和建议

请提交问题单到 https://github.com/dongyuwei/hallelujahIM/issues。

## 付费咨询服务

提供输入法功能定制开发。联系方式：

- 微信: dongyuwei
- gmail: newdongyuwei
