var levelup = require('levelup')
var fs = require('fs');
var http = require('http');

var db = levelup('./translation_leveldb')

var json = fs.readFileSync('../dictionary/google_227800_words.json', 'utf-8');
var data = JSON.parse(json);

var list = Object.keys(data), length = list.length;
list.sort(function(a, b){
    return data[a]- data[b];
});

var translation = {};
list.forEach(function(word,i){
    (function(word){
        db.get(word, function (err, value) {
            if(err){
                console.log('error: ', err)
            }

            if(value && JSON.parse(value)['ok'] === 0){
                console.log(word, value)
                db.del(word, function(err){
                    
                })
            }
          // translation[word] = value;
          // length = length - 1;

          // if(length === 0){
          //   fs.writeFileSync('all_translation.json', JSON.stringify(translation), 'utf-8');

          //   var top10000 = extractTopWords(data,translation,10000);
          //   fs.writeFileSync('top10000_translation.json', JSON.stringify(top10000), 'utf-8');

          //   var top20000 = extractTopWords(data,translation,20000);
          //   fs.writeFileSync('top20000_translation.json', JSON.stringify(top20000), 'utf-8');

          //   var top30000 = extractTopWords(data,translation,30000);
          //   fs.writeFileSync('top30000_translation.json', JSON.stringify(top30000), 'utf-8');

          //   var top50000 = extractTopWords(data,translation,50000);
          //   fs.writeFileSync('top50000_translation.json', JSON.stringify(top50000), 'utf-8');
          // }
        })
    })(word);
    
});


function extractTopWords(data,translation,limit){
    var list = Object.keys(data);
    var mapping = {};
    for(var i=0;i<limit;i++){
        mapping[list[i]] = translation[list[i]];
    }

    return mapping;
}