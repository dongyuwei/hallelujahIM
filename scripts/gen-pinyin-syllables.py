#!/usr/bin/env python3
"""Regenerate the syllable table in src/PinyinSegmenter.m.

The table is the union of the syllables used by rime-data/luna_pinyin.dict.yaml
and dictionary/cedict_1_0_ts_utf-8_mdbg.txt, minus single-letter noise (only a,
e, o are syllables on their own) and CEDICT junk (xx, ging, the erhua suffix
r), plus lue/nue (the schema's spelling corrections accept nue/lue for
nüe/lüe). Re-run this after either dictionary changes, then run
`sh format-code.sh` (the emitter does not wrap lines the way clang-format does)
and keep the marginal cases in Tests/TestPinyinSegmenter.m green.

Usage: python3 scripts/gen-pinyin-syllables.py
"""

import os
import re
import string

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SEGMENTER = os.path.join(ROOT, "src", "PinyinSegmenter.m")


def syllables_from_file(path, extract):
    syl = set()
    with open(path, encoding="utf-8") as f:
        for line in f:
            for s in extract(line):
                s = re.sub(r"\d", "", s).lower()
                if s.isalpha():
                    syl.add(s)
    return syl


def rime_dict_line(line):
    if line.startswith("#") or line.startswith("..."):
        return []
    parts = line.rstrip("\n").split("\t")
    return parts[1].split() if len(parts) >= 2 else []


def cedict_line(line):
    m = re.search(r"\[([^\]]+)\]", line)
    return m.group(1).split() if m else []


def main():
    syl = syllables_from_file(os.path.join(ROOT, "rime-data", "luna_pinyin.dict.yaml"), rime_dict_line)
    syl |= syllables_from_file(os.path.join(ROOT, "dictionary", "cedict_1_0_ts_utf-8_mdbg.txt"), cedict_line)
    syl -= set(string.ascii_lowercase) - {"a", "e", "o"}
    syl -= {"xx", "ging", "r"}
    syl |= {"lue", "nue"}

    words = sorted(syl)
    chunks, cur = [], ""
    for w in words:
        if len(cur) + len(w) + 1 > 96:
            chunks.append(cur)
            cur = w
        else:
            cur = (cur + " " + w) if cur else w
    chunks.append(cur)
    lit = 'static NSString *const kSyllables =\n' + "".join(f'    @"{c} "\n' for c in chunks[:-1]) + f'    @"{chunks[-1]}";'

    src = open(SEGMENTER, encoding="utf-8").read()
    src, n = re.subn(r"static NSString \*const kSyllables =.*?;", lit, src, count=1, flags=re.S)
    if n != 1:
        raise SystemExit("kSyllables block not found in PinyinSegmenter.m")
    open(SEGMENTER, "w", encoding="utf-8").write(src)
    print("%d syllables written to %s" % (len(syl), SEGMENTER))


if __name__ == "__main__":
    main()
