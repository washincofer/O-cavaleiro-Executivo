# RC2 — Playtest Completo do Jogo até este ponto

**Projeto:** O Cavaleiro Executivo  
**Branch de teste:** `release/rc2-final`  
**Escopo:** Fase 00 — Prólogo/Recepção + Fase 01 — Operações & Logística + Fase 02 — Tecnologia  
**Objetivo:** validar em uma única rodada todo o jogo implementado até este checkpoint da RC2.

---

## Como registrar cada problema

Sempre anotar no formato:

`Fase / Sala ou setor / Personagem / O que aconteceu / O que deveria acontecer`

Exemplo:

`Fase 01 / L04 / Cavaleiro Executivo / caiu do elevador e ficou em queda infinita / deveria retornar ao último checkpoint`

Classificação sugerida:

- **P0 — Bloqueador:** jogo não abre, crash, save corrompido, fase impossível de concluir, soft-lock ou queda infinita sem recuperação.
- **P1 — Grave:** chefe/subchefe não funciona, progressão quebra, personagem obrigatório não funciona, checkpoint permite bypass, item essencial falha.
- **P2 — Médio:** HUD incorreto, animação/direção errada, colisão ruim mas contornável, drop ou valor econômico incorreto.
- **P3 — Visual/Polimento:** posicionamento, texto, arte provisória, alinhamento, feedback visual.

---

# 0. Preparação do Playtest

Antes de iniciar:

- [ ] Confirmar que a branch usada é `release/rc2-final`.
- [ ] Executar o jogo a partir da cena principal normal, não por uma cena de debug isolada.
- [ ] Fazer uma rodada começando com **Novo Jogo**.
- [ ] Fazer pelo menos uma validação posterior usando **Continuar/Carregar**.
- [ ] Não considerar arte provisória de inimigos da Tecnologia ou de Sir Carth como bloqueador de gameplay.
- [ ] Registrar o saldo inicial de moedas e itens quando necessário para comparar depois.

---

# 1. TESTES GLOBAIS — antes e durante todas as fases

## 1.1 Inicialização e menus

- [ ] O jogo inicia sem erro fatal.
- [ ] A introdução abre corretamente.
- [ ] A introdução pode ser concluída normalmente.
- [ ] Se houver opção de pular, ela funciona sem quebrar o fluxo.
- [ ] Menu principal abre corretamente.
- [ ] Novo Jogo funciona.
- [ ] Continuar/Carregar não causa crash ou soft-lock.
- [ ] Pause funciona durante gameplay.
- [ ] Retomar do pause devolve controle normalmente.

## 1.2 Party e troca de personagem

Nas fases com party:

- [ ] Tecla `1` seleciona o protagonista.
- [ ] Tecla `2` seleciona o primeiro companion, quando existir.
- [ ] Tecla `3` seleciona o segundo companion, quando existir.
- [ ] Somente um personagem recebe controle direto por vez.
- [ ] Companions inativos seguem corretamente.
- [ ] Companion inativo não deve morrer por repetir o salto do personagem ativo e cair no vazio.
- [ ] Companion inativo não entra em loop de queda/respawn.
- [ ] Se o personagem ativo for derrotado e houver outro membro vivo, ocorre auto-handoff.
- [ ] Se nenhum membro estiver disponível, o comportamento de Game Over é coerente.

## 1.3 Vida base e Power Life

Regra canônica:

- Vida máxima inicial por personagem: **60 HP**.
- Cada Power Life: **+10 HP máximo permanente** para o personagem/role que o coleta.
- Limite: **100 HP**.

Validar:

- [ ] Personagem começa com 60 HP.
- [ ] HUD representa corretamente o HP atual/máximo.
- [ ] Power Life: 60 → 70.
- [ ] Segundo Power Life: 70 → 80.
- [ ] Terceiro: 80 → 90.
- [ ] Quarto: 90 → 100.
- [ ] Acima de 100 não aumenta.
- [ ] Se um companion coletar o Power Life, o aumento pertence a ele.
- [ ] O HP máximo obtido persiste após salvar/carregar.

## 1.4 Cura

Drops canônicos:

- Cura baixa: **+5 HP**.
- Cura média: **+15 HP**.
- Cura alta: **+20 HP**.
- Distribuição esperada ao longo de muitas mortes: aproximadamente 50% / 40% / 10%.

Validar:

