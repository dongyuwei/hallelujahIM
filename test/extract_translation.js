var levelup = require('levelup')
var fs = require('fs');
var http = require('http');

var db = levelup('./words_translation.ldb')

var json = fs.readFileSync('../dictionary/google_227800_words.json', 'utf-8');
var data = JSON.parse(json);

var list = Object.keys(data),
    length = list.length;
list.sort(function(a, b) {
    return data[a] - data[b];
});

var translation = {};
list.forEach(function(word, i) {
    (function(word) {
        db.get(word, function(err, value) {
            length = length - 1;

            if(!err && value){
                translation[word] = value;
                if (length === 0) {
                    var newTranslation = {};
                    Object.keys(translation).forEach(function(key, i) {
                        if(translation[key]){
                            var list = [];
                            var data = JSON.parse(translation[key]).out;
                            if(data.translation){
                                data.translation.forEach(function(item) {
                                    if (item.join(' ').trim()) {
                                        list.push(item.join(' ').trim())
                                    }
                                });
                                newTranslation[key] = list;
                            }
                            
                        }
                        
                    });

                    fs.writeFileSync('../dictionary/transformed_translation.json', JSON.stringify(newTranslation), 'utf-8');
                }
            }
        })
    })(word);

});
