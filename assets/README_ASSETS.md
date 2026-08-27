# Assets — Integration Notes

Esta árvore contém apenas placeholders para a estrutura canônica.

## Não adicionar assets falsos

- PNGs reais devem vir dos assets canônicos aprovados.
- Não copie previews, screenshots ou imagens de revisão para Runtime.
- Runtime = somente APPROVED.
- Source pode conter material de trabalho, conforme política do repositório.

## Runtime character filenames esperados

Espadachim:
- char_espadachim_idle.png
- char_espadachim_walk.png
- char_espadachim_attack.png
- char_espadachim_hit.png
- char_espadachim_death.png

Estagiário:
- char_estagiario_idle.png
- char_estagiario_walk.png
- char_estagiario_attack.png
- char_estagiario_hit.png
- char_estagiario_death.png

Coordenador:
- char_coordenador_idle.png
- char_coordenador_walk.png
- char_coordenador_attack.png
- char_coordenador_hit.png
- char_coordenador_death.png
- char_coordenador_invoke.png
- char_coordenador_order.png

## Sprint 12 — packs de terceiros (laboratorio de plataforma)

Diferente da arvore acima (que aguarda arte canonica aprovada para
Espadachim/Estagiario/Coordenador), o laboratorio de plataforma
(`scripts/playtest/`) usa asset packs prontos de terceiros para validar
mecanica com arte real. Ficam em `assets/Characters/Warrior|Archer|Mage/`,
`assets/Enemies/Rat|Slime/` e `assets/Environment/Cave/`:

| Pasta | Pack de origem | Licenca |
| --- | --- | --- |
| `Characters/Warrior/Runtime` | Medieval Warrior Pack 3 | CC0 |
| `Characters/Archer/Runtime` | Huntress 2 | CC0 |
| `Characters/Mage/Runtime` | Wizard Pack | CC0 (mesmo autor/estilo; sem `License.txt` no zip recebido) |
| `Enemies/Rat/Runtime`, `Enemies/Slime/Runtime` | Monsters Creatures Fantasy 2 | Mesmo autor/estilo; sem `License.txt` no zip recebido — confirmar antes de uso comercial fora deste prototipo |
| `Environment/Cave/Runtime` | Pixel Cave Tileset (NamiPixels) | Uso comercial/nao comercial permitido; **nao redistribuir/revender o asset pack em si** |

Apenas os spritesheets efetivamente usados no jogo foram copiados
(sem `Preview.png`/`.gif`/`License.txt`). Ver `SPRINT_12_README.md` para
detalhes de como cada animacao e fatiada em `platform_actor_12.gd`.
