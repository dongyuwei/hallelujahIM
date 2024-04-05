import sqlite3

# Connect to your SQLite database
conn = sqlite3.connect('pinyin_data.sqlite3')
c = conn.cursor()

# Open and read your data file
with open('../google_pinyin_rawdict_utf16_65105_freq.txt', 'r', encoding='utf-16') as file:
    for line in file:
        # Split the line into components
        parts = line.strip().split(' ')
        
        # Omit the '0' and reconstruct the line if necessary
        # Assuming the format is consistent and '0' always appears at the third position
        if parts[2] == '0':
            phrase = parts[0]
            score = parts[1]
            pinyin = ''.join(parts[3:])  # Join the remaining parts as the pinyin
            abbreviation = ''.join([p[0] for p in parts[3:]])  # Create the abbreviation from the pinyin parts
            print(phrase, pinyin, abbreviation, float(score))
            # Execute the insert command
            c.execute('INSERT INTO pinyin_data (hz, py, abbr, freq) VALUES (?, ?, ?, ?)', 
                (phrase, pinyin, abbreviation, float(score)))


# Commit the changes and close the connection
conn.commit()
conn.close()
