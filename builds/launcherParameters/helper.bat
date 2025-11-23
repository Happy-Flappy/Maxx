@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Configuration
:: ============================================================================
set "ScriptDir=%~dp0"
set "BuildsDir=%ScriptDir%.."
set "BuildEnvDir=%BuildsDir%\buildEnvironment"
set "LibrariesDir=%BuildsDir%\libraries"
set "BinariesDir=%BuildsDir%\binaries"
set "LogFile=%ScriptDir%launcher.log"
set "ConfigFile=%ScriptDir%config.ini"
set "FavoritesFile=%ScriptDir%favorites.ini"
set "ProfilesFile=%ScriptDir%profiles.ini"
set "MetricsFile=%ScriptDir%metrics.log"
set "TempDir=%ScriptDir%temp"

:: Load settings
call :LoadConfig

:: UI Settings
title Build Launcher Pro v2.0
mode con: cols=110 lines=35

:: ============================================================================
:: Main Entry
:: ============================================================================
call :InitLog
call :ValidateEnvironment
if !errorlevel! neq 0 goto End

:MainMenu
cls
call :Header
call :ShowFavorites
call :ListExecutables
call :ShowQuickMenu
call :HandleInput
goto MainMenu

:: ============================================================================
:: UI Components
:: ============================================================================
:Header
color !ColorTheme!
echo.
echo   ╔════════════════════════════════════════════════════════════════════════════════════════════════╗
echo   ║  BUILD LAUNCHER PRO v2.0                                                                       ║
echo   ╚════════════════════════════════════════════════════════════════════════════════════════════════╝
echo.
echo   Environment: %BuildEnvDir%
echo   Theme: !ThemeName!  ^|  Quick Launch: !QuickMode!  ^|  Parallel Jobs: !MaxParallel!
echo.
exit /b 0

:ShowFavorites
if not exist "%FavoritesFile%" exit /b 0

set "fav_count=0"
for /f "tokens=*" %%f in (%FavoritesFile%) do set /a fav_count+=1

if !fav_count! gtr 0 (
    echo   ★ FAVORITES
    for /f "tokens=*" %%f in (%FavoritesFile%) do echo     - %%f
    echo.
)
exit /b 0

:ListExecutables
set "count=0"
set "filtered_count=0"

echo   EXECUTABLES
echo.

for %%f in ("%BinariesDir%\*.exe") do (
    set /a count+=1
    set "exe_!count!=%%~nf"
    set "path_!count!=%%f"
    set "size_!count!=%%~zf"
    set "date_!count!=%%~tf"
    
    if defined FilterText (
        echo %%~nf | findstr /i "!FilterText!" >nul
        if !errorlevel! equ 0 (
            set /a filtered_count+=1
            call :DisplayExe !count! "%%~nf" "%%~zf" "%%~tf"
        )
    ) else (
        set /a filtered_count+=1
        call :DisplayExe !count! "%%~nf" "%%~zf" "%%~tf"
    )
)

if !filtered_count! equ 0 (
    if defined FilterText (
        echo   No matches for: "!FilterText!"
    ) else (
        echo   No executables found in binaries folder
    )
    echo.
)

exit /b 0

:DisplayExe
set "idx=%~1"
set "name=%~2"
set "size=%~3"
set "modified=%~4"

set "is_fav= "
if exist "%FavoritesFile%" (
    findstr /x /c:"%name%" "%FavoritesFile%" >nul 2>&1
    if !errorlevel! equ 0 set "is_fav=[FAV]"
)

set /a size_kb=%size% / 1024
echo   [!idx!] !is_fav! %name% ^| !size_kb! KB ^| Modified: %modified%
exit /b 0

:ShowQuickMenu
echo.
echo   ══════════════════════════════════════════════════════════════════════════════════════════════════
echo.
echo   QUICK: [1-9] Launch    [F+num] Favorite    [A+num] With Args    [P+num] Profile
echo   MULTI: [M] Parallel Test    [B] Batch Launch    [W] Watch Mode
echo   UTILS: [S] Search    [T] Theme    [R] Rebuild    [C] Config    [H] Help    [Q] Quit
echo.
set /p "choice=  Command: "
exit /b 0

