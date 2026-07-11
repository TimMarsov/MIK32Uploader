@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ==========================================================
REM MIK32 firmware write + verification tests for RAM/EEPROM/SPIFI
REM ==========================================================

set "PROJECT_NAME=firmware"
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "REPO_ROOT=%%~fI"

REM Paths can be overridden before launch:
REM   set UPLOADER_EXE=C:\path\to\mik32_upload.exe
REM   set OPENOCD_BIN=C:\path\to\openocd.exe
REM   set OPENOCD_SCRIPTS=C:\path\to\openocd-scripts
REM   set INTERFACE_CFG=C:\path\to\interface.cfg
REM   set TARGET_CFG=C:\path\to\target.cfg
REM   set EEPROM_FILE=C:\path\to\eeprom.hex
REM   set FLASH_FILE=C:\path\to\spifi.hex
REM   set RAM_FILE=C:\path\to\ram.hex

if not defined UPLOADER_EXE set "UPLOADER_EXE=%REPO_ROOT%\release\mik32_upload.exe"

if not defined OPENOCD_BIN set "OPENOCD_BIN=openocd.exe"
if not exist "%OPENOCD_BIN%" set "OPENOCD_BIN=openocd.exe"

if not defined OPENOCD_SCRIPTS set "OPENOCD_SCRIPTS=%SCRIPT_DIR%openocd-scripts"
if not defined INTERFACE_CFG set "INTERFACE_CFG=%OPENOCD_SCRIPTS%\interface\KoteLink.cfg"
if not defined TARGET_CFG set "TARGET_CFG=%OPENOCD_SCRIPTS%\target\mik32.cfg"

if not defined EEPROM_FILE set "EEPROM_FILE=%SCRIPT_DIR%firmware\eeprom.hex"
if not defined FLASH_FILE set "FLASH_FILE=%SCRIPT_DIR%firmware\spifi.hex"
if not defined RAM_FILE set "RAM_FILE=%SCRIPT_DIR%firmware\ram.hex"
if not defined MCU_TYPE set "MCU_TYPE=MIK32V2"
if not defined ADAPTER_SPEED set "ADAPTER_SPEED=500"
if not defined REPEAT_COUNT set "REPEAT_COUNT=1"

REM 1 - pause before every next test, 0 - run all tests without pauses.
if not defined PAUSE_BETWEEN_TESTS set "PAUSE_BETWEEN_TESTS=0"

if not exist "%EEPROM_FILE%" (
    echo [ERROR] EEPROM firmware file not found: %EEPROM_FILE%
    pause
    exit /b 1
)

if not exist "%FLASH_FILE%" (
    echo [ERROR] Flash firmware file not found: %FLASH_FILE%
    pause
    exit /b 1
)

if not exist "%RAM_FILE%" (
    echo [ERROR] RAM firmware file not found: %RAM_FILE%
    pause
    exit /b 1
)

if not exist "%UPLOADER_EXE%" (
    echo [ERROR] Uploader not found: %UPLOADER_EXE%
    pause
    exit /b 1
)

echo [INFO] EEPROM:    %EEPROM_FILE%
echo [INFO] Flash:     %FLASH_FILE%
echo [INFO] RAM:       %RAM_FILE%
echo [INFO] Uploader:  %UPLOADER_EXE%
echo [INFO] OpenOCD:   %OPENOCD_BIN%
echo [INFO] Scripts:   %OPENOCD_SCRIPTS%
echo [INFO] Interface: %INTERFACE_CFG%
echo [INFO] Target:    %TARGET_CFG%
echo [INFO] MCU type:  %MCU_TYPE%
echo [INFO] Repeats:   %REPEAT_COUNT% per parameter combination
echo [INFO] Speed:     %ADAPTER_SPEED% kHz
echo.
echo Verification is performed by mik32_upload.exe after every write.
echo Speed statistics are calculated from firmware file size and elapsed time.
echo.

set /a TOTAL_TESTS=0
set /a EXPECTED_TESTS=14*REPEAT_COUNT
set /a PASSED_TESTS=0
set /a FAILED_TESTS=0
set "FAILED_LIST="
set "SUMMARY_FILE=%TEMP%\mik32_upload_stats_%RANDOM%_%RANDOM%.txt"
break > "%SUMMARY_FILE%"

