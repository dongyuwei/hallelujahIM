# brew install clang-format

ls src/*.* | xargs clang-format -i
ls Tests/*.* | xargs clang-format -i
