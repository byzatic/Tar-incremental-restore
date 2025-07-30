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

function restore_wrapper() {
  local WORKING_DIRECTORY SOURCE_DIRECTORY STRIP_COMPONENTS
  WORKING_DIRECTORY=$(set_e && check_input "restore_wrapper" "WORKING_DIRECTORY" "${1}")
  SOURCE_DIRECTORY=$(set_e && check_input "restore_wrapper" "SOURCE_DIRECTORY" "${2}")
  STRIP_COMPONENTS=$(set_e && check_input "restore_wrapper" "STRIP_COMPONENTS" "${3}")
  #
  logging "INFO" "restore_wrapper" "run structure_responder"
  structure_responder "${WORKING_DIRECTORY}" "${SOURCE_DIRECTORY}" "${STRIP_COMPONENTS}"
}

function restore_wrapper_by_period() {
  local WORKING_DIRECTORY SOURCE_DIRECTORY STRIP_COMPONENTS
  WORKING_DIRECTORY=$(set_e && check_input "restore_wrapper" "WORKING_DIRECTORY" "${1}")
  SOURCE_DIRECTORY=$(set_e && check_input "restore_wrapper" "SOURCE_DIRECTORY" "${2}")
  STRIP_COMPONENTS=$(set_e && check_input "restore_wrapper" "STRIP_COMPONENTS" "${3}")
  RESTORE_PERIOD=$(set_e && check_input "restore_wrapper_by_period" "RESTORE_PERIOD" "${4}")
  #
  logging "INFO" "restore_wrapper" "run structure_responder"
  structure_responder "${WORKING_DIRECTORY}" "${SOURCE_DIRECTORY}" "${STRIP_COMPONENTS}" "${RESTORE_PERIOD}"
}

function structure_responder() {
  local WORKING_DIRECTORY SOURCE_DIRECTORY STRIP_COMPONENTS RESTORE_PERIOD
  WORKING_DIRECTORY=$(set_e && check_input "structure_responder" "WORKING_DIRECTORY" "${1}")
  SOURCE_DIRECTORY=$(set_e && check_input "structure_responder" "SOURCE_DIRECTORY" "${2}")
  STRIP_COMPONENTS=$(set_e && check_input "structure_responder" "STRIP_COMPONENTS" "${3}")
  RESTORE_PERIOD=$(set_e && check_input "restore_wrapper_by_period" "RESTORE_PERIOD" "${4}" "ARG-PASS")
  local STRUCTURE_YEARS="${SOURCE_DIRECTORY}/YEARS"
  local STRUCTURE_MONTHS="${SOURCE_DIRECTORY}/MONTHS"
  local STRUCTURE_WEEKS="${SOURCE_DIRECTORY}/WEEKS"
  local STRUCTURE_DAYS="${SOURCE_DIRECTORY}/DAYS"
  #
  logging "INFO" "structure_responder" "run iterate_over_structure << YEARS"
  iterate_over_structure "${STRUCTURE_YEARS}" "${WORKING_DIRECTORY}" "${STRIP_COMPONENTS}" "${RESTORE_PERIOD}"
  logging "INFO" "structure_responder" "run iterate_over_structure << MONTHS"
  iterate_over_structure "${STRUCTURE_MONTHS}" "${WORKING_DIRECTORY}" "${STRIP_COMPONENTS}" "${RESTORE_PERIOD}"
  logging "INFO" "structure_responder" "run iterate_over_structure << WEEKS"
  iterate_over_structure "${STRUCTURE_WEEKS}" "${WORKING_DIRECTORY}" "${STRIP_COMPONENTS}" "${RESTORE_PERIOD}"
  logging "INFO" "structure_responder" "run iterate_over_structure << DAYS"
  iterate_over_structure "${STRUCTURE_DAYS}" "${WORKING_DIRECTORY}" "${STRIP_COMPONENTS}" "${RESTORE_PERIOD}"
  logging "INFO" "structure_responder" "finish structure_responder"
}

