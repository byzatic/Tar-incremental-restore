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
MODULES="$(dirname $(realpath "$0"))/src"
# lib
. ${MODULES}/lib/root/_root.sh --source-only
# logic
. ${MODULES}/restore_tar.sh --source-only
# support
. ${MODULES}/support/version.sh --source-only

function main_processor() {
  #
  # :: $1 -- str -- restore plan regular/by_period
  # :: $2 -- str -- backup output directory abs path
  # :: $3 -- str -- backup source directory abs path
  # :: $4 -- int -- tar strip components
  # :: $5 -- str -- (OPTIONAL ARG) restore from date
  #
  local WORKING_DIRECTORY SOURCE_DIRECTORY STRIP_COMPONENTS
  local RESTORE_PLAN
  #
  RESTORE_PLAN=$(set_e && check_input "main_processor" "RESTORE_PLAN" "${1}")
  WORKING_DIRECTORY=$(set_e && check_input "main_processor" "WORKING_DIRECTORY" "${2}")
  SOURCE_DIRECTORY=$(set_e && check_input "main_processor" "SOURCE_DIRECTORY" "${3}")
  STRIP_COMPONENTS=$(set_e && check_input "main_processor" "STRIP_COMPONENTS" "${4}")
  RESTORE_FROM=$(set_e && check_input "main_processor" "RESTORE_FROM" "${5}" "ARG-PASS")

  case ${RESTORE_PLAN} in
    "regular")
      logging "INFO" "main_processor" "run in regular mode"
      restore_wrapper "${WORKING_DIRECTORY}" "${SOURCE_DIRECTORY}" "${STRIP_COMPONENTS}"
      ;;
    "by_period")
      logging "INFO" "main_processor" "run in by_period mode"
      restore_wrapper_by_period "${WORKING_DIRECTORY}" "${SOURCE_DIRECTORY}" "${STRIP_COMPONENTS}" "${RESTORE_FROM}"
      ;;
    *)
      logging "CRITICAL" "main_processor" "no such backup plan ${BACKUP_PLAN}"
      system_exit 1
      ;;
  esac
}

