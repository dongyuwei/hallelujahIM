#!/bin/bash
# Fetch the pinned Rime data files (luna_pinyin preset) into rime-data/.
# Run once; commit the resulting files so builds stay reproducible.
set -euo pipefail

cd "$(dirname "$0")/.."

PRELUDE_SHA="082425ea0684bca36474415d4a0e8db9b016487e"
LUNA_PINYIN_SHA="56b934b099dfbeab842320f13aa8b461a6ab3e42"
STROKE_SHA="1e8fff9b9494ddec23b0cbc526bcfd8171a6fd48"
ESSAY_SHA="e9b1a374a6ea015fca5bdd04318924b4483ac35a"
OPENCC_TAG="1.4.2"

fetch() {
  local url="$1" dest="$2"
  echo "Fetching ${url}"
  curl -fsSL --http1.1 --retry 5 --retry-delay 2 --retry-all-errors -o "${dest}" "${url}"
}

mkdir -p rime-data/opencc

# rime-prelude: core config + shared tables referenced via __include
fetch "https://raw.githubusercontent.com/rime/rime-prelude/${PRELUDE_SHA}/default.yaml" rime-data/default.yaml
fetch "https://raw.githubusercontent.com/rime/rime-prelude/${PRELUDE_SHA}/punctuation.yaml" rime-data/punctuation.yaml
fetch "https://raw.githubusercontent.com/rime/rime-prelude/${PRELUDE_SHA}/key_bindings.yaml" rime-data/key_bindings.yaml
fetch "https://raw.githubusercontent.com/rime/rime-prelude/${PRELUDE_SHA}/symbols.yaml" rime-data/symbols.yaml

# rime-luna-pinyin: schema + main dict + fuzzy-pinyin algebra template
fetch "https://raw.githubusercontent.com/rime/rime-luna-pinyin/${LUNA_PINYIN_SHA}/luna_pinyin.schema.yaml" rime-data/luna_pinyin.schema.yaml
fetch "https://raw.githubusercontent.com/rime/rime-luna-pinyin/${LUNA_PINYIN_SHA}/luna_pinyin.dict.yaml" rime-data/luna_pinyin.dict.yaml
fetch "https://raw.githubusercontent.com/rime/rime-luna-pinyin/${LUNA_PINYIN_SHA}/pinyin.yaml" rime-data/pinyin.yaml

# empty custom_phrase table (referenced by luna_pinyin's custom_phrase translator)
if [ ! -f rime-data/custom_phrase.txt ]; then
  printf '# Rime table\n# encoding: utf-8\n#@/db_name\tcustom_phrase.txt\n#@/db_type\tstable\n#@/table_name\tcustom_phrase\n#@/sort_order\t1\n#@/version\t1\n' > rime-data/custom_phrase.txt
fi

# rime-stroke: reverse-lookup dependency declared by luna_pinyin
fetch "https://raw.githubusercontent.com/rime/rime-stroke/${STROKE_SHA}/stroke.dict.yaml" rime-data/stroke.dict.yaml

# rime-essay: 八股文 preset vocabulary used for phrase frequencies
# (luna_pinyin.dict.yaml sets use_preset_vocabulary: true)
fetch "https://raw.githubusercontent.com/rime/rime-essay/${ESSAY_SHA}/essay.txt" rime-data/essay.txt

# OpenCC: the prebuilt librime embeds OpenCC 1.1.9, which only reads compiled
# .ocd2 dictionaries and requires the classic 1.x config layout (with a
# "segmentation" node). Pull the compiled dicts from the OpenCC PyPI wheel and
# write a 1.x-style t2s.json.
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT
pip3 download "opencc==${OPENCC_TAG}" --no-deps -d "${TMP_DIR}" -q
unzip -oq "${TMP_DIR}"/opencc-*.whl -d "${TMP_DIR}/wheel"
WHEEL_SHARE="${TMP_DIR}/wheel/opencc/clib/share/opencc"
cp "${WHEEL_SHARE}/TSPhrases.ocd2" "${WHEEL_SHARE}/TSCharacters.ocd2" rime-data/opencc/
cat > rime-data/opencc/t2s.json <<'EOF'
{
  "name": "Traditional Chinese (OpenCC Standard) to Simplified Chinese",
  "segmentation": {
    "type": "mmseg",
    "dict": {
      "type": "group",
      "match_policy": "short_circuit",
      "dicts": [
        { "type": "ocd2", "file": "TSPhrases.ocd2" },
        { "type": "ocd2", "file": "TSCharacters.ocd2" }
      ]
    }
  },
  "conversion_chain": [
    {
      "dict": {
        "type": "group",
        "match_policy": "short_circuit",
        "dicts": [
          { "type": "ocd2", "file": "TSPhrases.ocd2" },
          { "type": "ocd2", "file": "TSCharacters.ocd2" }
        ]
      }
    }
  ]
}
EOF

ls -la rime-data rime-data/opencc
