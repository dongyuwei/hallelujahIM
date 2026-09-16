#!/usr/bin/env python3
"""Rebuild the derived parts of words_with_frequency_and_translation_and_ipa.sqlite3.

The `words` table is the base dictionary. This script derives what the app
needs on top of it and drops what nothing uses:

  * `cedict_pinyin` - cedict.json's pinyin -> Chinese/English candidate list, one
    row per pinyin, entries newline-joined and capped at 50. ConversionEngine
    used to hold the whole parsed cedict.json as Objective-C objects (~49 MB
    resident for 10 MB of actual text); it now does one indexed lookup per
    keystroke and materialises only the candidates it can display.
  * drops `ngrams` and `idx_ngrams_context` - never referenced by src/.
  * drops `idx_word` - `word` is the PRIMARY KEY, so sqlite_autoindex_words_1
    is the same B-tree; EXPLAIN QUERY PLAN confirms the range query in
    -wordsStartsWith: still uses an index afterwards.
  * drops a `pinyin` table left over from the pre-rename schema.
  * sets PRAGMA user_version to the schema version ConversionEngine expects,
    which is what makes an existing install replace its stale copy.

Usage: python3 dictionary/build-sqlite.py
"""

import json
import os
import sqlite3

SCHEMA_VERSION = 3
# getCandidates: truncates the assembled list to this many candidates, and the
# pinyin entries are appended last, so entries past this one can never be
# displayed.
MAX_CANDIDATES = 50

HERE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(HERE, "words_with_frequency_and_translation_and_ipa.sqlite3")
CEDICT = os.path.join(HERE, "cedict.json")


def main():
    with open(CEDICT, encoding="utf-8") as f:
        cedict = json.load(f)

    conn = sqlite3.connect(DB)
    try:
        cur = conn.cursor()
        # `pinyin` is the pre-rename name of `cedict_pinyin`; drop it so an
        # already-migrated database does not keep both.
        cur.execute("DROP TABLE IF EXISTS pinyin")
        cur.execute("DROP TABLE IF EXISTS cedict_pinyin")
        cur.execute("CREATE TABLE cedict_pinyin (pinyin TEXT PRIMARY KEY, words TEXT)")
        cur.executemany(
            "INSERT INTO cedict_pinyin VALUES (?, ?)",
            [(pinyin, "\n".join(words[:MAX_CANDIDATES])) for pinyin, words in cedict.items()],
        )
        cur.execute("DROP TABLE IF EXISTS ngrams")
        cur.execute("DROP INDEX IF EXISTS idx_ngrams_context")
        cur.execute("DROP INDEX IF EXISTS idx_word")
        conn.commit()
        cur.execute("VACUUM")
        conn.commit()
        # The app only ever SELECTs, so WAL buys nothing and would force a
        # shared-memory (-shm) file next to the database; a plain rollback
        # journal also keeps the file readable without write access. This has
        # to run outside a transaction, hence the commits above.
        cur.execute("PRAGMA journal_mode = DELETE")
        cur.execute("PRAGMA user_version = %d" % SCHEMA_VERSION)
        conn.commit()
    finally:
        conn.close()

    print("cedict_pinyin rows: %d (capped at %d each)" % (len(cedict), MAX_CANDIDATES))
    print("database: %s (%.1f MB, schema version %d)" % (DB, os.path.getsize(DB) / 1048576.0, SCHEMA_VERSION))


if __name__ == "__main__":
    main()
