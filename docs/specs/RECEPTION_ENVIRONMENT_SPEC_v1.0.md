# Reception Environment Specification v1.0

## Gramática

- WALKABLE
- BLOCKING
- TRANSITION
- TACTICAL
- DECORATIVE

## Floor

- tile_floor_base
- tile_floor_var01
- tile_floor_var02
- tile_floor_var03

Variações são mecanicamente equivalentes.

## Walls

Suportar:
- horizontal
- vertical left/right
- inner corners
- outer corners
- end caps

## Doors

Estados:
- OPEN
- CLOSED
- LOCKED

Arte, colisão, navegação e transition trigger são sistemas separados.

## Functional Architecture

Obrigatórios:
- balcão modular
- 2 pilares principais
- divisória funcional

Secundários:
- banco
- arquivo/armário

## Reception Identity

- brasão corporativo
- placa institucional
- mural de avisos/pergaminhos
- banner com moderação
- documentos, livro-caixa, selo, pena/tinteiro
- tapete como overlay
- luminária/arandela

A estética deve traduzir funções corporativas para um mundo medieval, evitando escritório moderno literal ou dungeon genérica.

## Physics Matrix

| Elemento | Movimento | Projétil | Navigation | Y-Sort |
|---|---|---|---|---|
| Piso | Pass | Pass | Walkable | No |
| Tapete | Pass | Pass | Walkable | No |
| Parede | Block | Block | Blocked | Structural |
| Porta Open | Pass | Pass | Walkable | By asset |
| Porta Closed | Block | Block | Blocked | By asset |
| Porta Locked | Block | Block | Blocked | By asset |
| Pilar | Block | Block | Blocked | Yes |
| Balcão | Block | Block | Blocked | Yes |
| Banco | Block | Pass | Blocked | Yes |
| Armário | Block | Block | Blocked | Yes/Structural |
| Divisória alta | Block | TBD | Blocked | Yes |
| Decoração pequena | Pass | Pass | Walkable | No |

## Rendering

- Sorting por anchor de base.
- Personagens usam os pés.
- Props usam sua base física.
- Dividir Back/Front apenas quando necessário.