call :RUN_REPEATED_TEST "RAM no-reset-registers" "%RAM_FILE%" "--boot-mode=ram --no-reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "RAM reset-registers" "%RAM_FILE%" "--boot-mode=ram --reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "EEPROM driver no-reset-registers" "%EEPROM_FILE%" "--boot-mode=eeprom --no-reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "EEPROM driver reset-registers" "%EEPROM_FILE%" "--boot-mode=eeprom --reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "EEPROM no-driver no-reset-registers" "%EEPROM_FILE%" "--boot-mode=eeprom --no-driver --no-reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "EEPROM no-driver reset-registers" "%EEPROM_FILE%" "--boot-mode=eeprom --no-driver --reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "FLASH driver no-reset-registers" "%FLASH_FILE%" "--boot-mode=spifi --no-reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "FLASH driver reset-registers" "%FLASH_FILE%" "--boot-mode=spifi --reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "FLASH Quad SPI no-reset-registers" "%FLASH_FILE%" "--boot-mode=spifi --use-quad-spi --no-reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "FLASH Quad SPI reset-registers" "%FLASH_FILE%" "--boot-mode=spifi --use-quad-spi --reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "FLASH no-driver no-reset-registers" "%FLASH_FILE%" "--boot-mode=spifi --no-driver --no-reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "FLASH no-driver reset-registers" "%FLASH_FILE%" "--boot-mode=spifi --no-driver --reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "FLASH Quad SPI no-driver no-reset-registers" "%FLASH_FILE%" "--boot-mode=spifi --use-quad-spi --no-driver --no-reset-registers"
call :NEXT_TEST
call :RUN_REPEATED_TEST "FLASH Quad SPI no-driver reset-registers" "%FLASH_FILE%" "--boot-mode=spifi --use-quad-spi --no-driver --reset-registers"

echo.
echo ==========================================================
echo RESULT
echo ==========================================================
echo Total:  !TOTAL_TESTS!
echo Expected: !EXPECTED_TESTS!
echo Passed: !PASSED_TESTS!
echo Failed: !FAILED_TESTS!

echo.
echo ==========================================================
echo SPEED STATISTICS ^(successful runs only^)
echo ==========================================================
type "%SUMMARY_FILE%"
del "%SUMMARY_FILE%" >nul 2>nul

if not "!TOTAL_TESTS!"=="!EXPECTED_TESTS!" (
    echo.
    echo [ERROR] Unexpected number of checks.
    echo [ERROR] Expected !EXPECTED_TESTS! checks: final RAM/EEPROM/FLASH parameter matrix.
    pause
    exit /b 1
)

if "!FAILED_TESTS!" neq "0" (
    echo.
    echo Failed tests: !FAILED_LIST!
    echo.
    echo [ERROR] One or more firmware verification tests failed.
    pause
    exit /b 1
)

echo.
echo [OK] All firmware verification tests completed successfully.
pause
exit /b 0


:NEXT_TEST
if "%PAUSE_BETWEEN_TESTS%"=="1" (
    echo.
    echo [INFO] Press any key to start next test...
    pause >nul
    echo.
)
exit /b 0


:RUN_REPEATED_TEST
set "LABEL=%~1"
set "FIRMWARE_FILE=%~2"
set "EXTRA_ARGS=%~3"

for %%A in ("!FIRMWARE_FILE!") do set "GROUP_BYTES=%%~zA"
set /a GROUP_PASS=0
set /a GROUP_FAIL=0
set /a GROUP_TOTAL_MS=0
set /a GROUP_MIN_MS=2147483647
set /a GROUP_MAX_MS=0
set /a GROUP_TOTAL_KBPS=0

for /l %%R in (1,1,%REPEAT_COUNT%) do (
    call :RUN_TEST "!LABEL!" "!FIRMWARE_FILE!" "!EXTRA_ARGS!" "%%R"
    if "!LAST_RESULT!"=="0" (
        set /a GROUP_PASS+=1
        set /a GROUP_TOTAL_MS+=LAST_ELAPSED_MS
        set /a GROUP_TOTAL_KBPS+=LAST_SPEED_KBPS
        if !LAST_ELAPSED_MS! lss !GROUP_MIN_MS! set /a GROUP_MIN_MS=LAST_ELAPSED_MS
        if !LAST_ELAPSED_MS! gtr !GROUP_MAX_MS! set /a GROUP_MAX_MS=LAST_ELAPSED_MS
    ) else (
        set /a GROUP_FAIL+=1
    )
    if "%%R" neq "%REPEAT_COUNT%" call :NEXT_TEST
)

