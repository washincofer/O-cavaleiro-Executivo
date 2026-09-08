# Cânone RC2 — Fase 01: Operações & Logística

Status: **CANÔNICO / pronta para playtest integrado**.

## Identidade da fase

- Fase oficial: **01 — Operações & Logística**.
- As **Docas do Armazém fazem parte da Fase 01** e não constituem uma fase independente.
- A cena oficial continua sendo `platform_fase01_operacoes_12.tscn`, que já contém o percurso contínuo L01-L11.
- A antiga cena separada de Docas permanece no repositório apenas como material legado/protótipo e não deve ser apresentada como fase oficial no fluxo do jogo.

## Estrutura canônica

- L01 — Docas de Recebimento
- L02 — Triagem
- L03 — Separação / Conferência
- L04 — Armazenagem Vertical
- L05 — Operações Internas
- L06 — Arena do Especialista de Segurança Estevão (**subchefe**)
- L07 — Núcleo do Armazém
- L08 — Área Secreta / Protocolo
- L09 — Expedição Pesada
- L10 — Doca Central
- L11 — Arena de Danelmo Grossmanobra (**chefe final**)

## Distribuição de inimigos comuns RC2

Os inimigos comuns foram distribuídos de forma a não poluir as arenas de subchefe/chefe:

| Bloco | Inimigo | HP | Moeda-base |
|---|---|---:|---:|
| L01 | Auxiliar de Recebimento | 2 | 5 |
| L02 | Conferente | 3 | 10 |
| L02 | Auxiliar de Triagem | 3 | 10 |
| L03 | Conferente Sênior | 4 | 10 |
| L03/L04 | Operador de Armazém | 5 | 30 |
| L04 | Operador de Carga | 5 | 30 |
| L05 | Auxiliar de Operações | 6 | 30 |
| L05 | Encarregado de Operações | 7 | 30 |
| L07 | Guarda do Núcleo | 5 | 30 |
| L07/L08 | Guarda de Retenção | 6 | 30 |
| L09 | Operador de Expedição | 8 | 50 |
| L10 | Guarda da Doca Central | 9 | 50 |

A arte provisória desses inimigos reaproveita os roles humanoides já existentes `almoxarifado` e `protocolo`, mas eles são instanciados como `team=enemy` e têm HP próprio. A identidade visual definitiva pode ser substituída depois sem alterar a distribuição, HP ou economia.

## Subchefe — Estevão

- Local: **L06**.
- Role atual: `especialista`.
- HP atual: 32.
- Mantém o bloqueio físico da passagem enquanto vivo.
- Ao derrotá-lo, o bloqueio da L06 é removido.
- Como inimigo especial/mecânico, sua recompensa de moeda usa o tier de **100 moedas**.

## Chefe — Danelmo Grossmanobra

- Local: **L11**.
- Role: `danelmo`.
- HP atual: 75.
- É o chefe final oficial de Operações & Logística.
- Derrotá-lo encerra a Fase 01 e libera o Rapaz do Almoxarifado conforme fluxo já existente.
- Recompensa de inimigo especial: **100 moedas**.
- Primeira conclusão da Fase 01: **+500 moedas** uma única vez por save.

## Drops e itens

Aplicam-se integralmente as regras de `CANON_PROGRESSION_ECONOMY_RC2.md`:

- moeda sempre dropada;
- cura 50% baixa / 40% média / 10% alta;
- 5% de chance de Reviver Companion por inimigo;
- entre **2 e 5 Reviver Companion** também espalhados aleatoriamente pela fase a cada execução;
- cura e Power Life pertencem ao personagem que coleta;
- moedas e consumíveis pertencem ao inventário global.

## QA obrigatório da Fase 01

1. Confirmar que “Docas do Armazém” não aparece como fase jogável independente no seletor oficial.
2. Percorrer L01-L11 sem limbo ou soft-lock.
3. Confirmar os 12 inimigos comuns e suas posições aproximadas.
4. Confirmar que não há inimigo comum adicional dentro da arena L06.
5. Derrotar Estevão e validar remoção do bloqueio.
6. Confirmar que não há inimigo comum adicional dentro da arena L11.
7. Derrotar Grossmanobra e validar conclusão/recompensa.
8. Validar moedas conforme HP/dificuldade.
9. Validar drops de cura e Reviver Companion.
10. Confirmar 2-5 Reviver Companion espalhados pela fase.
11. Primeira vitória concede +500 moedas; segunda vitória não concede novamente.
12. Save/load mantém moedas, HP permanente, inventário, E-Tank e flag da recompensa de primeira conclusão.
