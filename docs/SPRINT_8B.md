# Sprint 8B — Correção de Integração Visual

Base mecânica: Sprint 7 (inalterada).

Correções desta build:
- direção do idle padronizada: todos os frames técnicos são authored para a direita e flip_h espelha para esquerda;
- idle/corrida/pulo normalizados em canvas 128x128, com altura visual consistente;
- animação de ataque adicionada sem mudar janela mecânica;
- animação de dash dedicada adicionada;
- densidade interna alterada para 640x360 com Camera2D zoom 2, preservando o enquadramento/world-space 320x180;
- protagonista mantém ~48 unidades de altura no mundo usando sheet 2x a scale 0.5;
- cenário usa assets 2x a scale 0.5, evitando ampliar sprites pequenos dentro da Godot;
- colliders, velocidades, salto, dash, dano e IA permanecem iguais à Sprint 7.

## Validar
1. Andar à direita, parar: idle deve olhar à direita.
2. Andar à esquerda, parar: idle deve olhar à esquerda.
3. Idle e corrida devem aparentar a mesma escala corporal.
4. Pulo não deve alterar a escala do personagem.
5. Dash deve mostrar animação dedicada.
6. Cenário deve ficar visualmente mais nítido, sem blocos ampliados do 8A.
7. Movimentação e colisões devem continuar iguais à Sprint 7.
