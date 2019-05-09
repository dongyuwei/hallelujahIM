
# https://github.com/mphilli/English-to-IPA
# python3 setup.py install
# python3 words_with_frequency_and_translation_and_ipa.py

import json
import eng_to_ipa as ipa

with open('words_with_frequency_and_translation.json', 'r') as f:
    data = json.load(f)

for key, val in data.items():
    phonetic_symbol = ipa.convert(key,
                                  keep_punct=False,
                                  retrieve_all=False,
                                  stress_marks="primary")
    if phonetic_symbol:
        val["ipa"] = phonetic_symbol

file = open("words_with_frequency_and_translation_and_ipa.json", "w")
file.write(json.dumps(data, ensure_ascii=False))
file.close()