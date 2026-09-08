# Aplicação manual — substituição direta

## 1. Faça backup/garanta branch correta

```bash
git checkout rc2/canonical-visual-rebuild
git status
```

Idealmente o `git status` deve estar limpo antes da cópia.

## 2. Copie `repo_overlay/` sobre a raiz do repositório

Linux/macOS:
```bash
cp -R repo_overlay/. /caminho/do/O-cavaleiro-Executivo/
```

Windows PowerShell:
```powershell
Copy-Item -Path .\repo_overlay\* -Destination C:\caminho\O-cavaleiro-Executivo -Recurse -Force
```

## 3. Confira

```bash
git status
git diff --stat
```

Você deverá ver como modificados os assets antigos do protagonista e os três assets
CorporateUI (`hp_frame_protagonist`, `cooldown_frame`, `dialogue_panel`), além dos
novos estados/botões.

## 4. Commit sugerido

```bash
git add assets/Characters/CavaleiroExecutivo/Runtime
git add assets/UI/Runtime/CorporateUI
git add docs/FASE00_REPLACE_OLD_ASSETS_V2.md

git commit -m "assets(fase00): substitui sprites e HUD antigos pelo canonico V2"
git push origin rc2/canonical-visual-rebuild
```

## Reverter antes do commit
```bash
git restore assets/Characters/CavaleiroExecutivo/Runtime
git restore assets/UI/Runtime/CorporateUI
git clean -fd assets/Characters/CavaleiroExecutivo/Runtime assets/UI/Runtime/CorporateUI/ButtonsV2
```

## Reverter depois do commit
Use um novo commit de revert:
```bash
git revert <SHA_DO_COMMIT>
```
