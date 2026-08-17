# Aplicação sugerida no Git

## Fluxo

```bash
git checkout -b dev/sprint-10c-10d-integration
# extrair/copy overlay para a raiz do repo
git status
git diff --stat
git add README_GIT_UPDATE.md CHANGELOG_DEV_v0.4.md APPLY_TO_GIT.md docs manifests config Assets
git commit -m "chore: add Sprint 10C/10D integration specs and manifests"
```

## Depois do commit documental

Criar commits separados para implementação real, por exemplo:

```text
feat(reception): update greybox to approved blueprint
feat(reception): add room encounter controller
feat(reception): configure v0.1 enemy spawns
feat(assets): integrate approved reception runtime assets
test(reception): add integrated playtest fixes
```

## Não recomendado

Evite um único commit misturando:
- documentação;
- refactor de sistemas;
- novos assets;
- balanceamento;
- correções de IA.

Separar os commits facilita regressão e review.
