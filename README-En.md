![Platform:macOS](https://img.shields.io/badge/platform-macOS-lightgrey)
![Platform:windows](https://img.shields.io/badge/platform-windows-lightgrey)
![Platform:linux](https://img.shields.io/badge/platform-linux-lightgrey)
![github actions](https://github.com/dongyuwei/hallelujahIM/actions/workflows/github-actions-ci.yml/badge.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

# hallelujahIM

hallelujahIM is an english input method with auto-suggestions and spell check features.

1. The auto-suggestion words are derived from Google's [1/3 million most frequent English words](http://norvig.com/ngrams/count_1w.txt). I have refined this list to 140,402 words, removing nearly all misspelled ones. Candidate words are sorted by frequency.
2. HallelujahIM also functions as a Spell-Checker: when you input an incorrect word, it will suggest the right alternatives.
3. HallelujahIM also serves as a Text Expander: You can define your favorite substitutions on Hallelujah's Preference UI(web page: http://localhost:62718), such as `{"te":"text expander", "yem":"you expand me"}`. 
4. Instant translation is available as you type words (currently, it only supports English-to-Chinese, but the translation dictionary can be configured later on).
5. Pinyin to English: you can input Hanyu Pinyin and receive the matching English word.
6. Fuzzy phonetic match is another feature. For example, you can input `cerrage` or `kerrage` to get `courage`, and `aosome` or `ausome` to get `awesome`.
7. You can switch to the default English input mode (the normal, quiet, or silent mode) by pressing the **right shift** key. Pressing shift again will switch back to the auto-suggestion mode.
8. **Pinyin to Chinese**: Press the right `Command` key to switch to Pinyin input mode. Type Chinese pinyin and get Chinese hanzi candidates; `space` or a digit key commits the highlighted candidate, `Enter` commits it without a trailing space. Press right `Command` again to switch back to intelligent English input mode.
9. **Custom candidate panel (vertical + grid)**: the candidate panel is drawn by the input method itself (`CandidatePanel` + `CandidatePanelState`): the default vertical candidate list, switchable to a 5-column grid layout in Preferences. The grid layout follows [SwiftType](https://github.com/mgxv/SwiftType/)'s Grid Panel design: arrow-key navigation, the first `↓` expands the grid, afterwards all four arrows navigate (another `↑` at the first row collapses it), `←`/`→` cycle within the active row, and space/Enter/digit keys commit the highlighted candidate.
10. **Translation drawn inside the candidate panel (replaces the separate annotation window)**: the highlighted word's phonetic symbol and gloss are drawn directly in the candidate panel instead of a floating window. The vertical layout expands a right column for the phonetic and meanings (collapsing back to a single column when there's no translation); the grid layout shows a compact gloss row at the bottom. Refreshes as you move the highlight.

# download and install

1. download releases

- for **macOS 26.6.2 (Tahoe) and later**: https://github.com/dongyuwei/hallelujahIM/releases/tag/build-a7c9a55, download the .pkg installer.
- for **older macOS (10.12 ~ 15.x)**: https://github.com/dongyuwei/hallelujahIM/releases/tag/v1.7.2, download the .pkg installer.
- for macOS 10.9 ~ 10.11(Deprecated version): https://github.com/dongyuwei/hallelujahIM/releases/tag/v1.1.1, deprecated version, need to install the .app manually.
- **Windows**: ported to Windows based on PIME，https://github.com/dongyuwei/Hallelujah-Windows, download the .exe installer.
- Linux：https://github.com/fcitx-contrib/fcitx5-hallelujah, thanks [Qijia Liu](https://github.com/eagleoflqj)！
- Android: https://github.com/dongyuwei/Hallelujah-Android

2. unzip the app, copy it to `/Library/Input\ Methods/` or `~/Library/Input\ Methods/`
3. go to `System Preferences` --> `Input Sources` --> click the + --> select English --> select hallelujah
   ![setup](https://github.com/dongyuwei/NumberInput_IMKit_Sample/blob/master/object-c/hallelujahIM/snapshots/setup.png?raw=true)
4. switch to hallelujah input method

> **⚠️ Note:** Because this app is not distributed through the App Store and is not signed/notarized with a Developer ID, macOS will show a security warning when you open the .pkg installer. How to get past it depends on your macOS version:
> - macOS 14 and earlier: right-click the hallelujah .pkg installer and choose `Open` to start the installation.
> - macOS 15 (Sequoia) and later: the right-click `Open` trick no longer works. Open `System Settings` → `Privacy & Security`, scroll down to the notice about the blocked installer, and click `Open Anyway`.
> - Alternatively, remove the quarantine attribute in Terminal, then double-click the pkg: `xattr -d com.apple.quarantine ~/Downloads/hallelujah-*.pkg`

> **⚠️ Note:** If the input method isn't added automatically after restarting, go to `System Settings` → `Keyboard` → `Text Input` and add it manually.

# update/reinstall

1. delete the hallelujah from `Input Sources`
2. kill the old hallelujah Process (kill it by `pkill -9 hallelujah`, check it been killed via `ps ax|grep hallelujah` )
3. replace the hallelujah app in `/Library/Input Methods/`.
4. add the hallelujah to `Input Sources`
5. switch to hallelujah, use it.

# Why it's named hallelujahIM?

Inspired by [hallelujah_autocompletion](https://daringfireball.net/2006/10/hallelujah_autocompletion).

# preferences setting

click `Preferences...` or visit web ui: http://localhost:62718/index.html
![preference](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/preference.png)

preferences config:<br/>
<img width="724" height="496" alt="image" src="https://github.com/user-attachments/assets/74e9f7a3-3287-43e5-92f2-08105dc1b461" />

- **Use grid candidate panel**: off by default. Shows candidates as a 5-column grid: the first `↓` press expands the panel to all rows, afterwards all four arrow keys navigate (`←`/`→` cycle within the active row, `↑` again at the first row collapses), and space/Enter/digits commit the highlighted candidate. Off keeps the default vertical list. Both layouts are custom-drawn; in either layout the highlighted word's phonetic and gloss are drawn inside the panel (a right column sized to the widest gloss line in vertical mode, a bottom gloss row in grid mode) and auto-hide when there's no translation.

## Candidate panel implementation

The candidate panel is drawn by the input method itself instead of the system `IMKCandidates`:

- `src/CandidatePanelState`: a pure navigation state machine with no AppKit dependency — vertical 9-row window scrolling, grid expand/collapse, column cycling, row-window scrolling — fully covered by unit tests;
- `src/CandidatePanel`: the `NSPanel` wrapper plus `drawRect` rendering, cursor positioning (below the caret, clamped to the screen), highlight, mouse-click commit, and the annotation (via `ConversionEngine`'s `getAnnotation`) drawn as a built-in gloss column or bottom gloss row.

The grid navigation semantics (first-press expand, four-way navigation, in-row cycling) are inspired by [SwiftType](https://github.com/mgxv/SwiftType/)'s Grid Panel implementation. Thanks [mgxv](https://github.com/mgxv) for the great work!

## Build project

1. `open hallelujah.xcworkspace`
2. build the project.

## License

GPL3(GNU GENERAL PUBLIC LICENSE Version 3)

## Data Storage

This input method uses two SQLite databases, queried via FMDB (SQLite wrapper):

1. **English word database**: `~/Library/Application Support/hallelujah/words_with_frequency_and_translation_and_ipa.sqlite3`
   - Contains ~140,402 English words with frequency, Chinese translation, and IPA
   - Auto-copied from the app bundle during installation
   - Used for prefix matching candidate queries

   Schema:

   ```sql
   -- Words table: stores English words, frequency, Chinese translation, and IPA
   CREATE TABLE words (
       word TEXT PRIMARY KEY,
       frequency INT,
       translation TEXT,
       ipa TEXT
   );
   CREATE INDEX idx_word ON words(word);
   ```

2. **Pinyin engine (librime)**: the pinyin input mode is powered by [librime](https://github.com/rime/librime)
   - Uses the luna_pinyin (朙月拼音) schema, Simplified Chinese output by default (OpenCC t2s)
   - Switch to pinyin mode via right Command key
   - Schema and dictionary data live in the app bundle at `Contents/SharedSupport/rime-data/`
   - Deployment runs automatically on first launch (artifacts go to `~/Library/Application Support/hallelujah/rime/`)
   - librime is a prebuilt universal library, downloaded and embedded via `scripts/get-librime.sh`

3. **Substitutions database**: `~/Library/Application Support/hallelujah/substitutions.sqlite3`
   - Stores user-defined Text-Expander substitution rules
   - Manage via the preference page at http://localhost:62718
   - Preserved across installs/updates (not overwritten)

   Schema:

   ```sql
   CREATE TABLE substitutions (
       key TEXT PRIMARY KEY,
       value TEXT
   );
   ```

### Thanks to the following projects:

1. [FMDB](https://github.com/ccgus/fmdb), SQLite wrapper for efficient prefix matching queries.
2. dictionary/cedict.json is transformed from [cc-cedict](https://cc-cedict.org/wiki/)
3. [librime](https://github.com/rime/librime), the Rime input method engine powering the pinyin mode, together with [rime-prelude](https://github.com/rime/rime-prelude), [rime-luna-pinyin](https://github.com/rime/rime-luna-pinyin) (schema and dictionary), [rime-stroke](https://github.com/rime/rime-stroke) (stroke reverse lookup), [rime-essay](https://github.com/rime/rime-essay) (word frequencies) and [OpenCC](https://github.com/BYVoid/OpenCC) (Chinese conversion).
4. [cmudict](http://www.speech.cs.cmu.edu/cgi-bin/cmudict) and https://github.com/mphilli/English-to-IPA
5. [GCDWebServer](https://github.com/swisspol/GCDWebServer)
6. [talisman](https://github.com/Yomguithereal/talisman), using its phonex algorithm to implement fuzzy phonics match.
7. [MDCDamerauLevenshtein](https://github.com/modocache/MDCDamerauLevenshtein), using it to calculate the edit distance.
8. [squirrel](https://github.com/rime/squirrel), I shamelessly copied the script to install and build pkg App for Mac.
9. [SwiftType](https://github.com/mgxv/SwiftType/), the grid candidate panel's navigation semantics (first-press expand, four-way navigation, in-row cycling) are inspired by its Grid Panel implementation. Thanks [mgxv](https://github.com/mgxv)!

### snapshots

auto suggestion from local dictionary:<br/>
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions.png)
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions2.png)
![auto-suggestion](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/suggestions3.png)

Text Expander: <br/>
![Text Expander](https://github.com/dongyuwei/hallelujahIM/blob/textExpander/snapshots/text_expander1.png)
![Text Expander](https://github.com/dongyuwei/hallelujahIM/blob/textExpander/snapshots/text_expander2.png)

translation(inspired by [MacUIM](https://github.com/uim/uim/wiki/What%27s-uim%3F)):<br/>
![translation](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/translation.png)

spell check:<br/>
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check2.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check3.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check4.png)
![spell-check](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/check5.png)

pinyin in, English out: <br/>
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/gaoji.png)
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/binmayong.png)
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/kexikehe.png)
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/laozi.png)
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/roujiamo.png)
![pinyin](https://github.com/dongyuwei/hallelujahIM/blob/master/snapshots/xiangbudao.png)

## Paid Support

If functional you need is missing but you're ready to pay for it, feel free to contact me. If not, create an issue anyway, I'll take a look as soon as I can.

### Contact me

- wechat: dongyuwei
- gmail: newdongyuwei
