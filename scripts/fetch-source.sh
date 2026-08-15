#!/usr/bin/env bash
#
# Fetch a source tarball from upstream and verify its SHA-256.
#
# Usage:  scripts/fetch-source.sh <path> [path ...]
#         scripts/fetch-source.sh --all
#
# The URL and expected checksum come from packages/manifest.txt. Names in the
# manifest are paths relative to the top of the repository. A file that is
# already present and already correct is left alone, so this is cheap to run
# repeatedly and safe to hang off a Makefile rule.
#
# Exits non-zero on any failure, and never leaves a partial or unverified
# download in place -- the download lands on a temporary name and is only moved
# into place once its checksum matches.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${REPO_ROOT}/packages/manifest.txt"

die() { printf '%s: %s\n' "${0##*/}" "$*" >&2; exit 1; }

[ -r "${MANIFEST}" ] || die "cannot read manifest: ${MANIFEST}"

# sha256sum on Linux, shasum -a 256 on macOS.
if command -v sha256sum >/dev/null 2>&1; then
	sha256_of() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
	sha256_of() { shasum -a 256 "$1" | awk '{print $1}'; }
else
	die "need sha256sum or shasum to verify downloads"
fi

# curl is on macOS by default, wget is common on Linux; accept either.
if command -v curl >/dev/null 2>&1; then
	download() { curl -fL --retry 3 --connect-timeout 30 -o "$2" -- "$1"; }
elif command -v wget >/dev/null 2>&1; then
	download() { wget --tries=3 --timeout=30 -O "$2" -- "$1"; }
else
	die "need curl or wget to download sources"
fi

# Look up one field of a manifest entry: manifest_field <filename> <1|2|3>
manifest_field() {
	awk -v want="$1" -v col="$2" '
		/^[[:space:]]*(#|$)/ { next }
		$1 == want { print $col; found = 1; exit }
		END { exit !found }
	' "${MANIFEST}"
}

manifest_names() {
	awk '/^[[:space:]]*(#|$)/ { next } { print $1 }' "${MANIFEST}"
}

fetch_one() {
	local name="$1" want_sum url tmp got_sum

	want_sum="$(manifest_field "${name}" 2)" || die "no manifest entry for '${name}'
Add one to ${MANIFEST#"${REPO_ROOT}"/}, or check the version set in the Makefile."
	url="$(manifest_field "${name}" 3)"

	local dest="${REPO_ROOT}/${name}"

	if [ -e "${dest}" ]; then
		got_sum="$(sha256_of "${dest}")"
		if [ "${got_sum}" = "${want_sum}" ]; then
			printf 'ok       %s (already present, checksum verified)\n' "${name}"
			return 0
		fi
		die "${name} exists but its checksum does not match the manifest.
  expected ${want_sum}
  got      ${got_sum}
Delete ${name} to re-fetch it, or correct the manifest if you
intentionally changed this file."
	fi

	printf 'fetch    %s\n' "${name}"
	printf '  from   %s\n' "${url}"

	# Manifest names are repo-relative paths, so the temporary file has to land
	# in the destination's own directory rather than at the top of the repo.
	local dest_dir="$(dirname "${dest}")"
	mkdir -p "${dest_dir}"
	tmp="$(mktemp "${dest_dir}/.$(basename "${name}").XXXXXX")"
	# shellcheck disable=SC2064  # expand tmp now, not at trap time
	trap "rm -f '${tmp}'" EXIT

	download "${url}" "${tmp}" || die "download failed for ${name} (${url})"

	got_sum="$(sha256_of "${tmp}")"
	if [ "${got_sum}" != "${want_sum}" ]; then
		die "checksum mismatch for ${name} -- refusing to use it.
  expected ${want_sum}
  got      ${got_sum}
  url      ${url}
The upstream file may have been re-rolled, or the download may be corrupt
or tampered with. Do not update the manifest without confirming why."
	fi

	# mktemp gives 0600; downloaded sources should be readable like any other.
	chmod a+r "${tmp}"
	mv -f "${tmp}" "${dest}"
	trap - EXIT
	printf 'ok       %s (checksum verified)\n' "${name}"
}

[ $# -gt 0 ] || die "usage: ${0##*/} <filename> [filename ...] | --all"

if [ "$1" = "--all" ]; then
	# Deliberately unquoted: one name per line, and names never contain spaces.
	set -- $(manifest_names)
	[ $# -gt 0 ] || die "manifest lists no files"
fi

for name in "$@"; do
	fetch_one "${name}"
done
