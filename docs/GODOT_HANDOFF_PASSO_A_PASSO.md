# Como trazer o projeto Godot para o fluxo do projeto

## Caminho A — Mais simples: ZIP do projeto
1. No computador, mantenha uma pasta única do projeto Godot.
2. Confirme que a pasta contém `project.godot`, `scenes/`, `scripts/` e `assets/`.
3. Feche a Godot antes de compactar, para evitar arquivos em uso.
4. Não é necessário enviar a pasta de cache `.godot/`.
5. Compacte a pasta inteira em `.zip`.
6. Envie o ZIP nesta conversa/projeto.
7. Informe qual versão/sprint é a base válida e quais testes passaram.
8. DEV trabalha sempre sobre essa base, gera nova Sprint e devolve outro ZIP.

Esse caminho é ótimo enquanto o projeto ainda é pequeno.

## Caminho B — Recomendado quando o projeto crescer: Git + GitHub
1. Instale Git no computador.
2. Crie um repositório para `O Cavaleiro Executivo`.
3. Coloque a pasta do Godot dentro do repositório.
4. Adicione `.godot/` ao `.gitignore`.
5. Faça o primeiro commit da base aprovada.
6. Envie o repositório para o GitHub.
7. Conecte o GitHub ao ChatGPT e autorize apenas esse repositório.
8. Use commits/tags para marcar marcos como `sprint-07-aprovada`, `sprint-09-test` etc.

## Abrindo qualquer Sprint no Godot
1. Descompacte a Sprint em uma pasta local.
2. Abra o Godot Project Manager.
3. Clique em **Import**.
4. Selecione a pasta do projeto ou diretamente o arquivo `project.godot`.
5. Confirme a importação e abra o projeto.
6. Pressione F6 para executar a cena aberta ou F5 para executar a cena principal.

## Regra de segurança de versões
Nunca substituir uma Sprint aprovada sem manter cópia ou commit dela.

Baseline atual:
- Sprint 7 = mecânica aprovada.
- Sprint 8 = direção visual aprovada, integração técnica não congelada.
- Sprint 9 = build de integração global para playtest.
