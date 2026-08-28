#!/usr/bin/env bash
set -euo pipefail

# Keep the editor and export templates on the exact same version.
GODOT_VERSION="4.4.1"
GODOT_RELEASE="${GODOT_VERSION}-stable"
GODOT_ARCHIVE="Godot_v${GODOT_RELEASE}_linux.x86_64.zip"
TEMPLATES_ARCHIVE="Godot_v${GODOT_RELEASE}_export_templates.tpz"
DOWNLOAD_BASE="https://github.com/godotengine/godot/releases/download/${GODOT_RELEASE}"
TOOLS_DIR="${PWD}/.render-tools"
TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.stable"

mkdir -p "${TOOLS_DIR}" "${TEMPLATE_DIR}" dist

if [[ ! -x "${TOOLS_DIR}/godot" ]]; then
  curl --fail --location --retry 3 \
    "${DOWNLOAD_BASE}/${GODOT_ARCHIVE}" \
    --output "${TOOLS_DIR}/${GODOT_ARCHIVE}"
  unzip -q "${TOOLS_DIR}/${GODOT_ARCHIVE}" -d "${TOOLS_DIR}"
  mv "${TOOLS_DIR}/Godot_v${GODOT_RELEASE}_linux.x86_64" "${TOOLS_DIR}/godot"
  chmod +x "${TOOLS_DIR}/godot"
fi

if [[ ! -f "${TEMPLATE_DIR}/web_release.zip" ]]; then
  curl --fail --location --retry 3 \
    "${DOWNLOAD_BASE}/${TEMPLATES_ARCHIVE}" \
    --output "${TOOLS_DIR}/${TEMPLATES_ARCHIVE}"
  rm -rf "${TOOLS_DIR}/templates"
  unzip -q "${TOOLS_DIR}/${TEMPLATES_ARCHIVE}" -d "${TOOLS_DIR}/templates"
  cp -R "${TOOLS_DIR}/templates/templates/." "${TEMPLATE_DIR}/"
fi

rm -rf dist
mkdir -p dist
echo "Importando e validando o projeto com Godot ${GODOT_RELEASE}..."
"${TOOLS_DIR}/godot" --headless --path "${PWD}" --import

echo "Exportando a versao Web para dist/..."
"${TOOLS_DIR}/godot" --headless --path "${PWD}" --export-release "Web" "dist/cavaleiro-sprint12-v01.html"

# Render serves index.html at the root. The generated runtime assets keep the
# Sprint-specific basename, bypassing packages cached by older builds.
mv dist/cavaleiro-sprint12-v01.html dist/index.html

# Video de abertura: servido como arquivo estatico solto (fora do .pck) pra
# company_intro_12.gd tocar com a tag <video> nativa do navegador em vez do
# VideoStreamPlayer do Godot — o player nativo do Godot decodifica Theora via
# software no thread principal do WASM e, sob a carga do proprio jogo, ficava
# visivelmente corrompido (zoom/blur progressivo, pedido do usuario pra
# consertar). <video src> com H.264 usa o decoder de hardware do navegador,
# a mesma tecnologia de qualquer video tocado num site.
cp assets/Video/Runtime/company_intro.mp4 dist/company_intro.mp4
cp assets/Video/Runtime/company_intro.webm dist/company_intro.webm

test -f dist/index.html
test -f dist/cavaleiro-sprint12-v01.js
test -f dist/cavaleiro-sprint12-v01.wasm
test -f dist/cavaleiro-sprint12-v01.pck
test -f dist/company_intro.mp4
test -f dist/company_intro.webm
echo "Exportacao Web concluida."