if !GROUP_PASS! gtr 0 (
    set /a GROUP_AVG_MS=GROUP_TOTAL_MS/GROUP_PASS
    set /a GROUP_AVG_KBPS=GROUP_TOTAL_KBPS/GROUP_PASS
    >> "%SUMMARY_FILE%" echo !LABEL!: pass=!GROUP_PASS! fail=!GROUP_FAIL! size=!GROUP_BYTES! bytes min=!GROUP_MIN_MS! ms avg=!GROUP_AVG_MS! ms max=!GROUP_MAX_MS! ms avg_speed=!GROUP_AVG_KBPS! KB/s
) else (
    >> "%SUMMARY_FILE%" echo !LABEL!: pass=0 fail=!GROUP_FAIL! size=!GROUP_BYTES! bytes avg_speed=N/A
)

exit /b 0


:RUN_TEST
set "LABEL=%~1"
set "FIRMWARE_FILE=%~2"
set "EXTRA_ARGS=%~3"
set "REPEAT_INDEX=%~4"

for %%A in ("!FIRMWARE_FILE!") do set "FILE_SIZE=%%~zA"
set /a TOTAL_TESTS+=1

echo ==========================================================
echo [TEST !TOTAL_TESTS!] !LABEL! ^(repeat !REPEAT_INDEX!/%REPEAT_COUNT%^)
echo [FILE] !FIRMWARE_FILE!
echo [SIZE] !FILE_SIZE! bytes
echo [ARGS] !EXTRA_ARGS!
echo ==========================================================

call :GET_TIME_MS START_MS

"%UPLOADER_EXE%" "!FIRMWARE_FILE!" ^
    --run-openocd ^
    --openocd-exec="%OPENOCD_BIN%" ^
    --openocd-scripts="%OPENOCD_SCRIPTS%" ^
    --openocd-interface="%INTERFACE_CFG%" ^
    --openocd-target="%TARGET_CFG%" ^
    --adapter-speed=%ADAPTER_SPEED% ^
    --mcu-type=%MCU_TYPE% ^
    !EXTRA_ARGS!

set "TEST_RESULT=%errorlevel%"

call :GET_TIME_MS END_MS

set /a ELAPSED_MS=!END_MS!-!START_MS!
if !ELAPSED_MS! lss 0 set /a ELAPSED_MS+=86400000
if !ELAPSED_MS! leq 0 set /a ELAPSED_MS=1
set /a SPEED_KBPS=FILE_SIZE*1000/ELAPSED_MS/1024

echo.
echo [!LABEL!] Exit code: !TEST_RESULT!
echo [!LABEL!] Time: !ELAPSED_MS! ms
echo [!LABEL!] Speed: !SPEED_KBPS! KB/s
echo [!LABEL!] Repeat: !REPEAT_INDEX!/%REPEAT_COUNT%
echo.

set "LAST_RESULT=!TEST_RESULT!"
set "LAST_ELAPSED_MS=!ELAPSED_MS!"
set "LAST_SPEED_KBPS=!SPEED_KBPS!"

if "!TEST_RESULT!"=="0" (
    set /a PASSED_TESTS+=1
    echo [PASS] !LABEL!
) else (
    set /a FAILED_TESTS+=1
    set "FAILED_LIST=!FAILED_LIST! !LABEL! repeat !REPEAT_INDEX!;"
    echo [FAIL] !LABEL!
)

exit /b 0


:GET_TIME_MS
for /f "tokens=1-4 delims=:.," %%a in ("%TIME%") do (
    set /a HH=1%%a-100
    set /a MM=1%%b-100
    set /a SS=1%%c-100
    set /a CC=1%%d-100
)

set /a NOW_MS=((HH*60+MM)*60+SS)*1000+CC*10
set "%~1=%NOW_MS%"
exit /b 0
