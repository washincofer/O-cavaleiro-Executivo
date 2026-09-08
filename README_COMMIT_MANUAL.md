# Como aplicar e commitar

1. Entre na branch desejada:
```bash
git checkout rc2/canonical-visual-rebuild
git pull
```

2. Copie o conteúdo de `repo_overlay/` para a raiz do repositório.

Linux/macOS:
```bash
cp -R repo_overlay/. /caminho/do/O-cavaleiro-Executivo/
```

Windows PowerShell:
```powershell
Copy-Item -Path .\repo_overlay\* -Destination C:\caminho\O-cavaleiro-Executivo -Recurse -Force
```

3. Revise:
```bash
git status
git diff --stat
```

4. Commit:
```bash
git add assets/Characters/CavaleiroExecutivo/Runtime
git add assets/UI/Runtime/CorporateUI
git add scripts/playtest/fase00_player_12.gd
git add scripts/ui/main_menu_oce12.gd
git add scripts/ui/fase00_hud_overlay_12.gd
git add scripts/ui/fase00_dialogue_ui_12.gd
git add scripts/ui/fase00_item_menu_12.gd
git add docs/FASE00_MENU_UI_REMAKE_PACK.md

git commit -m "feat(fase00): atualiza menu inicial, HUD, dialogos, itens e protagonista"
git push origin rc2/canonical-visual-rebuild
```

Se quiser aplicar diretamente na `main`, troque a branch no checkout/commit. Eu recomendo revisar primeiro numa branch separada.
