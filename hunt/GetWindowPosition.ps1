# Script PowerShell pour récupérer la position d'une fenêtre Chrome
param(
    [string]$ProcessName = "chrome",
    [switch]$AllWindows
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[LOG] === GetWindowPosition.ps1 démarré ===" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Importer les fonctions Windows API pour récupérer la position
$sig = @'
[DllImport("user32.dll")]
public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
[DllImport("user32.dll")]
public static extern IntPtr GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
[DllImport("user32.dll")]
public static extern int GetWindowTextLength(IntPtr hWnd);
[DllImport("user32.dll")]
public static extern bool IsWindowVisible(IntPtr hWnd);

[StructLayout(LayoutKind.Sequential)]
public struct RECT
{
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}
'@

Add-Type -MemberDefinition $sig -Name Win32 -Namespace Native

# Fonction pour obtenir le titre de la fenêtre
function Get-WindowTitle {
    param([IntPtr]$hWnd)
    
    $length = [Native.Win32]::GetWindowTextLength($hWnd)
    if ($length -eq 0) { return "" }
    
    $title = New-Object System.Text.StringBuilder
    $title.Capacity = $length + 1
    [Native.Win32]::GetWindowText($hWnd, $title, $title.Capacity) | Out-Null
    return $title.ToString()
}

# Fonction pour obtenir la position d'une fenêtre
function Get-WindowPosition {
    param([IntPtr]$hWnd)
    
    $rect = New-Object Native.Win32+RECT
    $success = [Native.Win32]::GetWindowRect($hWnd, [ref]$rect)
    
    if ($success) {
        return @{
            Left = $rect.Left
            Top = $rect.Top
            Right = $rect.Right
            Bottom = $rect.Bottom
            Width = $rect.Right - $rect.Left
            Height = $rect.Bottom - $rect.Top
        }
    }
    return $null
}

Write-Host "[LOG] Recherche des processus $ProcessName..." -ForegroundColor Yellow
$processes = Get-Process $ProcessName -ErrorAction SilentlyContinue

if ($processes.Count -eq 0) {
    Write-Host "[LOG] ERREUR: Aucun processus $ProcessName trouvé" -ForegroundColor Red
    exit 1
}

Write-Host "[LOG] $($processes.Count) processus $ProcessName trouvé(s)" -ForegroundColor Green

$windowCount = 0
foreach ($process in $processes) {
    $hWnd = $process.MainWindowHandle
    
    if ($hWnd -ne [IntPtr]::Zero) {
        $isVisible = [Native.Win32]::IsWindowVisible($hWnd)
        $title = Get-WindowTitle $hWnd
        
        if ($isVisible -and $title -ne "") {
            $position = Get-WindowPosition $hWnd
            
            if ($position) {
                $windowCount++
                Write-Host "========================================" -ForegroundColor Cyan
                Write-Host "[LOG] Fenêtre $windowCount" -ForegroundColor Green
                Write-Host "[LOG]   Titre: $title" -ForegroundColor White
                Write-Host "[LOG]   PID: $($process.Id)" -ForegroundColor White
                Write-Host "[LOG]   Position: ($($position.Left), $($position.Top))" -ForegroundColor Yellow
                Write-Host "[LOG]   Taille: $($position.Width) x $($position.Height)" -ForegroundColor Yellow
                Write-Host "[LOG]   Coordonnées complètes:" -ForegroundColor Gray
                Write-Host "[LOG]     Gauche: $($position.Left)" -ForegroundColor Gray
                Write-Host "[LOG]     Haut: $($position.Top)" -ForegroundColor Gray
                Write-Host "[LOG]     Droite: $($position.Right)" -ForegroundColor Gray
                Write-Host "[LOG]     Bas: $($position.Bottom)" -ForegroundColor Gray
                
                if (-not $AllWindows -and $windowCount -eq 1) {
                    break
                }
            }
        }
    }
}

if ($windowCount -eq 0) {
    Write-Host "[LOG] Aucune fenêtre visible trouvée pour $ProcessName" -ForegroundColor Yellow
} else {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "[LOG] Total: $windowCount fenêtre(s) trouvée(s)" -ForegroundColor Green
}

Write-Host "========================================" -ForegroundColor Cyan