- [ ] Cura baixa soma 5 sem ultrapassar o máximo.
- [ ] Cura média soma 15 sem ultrapassar o máximo.
- [ ] Cura alta soma 20 sem ultrapassar o máximo.
- [ ] A cura vai para o personagem que fisicamente coleta o item.

## 1.5 E-Tank

Regra canônica:

- Cura excedente de um personagem já cheio carrega o E-Tank.
- Capacidade operacional = **100% da vida máxima do personagem ativo**.
- O E-Tank armazena HP real.
- Ao usar, restaura somente o necessário e mantém eventual saldo restante.

Validar quando houver controle/acionamento disponível no build:

- [ ] Personagem cheio coleta cura e o excedente vai para o E-Tank.
- [ ] Capacidade não passa do máximo de HP do personagem ativo.
- [ ] Personagem ferido usa carga armazenada.
- [ ] O E-Tank não desperdiça carga além do HP necessário.
- [ ] Carga restante persiste.
- [ ] E-Tank persiste no save.

> **Observação RC2:** se o build atual não expuser botão/atalho de uso do E-Tank, registrar como **integração pendente conhecida**, não como falha de regra de economia.

## 1.6 Moedas

Valores canônicos por resistência/mecânica:

| Condição | Moedas |
|---|---:|
| menos de 3 acertos | 5 |
| 3–4 acertos | 10 |
| 5–7 acertos | 30 |
| 8–9 acertos | 50 |
| exatamente 10 acertos | 50 — fallback operacional atual |
| mais de 10 acertos | 100 |
| mecânica especial | 100 |

Validar:

- [ ] Todo inimigo derrotado gera moeda.
- [ ] Valor corresponde ao tier esperado.
- [ ] Chefes/mecânicas especiais usam o tier máximo quando aplicável.
- [ ] Moedas persistem entre fases.
- [ ] Moedas persistem após salvar/carregar.

## 1.7 Reviver Companion

Regra canônica:

- 5% de chance independente de drop por inimigo.
- **2–5 unidades espalhadas por fase**.
- Preço de compra definido: **700 moedas**.

Validar o que estiver exposto no build:

- [ ] Encontrar entre 2 e 5 unidades espalhadas na Fase 01.
- [ ] Encontrar entre 2 e 5 unidades espalhadas na Fase 02.
- [ ] Itens não aparecem dentro de paredes ou locais inacessíveis.
- [ ] Coleta aumenta o inventário.
- [ ] Eventual drop de inimigo funciona.
- [ ] Inventário persiste no save.

> **Observação RC2:** se ainda não houver interface de compra/uso do Reviver Companion, registrar como **integração de UI/uso pendente**, mantendo o preço canônico de 700 moedas.

## 1.8 Vida Extra — “1 Vida”

Regra canônica definida:

- Deve ser consumida automaticamente quando o personagem controlado morre durante a fase.
- Deve retornar ao mesmo ponto.
- Deve voltar com 50% do HP máximo atual.

> **Observação RC2:** caso essa automação ainda não esteja ligada no build, registrar como **integração pendente conhecida**.

## 1.9 Save/Load

- [ ] Salvar depois do Prólogo.
- [ ] Salvar depois de obter moedas.
- [ ] Salvar depois de Power Life.
- [ ] Salvar com Reviver Companion no inventário.
- [ ] Salvar com carga no E-Tank, se possível.
- [ ] Carregar e confirmar moedas.
- [ ] Carregar e confirmar HP máximo por personagem.
- [ ] Carregar e confirmar itens.
- [ ] Carregar e confirmar `prologue_cleared`.
- [ ] Save antigo sem dados de progressão não deve causar crash.

---

# 2. FASE 00 — PRÓLOGO / RECEPÇÃO

## Objetivo da fase

Validar narrativa, movimentação, interação, limites do mapa e transição para o fluxo principal. Nesta etapa, **combate não é o foco**.

## 2.1 Entrada e fluxo narrativo

- [ ] Recepção carrega sem tela preta.
- [ ] Personagem aparece na posição correta.
- [ ] Primeiro diálogo inicia corretamente.
- [ ] Todos os diálogos avançam.
- [ ] Nenhum diálogo congela o personagem permanentemente.
- [ ] Textos longos cabem na caixa de diálogo.
- [ ] Após fechar diálogo, controle retorna.

## 2.2 Cenário e colisões

- [ ] Café não sobrepõe escada de maneira problemática.
- [ ] NPCs não bloqueiam passagem indevidamente.
- [ ] Props não possuem colisão invisível errada.
- [ ] Escadas/níveis acessíveis funcionam.
- [ ] Personagem não atravessa paredes laterais.
- [ ] Personagem não escapa da sala.
- [ ] Não existe limbo nas bordas do mapa.

