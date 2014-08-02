var fs = require('fs');
var text = fs.readFileSync('../dictionary/google_227800_words.json','utf-8');

var words = JSON.parse(text);

words["neighbourhood"] = words['neighborhood'] - 1;
words["neighbourhoods"] = words['neighborhoods'] - 1;
words["neighbour"] = words['neighbor'] - 1;
words["stringify"] = words['string'] - 8;

fs.writeFileSync('../dictionary/google_227800_words.json',JSON.stringify(words),'utf-8');