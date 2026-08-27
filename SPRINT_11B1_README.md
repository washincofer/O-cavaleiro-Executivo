# O Cavaleiro Executivo — Sprint 11B.1 — Platform & Combat Fixes

## Origem

Correcoes derivadas do playtest aprovado da Sprint 11B. O sistema 1/2/3, habilidades manuais, queda fatal, Auto Handoff e camera lateral foram validados e NAO sao redesenhados aqui.

## Correcoes desta revisao

1. **Vaos fatais menores** — ambos passam a ter 40 px, permitindo travessia por salto normal sem eliminar o risco de queda.
2. **Plataformas elevadas acessiveis** — foram reposicionadas e passam a usar colisao one-way, permitindo saltar por baixo e pousar por cima.
3. **Besta colide com o cenario** — o projetil usa raycast no trajeto de cada frame e desaparece ao atingir chao, parede ou plataforma.
4. **Guarda acompanha facing** — escudo e efeito ativo sao espelhados para esquerda/direita.
5. **Guarda testavel** — o primeiro inimigo nasce no trecho inicial; quando a Guarda bloqueia um golpe, o HUD informa `GUARDA BLOQUEOU DANO`.
6. **IA evita queda fatal voluntaria** — inimigos terrestres detectam ausencia de piso adiante, recuam e retomam a perseguicao.
7. **Queda continua sendo morte real** — inimigos nao ficaram imunes ao vao; a protecao esta na IA. Futuramente, um empurrao ainda pode joga-los para a morte.
8. **Seguidores saltam vaos** — aliados nao controlados tentam saltar ao detectar borda durante o acompanhamento do personagem ativo.
9. **Inimigos reposicionados no piso** — combate pode ser testado sem depender de plataforma elevada.

## Arquivos alterados

- `scripts/playtest/platform_party_11b.gd`
- `scripts/playtest/platform_actor_11b.gd`
- `scripts/playtest/platform_bolt_11b.gd`

## O que permanece da 11B

- party fixa 1 protagonista + ate 2 companions;
- `1/2/3` troca o personagem controlado;
- companions nao atacam automaticamente;
- Espadachim: Guarda manual de laboratorio;
- Estagiario: disparo manual de besta de laboratorio;
- Auto Handoff circular `1 -> 2 -> 3 -> 1`, pulando mortos;
- Game Over apenas quando toda a party morre;
- camera lateral acompanha o personagem ativo.

## Observacao de design

Plataformas comuns desta sala devem ser alcancaveis pelo salto normal. Plataformas propositalmente inacessiveis ficam reservadas para puzzles/habilidades utilitarias futuras, como o companion de escada.
