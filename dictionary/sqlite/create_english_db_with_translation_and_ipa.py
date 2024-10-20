import sqlite3
import json

with open('../words_with_frequency_and_translation_and_ipa.json', encoding='utf-8') as f:
    data = json.load(f)

conn = sqlite3.connect('words_with_frequency_and_translation_and_ipa.sqlite3')
c = conn.cursor()

# Create table
c.execute('''
CREATE TABLE IF NOT EXISTS words (
    word TEXT PRIMARY KEY,
    frequency INT,
    translation TEXT,
    ipa TEXT
)
''')

c.execute('CREATE INDEX IF NOT EXISTS idx_word ON words(word);')
c.execute('delete from words;')
c.execute("PRAGMA journal_mode=WAL")

# Insert data
for word, details in data.items():
    c.execute('''
    INSERT INTO words (word, frequency, translation, ipa) VALUES (?,?,?,?)
    ''', (word, details['frequency'], '|'.join(details['translation']), details['ipa']))

# Commit the changes and close the connection
conn.commit()
conn.close()
