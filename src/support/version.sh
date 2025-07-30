#!/bin/bash -e
#
#
#

function get_version() {
  local VERSION="1.0.2"
  logging "DEBUG" "${FUNCNAME}" "return version string: ${VERSION}"
  freturn "${VERSION}"
}