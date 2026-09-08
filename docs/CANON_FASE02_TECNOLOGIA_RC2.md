# Cânone RC2 — Fase 02: Tecnologia

Status: **CANÔNICO PARA PLAYTEST RC2**

## Estrutura

- Fase 02 oficial: **Tecnologia**.
- Chefe final: **Sir Carth Gentrion**.
- **Não possui subchefe**.
- Percurso contínuo em cinco setores:
  1. Service Desk
  2. Datacenter
  3. Redes & Backup
  4. Segurança & Governança
  5. Conselho de Governança / arena final

## Inimigos

A fase possui 13 inimigos comuns distribuídos antes da arena final, com HP entre 2 e 9 para cobrir os tiers econômicos de 5/10/30/50 moedas conforme o cânone RC2.

A arte de inimigos comuns e do Sir Carth é provisória nesta candidata: reutiliza sprites existentes, mantendo nomes, HP, drops e mecânica independentes da arte para permitir substituição posterior sem refazer gameplay.

## Sir Carth Gentrion

- Sem subchefe anterior.
- HP de playtest: **90**.
- Protegido por **Firewall de Governança**.
- Enquanto o firewall estiver ativo, ataques não causam dano ao chefe.
- Existem três nodos de governança na arena.
- As combinações canônicas alternam entre **1+3** e **2+3**.
- O jogador usa **Interagir (E)** próximo aos nodos exigidos.
- Após completar a combinação, o firewall abre por uma janela variável de **5 a 10 segundos**.
- Ao encerrar a janela, o firewall volta e uma nova combinação deve ser executada.
- Se a combinação não for concluída no ciclo, o protocolo pode alternar novamente após **5 a 10 segundos**.

## Progressão e economia

- Inimigos usam drops canônicos da RC2: moedas sempre, cura 50/40/10 e Reviver Companion com 5%.
- A fase contém também **2 a 5 Reviver Companion** espalhados aleatoriamente.
- Existe **1 Power Life** de exploração no trecho final antes do chefe.
- Primeira vitória contra Sir Carth concede **500 moedas**, apenas uma vez por save.

## Entrada no fluxo

- O antigo slot visual de `Docas do Armazém` é reaproveitado em runtime como **Tecnologia**.
- Docas permanece conceitualmente dentro da Fase 01 — Operações & Logística.
- O seletor oficial passa a conduzir este slot para `platform_fase02_tecnologia_12.tscn`.

## QA obrigatório

1. Entrar em Tecnologia pelo Stage Select.
2. Trocar personagens por 1/2/3.
3. Confirmar 60 HP base e HUD correto.
4. Derrotar inimigos e validar moedas/drop de cura.
5. Validar 2–5 Reviver espalhados.
6. Coletar Power Life com personagem e companion.
7. Chegar à arena sem soft-lock/limbo.
8. Confirmar ausência de subchefe.
9. Ativar combinação 1+3 e 2+3 com E.
10. Confirmar janela variável 5–10 s.
11. Confirmar Sir Carth invulnerável fora da janela e vulnerável dentro dela.
12. Derrotar Sir Carth e validar +500 moedas somente na primeira conclusão.
13. Salvar/carregar e confirmar persistência da economia/progressão.
