hallelujahIM
============

hallelujahIM is  an english input method with auto-suggestions and spell check features, Mac only(supports 10.9+ OSX).

1. The auto-suggestion words come from google's  [1/3 million most frequent English words](http://norvig.com/ngrams/count_1w.txt). I have purged it to 227800 words (all wrong words removed). Candidates words are sorted by frequency.
2. hallelujahIM is also a __Spell-Checker__: when you input wrong word, it will give you the right candidates.
3. hallelujahIM is also a __Text-Expander__: it will load the file `~/.you_expand_me.json` in your Home directory. You can define your favorite substitutions, such as `{"te":"text expander", "yem":"you expand me"}`. 
4. hallelujahIM will get __Google Suggestions__ if inputed word has prefix `gs`. 
5. You can swith to the default English input mode(the normal||quiet||silent mode) by press the shift key. Press shift again, it switch to the auto-suggestion mode

download and install
======
1. [download releases](https://github.com/dongyuwei/hallelujahIM/releases)
2. unzip the app, copy it to `/Library/Input\ Methods/` or `~/Library/Input\ Methods/`
3. go to `System Preferences` --> `Input Sources` --> click the + --> select English --> select hallelujah
4. switch to hallelujah input method

setup:<br/>
![setup](https://github.com/dongyuwei/NumberInput_IMKit_Sample/blob/master/object-c/hallelujahIM/snapshots/setup.png?raw=true)

auto suggestion:<br/>
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions.png)
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions2.png)
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions3.png)

translation(inspired by [MacUIM](https://code.google.com/p/uim/wiki/WhatsUim)):<br/>
![translation](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/translation.png)

spell check:<br/>
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check2.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check3.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check4.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check5.png)

##Paid Support

If functional you need is missing but you're ready to pay for it, feel free to contact me. If not, create an issue anyway, I'll take a look as soon as I can.
