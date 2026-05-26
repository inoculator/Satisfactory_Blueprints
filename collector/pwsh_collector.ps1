# --- KONFIGURATION ---
$RepoDir = split-path $PSScriptRoot
$SatisfactoryBaseDir = "$env:LOCALAPPDATA\FactoryGame\Saved\SaveGames\blueprints"

# 1. UPDATE VOM REPO HOLEN
Write-Host "Hole neueste Blueprints aus dem Git-Repo..." -ForegroundColor Cyan
Set-Location $RepoDir
git pull origin main

# 2. VOM REPO IN ALLE WELTEN KOPIEREN
# Findet alle Unterordner (deine Welten) und kopiert die Files hinein
$WeltOrdner = Get-ChildItem -Path $SatisfactoryBaseDir -Directory
foreach ($Welt in $WeltOrdner) {
    Write-Host "Synchronisiere Repo -> Welt: $($Welt.Name)" -ForegroundColor Green
    Copy-Item -Path "$RepoDir\*" -Destination $Welt.FullName -Recurse -Force -Exclude ".git", "*.ps1"
}

# 3. VON DEN WELTEN INS REPO BACKUPPEN
# Hier nehmen wir eine deiner Welten als "Master" oder loopen durch, um neue Blueprints ins Repo zu holen
Write-Host "Suche nach neuen lokalen Blueprints zum Hochladen..." -ForegroundColor Cyan
foreach ($Welt in $WeltOrdner) {
    # Kopiert neue/geänderte Dateien zurück ins Repo-Verzeichnis
    Copy-Item -Path "$($Welt.FullName)\*" -Destination $RepoDir -Recurse -Force 
}



# 4. GIT AUTOMATISCH HOCHLADEN
$GitStatus = git status --porcelain
if ($GitStatus) {
    Write-Host "Änderungen erkannt. Reiche Blueprints bei GitHub ein..." -ForegroundColor Yellow
    git add .
    git commit -m "Automatischer Blueprint Sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git push origin main
    Write-Host "Sync erfolgreich abgeschlossen!" -ForegroundColor Green
} else {
    Write-Host "Alles up-to-date. Keine neuen Blueprints gefunden." -ForegroundColor Gray
}