## 2.3 Conclusão do Prólogo

- [ ] Evento final do Prólogo dispara.
- [ ] `prologue_cleared` é marcado.
- [ ] Fluxo segue para menu/seleção apropriada.
- [ ] Salvar após concluir preserva o estado.
- [ ] Carregar não reinicia indevidamente o Prólogo.

### Resultado da Fase 00

- [ ] **APROVADA**
- [ ] **APROVADA COM P2/P3**
- [ ] **REPROVADA — P0/P1**

Observações:

- 
- 
- 

---

# 3. FASE 01 — OPERAÇÕES & LOGÍSTICA

## Estrutura canônica

A antiga “Docas do Armazém” **faz parte desta fase** e não deve ser tratada como fase independente.

Percurso oficial contínuo:

- L01 — Docas de Recebimento
- L02 — Triagem
- L03 — Separação/Conferência
- L04 — Armazenagem/Elevação
- L05 — Operações Internas
- L06 — Arena do Especialista de Segurança Estevão
- L07 — Núcleo do Armazém
- L08 — Área/rota secreta
- L09 — Expedição Pesada
- L10 — Doca Central
- L11 — Arena de Danelmo Grossmanobra

## 3.1 Entrada

- [ ] A Fase 01 abre por “OPERACOES & LOGISTICA”.
- [ ] “Docas do Armazém” não deve aparecer como fase oficial independente.
- [ ] Party escolhida aparece corretamente.
- [ ] HUD aparece.
- [ ] Troca 1/2/3 funciona.

## 3.2 Inimigos comuns — distribuição oficial

Devem existir **12 inimigos comuns** distribuídos fora das arenas de chefe/subchefe:

| Local aproximado | Inimigo | HP | Tier esperado |
|---|---|---:|---:|
| L01 | Auxiliar de Recebimento | 2 | 5 moedas |
| L02 | Conferente | 3 | 10 moedas |
| L02 | Auxiliar de Triagem | 3 | 10 moedas |
| L03 | Conferente Sênior | 4 | 10 moedas |
| L03/L04 | Operador de Armazém | 5 | 30 moedas |
| L04 | Operador de Carga | 5 | 30 moedas |
| L05 | Auxiliar de Operações | 6 | 30 moedas |
| L05 | Encarregado de Operações | 7 | 30 moedas |
| L07 | Guarda do Núcleo | 5 | 30 moedas |
| L07/L08 | Guarda de Retenção | 6 | 30 moedas |
| L09 | Operador de Expedição | 8 | 50 moedas |
| L10 | Guarda da Doca Central | 9 | 50 moedas |

Validar:

- [ ] Todos aparecem.
- [ ] Nenhum nasce dentro de parede.
- [ ] Nenhum comete suicídio ao ativar.
- [ ] Perseguem/atacam normalmente.
- [ ] Viram/animação acompanha direção.
- [ ] Recebem ataque corpo a corpo.
- [ ] Recebem projéteis.
- [ ] Morrem após o número correto de golpes.
- [ ] Drop de moeda corresponde ao tier.
- [ ] Drop de cura ocorre.
- [ ] Eventual Reviver dropa sem substituir a moeda/cura.

> Arte dos inimigos comuns pode ser provisória nesta RC2. Avaliar gameplay primeiro.

## 3.3 Mecânicas de cenário

### L01 — caixas

- [ ] Caixa leve pode ser empurrada.
- [ ] Caixa não atravessa parede.
- [ ] Caixa não arrasta grupo para fora do mapa.

### L04 — elevador de carga

- [ ] Elevador sobe e desce.
- [ ] Personagem consegue embarcar.
- [ ] Personagem é carregado junto.
- [ ] Companion não cai em loop ao seguir.
- [ ] Queda retorna ao último checkpoint.

### L05 — gancho/vagonete

- [ ] Plataforma se move corretamente.
- [ ] Personagem acompanha a plataforma.
- [ ] Não existe queda infinita.
- [ ] É possível completar o trecho sem precisão extrema.

### Esteiras

- [ ] Esteira desloca personagem na direção prevista.
- [ ] Não atravessa colisões.
- [ ] Não prende companion.

### L08 — área secreta

- [ ] Caminho secreto é alcançável.
- [ ] Evento/companion Protocolo funciona se disponível.
- [ ] Não impede conclusão da rota principal.

