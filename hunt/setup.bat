@echo off
setlocal

rem Configuration du logging
set "LOG_FILE=%~dp0setup_log.txt"
set "LOG_TIMESTAMP=%date% %time%"

rem Creer/initialiser le fichier de log
echo ======================================== > "%LOG_FILE%"
echo [LOG] Demarrage du script setup.bat >> "%LOG_FILE%"
echo [LOG] Heure: %LOG_TIMESTAMP% >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"

rem Fonction pour logger (afficher ET enregistrer)
call :LogMessage "Demarrage du script setup.bat"
call :LogMessage "Heure: %LOG_TIMESTAMP%"
call :LogMessage "========================================"

rem Verifier si le script s'execute en tant qu'administrateur
call :LogMessage "Verification des privileges administrateur..."
net session >nul 2>&1
if %errorLevel% == 0 (
    call :LogMessage "Script execute en tant qu'administrateur"
) else (
    call :LogMessage "Privileges administrateur manquants"
    call :LogMessage "Relancement en tant qu'administrateur..."
    powershell -Command "Start-Process '%~f0' -Verb RunAs" >> "%LOG_FILE%" 2>&1
    exit /b
)

rem Definir les chemins
set "HUNT_BAT=%~dp0Hunt.bat"
set "HUNT_ICO=%~dp0hunt.ico"
set "DESKTOP=%USERPROFILE%\Desktop"
set "SHORTCUT_NAME=Hunt Dofus.lnk"
set "SHORTCUT_PATH=%DESKTOP%\%SHORTCUT_NAME%"

call :LogMessage "Chemins definis:"
call :LogMessage "  HUNT_BAT = %HUNT_BAT%"
call :LogMessage "  HUNT_ICO = %HUNT_ICO%"
call :LogMessage "  DESKTOP = %DESKTOP%"
call :LogMessage "  SHORTCUT_PATH = %SHORTCUT_PATH%"

rem Verifier l'existence des fichiers requis
call :LogMessage "Verification de l'existence des fichiers..."
if not exist "%HUNT_BAT%" (
    call :LogMessage "[ERREUR] Fichier Hunt.bat introuvable: %HUNT_BAT%"
    pause
    exit /b 1
) else (
    call :LogMessage "Fichier Hunt.bat trouve: %HUNT_BAT%"
)

if not exist "%HUNT_ICO%" (
    call :LogMessage "[ERREUR] Fichier hunt.ico introuvable: %HUNT_ICO%"
    call :LogMessage "Le raccourci sera cree sans icone personnalisee"
    set "USE_ICON=false"
) else (
    call :LogMessage "Fichier hunt.ico trouve: %HUNT_ICO%"
    set "USE_ICON=true"
)

rem Verifier l'existence du dossier Bureau
if not exist "%DESKTOP%" (
    call :LogMessage "[ERREUR] Dossier Bureau introuvable: %DESKTOP%"
    pause
    exit /b 1
) else (
    call :LogMessage "Dossier Bureau trouve: %DESKTOP%"
)

rem Supprimer l'ancien raccourci s'il existe
if exist "%SHORTCUT_PATH%" (
    call :LogMessage "Suppression de l'ancien raccourci..."
    del "%SHORTCUT_PATH%"
    call :LogMessage "Ancien raccourci supprime"
)

rem Creer le raccourci avec PowerShell
call :LogMessage "Creation du raccourci..."
if "%USE_ICON%"=="true" (
    call :LogMessage "Creation avec icone personnalisee"
    powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = '%HUNT_BAT%'; $Shortcut.WorkingDirectory = '%~dp0'; $Shortcut.IconLocation = '%HUNT_ICO%'; $Shortcut.Description = 'Lanceur Hunt Dofus'; $Shortcut.Save()" >> "%LOG_FILE%" 2>&1
) else (
    call :LogMessage "Creation sans icone personnalisee"
    powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = '%HUNT_BAT%'; $Shortcut.WorkingDirectory = '%~dp0'; $Shortcut.Description = 'Lanceur Hunt Dofus'; $Shortcut.Save()" >> "%LOG_FILE%" 2>&1
)

rem Verifier si le raccourci a ete cree avec succes
if exist "%SHORTCUT_PATH%" (
    call :LogMessage "Raccourci cree avec succes: %SHORTCUT_PATH%"
    call :LogMessage "Le raccourci 'Hunt Dofus' a ete cree sur le bureau"
) else (
    call :LogMessage "[ERREUR] Echec de la creation du raccourci"
    pause
    exit /b 1
)

rem Modifier l'icone du fichier Hunt.bat si hunt.ico existe
if "%USE_ICON%"=="true" (
    call :LogMessage "Modification de l'icone du fichier Hunt.bat..."
    powershell -Command "Set-ItemProperty -Path '%HUNT_BAT%' -Name 'Icon' -Value '%HUNT_ICO%'" >> "%LOG_FILE%" 2>&1
    if %errorLevel% == 0 (
        call :LogMessage "Icone du fichier Hunt.bat modifiee avec succes"
    ) else (
        call :LogMessage "Impossible de modifier l'icone du fichier Hunt.bat (normal sur certains systemes)"
    )
)

call :LogMessage "Setup termine avec succes"
call :LogMessage "========================================"
call :LogMessage "Fichier de log: %LOG_FILE%"

echo.
echo ========================================
echo Setup termine avec succes !
echo ========================================
echo Le raccourci "Hunt Dofus" a ete cree sur le bureau.
if "%USE_ICON%"=="true" (
    echo L'icone hunt.ico a ete appliquee au raccourci.
) else (
    echo ATTENTION: Le fichier hunt.ico n'a pas ete trouve.
    echo Le raccourci a ete cree sans icone personnalisee.
)
echo.
echo Vous pouvez maintenant lancer le programme depuis le bureau.
echo.
pause

endlocal
exit /b 0

rem ========================================
rem FONCTION DE LOGGING
rem ========================================
:LogMessage
set "MESSAGE=%~1"
set "TIMESTAMP=%date% %time%"
echo [%TIMESTAMP%] %MESSAGE%
echo [%TIMESTAMP%] %MESSAGE% >> "%LOG_FILE%"
goto :eof
