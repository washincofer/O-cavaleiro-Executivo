if (-not (Test-Path ".git")) {
  Write-Error "Execute este script na raiz do repositorio O-cavaleiro-Executivo."
  exit 1
}
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Copy-Item -Path "$ScriptDir\repo_overlay\*" -Destination "." -Recurse -Force
Write-Host "Arquivos copiados. Revise com: git status"
