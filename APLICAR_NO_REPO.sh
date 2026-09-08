#!/usr/bin/env bash
set -euo pipefail
if [ ! -d ".git" ]; then
  echo "Execute este script na raiz do repositório O-cavaleiro-Executivo."
  exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -R "$SCRIPT_DIR/repo_overlay/." .
echo "Arquivos copiados. Revise com: git status"
