#!/bin/bash

load_colors() {
  if [ -t 1 ] ; then
    export ESC_SEQ="\x1b["
    export COL_RESET="${ESC_SEQ}39;49;00m"
    export COL_LIGHT="${ESC_SEQ}1m"
    export COL_DIM="${ESC_SEQ}2m"
    export COL_BLINK="${ESC_SEQ}5m"
    export COL_RED="${ESC_SEQ}31m"
    export COL_GREEN="${ESC_SEQ}32m"
    export COL_YELLOW="${ESC_SEQ}33m"
    export COL_BLUE="${ESC_SEQ}34m"
    export COL_MAGENTA="${ESC_SEQ}35m"
    export COL_CYAN="${ESC_SEQ}36m"
  fi
}

abort() {
  echo -e "${COL_RED:-}${COL_LIGHT:-}ERROR:${COL_RESET:-} $*" 1>&2
  exit 1
}

info() {
  echo -e "${COL_CYAN:-}INFO:${COL_RESET:-} $*"
}

success() {
  echo -e "${COL_GREEN:-}SUCCESSFUL:${COL_RESET:-} $*"
}

generate_password() {
  PASSWORD=$(LC_CTYPE=C tr -cd '[:alpha:]0-9.,;:!?_/-' < /dev/urandom | head -c32 || true)
  if [[ -z "${PASSWORD}" ]]; then
    abort "Failure generating password"
  fi
}
