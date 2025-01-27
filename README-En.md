![Platform:macOS](https://img.shields.io/badge/platform-macOS-lightgrey)
![Platform:windows](https://img.shields.io/badge/platform-windows-lightgrey)
![Platform:linux](https://img.shields.io/badge/platform-linux-lightgrey)
![github actions](https://github.com/dongyuwei/hallelujahIM/actions/workflows/github-actions-ci.yml/badge.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

# hallelujahIM

hallelujahIM is an english input method with auto-suggestions and spell check features.

1. The auto-suggestion words are derived from Google's [1/3 million most frequent English words](http://norvig.com/ngrams/count_1w.txt). I have refined this list to 140,402 words, removing nearly all misspelled ones. Candidate words are sorted by frequency.
2. HallelujahIM also functions as a Spell-Checker: when you input an incorrect word, it will suggest the right alternatives.
3. HallelujahIM also serves as a Text Expander: it loads the file `~/.you_expand_me.json` from your Home directory. Here, you can define your favorite substitutions, such as `{"te":"text expander", "yem":"you expand me"}`. Note: need to restart IME if you changed the content of `~/.you_expand_me.json`.
4. Instant translation is available as you type words (currently, it only supports English-to-Chinese, but the translation dictionary can be configured later on).
5. Pinyin to English: you can input Hanyu Pinyin and receive the matching English word.
6. Fuzzy phonetic match is another feature. For example, you can input `cerrage` or `kerrage` to get `courage`, and `aosome` or `ausome` to get `awesome`.
7. You can switch to the default English input mode (the normal, quiet, or silent mode) by pressing the **right shift** key. Pressing shift again will switch back to the auto-suggestion mode.

# download and install

1. download releases

- for **macOS 10.12 ~ 14.2**: https://github.com/dongyuwei/hallelujahIM/releases/latest, download the .pkg installer.
- for macOS 10.9 ~ 10.11(Deprecated version): https://github.com/dongyuwei/hallelujahIM/releases/tag/v1.1.1, deprecated version, need to install the .app manually.
- **Windows**: ported to Windows based on PIME，https://github.com/dongyuwei/Hallelujah-Windows, download the .exe installer.
- Linux：https://github.com/fcitx-contrib/fcitx5-hallelujah, thanks [Qijia Liu](https://github.com/eagleoflqj)！
- Android: https://github.com/dongyuwei/Hallelujah-Android

2. unzip the app, copy it to `/Library/Input\ Methods/` or `~/Library/Input\ Methods/`
3. go to `System Preferences` --> `Input Sources` --> click the + --> select English --> select hallelujah
   ![setup](https://github.com/dongyuwei/NumberInput_IMKit_Sample/blob/master/object-c/hallelujahIM/snapshots/setup.png?raw=true)
4. switch to hallelujah input method

# update/reinstall

1. delete the hallelujah from `Input Sources`
2. kill the old hallelujah Process (kill it by `pkill -9 hallelujah`, check it been killed via `ps ax|grep hallelujah` )
3. replace the hallelujah app in `/Library/Input Methods/`.
4. add the hallelujah to `Input Sources`
5. switch to hallelujah, use it.

# Why it's named hallelujahIM?

Inspired by [hallelujah_autocompletion](https://daringfireball.net/2006/10/hallelujah_autocompletion).

# preferences setting

click `Preferences...` or visit web ui: http://localhost:62718/index.html
![preference](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/preference.png)

setup:<br/>
![setup](https://github.com/dongyuwei/NumberInput_IMKit_Sample/blob/master/object-c/hallelujahIM/snapshots/setup.png?raw=true)
![preference options](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/web-preference.png?raw=true)

## Build project

1. `open hallelujah.xcworkspace`
2. build the project.

## License

GPL3(GNU GENERAL PUBLIC LICENSE Version 3)

## About libmarisa / marisa-trie

1. The static `libmarisa.a` lib was built from [marisa-trie](https://github.com/s-yata/marisa-trie) @`006020c1df76d0d7dc6118dacc22da64da2e35c4`.
2. To build the `libmarisa.a` lib, run:

```bash
git clone git://github.com/s-yata/marisa-trie.git
cd marisa-trie
brew install autoconf automake libtool -verbose
autoreconf -i
./configure --enable-static
make
## ls -alh lib/marisa/.libs/libmarisa.a
make install ## we can use marisa-build marisa-lookup marisa-reverse-lookup marisa-common-prefix-search marisa-predictive-search marisa-dump marisa-benchmark cli commands to do some tests and pre-build the trie data.
```

### Thanks to the following projects:

1. [marisa-trie](https://github.com/s-yata/marisa-trie)
2. dictionary/cedict.json is transformed from [cc-cedict](https://cc-cedict.org/wiki/)
3. [cmudict](http://www.speech.cs.cmu.edu/cgi-bin/cmudict) and https://github.com/mphilli/English-to-IPA
4. [GCDWebServer](https://github.com/swisspol/GCDWebServer)
5. [talisman](https://github.com/Yomguithereal/talisman), using its phonex algorithm to implement fuzzy phonics match.
6. [MDCDamerauLevenshtein](https://github.com/modocache/MDCDamerauLevenshtein), using it to calculate the edit distance.
7. [squirrel](https://github.com/rime/squirrel), I shamelessly copied the script to install and build pkg App for Mac.

### snapshots

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

## Paid Support

If functional you need is missing but you're ready to pay for it, feel free to contact me. If not, create an issue anyway, I'll take a look as soon as I can.

### Contact me

- wechat: dongyuwei
- gmail: newdongyuwei
