# Como aplicar e commitar manualmente

## 1. Use a branch de reconstrução

```bash
git checkout rc2/canonical-visual-rebuild
git pull
```

## 2. Extraia este ZIP fora do repositório

Depois copie **somente o conteúdo da pasta `repo_overlay/`** para a raiz do repositório.

Linux/macOS:
```bash
cp -R repo_overlay/. /caminho/do/O-cavaleiro-Executivo/
```

Windows PowerShell:
```powershell
Copy-Item -Path .\repo_overlay\* -Destination C:\caminho\O-cavaleiro-Executivo -Recurse -Force
```

## 3. Confira o que será commitado

```bash
git status
git diff --stat
```

Você deverá ver principalmente:
- `assets/Characters/CavaleiroExecutivo/Runtime/CanonicalV2/`
- `assets/UI/Runtime/CanonicalV2/`
- `docs/FASE00_CANONICAL_ASSET_PACK_V2.md`

## 4. Commit

```bash
git add assets/Characters/CavaleiroExecutivo/Runtime/CanonicalV2
git add assets/UI/Runtime/CanonicalV2
git add docs/FASE00_CANONICAL_ASSET_PACK_V2.md

git commit -m "assets(fase00): adiciona protagonista canonico V2 e pacote HUD UI"
git push origin rc2/canonical-visual-rebuild
```

## 5. Não apague os assets antigos ainda

Este pack usa uma pasta `CanonicalV2` justamente para permitir revisão visual e novas mudanças sem quebrar a versão anterior.

## Estrutura adicional do ZIP

- `source_originals/`: cópia preservada das artes enviadas; não precisa ir para o Git.
- `PREVIEW_SPRITES.png`: visão geral do protagonista.
- `PREVIEW_HUD_UI.png`: visão geral da HUD/UI.
- `SHA256SUMS.txt`: hashes para conferência.
