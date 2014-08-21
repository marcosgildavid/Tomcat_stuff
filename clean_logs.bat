echo off
REM ********************************
REM *       USER VARIABLES         *

REM CLEAN FILES OLDER THAN NUM_DAYS
set NUM_DAYS=7

REM PATH WHERE TO RECURSIVELY SEARCH FOR FILES
set SRCDIR=e:\LOGS

REM FILE EXTENSION TO LOOK FOR (*.* FOR ALL FILES)
set EXT="*.log"
REM ********************************


echo "Cleaning Files older than %NUM_DAYS% on %SRCDIR%"

forfiles /p "%SRCDIR%" /s /m %EXT% /D -%NUM_DAYS% /C "cmd /c del @path"

echo "DONE!"
echo on
