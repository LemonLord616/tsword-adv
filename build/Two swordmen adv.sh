#!/bin/sh
printf '\033c\033]0;%s\a' Two swordmen adv
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Two swordmen adv.x86_64" "$@"
