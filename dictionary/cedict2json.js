const fs = require('fs');
const assert = require('assert');

const content = fs.readFileSync('./cedict_1_0_ts_utf-8_mdbg.txt', 'utf-8');
const lines = content.split('\n');
let results = {};

const googlePinyin = fs.readFileSync('./google_pinyin_rawdict_utf16_65105_freq.txt', 'ucs2');
const googlePinyinLines = googlePinyin.split('\n');
let googlePinyinFrequency = {};
googlePinyinLines.forEach(function(line) {
  // 帮 30125.3295903 0 bang
  let [cn, frequency, isSimplified, pinyin] = line.split(' ');
  // pinyin = pinyin.replace(/\s/g, '');
  googlePinyinFrequency[cn] = parseFloat(frequency);
});

lines.forEach(function(line) {
  if (!line.startsWith('#')) {
    const arr = line.split(/\[|\]/g);
    const [tw, cn] = arr[0].split(' ');
    const originalPinyin = arr[1];
    const pinyin = originalPinyin.replace(/\d|\s/g, '').toLowerCase();
    const abbr = originalPinyin
      .replace(/\d/g, '')
      .toLowerCase()
      .split(' ')
      .map(item => item.substring(0, 1))
      .join('');

    const translations = arr[2].split(/\//g).filter(text => text.trim() !== '');
    const value = {
      cn: cn,
      translations: translations
    };
    results[pinyin] = (results[pinyin] || []).concat(value);
    if (abbr.length >= 2) {
      results[abbr] = (results[abbr] || []).concat(value);
    }
  }
});

let finalResults = {};
for (let pinyin in results) {
  results[pinyin].sort(function(a, b) {
    return (googlePinyinFrequency[b.cn] || 0) - (googlePinyinFrequency[a.cn] || 0);
  });

  results[pinyin].forEach(item => {
    if (!finalResults[pinyin]) {
      finalResults[pinyin] = [item.cn].concat(item.translations);
    } else {
      if (finalResults[pinyin].indexOf(item.cn) === -1) {
        finalResults[pinyin] = finalResults[pinyin].concat(item.cn).concat(item.translations);
      } else {
        finalResults[pinyin] = finalResults[pinyin].concat(item.translations);
      }
    }
  });
}

assert.deepEqual(finalResults['ceshi'], [
  '测试',
  'to test (machinery etc)',
  'to test (students)',
  'test',
  'quiz',
  'exam',
  'beta (software)',
  '侧室',
  'sideroom',
  'concubine',
  '策士',
  'strategist',
  'counsellor on military strategy',
  '策试',
  'imperial exam involving writing essay on policy 策論|策论'
]);

assert.deepEqual(finalResults['gaoji'], [
  '高级',
  'high level',
  'high grade',
  'advanced',
  'high-ranking',
  '告急',
  'to be in a state of emergency',
  'to report an emergency',
  'to ask for emergency assistance',
  '搞基',
  '(slang) to engage in male homosexual practices'
]);

fs.writeFileSync('cedict.json', JSON.stringify(finalResults, null, 3), 'utf-8');
