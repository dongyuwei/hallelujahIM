var levelup = require('levelup')
var fs = require('fs');
var http = require('http');

var db = levelup('./translation_leveldb')

var json = fs.readFileSync('../dictionary/google_227800_words.json', 'utf-8');
var data = JSON.parse(json);

var list = Object.keys(data), length = list.length;
var translation = {};
list.forEach(function(word,i){
    (function(word){
        db.get(word, function (err, value) {
          // if (err) return console.log('Ooops!', err)

          // console.log('name=' + value);
          translation[word] = value;
          length = length - 1;

          if(length === 0){
            fs.writeFileSync('all_translation.json', JSON.stringify(translation), 'utf-8');
          }
        })
    })(word);
    
});
