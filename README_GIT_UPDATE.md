# O Cavaleiro Executivo — DEV Git Update v0.4

## Objetivo

Este pack consolida as decisões aprovadas nas Sprints **10C-A, 10C-B e 10D** em arquivos apropriados para versionamento no Git.

Ele foi preparado como **overlay de integração**: não contém uma nova build executável e não deve substituir silenciosamente código, cenas ou assets que já existam na baseline mecânica da Sprint 9.5.

## Baseline

- Sprint 9.5: baseline mecânica existente.
- Sprint 10A: aprovada.
- Sprint 10B1 / 10B2 / 10B3: aprovadas visualmente.
- Sprint 10C-A: especificação de Charset concluída.
- Sprint 10C-B: especificação da Recepção/Tileset concluída.
- Sprint 10D: integração e protocolos definidos; execução física da build/playtest permanece pendente.

## Como aplicar no repositório

1. Crie uma branch de integração, por exemplo:
   `git checkout -b dev/sprint-10c-10d-integration`
2. Extraia este pack na raiz do repositório.
3. Revise caminhos e adapte apenas se a estrutura atual do projeto usar nomes diferentes.
4. Não remova arquivos da baseline 9.5.
5. Preencha campos `TBD` somente após medir os assets físicos ou confirmar dados na engine.
6. Implemente a Recepção sobre o greybox/baseline existente; não reconstrua sistemas validados sem evidência de regressão.
7. Rode o checklist de `docs/checklists/10D_BUILD_AND_PLAYTEST_CHECKLIST.md`.
8. Commit sugerido:
   `chore: add Sprint 10C/10D specs, manifests and reception integration plan`

## Conteúdo

- `docs/` — especificações, handoff e checklists.
- `manifests/` — manifests de personagens e ambiente.
- `config/` — configuração lógica do encounter da Recepção.
- `Assets/` — árvore canônica Source/Runtime com placeholders, sem PNGs falsos.
- `CHANGELOG_DEV_v0.4.md` — resumo das decisões incluídas.
- `PACK_MANIFEST_SHA256.txt` — hashes dos arquivos do pack.

## Atenção

Este pack **não contém**:
- executável/build nova;
- sprites PNG finais 10B1/10B2/10B3;
- atlas físicos da Recepção;
- dimensões finais de tile/frame;
- implementação específica de engine.

Esses itens devem ser integrados a partir do repositório e dos assets canônicos reais.
