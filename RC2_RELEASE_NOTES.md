# O Cavaleiro Executivo — RC2

## Baseline

- Branch-base: `main`
- Commit-base: `6f95547db26025bb4f7be4dc17e0049038ac088f`
- Data de fechamento: 2026-09-08

## Escopo da RC2

Esta Release Candidate consolida o estado jogável atual do protótipo após as correções de playtest aplicadas em 03/09/2026.

### Conteúdo incluído

- Fase 00 / prólogo jogável.
- Menu principal e fluxo de salvar/carregar.
- Seleção de fases e seleção de grupo.
- Fase 01 — Operações & Logística.
- Docas do Armazém — travessia das 11 salas.
- Fases de boss e sistemas de desbloqueio já presentes no `main`.
- HUD de vida e cooldown.
- Sistema de companions com troca de controle.

### Correções consolidadas antes da RC2

- Corrigido congelamento de diálogo nas Docas do Armazém.
- Corrigida saída da escada com velocidade vertical residual.
- Alinhado topo das escadas às plataformas de destino.
- Adicionados limites invisíveis nas bordas das salas para evitar queda no limbo.
- Reposicionados cafeteira e NPC da cafeteria na Fase 00.
- Aumentada a caixa de diálogo para falas longas.
- Mantidas as correções anteriores de projéteis, comportamento de companions e gates da Fase 01.

## Status de qualidade

### Verificado por inspeção de repositório e histórico

- A baseline da RC2 corresponde ao `main` em `6f95547`.
- A fase `DOCAS DO ARMAZEM` está registrada em `stage_select_12.gd` e aponta para `platform_fase_docas_12.tscn`.
- As correções de 03/09/2026 estão integradas no `main` pelo PR #10.
- Não há PR aberto identificado como bloqueador de RC2 no momento do fechamento.

### Requer smoke test manual da build candidata

Antes de promover RC2 para release estável, executar o checklist em `RC2_QA_CHECKLIST.md`. Os itens de runtime não são marcados automaticamente como aprovados apenas pela inspeção estática.

## Known limitations / fora do gate da RC2

- A documentação histórica `CHANGELOG_DEV_v0.4.md` é anterior às Sprints e fases mais recentes e deve ser tratada como registro histórico, não como status atual do produto.
- As Docas do Armazém foram entregues inicialmente com foco em travessia; conteúdo de combate adicional deve seguir o roadmap de conteúdo e não bloqueia esta RC2 de protótipo.

## Critério de promoção

A RC2 pode ser promovida quando:

1. todos os itens P0/P1 do checklist estiverem aprovados;
2. não houver soft-lock, hard-lock, queda em limbo ou perda de progresso;
3. Fase 00, Fase 01 e Docas puderem ser percorridas no fluxo esperado;
4. salvar/carregar preservar o progresso essencial;
5. nenhuma regressão crítica for encontrada nas fases de boss.
