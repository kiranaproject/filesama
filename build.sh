#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Build script for filesama (Samarinda File Manager) supporting Pasbuild, FTML, and tests

FTPAS_DIR="../ftpas"

find_ftml_embed() {
  if command -v ftml_embed >/dev/null 2>&1; then
    command -v ftml_embed
  elif [ -x "${FTPAS_DIR}/bin/ftml_embed" ]; then
    echo "${FTPAS_DIR}/bin/ftml_embed"
  elif [ -x "${HOME}/.local/bin/ftml_embed" ]; then
    echo "${HOME}/.local/bin/ftml_embed"
  elif [ -x "${HOME}/.pasbuild/repository/ftpas/0.0.1-SNAPSHOT/x86_64-linux-3.2.3/bin/ftml_embed" ]; then
    echo "${HOME}/.pasbuild/repository/ftpas/0.0.1-SNAPSHOT/x86_64-linux-3.2.3/bin/ftml_embed"
  else
    echo "==> ftml_embed not found, building from ftpas..." >&2
    (cd "${FTPAS_DIR}" && ./build.sh tools >/dev/null 2>&1 || pasbuild compile -f tools/ftml-embed/project.xml >/dev/null 2>&1)
    echo "${FTPAS_DIR}/bin/ftml_embed"
  fi
}

ensure_ftml() {
  if [ ! -f src/main/pascal/filesama.res ] || [ src/main/ftml/filesama.ftml -nt src/main/pascal/filesama.res ]; then
    echo "==> Regenerating FTML resource (.res) using ftpas ftml_embed..."
    local FTML_EMBED
    FTML_EMBED="$(find_ftml_embed)"
    "${FTML_EMBED}" \
      --res src/main/pascal/filesama.res \
      src/main/ftml/filesama.ftml
    touch src/main/pascal/filesama.window.pas
    rm -rf target/units target/test-units
  fi
}

ensure_libft() {
  local SRC_LIB=""
  if [ -f "../floria-toolkit/target/libft.so" ]; then
    SRC_LIB="../floria-toolkit/target/libft.so"
  elif [ -f "${FTPAS_DIR}/target/libft.so" ]; then
    SRC_LIB="${FTPAS_DIR}/target/libft.so"
  fi
  if [ -n "${SRC_LIB}" ]; then
    mkdir -p target
    if [ ! -f target/libft.so ] || [ "${SRC_LIB}" -nt target/libft.so ]; then
      cp -f "${SRC_LIB}" target/libft.so
    fi
  fi
}

TARGET="${1:-compile}"

case "${TARGET}" in
  test)
    echo "==> Running tests with pasbuild..."
    shift 1 || true
    ensure_ftml
    ensure_libft
    pasbuild test "$@"
    ;;
  clean)
    echo "==> Cleaning target artifacts..."
    shift 1 || true
    rm -f src/main/pascal/filesama.res
    pasbuild clean "$@"
    ;;
  ftml)
    echo "==> Embedding FTML (.res) using ftpas ftml_embed..."
    FTML_EMBED="$(find_ftml_embed)"
    "${FTML_EMBED}" \
      --res src/main/pascal/filesama.res \
      src/main/ftml/filesama.ftml
    ;;
  run)
    ensure_ftml
    ensure_libft
    pasbuild compile
    exec ./target/filesama "$@"
    ;;
  compile|fpc|*)
    echo "==> Compiling filesama with pasbuild..."
    if [ "${TARGET}" = "compile" ] || [ "${TARGET}" = "fpc" ]; then
      shift 1 || true
    fi
    ensure_ftml
    ensure_libft
    pasbuild compile "$@"
    ensure_libft
    ;;
esac
