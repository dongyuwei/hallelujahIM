![Platform:macOS](https://img.shields.io/badge/platform-macOS-lightgrey)
[![Build Status](https://travis-ci.com/dongyuwei/hallelujahIM.svg?branch=master)](https://travis-ci.com/dongyuwei/hallelujahIM)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

**中文版** | [English Version](README-En.md)

# 哈利路亚英文输入法

哈利路亚英文输入法 是 Mac(10.9+ OSX)平台上一款智能英语输入法。其特性如下：

1. 离线词库较大较全，词频精准。参见 Google's [1/3 million most frequent English words](http://norvig.com/ngrams/count_1w.txt).
2. 内置拼写校正功能。不用担心拼写错误，能记住大概字形、发音，本输入法就会自动显示最可能的候选词。
3. 具备 Text-Expander 功能。 本输入法会自动读取定义在用户目录下的`~/.you_expand_me.json` 文件，你可以定义自己常用的词组，比如 `{"yem":"you expand me"}`，那么当输入 `yem` 时会显示 `you expand me` 。
4. 即时翻译功能(显示音标，及英文单词的中文释义)。不喜欢的话也可以通过配置窗口关闭此功能。
5. 支持按拼音来输出对应英文。如输入`suanfa`，输入法会候选词中会显示 `algorithm`。
6. 支持按英文单词的模糊音来输入。 如输入 `cerrage` 或者 `kerrage` 可以得到 `courage` 候选词，也可以输入 `aosome` 或者 `ausome` 来得到 `awesome` 候选词。
7. 按 `shift` 键可以在智能英语输入模式与传统英语输入模式间切换。
8. 选词方式：数字键 1~9 及 `Enter` 回车键和 `Space` 空格键均可选词提交。默认会自动附加一个空格在单词后面，可以在配置页面关闭自动附加空格功能。

# 下载与安装

1. 下载编译好的输入法应用（注意：不要点击 "Clone or download"，要从下面的链接下载 pkg 文件或者 zip 压缩包）

- macOS 10.12 ~ 10.15 下载 **最新版** : https://github.com/dongyuwei/hallelujahIM/releases/latest
- macOS 10.9 ~ 10.11 老版本: https://github.com/dongyuwei/hallelujahIM/releases/tag/v1.1.1

2. 打开下载后的 hallelujah .pkg 文件，会自动安装、注册、激活哈利路亚输入法。
3. 如果输入法不能正常使用，建议退出当前用户重新登录或者重启系统，毕竟输入法是比较特殊的程序。

注意：因为本程序不是通过 App store 发布的，Macos 会有下面的安全警告。选中 hallelujah pkg 安装程序，右键点击 `Open` 来打开，即可开始安装输入法。

![unidentified](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/unidentified.png?raw=true)

# 为什么叫 hallelujah 这个名字?

主要是受这篇文章启发： [hallelujah_autocompletion](https://daringfireball.net/2006/10/hallelujah_autocompletion).

# 少数派网友（@北堂岚舞）测评

[英文拼写心里「没底」？这个输入法能把拼音补全为英文：哈利路亚输入法](https://sspai.com/post/56572)

# 偏好设置

点击输入法的 `Preferences` 或者直接访问本地 HTTP 服务: http://localhost:62718/index.html
![preference](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/preference.png)

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

## 开源协议

GPL3(GNU GENERAL PUBLIC LICENSE Version 3)

## 构建 libmarisa.a

1. The static `libmarisa.a` lib was built from [marisa-trie](https://github.com/s-yata/marisa-trie) @`006020c1df76d0d7dc6118dacc22da64da2e35c4`.
2. To build the `libmarisa.a` lib, run:

```bash
git clone git://github.com/s-yata/marisa-trie.git
cd marisa-trie
brew install autoconf automake libtool -verbose ## proxychains4 -f /usr/local/etc/proxychains.conf brew install autoconf automake libtool -verbose
autoreconf -i
./configure --enable-static
make
## ls -alh lib/marisa/.libs/libmarisa.a
make install ## we can use marisa-build marisa-lookup marisa-reverse-lookup marisa-common-prefix-search marisa-predictive-search marisa-dump marisa-benchmark cli commands to do some tests and pre-build the trie data.
```

## 感谢以下开源项目:

1. [marisa-trie](https://github.com/s-yata/marisa-trie)，输入时前缀匹配的数据结构及算法实现，特点是高性能、节省空间，可以预先构建好 trie 树再反序列化到内存中。
2. dictionary/cedict.json is transformed from [cc-cedict](https://cc-cedict.org/wiki/)，拼音-英语词库。
3. [cmudict](http://www.speech.cs.cmu.edu/cgi-bin/cmudict) and https://github.com/mphilli/English-to-IPA， 国际音标。
4. [GCDWebServer](https://github.com/swisspol/GCDWebServer)，用于用户使用偏好配置。
5. [talisman](https://github.com/Yomguithereal/talisman)，使用其中的 phonex 算法，实现模糊近似音输入。
6. [MDCDamerauLevenshtein](https://github.com/modocache/MDCDamerauLevenshtein)，配合 talisman 的 phonex 算法，在音似词中按 Damerau Levenshtein 编辑距离筛选最接近的候选词。
7. [鼠鬚管 squirrel 输入法](https://github.com/rime/squirrel) 哈利路亚输入法安装包 pkg 的制作 copy/参考了 squirrel 的实现。

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
