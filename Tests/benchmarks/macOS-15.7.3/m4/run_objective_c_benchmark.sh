#!/bin/bash

set -euo pipefail

script_directory=$(cd "$(dirname "$0")" && pwd)
repository_root=$(cd "$script_directory/../../../.." && pwd)
lmdb_prefix=${LMDB_PREFIX:-$(brew --prefix lmdb)}
fmdb_directory="$repository_root/Pods/FMDB/src/fmdb"
build_directory=$(mktemp -d /tmp/hallelujah-objective-c-benchmark.XXXXXX)
benchmark_object="$build_directory/objective_c_storage_benchmark.o"
database_object="$build_directory/FMDatabase.o"
database_additions_object="$build_directory/FMDatabaseAdditions.o"
database_queue_object="$build_directory/FMDatabaseQueue.o"
result_set_object="$build_directory/FMResultSet.o"
benchmark_binary="$build_directory/objective_c_storage_benchmark"

cleanup() {
  rm -f \
    "$benchmark_object" \
    "$database_object" \
    "$database_additions_object" \
    "$database_queue_object" \
    "$result_set_object" \
    "$benchmark_binary"
  rmdir "$build_directory" 2>/dev/null || true
}
trap cleanup EXIT

common_flags=(
  -fobjc-arc
  -fblocks
  -O3
  -I"$fmdb_directory"
  -I"$lmdb_prefix/include"
)

clang "${common_flags[@]}" -Wall -Wextra -Werror \
  -c "$script_directory/objective_c_storage_benchmark.m" \
  -o "$benchmark_object"
clang "${common_flags[@]}" -c "$fmdb_directory/FMDatabase.m" \
  -o "$database_object"
clang "${common_flags[@]}" -c "$fmdb_directory/FMDatabaseAdditions.m" \
  -o "$database_additions_object"
clang "${common_flags[@]}" -c "$fmdb_directory/FMDatabaseQueue.m" \
  -o "$database_queue_object"
clang "${common_flags[@]}" -c "$fmdb_directory/FMResultSet.m" \
  -o "$result_set_object"

clang \
  "$benchmark_object" \
  "$database_object" \
  "$database_additions_object" \
  "$database_queue_object" \
  "$result_set_object" \
  -L"$lmdb_prefix/lib" \
  -framework Foundation \
  -llmdb \
  -lsqlite3 \
  -o "$benchmark_binary"

cd "$repository_root"
"$benchmark_binary" "$@"
