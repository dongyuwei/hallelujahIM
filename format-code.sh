if ! [ -x "$(command -v clang-format)" ]; then
  echo 'Error: clang-format is not installed.'
  brew install clang-format
fi

ls src/*.* | xargs clang-format -i
ls Tests/*.* | xargs clang-format -i
