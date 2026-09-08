# Cânone RC2 — Vida, Progressão, Drops, Moedas e Itens

Status: **CANÔNICO** a partir da RC2.

## 1. Vida dos personagens jogáveis

- Todo personagem jogável inicia com **60 HP máximos**.
- **Power Life** aumenta permanentemente o HP máximo do personagem que o coletou em **+10**.
- O limite canônico é **100 HP máximos**.
- Portanto, cada personagem pode receber no máximo **4 Power Life efetivos**: 60 → 70 → 80 → 90 → 100.
- O bônus é individual por personagem/role e deve persistir no save.
- Se o personagem controlado for um companion, o aumento pertence ao companion, não ao Cavaleiro Executivo.

## 2. Drops de cura dos inimigos

Ao derrotar um inimigo, o drop de cura usa a seguinte distribuição:

- **Baixo — 50%**: recupera **5 HP**.
- **Médio — 40%**: recupera **15 HP**.
- **Alto — 10%**: recupera **20 HP**.

A cura é aplicada ao personagem jogável que encostar/coletar o drop.

## 3. Moedas

- Todo inimigo derrotado sempre gera moedas.
- Valores canônicos possíveis: **5, 10, 30, 50 ou 100 moedas**.
- O valor é definido pela dificuldade prática do inimigo, medida principalmente por quantidade aproximada de acertos necessários para eliminá-lo e pela existência de mecânica especial obrigatória.
- **100 moedas**: inimigo com mecânica especial própria/obrigatória **ou** que exija **mais de 10 acertos**.
- **50 moedas**: inimigo sem mecânica especial que exija **8 a 9 acertos**.
- **30 moedas**: inimigo que exija **5 a 7 acertos**.
- **10 moedas**: inimigo que exija **3 a 4 acertos**.
- **5 moedas**: inimigo eliminado com **menos de 3 acertos**.
- **Caso exatamente 10 acertos sem mecânica:** fica temporariamente classificado em **50 moedas** para evitar lacuna de runtime; este único ponto permanece como micro-tuning revisável sem alterar a regra principal.
- Na **primeira conclusão** de cada fase, o jogador recebe um bônus único de **500 moedas**.
- Moedas são globais do save.

## 4. Item de Reviver Companion

- Existe um consumível de inventário dedicado a **reviver 1 companion derrotado**.
- Inimigos têm **5% de chance** independente de dropar esse item.
- O item também aparece espalhado pelas fases de forma aleatória.
- Cada fase deve distribuir aleatoriamente entre **2 e 5 unidades** desse item no cenário.
- O item também pode ser comprado na tela de seleção de companions.
- **Preço canônico de compra: 700 moedas por unidade.**
- A compra só é concluída se houver saldo suficiente; ao comprar, 700 moedas são descontadas e 1 Reviver Companion entra no inventário.

## 5. E-Tank de Vida

- Existe um **E-Tank de Vida** persistente e global.
- Quando o personagem selecionado está com a barra de vida cheia, cura excedente coletada passa a carregar o E-Tank, em vez de ser desperdiçada.
- A capacidade máxima do E-Tank equivale a **100% do HP máximo do personagem ativo** no momento da carga/uso.
- Exemplos: personagem com 60 HP → capacidade operacional de 60; personagem com 100 HP → capacidade operacional de 100.
- O E-Tank guarda pontos de HP reais.
- Ao usar o E-Tank, ele restaura somente a quantidade de vida que estiver armazenada e somente até completar a barra do personagem selecionado.
- Se houver mais carga do que a vida faltante, apenas o necessário é consumido e o restante permanece armazenado.
- A carga nunca pode ultrapassar a capacidade operacional do personagem ativo.

## 6. Item de 1 Vida / Respawn

- Existe um consumível de inventário que representa **1 vida extra**.
- Se o jogador possuir esse item e o personagem selecionado morrer durante a fase, **1 unidade é consumida automaticamente**.
- O personagem retorna **no mesmo ponto da morte**.
- Retorna com **50% do HP máximo atual**.
- Essa regra se aplica ao personagem selecionado/controlado naquele momento.

## 7. Persistência obrigatória

O save deve persistir, no mínimo:

- moedas;
- HP máximo por personagem/role;
- quantidade de itens de Reviver Companion;
- quantidade de itens de 1 Vida;
- carga do E-Tank;
- fases que já concederam o bônus de primeira conclusão de 500 moedas.

## 8. Regras de coleta

- Cura e Power Life pertencem ao personagem que efetivamente coleta o item.
- Moedas e consumíveis pertencem ao inventário global do jogador.
- Followers não selecionados continuam obedecendo às regras existentes de proteção; a identidade do coletor deve ser o ator que tocou o pickup.

## 9. Tuning ainda aberto

Os seguintes pontos permanecem fora do lock final de balanceamento:

1. classificação específica de cada inimigo existente na tabela de moedas, derivada de seus HP/acertos e mecânicas;
2. ponto exato de spawn das 2–5 unidades de Reviver Companion em cada fase;
3. origem/compra/colocação do item de 1 Vida, além do comportamento de consumo já definido;
4. revisão futura do caso limítrofe de exatamente 10 acertos sem mecânica, atualmente em 50 moedas.
