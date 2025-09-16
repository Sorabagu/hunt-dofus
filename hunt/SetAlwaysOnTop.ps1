# Script PowerShell pour appliquer AlwaysOnTop à la fenêtre Chrome
param(
    [int]$X = 0,
    [int]$Y = 0,
    [int]$Width = 0,
    [int]$Height = 0,
    [switch]$PositionOnly
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[LOG] === SetAlwaysOnTop.ps1 démarré ===" -ForegroundColor Cyan
Write-Host "[LOG] Paramètres reçus:" -ForegroundColor Yellow
Write-Host "[LOG]   X = $X" -ForegroundColor White
Write-Host "[LOG]   Y = $Y" -ForegroundColor White
Write-Host "[LOG]   Width = $Width" -ForegroundColor White
Write-Host "[LOG]   Height = $Height" -ForegroundColor White
Write-Host "[LOG]   PositionOnly = $PositionOnly" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

# Vérifier les privilèges administrateur
Write-Host "[LOG] Vérification des privilèges administrateur..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "[LOG] ATTENTION: Ce script devrait être exécuté en tant qu'administrateur pour un AlwaysOnTop optimal" -ForegroundColor Red
    Write-Host "[LOG] Continuez quand même..." -ForegroundColor Yellow
} else {
    Write-Host "[LOG] OK Privilèges administrateur confirmés" -ForegroundColor Green
}

# Importer les fonctions Windows API
$sig = @'
[DllImport("user32.dll")]
public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll")]
public static extern bool BringWindowToTop(IntPtr hWnd);
'@

Add-Type -MemberDefinition $sig -Name Win32 -Namespace Native

# Constantes Windows
$HWND_TOPMOST = [IntPtr]::new(-1)
$HWND_TOP = [IntPtr]::new(0)
$SWP_NOMOVE = 0x0002
$SWP_NOSIZE = 0x0001
$SWP_SHOWWINDOW = 0x0040
$SWP_NOACTIVATE = 0x0010
$SWP_FRAMECHANGED = 0x0020

Write-Host "[LOG] Recherche de la fenêtre Chrome..." -ForegroundColor Yellow

# Attendre un peu pour que Chrome démarre complètement
Write-Host "[LOG] Attente de 2 secondes pour le démarrage de Chrome..." -ForegroundColor Gray
Start-Sleep -Seconds 2

# Trouver le processus Chrome le plus récent
Write-Host "[LOG] Recherche des processus Chrome..." -ForegroundColor Yellow
$chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue | Sort-Object StartTime -Descending

if ($chromeProcesses.Count -eq 0) {
    Write-Host "[LOG] ERREUR: Aucun processus Chrome trouvé" -ForegroundColor Red
    Write-Host "[LOG] Tentative de recherche avec 'Google Chrome'..." -ForegroundColor Yellow
    $chromeProcesses = Get-Process "Google Chrome" -ErrorAction SilentlyContinue | Sort-Object StartTime -Descending
    
    if ($chromeProcesses.Count -eq 0) {
        Write-Host "[LOG] ERREUR: Aucun processus Chrome trouvé (même avec 'Google Chrome')" -ForegroundColor Red
        exit 1
    }
}

Write-Host "[LOG] OK $($chromeProcesses.Count) processus Chrome trouvé(s)" -ForegroundColor Green

# Sélectionner le processus avec une fenêtre principale valide
$chrome = $null
foreach ($process in $chromeProcesses) {
    if ($process.MainWindowHandle -ne [IntPtr]::Zero) {
        $chrome = $process
        Write-Host "[LOG] Processus Chrome sélectionné: PID $($chrome.Id), Handle: $($chrome.MainWindowHandle), démarré à $($chrome.StartTime)" -ForegroundColor White
        break
    }
}

if ($chrome -eq $null) {
    Write-Host "[LOG] Aucun processus Chrome avec fenêtre principale trouvé, utilisation du plus récent" -ForegroundColor Yellow
    $chrome = $chromeProcesses[0]
    Write-Host "[LOG] Processus Chrome sélectionné: PID $($chrome.Id), démarré à $($chrome.StartTime)" -ForegroundColor White
}

# Vérifier que la fenêtre principale existe
Write-Host "[LOG] Vérification de la fenêtre principale..." -ForegroundColor Yellow
if ($chrome.MainWindowHandle -eq [IntPtr]::Zero) {
    Write-Host "[LOG] ERREUR: Fenêtre principale Chrome non trouvée" -ForegroundColor Red
    Write-Host "[LOG] Tentative de récupération de la fenêtre..." -ForegroundColor Yellow
    
    # Attendre un peu plus
    Write-Host "[LOG] Attente supplémentaire de 3 secondes..." -ForegroundColor Gray
    Start-Sleep -Seconds 3
    
    # Recharger le processus
    Write-Host "[LOG] Rechargement du processus Chrome..." -ForegroundColor Yellow
    $chrome = Get-Process -Id $chrome.Id -ErrorAction SilentlyContinue
    if ($chrome.MainWindowHandle -eq [IntPtr]::Zero) {
        Write-Host "[LOG] ERREUR: Impossible de récupérer la fenêtre Chrome" -ForegroundColor Red
        Write-Host "[LOG] Tous les processus Chrome:" -ForegroundColor Yellow
        Get-Process chrome -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "[LOG]   PID: $($_.Id), Handle: $($_.MainWindowHandle), StartTime: $($_.StartTime)" -ForegroundColor Gray
        }
        exit 1
    }
}

