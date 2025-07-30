#!/bin/bash -e
#
#  MIT License
#
#  Copyright (c) 2023 s.vlasov.home@icloud.com
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in all
#  copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.
#

#  logging "CRITICAL" "main" "###### DEVELOP STOP #####" && system_exit 1

# shellcheck disable=SC2046
MODEULES="$(dirname $(realpath "$0"))/src"
# lib
. ${MODEULES}/lib/root/_root.sh --source-only
# src


function test_program_regular_mode() {
  logging "INFO" "test_program_regular_mode" "-----------------------------------"
  logging "INFO" "test_program_regular_mode" "--test test_program_regular_mode---"
  logging "INFO" "test_program_regular_mode" "-----------------------------------"
  local CONTROLLER_EXITCODE
  local BASEDIR DST_DIR SOURCE_DIR
  BASEDIR=$(set_e && check_input "test_program" "BASEDIR" "${1}")
  DST_DIR=$(set_e && check_input "test_program" "DST_DIR" "${2}")
  SOURCE_DIR=$(set_e && check_input "test_program" "SOURCE_DIR" "${3}")
  STRIP_COMPONENTS="6"
  ${BASEDIR}/restore_controller.sh "${DST_DIR}" "${SOURCE_DIR}" "${STRIP_COMPONENTS}"
  CONTROLLER_EXITCODE=$?
  echo -e "$( date +%Y.%m.%d-%H:%M:%S) [DEBUG] (test): restore_controller.sh finished with exit code ${CONTROLLER_EXITCODE}"
  if [ "${CONTROLLER_EXITCODE}" != "0" ]; then
    echo -e "$( date +%Y.%m.%d-%H:%M:%S) [ERROR] (test): something goes wrong in ${BASEDIR}/restore_controller.sh; exit code ${CONTROLLER_EXITCODE}"
    echo -e "$( date +%Y.%m.%d-%H:%M:%S) [ERROR] (test): call was ${BASEDIR}/restore_controller.sh "
    exit 1
  fi
}


function test_program_by_period_mode() {
  logging "INFO" "test_program_by_period_mode" "-----------------------------------"
  logging "INFO" "test_program_by_period_mode" "--test test_program_by_period_mode-"
  logging "INFO" "test_program_by_period_mode" "-----------------------------------"
  local CONTROLLER_EXITCODE
  local BASEDIR DST_DIR SOURCE_DIR TS STRIP_COMPONENTS
  BASEDIR=$(set_e && check_input "test_program" "BASEDIR" "${1}")
  DST_DIR=$(set_e && check_input "test_program" "DST_DIR" "${2}")
  SOURCE_DIR=$(set_e && check_input "test_program" "SOURCE_DIR" "${3}")
  TS=$(set_e && check_input "test_program" "SOURCE_DIR" "${4}")
  STRIP_COMPONENTS="6"
  ${BASEDIR}/restore_controller.sh "${DST_DIR}" "${SOURCE_DIR}" "${STRIP_COMPONENTS}" "${TS}"
  CONTROLLER_EXITCODE=$?
  echo -e "$( date +%Y.%m.%d-%H:%M:%S) [INFO] (test): restore_controller.sh finished with exit code ${CONTROLLER_EXITCODE}"
  if [ "${CONTROLLER_EXITCODE}" != "0" ]; then
    echo -e "$( date +%Y.%m.%d-%H:%M:%S) [ERROR] (test): something goes wrong in ${BASEDIR}/restore_controller.sh; exit code ${CONTROLLER_EXITCODE}"
    echo -e "$( date +%Y.%m.%d-%H:%M:%S) [ERROR] (test): call was ${BASEDIR}/restore_controller.sh "
    exit 1
  fi
}

function recreate_folders() {
  BASEDIR=$(set_e && check_input "test_program" "BASEDIR" "${1}")
  rm -rf ${BASEDIR}/TEST_RESTORED
  mkdir -p ${BASEDIR}/TEST_RESTORED
}

function main() {
  init_logger "std" "INFO" "$(dirname $(realpath "$0"))/test_restore_controller.log"
  BASEDIR="$(dirname $(realpath "$0"))"
  DST_DIR="${BASEDIR}/TEST_RESTORED"
  SOURCE_DIR="${BASEDIR}/../tar-incremental-backup/TESTS/DIST"
  recreate_folders "${BASEDIR}"
  test_program_regular_mode "${BASEDIR}" "${DST_DIR}" "${SOURCE_DIR}"
  recreate_folders "${BASEDIR}"
  test_program_by_period_mode "${BASEDIR}" "${DST_DIR}" "${SOURCE_DIR}" "2020-06-10"
}

if [ "${1}" != "--source-only" ]; then
    main "${@}"
fi