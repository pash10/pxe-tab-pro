#!/bin/bash
set -euo pipefail

SOURCE=/mnt/samba/images
DEST=/var/lib/tftpboot/iso_files
MANIFEST=${IMAGE_CHECKSUMS_FILE:-/run/secrets/image-sha256sums}
CREDENTIALS=${SAMBA_CREDENTIALS_FILE:-/run/secrets/samba-credentials}

sync_verified_images() {
    mkdir -p "$SOURCE" "$DEST"
    if ! mountpoint -q "$SOURCE"; then
        : "${SAMBA_SERVER:?Set SAMBA_SERVER}"
        [[ -f "$CREDENTIALS" && ! -L "$CREDENTIALS" ]] || return 1
        [[ "$(stat -c '%a' "$CREDENTIALS")" =~ ^(400|600)$ ]] || return 1
        mount -t cifs -o "credentials=$CREDENTIALS,ro,nosuid,nodev,noexec" "$SAMBA_SERVER" "$SOURCE"
    fi
    mountpoint -q "$SOURCE" || return 1
    [[ -s "$MANIFEST" && ! -L "$MANIFEST" ]] || return 1

    # Trust only an operator-provided manifest outside the network share.
    # Limit this prototype to flat ISO filenames. Reject unexpected paths.
    local digest name tmp count=0
    tmp=$(mktemp -d "$DEST/.verified.XXXXXXXX") || return 1
    while read -r digest name; do
        name=${name#\*}
        if [[ ! "$digest" =~ ^[A-Fa-f0-9]{64}$ || ! "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\.iso$ || ! -f "$SOURCE/$name" || -L "$SOURCE/$name" ]]; then
            rm -rf -- "$tmp"
            return 1
        fi
        if ! cp -- "$SOURCE/$name" "$tmp/$name" || ! (cd "$tmp" && printf '%s  %s\n' "$digest" "$name" | sha256sum --check --status); then
            rm -rf -- "$tmp"
            return 1
        fi
        count=$((count + 1))
    done < "$MANIFEST"
    if (( count == 0 )); then rm -rf -- "$tmp"; return 1; fi
    mountpoint -q "$SOURCE" || { rm -rf -- "$tmp"; return 1; }
    # Publish only verified files; do not remove previously published files.
    for name in "$tmp"/*.iso; do
        mv -fT -- "$name" "$DEST/$(basename "$name")" || { rm -rf -- "$tmp"; return 1; }
    done
    rmdir -- "$tmp"
}

while true; do
    if ! sync_verified_images; then
        echo "Image sync refused: check mount, permissions and trusted checksum manifest." >&2
    fi
    sleep 60
done