Write-Host "[LOG] OK Fenêtre Chrome trouvée: Handle $($chrome.MainWindowHandle)" -ForegroundColor Green

# Appliquer les paramètres
Write-Host "[LOG] Application des paramètres de fenêtre..." -ForegroundColor Yellow
try {
    if ($PositionOnly) {
        Write-Host "[LOG] Mode: Position seulement" -ForegroundColor Cyan
        Write-Host "[LOG] Position: ($X, $Y)" -ForegroundColor White
        if ($Width -gt 0 -and $Height -gt 0) {
            Write-Host "[LOG] Taille: ${Width}x${Height}" -ForegroundColor White
            $result = [Native.Win32]::SetWindowPos(
                $chrome.MainWindowHandle, 
                $HWND_TOP, 
                $X, $Y, $Width, $Height,
                $SWP_SHOWWINDOW -bor $SWP_NOACTIVATE
            )
            Write-Host "[LOG] OK Position ($X, $Y) et taille (${Width}x${Height}) appliqués" -ForegroundColor Green
        } else {
            $result = [Native.Win32]::SetWindowPos(
                $chrome.MainWindowHandle, 
                $HWND_TOP, 
                $X, $Y, 0, 0,
                $SWP_NOSIZE -bor $SWP_SHOWWINDOW -bor $SWP_NOACTIVATE
            )
            Write-Host "[LOG] OK Position appliquée: ($X, $Y)" -ForegroundColor Green
        }
    } else {
        Write-Host "[LOG] Mode: Position + AlwaysOnTop" -ForegroundColor Cyan
        Write-Host "[LOG] Position: ($X, $Y)" -ForegroundColor White
        Write-Host "[LOG] AlwaysOnTop: Activé" -ForegroundColor White
        if ($Width -gt 0 -and $Height -gt 0) {
            Write-Host "[LOG] Taille: ${Width}x${Height}" -ForegroundColor White
            $result = [Native.Win32]::SetWindowPos(
                $chrome.MainWindowHandle, 
                $HWND_TOPMOST, 
                $X, $Y, $Width, $Height,
                $SWP_SHOWWINDOW -bor $SWP_FRAMECHANGED -bor $SWP_NOACTIVATE
            )
            Write-Host "[LOG] OK Position ($X, $Y), taille (${Width}x${Height}) et AlwaysOnTop appliqués" -ForegroundColor Green
        } else {
            $result = [Native.Win32]::SetWindowPos(
                $chrome.MainWindowHandle, 
                $HWND_TOPMOST, 
                $X, $Y, 0, 0,
                $SWP_NOMOVE -bor $SWP_NOSIZE -bor $SWP_SHOWWINDOW -bor $SWP_FRAMECHANGED -bor $SWP_NOACTIVATE
            )
            Write-Host "[LOG] OK Position ($X, $Y) et AlwaysOnTop appliqués" -ForegroundColor Green
        }
    }
    
    if ($result) {
        Write-Host "[LOG] OK Succès: Configuration appliquée avec succès" -ForegroundColor Green
        
        # Forcer la fenêtre au premier plan
        Write-Host "[LOG] Forçage de la fenêtre au premier plan..." -ForegroundColor Yellow
        [Native.Win32]::BringWindowToTop($chrome.MainWindowHandle)
        [Native.Win32]::ShowWindow($chrome.MainWindowHandle, 9) # SW_RESTORE
        Write-Host "[LOG] OK Fenêtre forcée au premier plan" -ForegroundColor Green
        
        # Réappliquer AlwaysOnTop après un court délai (pour les cas difficiles)
        if (-not $PositionOnly) {
            Write-Host "[LOG] Réapplication de l'AlwaysOnTop après délai..." -ForegroundColor Yellow
            Start-Sleep -Milliseconds 500
            $result2 = [Native.Win32]::SetWindowPos(
                $chrome.MainWindowHandle, 
                $HWND_TOPMOST, 
                0, 0, 0, 0,
                $SWP_NOMOVE -bor $SWP_NOSIZE -bor $SWP_SHOWWINDOW -bor $SWP_NOACTIVATE
            )
            if ($result2) {
                Write-Host "[LOG] OK AlwaysOnTop réappliqué avec succès" -ForegroundColor Green
            } else {
                Write-Host "[LOG] ATTENTION: Échec de la réapplication de l'AlwaysOnTop" -ForegroundColor Yellow
            }
        }
        
    } else {
        Write-Host "[LOG] ERREUR: Échec de l'application de la configuration" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "[LOG] ERREUR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[LOG] Détails de l'erreur: $($_.Exception)" -ForegroundColor Red
    exit 1
}

Write-Host "[LOG] OK Script terminé avec succès" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
