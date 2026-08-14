# Sprint 8A — Integração Visual Jogável: Protagonista + Recepção Base

## Status
BUILD PREPARADA / AGUARDANDO PLAYTEST EM GODOT

## Regra da Sprint
A mecânica da Sprint 7 permanece congelada. Esta subetapa troca apenas apresentação visual do protagonista e do cenário-base.

## DEV — executado
- [x] Criada pasta `assets/sprint8/player/`.
- [x] Extraídos frames técnicos do material visual aprovado.
- [x] Integrado `AnimatedSprite2D` no Cavaleiro Executivo.
- [x] Idle lateral integrado.
- [x] Corrida com 6 frames integrada.
- [x] Pulo/apice/queda integrados.
- [x] Flip horizontal para movimento à esquerda.
- [x] Collider, hitbox, vida, ataque, salto e dash mantidos com valores da Sprint 7.
- [x] Criada pasta `assets/sprint8/reception/`.
- [x] Kit aprovado preservado como referência.
- [x] Piso, paredes, balcão, plataforma e portão aplicados visualmente.
- [x] Colliders originais do greybox preservados.
- [ ] Validar execução real na Godot.

## DG — executado
- [x] Direção visual aplicada ao protagonista em escala de gameplay.
- [x] Direção visual da Recepção aplicada como camada de cenário.
- [x] Paleta mantém carvão, azul corporativo, aço, latão e luz âmbar.
- [ ] Refinar recortes técnicos após playtest visual, se necessário.
- [ ] Preparar integração dos três inimigos na Sprint 8B.

## DOC — registro
- Base mecânica: Laboratório Mecânico v0.1 / Sprint 7.
- Build derivada: Sprint 8A.
- Escopo desta build: protagonista + Recepção básica.
- Inimigos continuam usando visuais de laboratório para isolar o teste.

## O que validar no próximo playtest
1. Cavaleiro está legível em 320x180?
2. Tamanho visual combina com o collider de 48 px?
3. Corrida parece natural em relação à velocidade já aprovada?
4. Flip horizontal funciona sem problemas de leitura?
5. Pulo/apice/queda mantêm o personagem legível?
6. O cenário interfere na leitura de plataformas e inimigos?
7. Balcão e plataforma visual coincidem com suas colisões?
8. A Recepção está escura demais ou clara demais?

## Observação de produção
Os frames foram derivados da prancha visual aprovada para permitir integração imediata. Eles são assets técnicos v0.1 e poderão receber limpeza pixel a pixel antes da arte final.
