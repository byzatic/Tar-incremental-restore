#!/usr/bin/env bash
printf "Running scriptlet\n"
set -e
set -x

# shellcheck disable=SC2046
DIRECTORY=$(dirname $(readlink -e "$0"))

if [ -z "${STRIP_COMPONENTS}" ]; then
  STRIP_COMPONENTS="1"
fi

cd "${DIRECTORY}"
bash ./restore_controller.sh --working-directory "/backup_output" --source-directory "/backup_source" --strip-components "${STRIP_COMPONENTS}" --restore-from "${RESTORE_FROM}" --restore-period "${RESTORE_PERIOD}"
