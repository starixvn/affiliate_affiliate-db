Param(
  [string]$Server = $env:DB_SERVER,
  [string]$Database = $env:DB_NAME,
  [switch]$SkipGit
)

Write-Host "[Context] Extracting dependencies..."
# Requires sqlcmd or Invoke-Sqlcmd depending on environment
# Example using sqlcmd output to DOT fragment
# sqlcmd -S $Server -d $Database -i scripts/context/generate_dependency_graph.sql -h -1 -W > .context/dependency-graph.dot

Write-Host "[Context] (Placeholder) Generate schema summary & table profiles"
# Future: invoke profile_tables.sql and write summarized markdown

if(-not $SkipGit){
  git add .context/* scripts/context/* 2>$null
  git commit -m "chore(context): refresh context artifacts" --allow-empty | Out-Null
}

Write-Host "[Context] Done."