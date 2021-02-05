@ECHO OFF
:: traverse a BirdScan raw data tree, identify 'yesterday' data, compress, test, delete.

:: raw data drive+path, i.e. directory that contains "year" subdirectories
SET ROOTDIR="E:\BollediMagadino\RawData"

:: zip file storage, if empty will leave /zip files "in place"

ECHO Root is %ROOTDIR%

:: convenience shortcuts
SET zipcmd="%ProgramFiles%/7-zip/7z.exe"


:: get today's date, parse it and get yesterday's 
:: as from https://stackoverflow.com/questions/355425/date-arithmetic-in-cmd-scripting
:: note the pile of shit needed, on *NIX it would be date -d "yesterday 13:00" '+%Y-%m-%d', but oh well
SET yyyy=
SET $tok=1-3
FOR /f "tokens=1 delims=.:/-, " %%u IN ('date /t') DO SET $d1=%%u
IF "%$d1:~0,1%" GTR "9" SET $tok=2-4
FOR /f "tokens=%$tok% delims=.:/-, " %%u IN ('date /t') DO (
  FOR /f "skip=1 tokens=2-4 delims=/-,()." %%x IN ('echo.^|date') DO (
    SET %%x=%%u
    SET %%y=%%v
    SET %%z=%%w
    SET $d1=
    SET $tok=))
IF "%yyyy%"=="" SET yyyy=%yy%
IF /I %yyyy% LSS 100 SET /A yyyy=2000 + 1%yyyy% - 100
:: now we have current date in three variables
SET CurDate=%mm%/%dd%/%yyyy%

SET dayCnt=%1
IF "%dayCnt%"=="" SET dayCnt=1

:: substract days here
SET /A dd=1%dd% - 100 - %dayCnt%
SET /A mm=1%mm% - 100

:: check and fix date
:CHKDAY
IF /I %dd% GTR 0 GOTO DONE
SET /A mm=%mm% - 1
IF /I %mm% GTR 0 GOTO ADJUSTDAY
SET /A mm=12
SET /A yyyy=%yyyy% - 1

:ADJUSTDAY
IF %mm%==1 GOTO SET31
IF %mm%==2 GOTO LEAPCHK
IF %mm%==3 GOTO SET31
IF %mm%==4 GOTO SET30
IF %mm%==5 GOTO SET31
IF %mm%==6 GOTO SET30
IF %mm%==7 GOTO SET31
IF %mm%==8 GOTO SET31
IF %mm%==9 GOTO SET30
IF %mm%==10 GOTO SET31
IF %mm%==11 GOTO SET30
:: note that ** Month 12 falls through

:SET31
SET /A dd=31 + %dd%
GOTO CHKDAY

:SET30
SET /A dd=30 + %dd%
GOTO CHKDAY

:LEAPCHK
SET /A tt=%yyyy% %% 4
IF NOT %tt%==0 GOTO SET28
SET /A tt=%yyyy% %% 100
IF NOT %tt%==0 GOTO SET29
SET /A tt=%yyyy% %% 400
IF %tt%==0 GOTO SET29

:SET28
SET /A dd=28 + %dd%
GOTO CHKDAY

:SET29
SET /A dd=29 + %dd%
GOTO CHKDAY

:DONE
IF /I %mm% LSS 10 SET mm=0%mm%
IF /I %dd% LSS 10 SET dd=0%dd%

ECHO Date %dayCnt% day(s) before %CurDate% is %yyyy%-%mm%-%dd%
:: we now have yesterdays year in %yyyy%
::             yesterdays month in %mm%
::             yesterdays day ib %dd%

:: cd into the 'year/month' directory
CD/D "%ROOTDIR%"
CD %yyyy%
CD %mm% 

:: compress 'yesterday'
%zipcmd% a -tzip -bt -mmt1 -mx9 -r -y "%dd%.zip" "%dd%/*.*"
IF %ERRORLEVEL% GTR 0 EXIT 999 REM here should raise an error

:: test it
%zipcmd% a "%dd%.zip"
IF %ERRORLEVEL% GTR 0 EXIT 998 REM here should raise an error

:: delete raw
DEL /q "%dd%"

:: end
cd \
