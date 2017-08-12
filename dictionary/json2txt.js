let fs = require('fs');
let words = require('./google_227800_words.json');

var list = [];
for (let key in words) {
    list.push(`${key}\t${words[key]}`);
}

fs.writeFileSync('./google_227800_words.txt', list.join('\n'), 'utf-8');