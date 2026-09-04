#!/bin/bash

set -euo pipefail

script_directory=$(cd "$(dirname "$0")" && pwd)
repository_root=$(cd "$script_directory/../../../.." && pwd)
lmdb_prefix=${LMDB_PREFIX:-$(brew --prefix lmdb)}
build_directory=$(mktemp -d /tmp/hallelujah-native-benchmark.XXXXXX)
benchmark_binary="$build_directory/native_storage_benchmark"

cleanup() {
  rm -f "$benchmark_binary"
  rmdir "$build_directory" 2>/dev/null || true
}
trap cleanup EXIT

clang \
  -std=c11 \
  -O3 \
  -Wall \
  -Wextra \
  -Werror \
  -I"$lmdb_prefix/include" \
  -L"$lmdb_prefix/lib" \
  "$script_directory/native_storage_benchmark.c" \
  -llmdb \
  -lsqlite3 \
  -o "$benchmark_binary"

cd "$repository_root"
"$benchmark_binary" "$@"
