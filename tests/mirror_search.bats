#!/usr/bin/env bats

load helper

setup() {
  load_functions
  cd "$BATS_TEST_TMPDIR" || exit 1

  BaseURL="https://download.kiwix.org/zim/"
  COUNTRY_CODE=""
  DOWNLOAD_METHOD=1
  z=0
  LocalZIMRemoteIndexArray=(0)
  RemotePaths=("wikipedia/wikipedia_en_all_2026-01.zim")
  FileSizes=(1024)

  # Stand in for the wget binary; every call is recorded.
  wget() {
    echo "$*" >> "$BATS_TEST_TMPDIR/wget.log"
    meta4_fixture
  }
  export -f wget
}

@test "picks the priority-1 mirror" {
  call mirror_search
  [ "$DownloadURL" = "https://mirror.example.org/zim/wikipedia/wikipedia_en_all_2026-01.zim" ]
  [ "$IsMirror" -eq 1 ]
}

@test "falls back to the direct download when no mirror is offered" {
  wget() { echo "<metalink><size>1234567</size></metalink>"; }
  call mirror_search
  [ "$DownloadURL" = "https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_2026-01.zim" ]
  [ "$IsMirror" -eq 0 ]
}

@test "reads the expected size out of the meta4" {
  call mirror_search
  [ "$ExpectedSize" = "1234567" ]
}

@test "reads the sha-256 out of the meta4" {
  call mirror_search
  [ "$ExpectedHash" = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" ]
}

@test "torrent mode returns the .torrent URL and never a mirror" {
  DOWNLOAD_METHOD=2
  call mirror_search
  [ "$DownloadURL" = "https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_2026-01.zim.torrent" ]
  [ "$IsMirror" -eq 0 ]
}

@test "torrent mode still reads the size and hash so verification can run" {
  DOWNLOAD_METHOD=2
  call mirror_search
  [ "$ExpectedSize" = "1234567" ]
  [ -n "$ExpectedHash" ]
}

@test "the country code is passed through to the meta4 request" {
  COUNTRY_CODE="CA"
  call mirror_search
  grep -q "country=CA" "$BATS_TEST_TMPDIR/wget.log"
}

@test "state from a previous call does not leak into the next one" {
  call mirror_search
  [ "$IsMirror" -eq 1 ]

  wget() { echo "<metalink><size>1</size></metalink>"; }
  call mirror_search
  [ "$IsMirror" -eq 0 ]
}
