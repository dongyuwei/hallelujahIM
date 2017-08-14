let fs = require('fs');
let words = require('./google_227800_words.json');

var list = [];
for (let key in words) {
    list.push(`[dict setObject: @${words[key]} forKey: @"${key}"];`);
}

let tpl = `
// This file is generated via **hallelujahIM/dictionary/json2NSDict.js**, don't modify it manually.

#import "Words.h"

@implementation Words

+ (NSDictionary*)buildWordsWithFrequency{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    ${list.join("\n\t")};
    return [dict mutableCopy];
}

@end
`
fs.writeFileSync('./Words.m.generated', tpl, 'utf-8');