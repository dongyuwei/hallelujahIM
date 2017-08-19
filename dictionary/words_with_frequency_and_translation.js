let fs = require('fs');
let words = require('./google_227800_words.json');
let translation = require('./transformed_translation.json');

var data = {};
for (let key in words) {
    data[key] = {
        frequency: words[key]
    };
    if (translation[key]) {
        data[key].translation = translation[key];
    }
}

fs.writeFileSync('./words_with_frequency_and_translation.json', JSON.stringify(data), 'utf-8');
