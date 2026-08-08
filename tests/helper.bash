#!/usr/bin/env bash
#
# Sources the function definitions out of kiwix-zim-updater.sh without running
# the script. Everything below the "Begin Script Execute" banner is argument
# parsing and the main loop, which would fire on source.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

load_functions() {
  local lib="$BATS_TEST_TMPDIR/kiwix_functions.sh"
  sed '/^# Begin Script Execute$/,$d' "$REPO_ROOT/kiwix-zim-updater.sh" > "$lib"
  # shellcheck disable=SC1090
  source "$lib"
}

# The script is not written for `set -e` -- `read -d ''` always returns 1 at
# EOF, and greps that legitimately match nothing return 1 too. bats runs the
# test body under errexit, so calls into the script go through here.
call() {
  set +e
  "$@"
  set -e
}

# A catalog page shaped like library.kiwix.org/catalog/v2/entries. The leading
# whitespace matters: master_scrape strips it with `grep -ioP "^\s+\K.*$"`.
catalog_fixture() {
  cat <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <updated>2026-08-07T12:00:00Z</updated>
  <entry>
    <link rel="http://opds-spec.org/acquisition/open-access" type="application/x-zim" href="https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_2026-01.zim.meta4" length="1024" />
  </entry>
  <entry>
    <link rel="http://opds-spec.org/acquisition/open-access" type="application/x-zim" href="https://download.kiwix.org/zim/gutenberg/gutenberg_en_all_2026-02.zim.meta4" length="2048" />
  </entry>
</feed>
XML
}

# A meta4 document as served by download.kiwix.org, with a priority-1 mirror.
meta4_fixture() {
  cat <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<metalink xmlns="urn:ietf:params:xml:ns:metalink">
  <file name="wikipedia_en_all_2026-01.zim">
    <size>1234567</size>
    <hash type="sha-256">0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef</hash>
    <url location="us" priority="1">https://mirror.example.org/zim/wikipedia/wikipedia_en_all_2026-01.zim</url>
    <url location="ca" priority="2">https://other.example.org/zim/wikipedia/wikipedia_en_all_2026-01.zim</url>
  </file>
</metalink>
XML
}
