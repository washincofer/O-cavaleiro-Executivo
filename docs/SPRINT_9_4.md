# Sprint 9.4 — Mira Vetorial do Estagiário

## Objetivo
Corrigir a leitura do disparo do Estagiário sem transformar o virote em projétil teleguiado.

## Regra aprovada
- O Estagiário mira na posição atual do Cavaleiro **no instante em que o tiro é criado**.
- Se o Cavaleiro estiver acima, o virote sai em diagonal para cima.
- Se estiver abaixo, o virote sai em diagonal para baixo.
- Depois do disparo, a direção fica congelada. O virote **não acompanha** salto, queda ou corrida posterior do jogador.
- A velocidade permanece constante ao longo desse vetor.

## Colisão
A varredura contínua do projétil foi generalizada para a direção real do tiro. Ela cobre a espessura do virote perpendicularmente à trajetória, portanto tiros diagonais também devem parar em paredes, plataformas, piso e portas.

## Testes recomendados
1. Fique no mesmo nível do Estagiário: tiro deve sair praticamente horizontal.
2. Fique em plataforma acima: tiro deve apontar para cima.
3. Fique abaixo: tiro deve apontar para baixo.
4. Pule **depois** do disparo: o virote não deve alterar sua direção.
5. Mude de direção depois do disparo: o virote não deve corrigir a mira.
6. Teste tiro diagonal contra plataforma/parede: deve colidir e desaparecer.

## Baseline
Derivada da Sprint 9.3. Mecânicas de movimento, dano, porta e IA de distância permanecem inalteradas.