function iterate_over_structure() {
  local STRUCTURE_PATH WORKING_DIRECTORY RESTORE_PERIOD
  local COMPARISON_RESULT
  STRUCTURE_PATH=$(set_e && check_input "iterate_over_structure" "STRUCTURE_PATH" "${1}")
  WORKING_DIRECTORY=$(set_e && check_input "iterate_over_structure" "WORKING_DIRECTORY" "${2}")
  STRIP_COMPONENTS=$(set_e && check_input "iterate_over_structure" "STRIP_COMPONENTS" "${3}")
  RESTORE_PERIOD=$(set_e && check_input "restore_wrapper_by_period" "RESTORE_PERIOD" "${4}" "ARG-PASS")

  # iterate over files in STRUCTURE_PATH by globbing archive_*_*_*_*.tar.gz
  for filename in "${STRUCTURE_PATH}/"archive_*_*_*_*.tar.gz; do

    # Whenever you iterate over files by globbing, it's good practice to avoid
    # the corner case where the glob does not match (which makes the loop
    # variable expand to the (un-matching) glob pattern string itself).
    #
    # -e file True if file exists (regardless of type).
    if [ -e "${filename}" ]; then
      logging "INFO" "structure_responder" "There is a files in directory ${STRUCTURE_PATH}"
      # true is a command that successfully does nothing.
      # false would, in a way, be the opposite: it doesn't do anything, but claims that a failure occurred.
      true
    else
      logging "INFO" "structure_responder" "There is no files in directory ${STRUCTURE_PATH}; passing this one"
      continue
    fi

    # -z string True if the length of string is zero.
    if [ -z ${RESTORE_PERIOD} ]; then
      logging "DEBUG" "iterate_over_structure" "structure file is ${filename}"
      __restore_tar "${filename}" "${WORKING_DIRECTORY}" "${STRIP_COMPONENTS}"
    else
      COMPARISON_RESULT=$(set_e && item1_is_greater_than_item2 "$(set_e && get_ts_from_file "${filename}")" "$(set_e && convert_date_to_seconds "${RESTORE_PERIOD}")")
      if [ "${COMPARISON_RESULT}" == "0" ]; then
        logging "DEBUG" "iterate_over_structure" "structure file is ${filename}"
        __restore_tar "${filename}" "${WORKING_DIRECTORY}" "${STRIP_COMPONENTS}"
      else
        logging "DEBUG" "iterate_over_structure" "skip file ${filename}; not in defined timeline"
      fi
    fi
  done
}

function get_ts_from_file() {
  local FILE FILE_BASENAME FILE_DATE
  FILE=$(set_e && check_input "get_ts_from_file" "FILENAME" "${1}")
  logging "INFO" "get_ts_from_file" "start getting ts from file ${FILE}"
  FILE_BASENAME=$(set_e && basename "${FILE}")
  FILE_DATE=$(set_e && echo "${FILE_BASENAME}" | cut -d '_' -f 4)
  logging "INFO" "get_ts_from_file" "derived data from filename is ${FILE_DATE}"
  freturn "${FILE_DATE}"
}

function item1_is_greater_than_item2() {
  local INT_ITEM_1 INT_ITEM_2
  INT_ITEM_1=$(set_e && check_input "item1_is_greater_than_item2" "INT_ITEM_1" "${1}")
  INT_ITEM_2=$(set_e && check_input "item1_is_greater_than_item2" "INT_ITEM_2" "${2}")
  if (( INT_ITEM_1 > INT_ITEM_2 )); then
    freturn 0
  else
    freturn 1
  fi
}

# Convert an ISO date (%Y-%m-%dT%H:%M:%S%:z) to seconds since epoch in linux bash
function convert_date_to_seconds() {
  local DATE_ISO DATE_SEC
  DATE_ISO=$(set_e && check_input "convert_date_to_seconds" "DATE_ISO" "${1}")
  DATE_SEC=$(set_e && date +%s -d "${DATE_ISO}")
  freturn "${DATE_SEC}"
}

function main() {
    exit 0
}

if [ "${1}" != "--source-only" ]; then
    main "${@}"
fi