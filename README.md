hallelujahIM
============

hallelujahIM is  an english input method with auto-suggestions and spell check features, mac only.

1. The auto-suggestion words come from google's  [1/3 million most frequent English words](http://norvig.com/ngrams/count_1w.txt). I have purged it to 227800 words (all wrong words removed). Candidates words are sorted by frequency.
2. hallelujahIM is also a __Spell-Checker__: when you input wrong word, it will give you the right candidates.
3. It will show __Phonetic Symbol__ of your selected word.
4. hallelujahIM is also a __Password Manager__: it has a special __Command Mode__ to manage your password, when you input `:! zhima xyz` and press the `Enter` key, the `xyz`(which can be any valid characters) is recognized as the password. The `zhima` means `Sesame`(Open, O Sesame!) in Chinese. After the first time, just input `:! zhima` and press the `Enter` key, hallelujahIM will give the password to the paired application.
5. You can swith to the default English input mode by press the `shift` key. Press `shift` again, it switch to the auto-suggestion mode

[download releases](https://github.com/dongyuwei/hallelujahIM/releases)

![setup](https://github.com/dongyuwei/NumberInput_IMKit_Sample/blob/master/object-c/hallelujahIM/snapshots/setup.png?raw=true)


![auto-suggestion](https://github.com/dongyuwei/NumberInput_IMKit_Sample/blob/master/object-c/hallelujahIM/snapshots/auto-suggestion-2.png?raw=true)

![sort-by-frequency](https://github.com/dongyuwei/NumberInput_IMKit_Sample/blob/master/object-c/hallelujahIM/snapshots/sort-by-frequency-2.png?raw=true)

![spell-check](https://github.com/dongyuwei/NumberInput_IMKit_Sample/blob/master/object-c/hallelujahIM/snapshots/spell-check-1.png?raw=true)

![spell-check-2](https://github.com/dongyuwei/NumberInput_IMKit_Sample/blob/master/object-c/hallelujahIM/snapshots/spell-check-2.png?raw=true)


##Paid Support

If functional you need is missing but you're ready to pay for it, feel free to contact me. If not, create an issue anyway, I'll take a look as soon as I can.

中文说明
=======
1. hallelujahIM 是一个mac平台上的智能英文输入法. 它可以按照prefix前缀自动补全英语单词，候选词列表按使用频率排列。总词库有227800个单词。

2. hallelujahIM也是一个拼写检查器(spell checker)，当用户输入错误的单词时，它会自动提示最相近的正确单词列表。

3. hallelujahIM也是一个密码管理器，免费的OnePass替代品:) ：第一次在密码框输入 :! zhima xyz 按回车键, xyz就是用户的密码字符串。zhima就是芝麻开门的意思(Open, O Sesame!) 。以后只要输入 :! zhima 按回车键, 输入法就会自动输入密码给对应的应用程序（如Cisco AnyConnectVPN client）。

4. hallelujahIM可以显示用户选中的候选单词的音标。

5. 按shift键，可以切换到原始的English input状态，比如在iterm2下不想使用自动补全模式。再次按shift键，切换到自动补全模式。
