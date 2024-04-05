import sqlite3

# Path to the SQLite database file
db_file = 'pinyin_data.sqlite3'

# Connect to the database. This will create the file if it doesn't exist.
conn = sqlite3.connect(db_file)

# Create a cursor object using the connection
cur = conn.cursor()

# SQL statement to create the pinyin_data table
# hz hanzhi
# py pinyin
# abbr abbreviation
# freq frequency
create_table_sql = """
CREATE TABLE IF NOT EXISTS pinyin_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hz TEXT NOT NULL,
    py TEXT NOT NULL,
    abbr TEXT NOT NULL,
    freq REAL NOT NULL
);
"""

# Execute the SQL statement to create the table
cur.execute(create_table_sql)

# SQL statements to create indexes on the pinyin and abbreviation columns
create_index_pinyin_sql = "CREATE INDEX IF NOT EXISTS idx_pinyin ON pinyin_data(py);"
create_index_abbreviation_sql = "CREATE INDEX IF NOT EXISTS idx_abbr ON pinyin_data(abbr);"

# Execute the SQL statements to create the indexes
cur.execute(create_index_pinyin_sql)
cur.execute(create_index_abbreviation_sql)

# Commit the changes
conn.commit()

# Close the connection
conn.close()

print("Database, table, and indexes created successfully.")