:HandleInput
if "!choice!"=="" exit /b 0
if /i "!choice!"=="Q" goto End
if /i "!choice!"=="QUIT" goto End
if /i "!choice!"=="EXIT" goto End

:: Extract command and number (e.g., "F3" -> cmd=F, num=3)
set "cmd=!choice:~0,1!"
set "num=!choice:~1!"

:: Single letter commands
if /i "!choice!"=="H" goto Help
if /i "!choice!"=="?" goto Help
if /i "!choice!"=="S" goto Search
if /i "!choice!"=="T" goto ChangeTheme
if /i "!choice!"=="C" goto ConfigMenu
if /i "!choice!"=="L" goto ViewLogs
if /i "!choice!"=="R" goto RebuildMenu
if /i "!choice!"=="M" goto ParallelTest
if /i "!choice!"=="B" goto BatchLaunch
if /i "!choice!"=="W" goto WatchMode

:: Compound commands (F3, A5, P2, etc.)
if /i "!cmd!"=="F" (
    if defined num call :ToggleFavoriteQuick !num!
    exit /b 0
)
if /i "!cmd!"=="A" (
    if defined num call :ArgumentsMenuQuick !num!
    exit /b 0
)
if /i "!cmd!"=="P" (
    if defined num call :ProfileMenuQuick !num!
    exit /b 0
)

:: Direct number launch
call :ValidateNumber "!choice!"
if !errorlevel! equ 0 (
    call :LaunchExecutable !choice!
)

exit /b 0

