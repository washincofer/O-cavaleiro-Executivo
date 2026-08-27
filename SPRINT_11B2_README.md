# O Cavaleiro Executivo — Sprint 11B.2 — Companion Follow Safety

## Origem

Melhoria derivada do playtest da 11B.1. Guarda, colisao da besta, IA inimiga de borda e Auto Handoff foram aprovados. Esta revisao corrige apenas o risco indevido dos membros da party que NAO estao sob controle do jogador.

## Regra consolidada

**Somente o personagem atualmente selecionado assume risco de dano e queda fatal.**

Enquanto um aliado estiver em modo follower (nao selecionado):

- nao recebe dano de inimigos;
- nao morre ao cair em um vao;
- nao salta cegamente ao detectar uma borda;
- so tenta saltar se houver piso de aterrissagem adiante;
- se mesmo assim cair, faz auto-resgate perto do personagem ativo e volta a seguir.

Ao selecionar esse personagem com `1/2/3`, a protecao termina imediatamente: ele volta a receber dano normal e queda fatal volta a matar, preservando o Auto Handoff.

## Motivo de design

O jogador nao deve ser punido por uma decisao ruim da IA de seguimento. Em contrapartida, o personagem controlado continua assumindo todo o risco real da plataforma e do combate. Isso mantem a responsabilidade nas maos do jogador e evita mortes invisiveis/off-screen.

## Arquivos alterados

- `scripts/playtest/platform_actor_11b.gd`
  - followers aliados ignoram dano;
  - follower verifica piso de aterrissagem antes de saltar um vao;
  - sem piso seguro, para na borda.
- `scripts/playtest/platform_party_11b.gd`
  - queda fatal resgata follower em vez de mata-lo;
  - busca um ponto de piso proximo do personagem ativo;
  - fallback reposiciona junto do personagem ativo;
  - HUD passa a identificar a revisao 11B.2.

## O que permanece inalterado

- selecao `1/2/3`;
- Auto Handoff circular `1 -> 2 -> 3 -> 1`;
- Game Over somente quando toda a party morrer;
- Guarda manual do Espadachim;
- besta manual do Estagiario;
- projetil destruido por plataformas/cenario;
- inimigos terrestres evitam bordas fatais por IA;
- camera lateral.

## Proximo passo

Com a infraestrutura 11B estabilizada, a proxima sprint pode iniciar habilidades utilitarias de plataforma. O primeiro candidato de design e o **companion da escada**, cuja habilidade nao ataca: ele posiciona uma escada para permitir acesso a plataformas altas e, quando aplicavel, criar controle fisico de passagem.
