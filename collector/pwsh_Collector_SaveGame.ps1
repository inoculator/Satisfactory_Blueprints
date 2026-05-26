# --- CONFIGURATION ---
$RepoDir = split-path $PSScriptRoot
$SatisfactoryBaseDir = "$env:LOCALAPPDATA\FactoryGame\Saved\SaveGames\blueprints"

# 1. UPDATE VOM REPO HOLEN
Write-Host "Hole neueste Änderungen aus dem Git-Repo..." -ForegroundColor Cyan
Set-Location $RepoDir
git pull origin main

# Funktion für den bidirektionalen Sync zweier Ordner basierend auf LastWriteTime
function Sync-BlueprintFolders ($SourceDir, $TargetDir) {
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir | Out-Null
    }

    # Alle Dateien aus beiden Ordnern holen
    $SourceFiles = Get-ChildItem -Path $SourceDir -File -Exclude ".git", "*.ps1", "README.md"
    $TargetFiles = Get-ChildItem -Path $TargetDir -File -Exclude ".git", "*.ps1", "README.md"

    # Von Quelle nach Ziel (z.B. Spiel -> Repo)
    foreach ($SFile in $SourceFiles) {
        $TFilePath = Join-Path $TargetDir $SFile.Name
        if (Test-Path $TFilePath) {
            $TFile = Get-Item $TFilePath
            if ($SFile.LastWriteTime -gt $TFile.LastWriteTime) {
                Write-Host "  -> Aktualisiere im Ziel: $($SFile.Name) (Grund: Neuer)" -ForegroundColor Yellow
                Copy-Item -Path $SFile.FullName -Destination $TFilePath -Force
            }
        } else {
            Write-Host "  -> Neu im Ziel: $($SFile.Name)" -ForegroundColor Green
            Copy-Item -Path $SFile.FullName -Destination $TFilePath
        }
    }

    # Von Ziel nach Quelle (z.B. Repo -> Spiel)
    foreach ($TFile in $TargetFiles) {
        $SFilePath = Join-Path $SourceDir $TFile.Name
        if (Test-Path $SFilePath) {
            $SFile = Get-Item $SFilePath
            if ($TFile.LastWriteTime -gt $SFile.LastWriteTime) {
                Write-Host "  <- Aktualisiere in Quelle: $($TFile.Name) (Grund: Neuer)" -ForegroundColor Cyan
                Copy-Item -Path $TFile.FullName -Destination $SFilePath -Force
            }
        } else {
            Write-Host "  <- Neu in Quelle: $($TFile.Name)" -ForegroundColor Green
            Copy-Item -Path $TFile.FullName -Destination $SFilePath
        }
    }
}

# 2. WELTEN DURCHLAUFEN UND SYNCHRONISIEREN
$WeltOrdner = Get-ChildItem -Path $SatisfactoryBaseDir -Directory

foreach ($Welt in $WeltOrdner) {
    $WeltName = $Welt.Name
    $LokalerWeltPfad = $Welt.FullName
    $RepoWeltPfad = Join-Path $RepoDir $WeltName

    Write-Host "Synchronisiere Welt-Ordner: $WeltName" -ForegroundColor Magenta
    Sync-BlueprintFolders -SourceDir $LokalerWeltPfad -TargetDir $RepoWeltPfad
}

# 3. GIT AUTOMATISCH HOCHLADEN
$GitStatus = git status --porcelain
if ($GitStatus) {
    Write-Host "Änderungen im Repo erkannt. Pushe zu GitHub..." -ForegroundColor Yellow
    git add .
    git commit -m "Strukturierter Blueprint-Sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git push origin main
    Write-Host "Sync erfolgreich abgeschlossen!" -ForegroundColor Green
} else {
    Write-Host "Keine Änderungen vorhanden. Alles up-to-date." -ForegroundColor Gray
}