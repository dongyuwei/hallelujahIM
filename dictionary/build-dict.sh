# configure --enable-static 
# marisa-build  -t /usr/share/dict/web2  -o ./dict-test 

marisa-build  -b ./google_227800_words.txt  -o ./google-227800-words-trie.bin 

# /usr/local/lib/libmarisa.a
# ls -alh lib/marisa/.libs/libmarisa.a
