import sqlite3

# Step 1: Connect to the SQLite database (it will be created if it doesn't exist)
conn = sqlite3.connect('english.sqlite3')
c = conn.cursor()

# Step 2: Create the table
c.execute('''
CREATE TABLE IF NOT EXISTS words (
    word TEXT NOT NULL,
    freq INTEGER NOT NULL
);
''')

# Step 3: Create an index on the 'word' column for efficient prefix matching
c.execute('CREATE INDEX IF NOT EXISTS idx_word ON words(word);')

# Step 4: Read from english.txt and insert data into the database
with open('../google_227800_words.txt', 'r', encoding='utf-8') as file:
    for line in file:
        parts = line.strip().split('\t')
        if len(parts) == 2:
            word, frequency = parts
            c.execute('INSERT INTO words (word, freq) VALUES (?, ?)', (word, int(frequency)))

# Commit the changes and close the connection
conn.commit()
conn.close()

print("Database created, table and index created, and data inserted successfully.")