### L09 — caixa pesada

- [ ] Caixa pesada não se comporta como caixa leve comum.
- [ ] Atalho associado não bloqueia rota obrigatória.
- [ ] Rota alternativa permanece possível.

## 3.4 Checkpoints e quedas

- [ ] Checkpoint inicial funciona.
- [ ] Checkpoints intermediários atualizam corretamente.
- [ ] Cair com personagem ativo retorna grupo ao último checkpoint.
- [ ] Companion inativo é resgatado próximo do personagem ativo.
- [ ] Respawn não permite atravessar o gate do Estevão.

## 3.5 L06 — SUBCHEFE: Especialista de Segurança Estevão

Estado esperado:

- Role: `especialista`
- HP de playtest: **32**
- Mecânica: bloqueia progressão até ser derrotado.

Testar:

- [ ] Estevão aparece na arena.
- [ ] Não existem inimigos comuns extras dentro da arena.
- [ ] Parede/gate está fechado enquanto ele está vivo.
- [ ] Não é possível contornar pelo chão/plataforma.
- [ ] Não é possível bypassar via checkpoint/respawn.
- [ ] Caixa não atravessa o gate.
- [ ] Estevão persegue/ataca.
- [ ] Estevão recebe dano.
- [ ] HP é coerente.
- [ ] Ao morrer, gate é removido.
- [ ] Caminho fica livre.
- [ ] Drop/economia do subchefe funciona.

## 3.6 L11 — CHEFE: Danelmo Grossmanobra

Estado esperado:

- Role: `danelmo`
- HP de playtest: **75**
- Chefe final oficial de Operações & Logística.

Testar:

- [ ] Grossmanobra aparece na arena.
- [ ] Não existem inimigos comuns extras na arena.
- [ ] Boss não nasce fora do chão.
- [ ] Boss persegue/ataca adequadamente.
- [ ] Boss recebe dano.
- [ ] Luta pode ser concluída.
- [ ] Morte do boss encerra a fase corretamente.
- [ ] Recompensa do Almoxarifado funciona.
- [ ] Primeira conclusão concede **+500 moedas**.
- [ ] Segunda conclusão não concede outros +500.
- [ ] Progresso permanece após salvar/carregar.

### Resultado da Fase 01

- [ ] **APROVADA**
- [ ] **APROVADA COM P2/P3**
- [ ] **REPROVADA — P0/P1**

Observações:

- 
- 
- 

---

# 4. FASE 02 — TECNOLOGIA

## Estrutura canônica

- Não possui subchefe.
- Possui inimigos comuns distribuídos pela fase.
- Chefe final: **Sir Carth Gentrion**.
- Arte de inimigos e boss pode ser provisória neste checkpoint; a prioridade do teste é mecânica, colisão, progressão e economia.

Setores:

- T01 — Service Desk
- T02 — Datacenter
- T03 — Redes & Backup
- T04 — Segurança & Governança
- T05 — Conselho de Governança

## 4.1 Entrada e navegação

- [ ] Seletor mostra a entrada da Tecnologia no slot oficial.
- [ ] Não existe entrada oficial separada para Docas.
- [ ] Tecnologia carrega sem erro.
- [ ] Party aparece corretamente.
- [ ] HUD aparece.
- [ ] Câmera acompanha o personagem.
- [ ] Todos os cinco setores podem ser atravessados.
- [ ] Plataformas são alcançáveis.
- [ ] Não existem buracos invisíveis no chão.
- [ ] Não é possível escapar pelas bordas.

## 4.2 Inimigos comuns da Tecnologia

Devem existir **13 inimigos comuns** antes do boss:

| Setor aproximado | Inimigo | HP | Tier esperado |
|---|---|---:|---:|
| T01 | Técnico de Suporte | 2 | 5 moedas |
| T01 | Analista de Service Desk | 3 | 10 moedas |
| T02 | Técnico de Campo | 3 | 10 moedas |
| T02 | Analista de Sistemas | 4 | 10 moedas |
| T02 | Operador de Datacenter | 5 | 30 moedas |
| T02 | Administrador de Servidores | 5 | 30 moedas |
| T03 | Analista de Redes | 6 | 30 moedas |
| T03 | Especialista de Backup | 6 | 30 moedas |
| T03/T04 | Analista de Segurança | 7 | 30 moedas |
| T04 | Engenheiro de Redes | 7 | 30 moedas |
| T04 | Arquiteto de Sistemas | 8 | 50 moedas |
| T04 | Especialista de Infra | 8 | 50 moedas |
| T04 | Guarda de Governança | 9 | 50 moedas |

