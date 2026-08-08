#!/usr/bin/env bats

load helper

setup() {
  load_functions
  cd "$BATS_TEST_TMPDIR" || exit 1

  BaseURL="https://download.kiwix.org/zim/"
  FORCE_FETCH_INDEX=0

  wget() {
    echo "fetched" >> "$BATS_TEST_TMPDIR/wget.log"
    catalog_fixture
  }
  export -f wget
}

@test "parses the remote file names out of the catalog" {
  call master_scrape
  [ "${#RemoteFiles[@]}" -eq 2 ]
  [ "${RemoteFiles[0]}" = "wikipedia_en_all_2026-01.zim" ]
  [ "${RemoteFiles[1]}" = "gutenberg_en_all_2026-02.zim" ]
}

@test "basenames drop the YYYY-MM suffix so versions can be compared" {
  call master_scrape
  [ "${Basenames[0]}" = "wikipedia_en_all_" ]
  [ "${Basenames[1]}" = "gutenberg_en_all_" ]
}

@test "remote paths keep the category directory" {
  call master_scrape
  [ "${RemotePaths[0]}" = "wikipedia/wikipedia_en_all_2026-01.zim" ]
}

@test "categories are the top-level directory" {
  call master_scrape
  [ "${RemoteCategory[0]}" = "wikipedia" ]
  [ "${RemoteCategory[1]}" = "gutenberg" ]
}

@test "file sizes are read from the length attribute" {
  call master_scrape
  [ "${FileSizes[0]}" = "1024" ]
  [ "${FileSizes[1]}" = "2048" ]
}

@test "the catalog is cached to kiwix-index" {
  call master_scrape
  [ -f kiwix-index ]
  head -1 kiwix-index | grep -q '^2026-08-07T12:00:00$'
}

@test "a fresh index is reused instead of refetching" {
  {
    date -u +%Y-%m-%dT%H:%M:%S
    echo '    <link rel="http://opds-spec.org/acquisition/open-access" type="application/x-zim" href="https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_2026-01.zim.meta4" length="1024" />'
  } > kiwix-index

  call master_scrape

  [ ! -f "$BATS_TEST_TMPDIR/wget.log" ]
  [ "${RemoteFiles[0]}" = "wikipedia_en_all_2026-01.zim" ]
}

@test "a stale index is refetched" {
  {
    date -u -d "3 days ago" +%Y-%m-%dT%H:%M:%S
    echo '    <link rel="stale" />'
  } > kiwix-index

  call master_scrape

  [ -f "$BATS_TEST_TMPDIR/wget.log" ]
  [ "${#RemoteFiles[@]}" -eq 2 ]
}

@test "an empty index file is treated as invalid" {
  : > kiwix-index
  call master_scrape
  [ -f "$BATS_TEST_TMPDIR/wget.log" ]
}

@test "--get-index forces a refetch even when the cache is fresh" {
  {
    date -u +%Y-%m-%dT%H:%M:%S
    echo '    <link rel="cached" />'
  } > kiwix-index
  FORCE_FETCH_INDEX=1

  call master_scrape

  [ -f "$BATS_TEST_TMPDIR/wget.log" ]
}

@test "an empty catalog aborts rather than reporting zero files as success" {
  wget() { echo "<feed></feed>"; }
  run master_scrape
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Could not find any remote files"
}
