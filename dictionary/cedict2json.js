const fs = require('fs');

const content = fs.readFileSync('./cedict_1_0_ts_utf-8_mdbg.txt', 'utf-8');
const lines = content.split('\n');
let results = {};
lines.forEach(function(line){
    if (!line.startsWith('#')) {
        const arr = line.split(/\[|\]/g);
        const [cn, tw] = arr[0].split(' ');
        const originalPinyin = arr[1];
        const pinyin = originalPinyin.replace(/\d|\s/g, '').toLowerCase();
        const translations = arr[2].split(/\//g).filter((text => text.trim() !== ""));
        if (!results[pinyin]) {
            results[pinyin] = [cn].concat(translations);
        } else {
            results[pinyin] = results[pinyin].concat([cn].concat(translations)) ;
        }
    }
});

fs.writeFileSync('cedict.json', JSON.stringify(results, null, 3), 'utf-8');