Validar:

- [ ] Os 13 aparecem antes da arena final.
- [ ] Não há subchefe no meio do percurso.
- [ ] Inimigos não nascem presos.
- [ ] Não cometem suicídio.
- [ ] Recebem corpo a corpo.
- [ ] Recebem projétil.
- [ ] HP corresponde à tabela.
- [ ] Moeda corresponde ao tier.
- [ ] Cura aparece.
- [ ] Eventual Reviver aparece.

## 4.3 Itens da fase

- [ ] Existem **2–5 Reviver Companion** espalhados pela fase.
- [ ] Todos os Reviver estão alcançáveis.
- [ ] Existe **1 Power Life** no trecho final.
- [ ] Power Life aumenta +10 HP do personagem que o coleta.
- [ ] Power Life persiste depois da fase/save.

## 4.4 Entrada da arena de Sir Carth

- [ ] Arena final é alcançável.
- [ ] Sir Carth aparece corretamente.
- [ ] Não há subchefe anterior.
- [ ] Não há inimigo comum misturado à luta final.
- [ ] Colisão do boss é funcional apesar da arte provisória.

## 4.5 CHEFE — Sir Carth Gentrion

Estado esperado:

- Chefe final da Tecnologia.
- HP de playtest: **90**.
- Possui **Firewall de Governança**.
- Fora da janela correta, ataques não causam dano.
- Combinações possíveis: **1+3** ou **2+3**.
- Janela de ativação/vulnerabilidade: aproximadamente **5 a 10 segundos**, variável.

### Teste do Firewall

- [ ] Atacar Sir Carth antes da combinação não reduz HP.
- [ ] Ataque corpo a corpo é bloqueado pelo Firewall.
- [ ] Projétil é bloqueado pelo Firewall.
- [ ] Habilidade não deve burlar o Firewall.
- [ ] Há feedback indicando Firewall ativo.

### Teste dos terminais

- [ ] Existem três pontos/terminais de ativação.
- [ ] `E` ativa o terminal próximo.
- [ ] A combinação requerida é informada.
- [ ] Combinação 1+3 pode ocorrer.
- [ ] Combinação 2+3 pode ocorrer.
- [ ] Terminal errado não completa a combinação sozinho.
- [ ] Completar os dois terminais corretos abre a vulnerabilidade.

### Janela de vulnerabilidade

- [ ] Janela dura aproximadamente 5–10 segundos.
- [ ] Durante a janela, corpo a corpo causa dano.
- [ ] Durante a janela, projétil causa dano.
- [ ] Durante a janela, habilidades causam dano quando aplicável.
- [ ] Ao acabar o tempo, Firewall volta.
- [ ] Uma nova combinação é exigida.
- [ ] Boss não permanece vulnerável para sempre.
- [ ] Repetir pelo menos 3 ciclos sem soft-lock.

### Vitória

- [ ] Sir Carth chega a 0 HP.
- [ ] Vitória encerra a luta.
- [ ] Fase finaliza sem travar.
- [ ] Primeira conclusão concede **+500 moedas**.
- [ ] Segunda conclusão não concede novos +500.
- [ ] Save mantém progresso depois da vitória.

### Resultado da Fase 02

- [ ] **APROVADA**
- [ ] **APROVADA COM P2/P3**
- [ ] **REPROVADA — P0/P1**

Observações:

- 
- 
- 

---

# 5. TESTE DE PERSISTÊNCIA ENTRE AS TRÊS FASES

Realizar uma rodada sem zerar o save:

1. Concluir Fase 00.
2. Entrar na Fase 01.
3. Ganhar moedas e, se possível, Power Life/Reviver.
4. Concluir Grossmanobra.
5. Entrar na Fase 02 com o mesmo save.
6. Confirmar progressão.
7. Concluir Sir Carth.
8. Fechar o jogo.
9. Abrir novamente.
10. Carregar o save.

Checklist:

- [ ] `prologue_cleared` permanece.
- [ ] Moedas da Fase 01 permanecem ao entrar na Fase 02.
- [ ] +500 da primeira vitória da Fase 01 permanece.
- [ ] +500 da primeira vitória da Fase 02 permanece.
- [ ] Repetir uma fase não concede novamente o bônus de primeira conclusão.
- [ ] HP máximo por role permanece.
- [ ] Power Life permanece.
- [ ] Reviver Companion permanece.
- [ ] E-Tank permanece, quando houver carga.
- [ ] Continuar/Load retorna a um estado utilizável.