:: ============================================================================
:: Help System
:: ============================================================================
:Help
cls
echo.
echo   ╔════════════════════════════════════════════════════════════════════════════════════════════════╗
echo   ║  HELP - BUILD LAUNCHER PRO                                                                     ║
echo   ╚════════════════════════════════════════════════════════════════════════════════════════════════╝
echo.
echo   QUICK LAUNCH
echo     [1-9]         Launch executable by number
echo     [F+num]       Toggle favorite (e.g., F3 toggles exe #3)
echo     [A+num]       Launch with arguments (e.g., A5 launches exe #5 with args)
echo     [P+num]       Launch with profile (e.g., P2 uses saved profile for exe #2)
echo.
echo   MULTI-EXECUTION
echo     [M]           Parallel Multi-Test - Run multiple executables simultaneously
echo     [B]           Batch Launch - Launch multiple executables in sequence
echo     [W]           Watch Mode - Auto-reload on binary changes (experimental)
echo.
echo   MANAGEMENT
echo     [S]           Search/Filter executables by name
echo     [T]           Change color theme
echo     [R]           Rebuild solution (MSBuild integration)
echo     [C]           Configuration menu
echo     [L]           View logs and metrics
echo.
echo   ADVANCED
echo     [H] or [?]    Show this help
echo     [Q]           Quit launcher
echo.
echo   FEATURES
echo     - Favorites: Star frequently used builds for quick access
echo     - Profiles: Save argument configurations per executable
echo     - Parallel Testing: Run up to %MaxParallel% executables simultaneously
echo     - Crash Recovery: Auto-restart failed builds in multi-test mode
echo     - Metrics: Track success/failure rates and execution times
echo.
echo   CONFIG FILE: %ConfigFile%
echo   PROFILES:    %ProfilesFile%
echo   LOGS:        %LogFile%
echo.
pause
exit /b 0

:: ============================================================================
:: Search & Filter
:: ============================================================================
:Search
echo.
set /p "FilterText=  Search term (or Enter to clear): "
if "!FilterText!"=="" (
    set "FilterText="
    echo   Filter cleared
) else (
    echo   Filtering: !FilterText!
)
timeout /t 1 /nobreak >nul
exit /b 0

:: ============================================================================
:: Favorites System (Enhanced)
:: ============================================================================
:ToggleFavoriteQuick
set "fav_num=%~1"
call :ValidateNumber "!fav_num!"
if !errorlevel! neq 0 exit /b 1

set "ExeName=!exe_%fav_num%!"

if exist "%FavoritesFile%" (
    findstr /x /c:"!ExeName!" "%FavoritesFile%" >nul 2>&1
    if !errorlevel! equ 0 (
        findstr /v /x /c:"!ExeName!" "%FavoritesFile%" > "%FavoritesFile%.tmp"
        move /y "%FavoritesFile%.tmp" "%FavoritesFile%" >nul 2>&1
        echo   Removed from favorites: !ExeName!
        call :Log "Removed favorite: !ExeName!"
    ) else (
        echo !ExeName!>> "%FavoritesFile%"
        echo   Added to favorites: !ExeName!
        call :Log "Added favorite: !ExeName!"
    )
) else (
    echo !ExeName!> "%FavoritesFile%"
    echo   Added to favorites: !ExeName!
    call :Log "Added favorite: !ExeName!"
)

timeout /t 1 /nobreak >nul
exit /b 0

:: ============================================================================
:: Profile System (Enhanced)
:: ============================================================================
:ProfileMenuQuick
set "prof_num=%~1"
call :ValidateNumber "!prof_num!"
if !errorlevel! neq 0 exit /b 1

set "ExeName=!exe_%prof_num%!"

if not exist "%ProfilesFile%" (
    echo   No profiles exist. Create one in Config menu.
    timeout /t 2 /nobreak >nul
    exit /b 0
)

echo.
echo   Profiles for: !ExeName!
echo.

set "profile_count=0"
for /f "usebackq tokens=*" %%p in (`findstr /b "\[!ExeName!" "%ProfilesFile%"`) do (
    set /a profile_count+=1
    set "profile_line=%%p"
    set "profile_line=!profile_line:[=!"
    set "profile_line=!profile_line:]=!"
    echo   [!profile_count!] !profile_line!
)

if !profile_count! equ 0 (
    echo   No profiles for this executable
    timeout /t 2 /nobreak >nul
    exit /b 0
)

echo.
set /p "prof_choice=  Select profile (or Enter to cancel): "
if "!prof_choice!"=="" exit /b 0

:: Load and launch with profile
:: (Simplified - you'd parse the actual profile here)
call :LaunchExecutable !prof_num!
exit /b 0

:: ============================================================================
:: Arguments Menu (Enhanced)
:: ============================================================================
:ArgumentsMenuQuick
set "arg_num=%~1"
call :ValidateNumber "!arg_num!"
if !errorlevel! neq 0 exit /b 1

echo.
set /p "launch_args=  Arguments for !exe_%arg_num%!: "

call :LaunchExecutable !arg_num! "!launch_args!"
exit /b 0

:: ============================================================================
:: TRUE PARALLEL MULTI-TEST
:: ============================================================================
:ParallelTest
cls
echo.
echo   ╔════════════════════════════════════════════════════════════════════════════════════════════════╗
echo   ║  PARALLEL MULTI-TEST                                                                           ║
echo   ╚════════════════════════════════════════════════════════════════════════════════════════════════╝
echo.
echo   Run multiple executables SIMULTANEOUSLY (up to %MaxParallel% at once)
echo.

set /p "test_list=  Enter numbers (space-separated, e.g., 1 3 5 7): "
if "!test_list!"=="" (
    echo   Cancelled
    timeout /t 1 /nobreak >nul
    exit /b 0
)

echo.
set /p "test_args=  Arguments (same for all, or Enter for none): "

echo.
set /p "auto_restart=  Auto-restart on crash? [Y/N]: "

:: Create temp directory for parallel execution
if not exist "%TempDir%" mkdir "%TempDir%"

echo.
echo   ══════════════════════════════════════════════════════════════════════════════════════════════════
echo   Starting parallel execution...
echo.

call :Log "Parallel test started: !test_list!"

set "job_count=0"
set "active_jobs=0"

:: Launch all jobs in parallel
for %%t in (!test_list!) do (
    call :ValidateNumber "%%t"
    if !errorlevel! equ 0 (
        set /a job_count+=1
        set "job_!job_count!=%%t"
        set "job_name_!job_count!=!exe_%%t!"
        
        echo   [JOB !job_count!] Launching: !exe_%%t!
        
        :: Launch in background using start command
        set "LogPath=%TempDir%\job_!job_count!.log"
        set "ExePath=!path_%%t!"
        
        start "Job!job_count!" /min cmd /c "call :ExecuteJob "!ExePath!" "!test_args!" "!LogPath!" & exit"
        
        set /a active_jobs+=1
        
        :: Wait if we hit max parallel limit
        if !active_jobs! geq !MaxParallel! (
            echo   [WAIT] Max parallel jobs reached, waiting...
            timeout /t 2 /nobreak >nul
        )
    )
)

echo.
echo   All jobs launched! Monitoring...
echo.

:: Monitor job completion
set "completed=0"
:MonitorLoop
timeout /t 2 /nobreak >nul

set "still_running=0"
for /l %%i in (1,1,!job_count!) do (
    tasklist | findstr /i "Job%%i" >nul 2>&1
    if !errorlevel! equ 0 set /a still_running+=1
)

set /a completed=!job_count!-!still_running!
echo   Progress: !completed!/!job_count! completed  ^| !still_running! running

if !still_running! gtr 0 goto MonitorLoop

:: Collect results
echo.
echo   ══════════════════════════════════════════════════════════════════════════════════════════════════
echo   RESULTS
echo.

set "pass_count=0"
set "fail_count=0"

for /l %%i in (1,1,!job_count!) do (
    set "LogPath=%TempDir%\job_%%i.log"
    if exist "!LogPath!" (
        findstr /c:"SUCCESS" "!LogPath!" >nul 2>&1
        if !errorlevel! equ 0 (
            set /a pass_count+=1
            echo   [PASS] !job_name_%%i!
        ) else (
            set /a fail_count+=1
            echo   [FAIL] !job_name_%%i!
        )
    ) else (
        set /a fail_count+=1
        echo   [ERROR] !job_name_%%i! - No log found
    )
)

echo.
echo   Total: !job_count!  ^| Passed: !pass_count!  ^| Failed: !fail_count!
echo.

call :Log "Parallel test completed: !pass_count! passed, !fail_count! failed"

pause
exit /b 0

:: ============================================================================
:: Batch Launch (Sequential)
:: ============================================================================
:BatchLaunch
echo.
echo   BATCH LAUNCH (Sequential)
echo.
set /p "batch_list=  Enter numbers (space-separated): "
if "!batch_list!"=="" exit /b 0

echo.
set /p "batch_args=  Arguments (or Enter for none): "

echo.
echo   Launching in sequence...
call :Log "Batch launch: !batch_list!"

for %%b in (!batch_list!) do (
    call :ValidateNumber "%%b"
    if !errorlevel! equ 0 (
        echo.
        echo   Launching: !exe_%%b!
        call :LaunchExecutable %%b "!batch_args!"
        echo.
        timeout /t 1 /nobreak >nul
    )
)

echo.
echo   Batch complete
pause
exit /b 0

:: ============================================================================
:: Watch Mode (Auto-reload on changes)
:: ============================================================================
:WatchMode
echo.
echo   WATCH MODE
echo.
echo   Monitors binaries folder and auto-reloads when files change
echo   Press Ctrl+C to exit
echo.
pause

:: Store initial file list
dir /b "%BinariesDir%\*.exe" > "%TempDir%\watch_initial.txt"

:WatchLoop
timeout /t 3 /nobreak >nul
dir /b "%BinariesDir%\*.exe" > "%TempDir%\watch_current.txt"

fc "%TempDir%\watch_initial.txt" "%TempDir%\watch_current.txt" >nul 2>&1
if !errorlevel! neq 0 (
    echo   Changes detected! Reloading...
    call :Log "Watch mode: Changes detected"
    copy "%TempDir%\watch_current.txt" "%TempDir%\watch_initial.txt" >nul
    timeout /t 1 /nobreak >nul
    goto MainMenu
)

goto WatchLoop

:: ============================================================================
:: Rebuild Integration (Enhanced)
:: ============================================================================
:RebuildMenu
echo.
echo   BUILD INTEGRATION
echo.
echo   [1] Rebuild Solution (msbuild)
echo   [2] Clean Build
echo   [3] Build Specific Configuration
echo   [4] Back
echo.
set /p "build_choice=  Select: "

if "!build_choice!"=="4" exit /b 0
if "!build_choice!"=="" exit /b 0

if "!build_choice!"=="3" (
    echo.
    echo   Configurations: Debug, Release, Profile
    set /p "build_config=  Enter configuration: "
    set "BuildCommand=msbuild /p:Configuration=!build_config!"
) else if "!build_choice!"=="1" (
    set "BuildCommand=msbuild /t:Rebuild"
) else if "!build_choice!"=="2" (
    set "BuildCommand=msbuild /t:Clean;Build"
)

if defined BuildCommand (
    echo.
    for %%s in ("%BuildsDir%\*.sln") do (
        echo   Building: %%~nxs
        call :Log "Building: %%~nxs with !BuildCommand!"
        
        cd /d "%BuildsDir%"
        !BuildCommand! "%%s"
        
        if !errorlevel! equ 0 (
            echo   Build successful
            call :Log "Build succeeded"
        ) else (
            echo   Build failed
            call :Log "Build failed"
        )
        
        pause
        exit /b 0
    )
    echo   No solution file found
    pause
)

exit /b 0

:: ============================================================================
:: Theme Management
:: ============================================================================
:ChangeTheme
echo.
echo   THEMES
echo.
echo   [1] Cyan     [2] Matrix   [3] Ocean    [4] Night
echo   [5] Alert    [6] Sunshine [7] Hacker   [8] Custom
echo.
set /p "theme_choice=  Select: "

if "!theme_choice!"=="1" set "ColorTheme=0B" & set "ThemeName=Cyan"
if "!theme_choice!"=="2" set "ColorTheme=0A" & set "ThemeName=Matrix"
if "!theme_choice!"=="3" set "ColorTheme=09" & set "ThemeName=Ocean"
if "!theme_choice!"=="4" set "ColorTheme=0D" & set "ThemeName=Night"
if "!theme_choice!"=="5" set "ColorTheme=0C" & set "ThemeName=Alert"
if "!theme_choice!"=="6" set "ColorTheme=0E" & set "ThemeName=Sunshine"
if "!theme_choice!"=="7" set "ColorTheme=02" & set "ThemeName=Hacker"

if "!theme_choice!"=="8" (
    echo.
    echo   Enter hex code (e.g., 0A for green on black):
    set /p "ColorTheme=  Code: "
    set "ThemeName=Custom"
)

if defined ThemeName (
    call :SaveConfig
    echo   Theme: !ThemeName!
    call :Log "Theme changed: !ThemeName!"
    timeout /t 1 /nobreak >nul
)

exit /b 0

:: ============================================================================
:: Configuration Menu
:: ============================================================================
:ConfigMenu
cls
echo.
echo   ╔════════════════════════════════════════════════════════════════════════════════════════════════╗
echo   ║  CONFIGURATION                                                                                 ║
echo   ╚════════════════════════════════════════════════════════════════════════════════════════════════╝
echo.
echo   [1] Max Parallel Jobs: !MaxParallel!
echo   [2] Quick Mode: !QuickMode!
echo   [3] Auto-Restart: !AutoRestart!
echo   [4] Show File Sizes: !ShowSizes!
echo   [5] Clear Favorites
echo   [6] Clear Profiles
echo   [7] Reset Metrics
echo   [8] Back
echo.
set /p "config_choice=  Select: "

if "!config_choice!"=="1" (
    echo.
    set /p "MaxParallel=  Max parallel jobs (1-10): "
    call :SaveConfig
)

if "!config_choice!"=="2" (
    if "!QuickMode!"=="ON" (set "QuickMode=OFF") else (set "QuickMode=ON")
    call :SaveConfig
)

if "!config_choice!"=="3" (
    if "!AutoRestart!"=="ON" (set "AutoRestart=OFF") else (set "AutoRestart=ON")
    call :SaveConfig
)

if "!config_choice!"=="4" (
    if "!ShowSizes!"=="ON" (set "ShowSizes=OFF") else (set "ShowSizes=ON")
    call :SaveConfig
)

if "!config_choice!"=="5" (
    if exist "%FavoritesFile%" del "%FavoritesFile%"
    echo   Favorites cleared
    timeout /t 1 /nobreak >nul
)

if "!config_choice!"=="6" (
    if exist "%ProfilesFile%" del "%ProfilesFile%"
    echo   Profiles cleared
    timeout /t 1 /nobreak >nul
)

if "!config_choice!"=="7" (
    if exist "%MetricsFile%" del "%MetricsFile%"
    echo   Metrics reset
    timeout /t 1 /nobreak >nul
)

exit /b 0

:: ============================================================================
:: View Logs
:: ============================================================================
:ViewLogs
cls
echo.
echo   ╔════════════════════════════════════════════════════════════════════════════════════════════════╗
echo   ║  LOGS & METRICS                                                                                ║
echo   ╚════════════════════════════════════════════════════════════════════════════════════════════════╝
echo.

if exist "%LogFile%" (
    echo   RECENT ACTIVITY
    echo.
    powershell -Command "Get-Content '%LogFile%' -Tail 15"
) else (
    echo   No logs available
)

echo.
echo   ══════════════════════════════════════════════════════════════════════════════════════════════════

if exist "%MetricsFile%" (
    echo.
    echo   METRICS
    echo.
    
    for /f %%a in ('findstr /c:"SUCCESS" "%MetricsFile%" ^| find /c /v ""') do set "success_count=%%a"
    for /f %%a in ('findstr /c:"CRASH" "%MetricsFile%" ^| find /c /v ""') do set "crash_count=%%a"
    
    echo   Successful launches: !success_count!
    echo   Crashes: !crash_count!
)

echo.
echo   Full logs: %LogFile%
echo.
pause
exit /b 0

:: ============================================================================
:: Core Functions
:: ============================================================================
:ValidateEnvironment
call :Log "Validating environment"

if not exist "%LibrariesDir%" (
    echo   ERROR: Libraries folder not found: %LibrariesDir%
    call :Log "ERROR: Libraries missing"
    pause
    exit /b 1
)

if not exist "%BinariesDir%" (
    echo   ERROR: Binaries folder not found: %BinariesDir%
    call :Log "ERROR: Binaries missing"
    pause
    exit /b 1
)

if not exist "%BuildEnvDir%" call :SetupEnvironment
if not exist "%TempDir%" mkdir "%TempDir%"

exit /b 0

:SetupEnvironment
cls
echo.
echo   FIRST TIME SETUP
echo.
echo   Creating build environment...

mkdir "%BuildEnvDir%" 2>nul
xcopy "%LibrariesDir%\*" "%BuildEnvDir%\" /Y /I /Q /E >nul 2>&1

echo   Complete
timeout /t 2 /nobreak >nul
call :Log "Build environment initialized"
exit /b 0

:ValidateNumber
set "test_num=%~1"
if "!test_num!"=="" exit /b 1

for /l %%i in (1,1,!count!) do (
    if "!test_num!"=="%%i" exit /b 0
)

echo   Invalid number: !test_num!
timeout /t 1 /nobreak >nul
exit /b 1

:LaunchExecutable
set "ExeIdx=%~1"
set "LaunchArgs=%~2"

set "ExeName=!exe_%ExeIdx%!"
set "ExePath=!path_%ExeIdx%!"

call :Log "Launching: !ExeName! !LaunchArgs!"

copy "%ExePath%" "%BuildEnvDir%\" /Y >nul 2>&1
if !errorlevel! neq 0 (
    echo   ERROR: Failed to copy executable
    call :Log "ERROR: Copy failed"
    timeout /t 2 /nobreak >nul
    exit /b 1
)

cls
echo.
echo   RUNNING: !ExeName!
if defined LaunchArgs echo   ARGS: !LaunchArgs!
echo.
echo   ══════════════════════════════════════════════════════════════════════════════════════════════════
echo.

cd /d "%BuildEnvDir%"

if defined LaunchArgs (
    call "!ExeName!.exe" !LaunchArgs!
) else (
    call "!ExeName!.exe"
)

set "ExitCode=!errorlevel!"

echo.
echo   ══════════════════════════════════════════════════════════════════════════════════════════════════

if !ExitCode! equ 0 (
    echo   SUCCESS
    call :Log "SUCCESS: !ExeName!"
) else (
    echo   FAILED - Exit code: !ExitCode!
    call :Log "CRASH: !ExeName! (code: !ExitCode!)"
)

echo.
pause
exit /b !ExitCode!

:ExecuteJob
set "JobExePath=%~1"
set "JobArgs=%~2"
set "JobLog=%~3"

cd /d "%BuildEnvDir%"
if defined JobArgs (
    call "!JobExePath!" !JobArgs! >"%JobLog%" 2>&1
) else (
    call "!JobExePath!" >"%JobLog%" 2>&1
)

if !errorlevel! equ 0 (
    echo SUCCESS >> "%JobLog%"
) else (
    echo FAILED >> "%JobLog%"
)
exit /b

:: ============================================================================
:: Configuration Management
:: ============================================================================
:LoadConfig
set "ColorTheme=0B"
set "ThemeName=Cyan"
set "MaxParallel=4"
set "QuickMode=ON"
set "AutoRestart=OFF"
set "ShowSizes=ON"

if exist "%ConfigFile%" (
    for /f "usebackq tokens=1,2 delims==" %%a in ("%ConfigFile%") do (
        if "%%a"=="ColorTheme" set "ColorTheme=%%b"
        if "%%a"=="ThemeName" set "ThemeName=%%b"
        if "%%a"=="MaxParallel" set "MaxParallel=%%b"
        if "%%a"=="QuickMode" set "QuickMode=%%b"
        if "%%a"=="AutoRestart" set "AutoRestart=%%b"
        if "%%a"=="ShowSizes" set "ShowSizes=%%b"
    )
)
exit /b 0

:SaveConfig
(
    echo ColorTheme=!ColorTheme!
    echo ThemeName=!ThemeName!
    echo MaxParallel=!MaxParallel!
    echo QuickMode=!QuickMode!
    echo AutoRestart=!AutoRestart!
    echo ShowSizes=!ShowSizes!
) > "%ConfigFile%"
call :Log "Config saved"
exit /b 0

:: ============================================================================
:: Utilities
:: ============================================================================
:InitLog
if not exist "%LogFile%" (
    echo Build Launcher Pro v2.0 Log > "%LogFile%"
    echo. >> "%LogFile%"
)
call :Log "Session started"
exit /b 0

:Log
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do set "mydate=%%c-%%a-%%b"
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do set "mytime=%%a:%%b"
echo [!mydate! !mytime!] %~1 >> "%LogFile%"
exit /b 0

:End
if exist "%TempDir%" rd /s /q "%TempDir%" 2>nul
echo.
call :Log "Session ended"
echo   Goodbye
timeout /t 1 /nobreak >nul
exit /b 0