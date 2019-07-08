[![Build Status](https://travis-ci.com/dongyuwei/hallelujahIM.svg?branch=master)](https://travis-ci.com/dongyuwei/hallelujahIM)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

# hallelujahIM

hallelujahIM is an english input method with auto-suggestions and spell check features, Mac only(supports 10.9+ OSX).

1. The auto-suggestion words come from google's [1/3 million most frequent English words](http://norvig.com/ngrams/count_1w.txt). I have purged them to 140402 words (almost all misspelled words removed). Candidate words are sorted by frequency.
2. hallelujahIM is also a **Spell-Checker**: when you input wrong word, it will give you the right candidates.
3. hallelujahIM is also a **Text-Expander**: it will load the file `~/.you_expand_me.json` in your Home directory. You can define your favorite substitutions, such as `{"te":"text expander", "yem":"you expand me"}`.
4. Instant translation when you type words(currently it supports English-to-Chinese only, but the translation dictionary can be configured later on).
5. Pinyin in, English out: you can input Hanyu Pinyin and get the matching English word.
6. Fuzzy phonetic match. For example, you can input `cerrage` or `kerrage` to get `courage`, and you can input `aosome` or `ausome` to get `awesome`.
7. You can swith to the default English input mode(the normal||quiet||silent mode) by pressing the shift key. Pressing shift again, it will switch to the auto-suggestion mode.

# download and install

1. download releases

- for macOS 10.9 ~ 10.11: https://github.com/dongyuwei/hallelujahIM/releases/tag/v1.1.1
- for macOS 10.12 ~ 10.14: https://github.com/dongyuwei/hallelujahIM/releases/latest

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

## Paid Support

If functional you need is missing but you're ready to pay for it, feel free to contact me. If not, create an issue anyway, I'll take a look as soon as I can.

## Build project

1. `open hallelujah.xcworkspace`
2. build the project.

## License

GPL3(GNU GENERAL PUBLIC LICENSE Version 3)

## About libmarisa / marisa-trie

1. the static `libmarisa.a` lib was built from [marisa-trie](https://github.com/s-yata/marisa-trie) @`59e410597981475bae94d9d9eb252c1d9790dc2f`
2. to build the `libmarisa.a` lib, run:

```bash
git clone git://github.com/s-yata/marisa-trie.git
cd marisa-trie
autoreconf -i
./configure --enable-static
make
```

### Thanks to the following projects:

1. [marisa-trie](https://github.com/s-yata/marisa-trie)
2. dictionary/cedict.json is transformed from [cc-cedict](https://cc-cedict.org/wiki/)
3. [cmudict](http://www.speech.cs.cmu.edu/cgi-bin/cmudict) and https://github.com/mphilli/English-to-IPA
4. [GCDWebServer](https://github.com/swisspol/GCDWebServer)

### Contact me

- wechat: dongyuwei
- gmail: newdongyuwei
