# Sprint 9.5 — Projétil estável e fuga inteligente do Estagiário

Patch de gameplay sobre a Sprint 9.4.

## Correções do virote pneumático

- O projétil só começa a se mover depois de receber `setup()`.
- A direção continua sendo um snapshot da posição do jogador no instante do disparo.
- Depois de lançado, não existe homing.
- Movimento foi simplificado para um vetor fixo com velocidade própria (`170 px/s`).
- Lifetime permanece em `2.6 s`; se não colidir, o virote é removido automaticamente.
- Um raycast cobre todo o trecho percorrido em cada frame de física.
- StaticBody2D/CharacterBody2D do cenário absorvem o virote: plataformas, piso, paredes e porta.

## Nova fuga do Estagiário

Quando o jogador entra na distância de fuga:

1. O Estagiário tenta correr para o lado oposto ao jogador.
2. Se sua rota física estiver bloqueada por geometria da fase, usa um salto (`235 px/s` vertical) para tentar superar o obstáculo/plataforma.
3. Ele realiza apenas uma tentativa de salto para o mesmo bloqueio.
4. Se pousar e continuar bloqueado, após uma curta confirmação (`0,24 s`) considera-se encurralado.
5. Encurralado, ele deixa de insistir na fuga e realiza um **disparo desesperado** mesmo com o jogador próximo.
6. Após o disparo, volta a avaliar distância/fuga normalmente.

## Checklist de teste

### Projétil
- [ ] Mesmo nível: virote se move normalmente.
- [ ] Jogador acima: virote segue diagonal fixa para cima.
- [ ] Jogador abaixo: virote segue diagonal fixa para baixo.
- [ ] Jogador muda de posição após disparo: virote não acompanha.
- [ ] Sem colisão: virote desaparece após ~2,6 s.
- [ ] Plataforma/parede/porta: virote é destruído no impacto.

### Estagiário
- [ ] Aproximação normal: foge mais devagar que o Cavaleiro.
- [ ] Plataforma/obstáculo na rota: tenta saltar.
- [ ] Salto resolve rota: continua fugindo.
- [ ] Encurralado após tentativa de salto: para de insistir e ataca.
- [ ] Depois do ataque encurralado: volta a avaliar a situação.
