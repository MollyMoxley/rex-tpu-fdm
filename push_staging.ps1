# ============================================================
# push_staging.ps1
# Copie les fichiers depuis rex-tpu-staging vers le repo
# et pousse automatiquement avec commit horodaté
# Usage : clic droit > Exécuter avec PowerShell
# OU depuis PowerShell : .\push_staging.ps1
# ============================================================

$STAGING = "C:\Users\lutte\Documents\rex-tpu-staging"
$REPO    = "C:\Users\lutte\Documents\rex-tpu-fdm"

# Vérifications
if (-not (Test-Path $STAGING)) {
    Write-Host "ERREUR : dossier staging introuvable : $STAGING" -ForegroundColor Red
    pause; exit 1
}
if (-not (Test-Path "$REPO\.git")) {
    Write-Host "ERREUR : repo git introuvable : $REPO" -ForegroundColor Red
    pause; exit 1
}

# Lister les fichiers dans staging
$files = Get-ChildItem $STAGING -File
if ($files.Count -eq 0) {
    Write-Host "STAGING vide — rien à pousser." -ForegroundColor Yellow
    pause; exit 0
}

Write-Host "`nFichiers détectés dans staging :" -ForegroundColor Cyan
$files | ForEach-Object { Write-Host "  $_" }

# Routage automatique par extension et nom
foreach ($file in $files) {
    $dest = ""
    $name = $file.Name.ToLower()

    if ($name -match "\.json$") {
        if ($name -match "tpu70d") {
            $dest = "$REPO\profiles\tpu70d\$($file.Name)"
        } elseif ($name -match "tpu98a") {
            $dest = "$REPO\profiles\tpu98a\$($file.Name)"
        } elseif ($name -match "tpu85a" -or $name -match "bambu" -or $name -match "qidi") {
            $dest = "$REPO\profiles\tpu85a\$($file.Name)"
        } else {
            $dest = "$REPO\profiles\$($file.Name)"
        }
    } elseif ($name -match "\.cfg$") {
        $dest = "$REPO\macros\klipper\$($file.Name)"
    } elseif ($name -match "\.html$") {
        $dest = "$REPO\rex\$($file.Name)"
    } elseif ($name -match "\.md$") {
        $dest = "$REPO\$($file.Name)"
    } else {
        $dest = "$REPO\$($file.Name)"
    }

    # Créer le dossier destination si absent
    $destDir = Split-Path $dest
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    Copy-Item $file.FullName $dest -Force
    Write-Host "  Copié : $($file.Name) → $dest" -ForegroundColor Green
}

# Commit horodaté
Set-Location $REPO
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$msg = "push $timestamp"

git add .
$status = git status --short
if (-not $status) {
    Write-Host "`nRien de nouveau à committer." -ForegroundColor Yellow
    pause; exit 0
}

git commit -m $msg
git push

Write-Host "`n✓ Poussé : $msg" -ForegroundColor Green
Write-Host "Fichiers staging conservés (supprimer manuellement si souhaité).`n"
pause
