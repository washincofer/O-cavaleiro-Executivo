# O Cavaleiro Executivo

Protótipo 2D desenvolvido com Godot 4.4.1.

## Executar no Render

O projeto está configurado como um **Static Site** por meio do arquivo `render.yaml`.
O build instala automaticamente o Godot e seus templates, exporta o jogo para Web
e publica o conteúdo da pasta `dist`.

1. Envie este repositório para GitHub, GitLab ou Bitbucket.
2. No Render, escolha **New > Blueprint**.
3. Conecte o repositório e confirme a criação do serviço
   `o-cavaleiro-executivo`.

Não é necessário cadastrar variáveis de ambiente. Cada push na branch conectada
gera uma nova versão do jogo. Os cabeçalhos exigidos pelo build Web com threads
já estão definidos no Blueprint.

## Exportar Web localmente

Em Linux (ou WSL), execute:

```bash
bash scripts/build_web.sh
```

O resultado será criado em `dist/`. Para testar, sirva essa pasta por HTTP com os
cabeçalhos `Cross-Origin-Opener-Policy: same-origin` e
`Cross-Origin-Embedder-Policy: require-corp`; abrir o HTML diretamente pelo sistema
de arquivos não é suportado pelo runtime Web.