function main() {
  #
  # :: $1 -- str -- backup output directory abs path
  # :: $2 -- str -- backup source directory abs path
  # :: $3 -- int -- tar strip components
  # :: $4 -- str -- (OPTIONAL ARG) restore from date
  #
  local WORKING_DIRECTORY SOURCE_DIRECTORY RESTORE_FROM RESTORE_PERIOD STRIP_COMPONENTS
  local RESTORE_PLAN RESTORE_DATE
  init_logger "std" "DEBUG" "$(dirname $(realpath "$0"))/restore_controller.log"
  #
  while [[ $# -gt 0 ]]; do
      case "$1" in
          --working-directory)
              WORKING_DIRECTORY=$(set_e && check_input "${FUNCNAME}" "WORKING_DIRECTORY" "${2}")
              #logging "DEBUG" "${FUNCNAME}" "working directory WORKING_DIRECTORY= ${WORKING_DIRECTORY}"
              shift 2
              ;;
          --source-directory)
              SOURCE_DIRECTORY=$(set_e && check_input "${FUNCNAME}" "SOURCE_DIRECTORY" "${2}")
              #logging "DEBUG" "${FUNCNAME}" "source directory SOURCE_DIRECTORY= ${SOURCE_DIRECTORY}"
              shift 2
              ;;
          --strip-components)
              STRIP_COMPONENTS=$(set_e && check_input "${FUNCNAME}" "STRIP_COMPONENTS" "${2}")
              #logging "DEBUG" "${FUNCNAME}" "force flag STRIP_COMPONENTS= ${STRIP_COMPONENTS}"
              shift 2
              ;;
          --restore-from)
              RESTORE_FROM=$(set_e && check_input "${FUNCNAME}" "RESTORE_FROM" "${2}" "ARG-PASS")
              #logging "DEBUG" "${FUNCNAME}" "backup plan RESTORE_FROM= ${RESTORE_FROM}"
              shift 2
              ;;
          --restore-period)
              RESTORE_PERIOD=$(set_e && check_input "${FUNCNAME}" "RESTORE_PERIOD" "${2}" "ARG-PASS")
              #logging "DEBUG" "${FUNCNAME}" "current timestamp RESTORE_PERIOD= ${RESTORE_PERIOD}"
              shift 2
              ;;
          *)
              logging "CRITICAL" "${FUNCNAME}" "Unknown argument '${1}'"
              system_exit 1
              ;;
      esac
  done

  logging "INFO" "${FUNCNAME}" "application version $(get_version)"

  # RESTORE_PLAN - regular by_period
  # RESTORE_FROM - "2024-02-30" ""
  # RESTORE_PERIOD - Nd Nw Nm Ny

  if [ ! -z "${RESTORE_PERIOD}" ]; then
    if [ "${RESTORE_PERIOD}" == "all" ]; then
      RESTORE_PLAN="regular"
      RESTORE_DATE=""
    else
      RESTORE_PLAN="by_period"
      RESTORE_DATE="$(set_e && calculate_period "${RESTORE_PERIOD}")"
      if [ "${?}" != 0 ]; then
        logging "CRITICAL" "Error in period calculation"
        system_exit 1
      fi
    fi
  elif [ ! -z "${RESTORE_FROM}" ]; then
    RESTORE_PLAN="by_period"
    RESTORE_DATE="${RESTORE_FROM}"
  else
    logging "CRITICAL" "${FUNCNAME}" "Neither RESTORE_FROM nor RESTORE_PERIOD is set."
    system_exit 1
  fi

  logging "INFO" "${FUNCNAME}" "restore plan: ${RESTORE_PLAN}"
  logging "INFO" "${FUNCNAME}" "restore from date= ${RESTORE_DATE}"

  main_processor "${RESTORE_PLAN}" "${WORKING_DIRECTORY}" "${SOURCE_DIRECTORY}" "${STRIP_COMPONENTS}" "${RESTORE_DATE}"

}

# The function is flexible and supports any combination of Nd:Nw:Nm:Ny, even if values are repeated.
function calculate_period() {
  local RESTORE_PERIOD RESTORE_DATE num unit offset IFS parts
  #
  RESTORE_PERIOD=$(set_e && check_input "${FUNCNAME}" "RESTORE_PERIOD" "${1}")

  if [[ -z "$1" ]]; then
      logging "CRITICAL" "${FUNCNAME}" "Usage RESTORE_PERIOD: past date Nd:Nw:Nm:Ny"
      system_exit 1
  fi

  offset=""
  IFS=":" read -ra parts <<< "$1"  # Разбиваем строку по ":"

  for part in "${parts[@]}"; do
      if [[ ! "$part" =~ ^[0-9]+[dwmy]$ ]]; then
          logging "CRITICAL" "${FUNCNAME}" "Invalid format: $part"
          system_exit 1
      fi

      num="${part::-1}"   # Берём все символы, кроме последнего
      unit="${part: -1}"  # Последний символ - единица измерения

      logging "DEBUG" "${FUNCNAME}" "format num: ${num}"
      logging "DEBUG" "${FUNCNAME}" "format unit: ${unit}"

      case "$unit" in
          d) offset+=" -$num days" ;;
          w) offset+=" -$((num * 7)) days" ;;  # Неделя = 7 дней
          m) offset+=" -$num months" ;;
          y) offset+=" -$num years" ;;
          *) logging "CRITICAL" "${FUNCNAME}" "Invalid unit format"; system_exit 1 ;;
      esac
  done

  date -d "today $offset" +"%Y-%m-%d"
}


if [ "${1}" != "--source-only" ]; then
    main "${@}"
fi