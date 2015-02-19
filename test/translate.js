var levelup = require('levelup')
var fs = require('fs');
var http = require('http');

var db = levelup('./translation_leveldb')

var json = fs.readFileSync('../dictionary/google_227800_words.json', 'utf-8');
var data = JSON.parse(json);

var list = Object.keys(data),
    index = -1,
    length = list.length;

function getAndSetTranslation() {
    if(index < length - 1){
        index = index + 1;
        var word = list[index];
        http.get("http://fanyi.dict.cn/search.php?q=" + word, function(res) {
            if (res.statusCode === 200) {
                res.setEncoding('utf8');
                res.on('data', function(chunk) {
                    // console.log(word,chunk)
                    db.put(word, chunk.substring(1, chunk.length - 1), function(err) {
                        if (err) {
                            console.log('Ooops!', err)
                        }

                        getAndSetTranslation();
                    })
                });
            }
        }).on('error', function(e) {
            console.log("Got error: " + e.message);
            
            getAndSetTranslation();
        });
    }
}

getAndSetTranslation()


// db.get('name', function (err, value) {
//   if (err) return console.log('Ooops!', err)

//   console.log('name=' + value)
// })

// db.del('name', function(err){
//     if(err){
//         throw err;
//     }
// })
