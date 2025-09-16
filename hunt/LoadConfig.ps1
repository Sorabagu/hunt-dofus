# Script PowerShell pour charger la configuration depuis config.ini
param(
    [string]$ConfigFile = "config.ini"
)

# Vérifier si le fichier de configuration existe
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Fichier de configuration $ConfigFile introuvable"
    exit 1
}

# Lire le fichier de configuration et créer un fichier batch temporaire
$tempBatchFile = "temp_config.bat"
$configContent = Get-Content $ConfigFile

# Créer le fichier batch temporaire
@"
@echo off
rem Variables de configuration générées depuis config.ini
"@ | Out-File -FilePath $tempBatchFile -Encoding ASCII

# Parser chaque ligne de configuration
foreach ($line in $configContent) {
    $line = $line.Trim()
    
    # Ignorer les lignes vides et les commentaires
    if ($line -eq "" -or $line.StartsWith("#")) {
        continue
    }
    
    # Parser les variables (format: VARIABLE=valeur)
    if ($line -match "^([^=]+)=(.*)$") {
        $variableName = $matches[1].Trim()
        $variableValue = $matches[2].Trim()
        
        # Supprimer les guillemets si présents
        if ($variableValue.StartsWith('"') -and $variableValue.EndsWith('"')) {
            $variableValue = $variableValue.Substring(1, $variableValue.Length - 2)
        }
        
        # Écrire la variable dans le fichier batch
        "set `"$variableName=$variableValue`"" | Out-File -FilePath $tempBatchFile -Append -Encoding ASCII
    }
}

Write-Host "Configuration chargée depuis $ConfigFile"
Write-Host "Fichier temporaire créé: $tempBatchFile"
