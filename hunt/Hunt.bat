@echo off
setlocal

rem Configuration du logging
set "LOG_FILE=%~dp0hunt_log.txt"
set "LOG_TIMESTAMP=%date% %time%"

rem Creer/initialiser le fichier de log
echo ======================================== > "%LOG_FILE%"
echo [LOG] Demarrage du script Hunt.bat >> "%LOG_FILE%"
echo [LOG] Heure: %LOG_TIMESTAMP% >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"

rem Fonction pour logger (afficher ET enregistrer)
call :LogMessage "Demarrage du script Hunt.bat"
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

rem Charger la configuration depuis config.ini
call :LogMessage "Chargement de la configuration..."
if exist "%~dp0config.ini" (
    call :LogMessage "Fichier config.ini trouve"
    powershell -ExecutionPolicy Bypass -File "%~dp0LoadConfig.ps1" >> "%LOG_FILE%" 2>&1
    if %errorLevel% neq 0 (
        call :LogMessage "[ERREUR] Echec du chargement de la configuration"
    )
    if exist "%~dp0temp_config.bat" (
        call :LogMessage "Application des variables de configuration..."
        call "%~dp0temp_config.bat" >> "%LOG_FILE%" 2>&1
        del "%~dp0temp_config.bat"
        call :LogMessage "Configuration appliquee avec succes"
    ) else (
        call :LogMessage "Aucun fichier de configuration temporaire trouve"
    )
) else (
    call :LogMessage "Fichier config.ini introuvable, utilisation des valeurs par defaut"
)
call :LogMessage "Configuration chargee"

rem Configuration par defaut (utilisee si config.ini n'existe pas)
call :LogMessage "Application des valeurs par defaut..."
set "CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe"
if "%CHROME_PATH%" neq "" (
    call :LogMessage "Chemin Chrome personnalise: %CHROME_PATH%"
    set "CHROME=%CHROME_PATH%"
)
if "%ALWAYS_ON_TOP%"=="" set "ALWAYS_ON_TOP=true"
if "%WINDOW_SIZE%"=="" set "WINDOW_SIZE=360x520"
if "%URL%"=="" set "URL=https://dofusdb.fr/pip/fr/tools/treasure-hunt"

call :LogMessage "Configuration finale:"
call :LogMessage "  CHROME = %CHROME%"
call :LogMessage "  ALWAYS_ON_TOP = %ALWAYS_ON_TOP%"
call :LogMessage "  WINDOW_SIZE = %WINDOW_SIZE%"
call :LogMessage "  WINDOW_POSITION = %WINDOW_POSITION%"
call :LogMessage "  URL = %URL%"
call :LogMessage "Verification de l'existence de Chrome..."
if not exist "%CHROME%" (
    call :LogMessage "Google Chrome introuvable dans %CHROME%"
    call :LogMessage "[ERREUR] Google Chrome introuvable dans %CHROME%"
    pause
    exit /b 1
) else (
    call :LogMessage "Chrome trouve: %CHROME%"
)

rem Lance Chrome en mode App avec taille personnalisee
call :LogMessage "Lancement de Chrome..."
if "%FULLSCREEN%"=="true" (
    call :LogMessage "Mode plein ecran active"
    start "" "%CHROME%" --new-window --app="%URL%" --start-fullscreen
) else (
    call :LogMessage "Mode fenetre avec taille: %WINDOW_SIZE%"
    rem Utiliser --window-size ET --window-position pour un meilleur controle
    start "" "%CHROME%" --new-window --app="%URL%" --window-size=%WINDOW_SIZE% --window-position=100,100
)
call :LogMessage "Commande Chrome executee"

rem Pause plus longue pour laisser Chrome demarrer completement
call :LogMessage "Attente du demarrage de Chrome (5 secondes)..."
timeout /t 5 >nul
call :LogMessage "Attente terminee"

rem Configurer la fenetre Chrome (position et AlwaysOnTop)
call :LogMessage "Configuration de la fenetre Chrome..."
if exist "%~dp0SetAlwaysOnTop.ps1" (
    if "%ALWAYS_ON_TOP%"=="true" (
        call :LogMessage "AlwaysOnTop active"
        if "%WINDOW_POSITION%" neq "" (
            call :LogMessage "Position personnalisee: %WINDOW_POSITION%"
            rem Positionner et mettre au premier plan
            for /f "tokens=1,2 delims=," %%a in ("%WINDOW_POSITION%") do (
                for /f "tokens=1,2 delims=x" %%c in ("%WINDOW_SIZE%") do (
                    call :LogMessage "Execution de SetAlwaysOnTop.ps1 avec position (%%a, %%b) et taille (%%c, %%d)"
                    powershell -ExecutionPolicy Bypass -File "%~dp0SetAlwaysOnTop.ps1" -X %%a -Y %%b -Width %%c -Height %%d >> "%LOG_FILE%" 2>&1
                    if %errorLevel% neq 0 (
                        call :LogMessage "[ERREUR] Echec de la configuration de la fenetre"
                    )
                )
            )
        ) else (
            call :LogMessage "Position par defaut"
            rem Mettre au premier plan seulement avec taille
            for /f "tokens=1,2 delims=x" %%a in ("%WINDOW_SIZE%") do (
                call :LogMessage "Execution de SetAlwaysOnTop.ps1 avec taille (%%a, %%b)"
                powershell -ExecutionPolicy Bypass -File "%~dp0SetAlwaysOnTop.ps1" -Width %%a -Height %%b >> "%LOG_FILE%" 2>&1
                if %errorLevel% neq 0 (
                    call :LogMessage "[ERREUR] Echec de la configuration de la fenetre"
                )
            )
        )
    ) else if "%WINDOW_POSITION%" neq "" (
        call :LogMessage "Position seulement (sans AlwaysOnTop): %WINDOW_POSITION%"
        rem Positionner seulement (sans AlwaysOnTop)
        for /f "tokens=1,2 delims=," %%a in ("%WINDOW_POSITION%") do (
            for /f "tokens=1,2 delims=x" %%c in ("%WINDOW_SIZE%") do (
                call :LogMessage "Execution de SetAlwaysOnTop.ps1 avec position seulement (%%a, %%b) et taille (%%c, %%d)"
                powershell -ExecutionPolicy Bypass -File "%~dp0SetAlwaysOnTop.ps1" -X %%a -Y %%b -Width %%c -Height %%d -PositionOnly >> "%LOG_FILE%" 2>&1
                if %errorLevel% neq 0 (
                    call :LogMessage "[ERREUR] Echec de la configuration de la fenetre"
                )
            )
        )
    ) else (
        call :LogMessage "Aucune configuration de fenetre demandee"
    )
) else (
    call :LogMessage "[ATTENTION] Script SetAlwaysOnTop.ps1 introuvable, configuration de fenetre ignoree"
)

call :LogMessage "Script termine avec succes"
call :LogMessage "========================================"
call :LogMessage "Fichier de log: %LOG_FILE%"
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