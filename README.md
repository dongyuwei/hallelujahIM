hallelujahIM(哈利路亚 英文输入法)
============

hallelujahIM is  an english input method with auto-suggestions and spell check features, Mac only(supports 10.9+ OSX).

1. The auto-suggestion words come from google's  [1/3 million most frequent English words](http://norvig.com/ngrams/count_1w.txt). I have purged it to 227800 words (all wrong words removed). Candidates words are sorted by frequency.
2. hallelujahIM is also a __Spell-Checker__: when you input wrong word, it will give you the right candidates.
3. It will show __Phonetic Symbol__ of your selected word.
4. hallelujahIM is also a __Password Manager__: it has a special __Command Mode__ to manage your password.
    1. set/update password: input `:! zhima your_password` and press the `Enter` key. The `zhima` means `Sesame`(Open, O Sesame!) in Chinese. 
    2. get password: just input `:! zhima` and press the `Enter` key, hallelujahIM will give the password according to the key.
    3. Is it safe? Yes. It stores your password based on cocoa `security` framework. 
5. You can swith to the default English input mode by press the `shift` key. Press `shift` again, it switch to the auto-suggestion mode
6. when annotation clicked, speak(like the `say` cmd) the word.

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
