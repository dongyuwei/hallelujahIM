const fs = require('fs');

const content = fs.readFileSync('./cedict_1_0_ts_utf-8_mdbg.txt', 'utf-8');
const lines = content.split('\n');
let results = {};

const googlePinyin = fs.readFileSync('./google_pinyin_rawdict_utf16_65105_freq.txt', 'utf-8');
const googlePinyinLines = googlePinyin.split('\n');
let googlePinyinFrequency = {};
googlePinyinLines.forEach(function(line){
    // 帮 30125.3295903 0 bang
    let [cn, frequency, isSimplified, pinyin] = line.split(' '); 
    // pinyin = pinyin.replace(/\s/g, '');
    googlePinyinFrequency[cn] = parseFloat(frequency);
});

lines.forEach(function(line){
    if (!line.startsWith('#')) {
        const arr = line.split(/\[|\]/g);
        const [tw, cn] = arr[0].split(' ');
        const originalPinyin = arr[1];
        const pinyin = originalPinyin.replace(/\d|\s/g, '').toLowerCase();
        const translations = arr[2].split(/\//g).filter((text => text.trim() !== ""));
        if (!results[pinyin]) {
            results[pinyin] = [cn].concat(translations);
        } else {
            if (results[pinyin].indexOf(cn) === -1) {
                results[pinyin] = results[pinyin].concat([cn].concat(translations));
            } else {
                results[pinyin] = results[pinyin].concat(translations);
            }
        }
    }
});


fs.writeFileSync('cedict.json', JSON.stringify(results, null, 3), 'utf-8');