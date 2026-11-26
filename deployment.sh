#!/bin/bash
set -euo pipefail

# A TFTP request is never approval to write a disk.
# This prototype no longer generates unattended restoration commands.
[[ $# -eq 0 ]] || { echo "Automatic disk restoration is disabled." >&2; exit 1; }
echo "Use a separately authorized, interactive recovery procedure in an isolated lab."
exit 1
