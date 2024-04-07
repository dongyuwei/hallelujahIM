import sqlite3
import json


def query_words_by_prefix(prefix):
    with sqlite3.connect('words_with_frequency_and_translation_and_ipa.sqlite3') as conn:
        c = conn.cursor()
        # The LIKE operator is case-insensitive in SQLite by default
        c.execute('SELECT * FROM words WHERE word LIKE ? ORDER BY frequency DESC limit 30', (prefix + '%',))
        results = c.fetchall()
        # conn.close()
        
        words_details = []
        for result in results:
            words_details.append({
                "word": result[0],
                "translation": result[2],
                "ipa": result[3]
            })
        return words_details

# Example usage: Find words starting with "pre"
prefix_match_words = query_words_by_prefix("TEst")
for word_detail in prefix_match_words:
    print(111, word_detail)

prefix_match_words2 = query_words_by_prefix("good")
for word_detail in prefix_match_words2:
    print(222, word_detail)

