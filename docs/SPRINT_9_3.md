# Sprint 9.3 — IA de Distância + Colisão de Projétil

Patch sobre a Sprint 9.2.

## Correções

### Projétil do Estagiário
- continua 100% horizontal;
- agora usa varredura contínua em três linhas (topo, centro e base) considerando a espessura do virote;
- qualquer corpo sólido do mundo bloqueia o projétil;
- pisos, plataformas, paredes, porta e limites da sala devem absorver o virote;
- preparado também para colisões de TileMap no layer de mundo.

### IA por distância
Foi separada a ideia de **detecção**, **alcance de ataque** e **alcance de perseguição**.

**Estagiário**
- muito perto: foge;
- em distância de tiro: mira e dispara;
- longe demais para atirar, mas ainda engajado: segue o jogador;
- fora do limite de perseguição: volta para IDLE.

**Espadachim**
- ataca apenas no alcance corpo a corpo;
- fora do alcance de ataque: persegue;
- fora do limite máximo de perseguição: volta para IDLE.

**Coordenador**
- mesma regra do Espadachim, com seus próprios alcances e velocidade.

## Testes recomendados
1. Coloque uma plataforma/parede entre Estagiário e Cavaleiro; o virote deve sumir ao tocar o sólido.
2. Afaste-se do Estagiário durante MIRAR: ele deve cancelar o tiro e entrar em SEGUIR.
3. Aproxime-se novamente: ele deve voltar a MIRAR quando entrar na faixa válida.
4. Afaste-se do Espadachim: ele deve perseguir e não atacar fora do alcance.
5. Faça o mesmo com o Coordenador.
6. Saia muito além do limite de perseguição: o inimigo deve voltar a IDLE.