---

# 6. TESTE DE REGRESSÃO DE COMBATE/COMPANIONS

Durante Fase 01 e Fase 02:

- [ ] Projéteis não atravessam plataformas que devem bloqueá-los.
- [ ] Inimigos não morrem sozinhos ao ativar.
- [ ] Personagem corpo a corpo acerta somente dentro do alcance.
- [ ] Ataque a distância funciona.
- [ ] Cooldown impede spam indevido.
- [ ] HUD de cooldown acompanha uso de habilidade.
- [ ] Companion inativo não recebe dano indevido.
- [ ] Trocar de companion durante combate não duplica controle.
- [ ] Morte de um companion não mata os outros.
- [ ] Auto-handoff mantém a fase jogável.

---

# 7. TESTE DE HUD

- [ ] HP do personagem selecionado está correto.
- [ ] HP dos membros da party está correto.
- [ ] HUD acompanha dano em tempo real.
- [ ] HUD acompanha cura em tempo real.
- [ ] HUD acompanha aumento de HP por Power Life.
- [ ] Valor de moedas atualiza.
- [ ] Cooldown atualiza.
- [ ] Textos não ficam sobrepostos.
- [ ] HUD continua funcional depois de troca 1/2/3.

> Atenção especial: Power Life coletado no meio da fase deve refletir o novo HP máximo sem exigir reiniciar a cena.

---

# 8. LIMITAÇÕES/INTEGRAÇÕES CONHECIDAS DESTA RC2

Estas situações devem ser registradas, mas não confundidas com regressões inesperadas:

- Arte definitiva dos inimigos comuns da Tecnologia ainda pode ser substituída.
- Arte definitiva de Sir Carth ainda pode ser substituída sem alterar a mecânica.
- Se não houver UI de compra do Reviver Companion, o preço canônico permanece **700 moedas**, mas a interface é pendência.
- Se não houver comando de uso do E-Tank no build, a regra/persistência existe, mas a interação de UI é pendência.
- Se não houver ação de reviver companion derrotado no build, registrar a integração de uso como pendência.
- Se a Vida Extra ainda não executar respawn automático de 50%, registrar a integração como pendência.

Essas pendências não devem mascarar P0/P1 reais de fase, chefe, progressão ou save.

---

# 9. CRITÉRIO FINAL DE APROVAÇÃO DA RC2

## GO

Marcar **GO** somente se:

- [ ] Fase 00 pode ser concluída.
- [ ] Fase 01 pode ser concluída.
- [ ] Estevão funciona e não pode ser bypassado.
- [ ] Grossmanobra funciona e encerra Fase 01.
- [ ] Fase 02 pode ser concluída.
- [ ] Sir Carth funciona por múltiplos ciclos e pode ser derrotado.
- [ ] Não existe crash fatal.
- [ ] Não existe soft-lock obrigatório.
- [ ] Não existe queda infinita sem recuperação em rota obrigatória.
- [ ] Save/Load mantém a progressão essencial.
- [ ] Primeira conclusão de Fase 01 dá 500 uma vez.
- [ ] Primeira conclusão de Fase 02 dá 500 uma vez.

## ITERATE

Marcar **ITERATE** se as três fases forem concluíveis, mas existirem P1/P2 que exigem correção antes da release.

## NO-GO

Marcar **NO-GO** se houver qualquer P0 ou se Fase 00, Fase 01 ou Fase 02 não puder ser concluída normalmente.

---

# 10. RESULTADO FINAL DO PLAYTEST

**Data:** ____ / ____ / ______  
**Build/commit testado:** ______________________________  
**Tester:** ______________________________

- [ ] GO
- [ ] ITERATE
- [ ] NO-GO

## Resumo de defeitos

| ID | Severidade | Fase | Sala/Setor | Personagem | Problema | Esperado | Status |
|---|---|---|---|---|---|---|---|
| 001 |  |  |  |  |  |  |  |
| 002 |  |  |  |  |  |  |  |
| 003 |  |  |  |  |  |  |  |
| 004 |  |  |  |  |  |  |  |
| 005 |  |  |  |  |  |  |  |

## Observações finais

- 
- 
- 

---

**Este documento representa o checklist mestre do jogo implementado até o checkpoint RC2 atual: Prólogo/Recepção + Operações & Logística + Tecnologia.**
