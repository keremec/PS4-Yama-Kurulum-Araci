@echo off
color 1f
setlocal enabledelayedexpansion

echo.
echo ::::::::::::::::::::::::::::::::::::::::::::::
echo :: PS4 FPKG Patch Yama Kurucu - keremec ::
echo ::::::::::::::::::::::::::::::::::::::::::::::
echo.

:: to decrease verbosity just comment first line below (induced popup)
set verbose=yes

::: create few working directories :::

set root=%~dp0
set root=%root:~0,-1%

md "%root%\bin" "%root%\game" "%root%\patch" "%root%\repack" "%root%\mods" >nul 2>&1

::: change system temporary directory path :::

:: by default, temp values refer natively to system drive and is commonly used by software
:: but it should not be used to buffer huge amount of data (see "ps4pub" directory)

:: to avoid system drive overload during extracting and building process
:: we're going to change that in a non persistent way to only impact this script

:: temp values referer in this script to the temp directory made at the root (see command just above)

:: performance may be improved by working on different disks to separate read and write access
:: value must be an absolute path without double quote nor trailing backslash (ex : set temp=d:\temp )
:: to do that change only the value on the first line below

set temp=%root%\temp

:: temp and tmp vars must have the same value so it's why tmp refer to %temp% (don't change that)

set tmp=%temp%

:: quick check

md "%temp%" >nul 2>&1
copy /y nul "%temp%\.writable" >nul 2>&1 || (echo Warning : temp directory is not accessible or writable ?! & goto exit)
del /f "%temp%\.writable" >nul 2>&1

::: change unpack directory path :::

:: for convenience you can customize and change unpack directory path

:: performance may also be improved by working on different disks to separate read and write access
:: value must be an absolute path without double quote nor trailing backslash (ex : set unpack=d:\unpack )
:: to do that change only the value on the first line below

set unpack=%root%\unpack

:: quick check

md "%unpack%" >nul 2>&1
copy /y nul "%unpack%\.writable" >nul 2>&1 || (echo Warning : unpack directory "%unpack%" is not accessible or writable ?! & goto exit)
del /f "%unpack%\.writable" >nul 2>&1

::: checking binary requirements :::

if not exist "%root%\bin\orbis-pub-cmd.exe" copy /y "%root%\bin\orbis-pub-cmd-ps2.exe" "%root%\bin\orbis-pub-cmd.exe" >nul 2>&1
if not exist "%root%\bin\orbis-pub-cmd.exe" (echo Warning : missing "%root%\bin\orbis-pub-cmd.exe" ... something wrong with binaries requirements ?! & goto exit)
if not exist "%root%\bin\gengp4.exe" (echo Warning : missing "%root%\bin\gengp4.exe" ... something wrong with binaries requirements ?! & goto exit)
if not exist "%root%\bin\ext\di.exe" (echo Warning : missing "%root%\bin\ext\di.exe" ... something wrong with binaries requirements ?! & goto exit)
if not exist "%root%\bin\ext\sc.exe" (echo Warning : missing "%root%\bin\ext\sc.exe" ... something wrong with binaries requirements ?! & goto exit)

::: check integrity project and fill local vars :::

for /f %%i in ('dir /b "%root%\game\*.pkg" 2^>nul ^| find /v /c ""') do if not %%i equ 1 (echo Warning : put at least one and only one base fpkg in "%root%\game" directory & goto exit)
for /f %%i in ('dir /b "%root%\patch\*.pkg" 2^>nul ^| find /v /c ""') do if not %%i equ 1 (echo Warning : put at least one and only one update fpkg in "%root%\patch" directory & goto exit)

for /f "tokens=*" %%i in ('dir /b "%root%\game\*.pkg"') do set game=%%i
for /f "tokens=*" %%i in ('dir /b "%root%\patch\*.pkg"') do set patch=%%i

echo ::::: Ana Oyun Dosyasi Ozellikleri :::::
echo.

echo File Name: %game%
"%root%\bin\orbis-pub-cmd.exe" img_info "%root%\game\%game%" | findstr /i /c:"title name (default)" /c:"content" /c:"version" /c:"volume"
if not %errorlevel% equ 0 (echo Warning : something went wrong parsing base fpkg in game directory & goto exit)
echo.

for /f "tokens=3" %%i in ('""%root%\bin\orbis-pub-cmd.exe" img_info "%root%\game\%game%" | find /i "title id:""') do set cusa=%%i
echo %cusa% | find /i "cusa" >nul 2>&1 || (echo Warning : something went wrong checking cusa base fpkg in game directory & goto exit)

for /f "tokens=3" %%i in ('""%root%\bin\orbis-pub-cmd.exe" img_info "%root%\game\%game%" | find /i "Volume Type:""') do ^
if /i not [%%i] == [application] (echo Warning : this is not a base fpkg in game directory & goto exit)

echo ::::: Patch Dosyasi Ozellikleri :::::
echo.

echo File Name: %patch%
"%root%\bin\orbis-pub-cmd.exe" img_info "%root%\patch\%patch%" | findstr /i /c:"title name (default)" /c:"content" /c:"version" /c:"volume"
if not %errorlevel% equ 0 (echo Warning : something went wrong parsing update fpkg in patch directory & goto exit)
echo.

for /f "tokens=3" %%i in ('""%root%\bin\orbis-pub-cmd.exe" img_info "%root%\patch\%patch%" | find /i "title id:""') do ^
if /i not [%%i] == [%cusa%] echo Warning : cusa fpkg base and update are not corresponding

for /f "tokens=3" %%i in ('""%root%\bin\orbis-pub-cmd.exe" img_info "%root%\patch\%patch%" | find /i "Volume Type:""') do ^
if /i not [%%i] == [patch] (echo Warning : this is not an update fpkg in patch directory & goto exit)

::: extract ps4 fpkg update :::

echo ::::: Patch Dosyasi Cikartiliyor :::::
echo.

md "%unpack%\%cusa%" >nul 2>&1

if exist "%unpack%\%cusa%\image0" (echo Warning : found scories of a previous extracting ... you should cleanup or delete "%unpack%\%cusa%" & goto exit)
if exist "%unpack%\%cusa%\sc0" (echo Warning : found scories of a previous extracting ... you should cleanup or delete "%unpack%\%cusa%" & goto exit)

:: passcode is voluntary hardcoded
:: everyone should follow this recommended value

if not exist "%unpack%\%cusa%\%cusa%-patch" (
	echo Unpacking "%root%\patch\%patch%" in progess ...
	"%root%\bin\orbis-pub-cmd.exe" img_extract --passcode 00000000000000000000000000000000 --tmp_path "%temp%" "%root%\patch\%patch%" "%unpack%\%cusa%" >nul 2>&1
	if !errorlevel! equ 0 (echo. & echo Succeed.) else (echo Warning : something went wrong extracting update fpkg in patch directory & goto exit)
) else (
	echo "%unpack%\%cusa%\%cusa%-patch" directory already exist
	echo.
	echo To save time we are not going to extract related patch again :
	echo "%root%\patch\%patch%"
	echo. 
	echo If you want to reset this step, just break this script now ^(ctrl + c^)
	echo Then delete "%unpack%\%cusa%\%cusa%-patch" and re-launch %~nx0 ^^!^^!^^!
	echo.
	echo Otherwise press any key to continue ...
	pause >nul 2>&1
)
echo.

::: adjust previous extracting tree directories for gengp4 :::



echo ::::: GenGP4 Projesi Hazirligi Yapiliyor :::::
echo.

:: this is based on sashka guide and alexandre47 update

:: notice : using robocopy to move files is a false good idea
:: even with a /mov, robocopy copy files first then delete them
:: with some giga it takes time on slow hdd for nothing :(

:robocopy "%unpack%\%cusa%\%cusa%-patch\sc0" "%unpack%\%cusa%\%cusa%-patch\image0\sce_sys" /mov /e >nul 2>&1
:rmdir /s /q "%unpack%\%cusa%\%cusa%-patch\sc0" >nul 2>&1
:move /y "%unpack%\%cusa%\%cusa%-patch\image0\sce_sys\app\playgo-chunk.dat" "%unpack%\%cusa%\%cusa%-patch\image0\sce_sys" >nul 2>&1
:rmdir /s /q "%unpack%\%cusa%\%cusa%-patch\image0\sce_sys\app" >nul 2>&1
:robocopy "%unpack%\%cusa%\%cusa%-patch\image0" "%unpack%\%cusa%\%cusa%-patch" /mov /e >nul 2>&1
:rmdir /s /q "%unpack%\%cusa%\%cusa%-patch\image0" >nul 2>&1

:: using move native command is better because it's nearly instantaneous
:: but move command is a bit more restrictive (cannot merge existing directory)
:: so we need to move file by file and create each (tree) directory before

for /f "tokens=*" %%i in ('dir /B /AD /S "%unpack%\%cusa%\sc0" 2^>nul') do (
set line=%%i
set line=!line:sc0=image0\sce_sys!
mkdir "!line!" >nul 2>&1
)

for /f "tokens=*" %%i in ('dir /B /A-D /S "%unpack%\%cusa%\sc0" 2^>nul') do (
set line=%%i
set line=!line:sc0=image0\sce_sys!
move /y "%%i" "!line!" >nul 2>&1
)

rmdir /s /q "%unpack%\%cusa%\sc0" >nul 2>&1
move /y "%unpack%\%cusa%\image0\sce_sys\app\playgo-chunk.dat" "%unpack%\%cusa%\image0\sce_sys" >nul 2>&1
rmdir /s /q "%unpack%\%cusa%\image0\sce_sys\app" >nul 2>&1
move /y "%unpack%\%cusa%\image0" "%unpack%\%cusa%\%cusa%-patch" >nul 2>&1

:: quick integrity gp4 project check 

if not exist "%unpack%\%cusa%\%cusa%-patch\eboot.bin" (echo Warning : missing "%unpack%\%cusa%\%cusa%-patch\eboot.bin" ... something wrong with fpkg extract step ?! & goto exit)
if not exist "%unpack%\%cusa%\%cusa%-patch\sce_sys\param.sfo" (echo Warning : missing "%unpack%\%cusa%\%cusa%-patch\sce_sys\param.sfo" ... something wrong with fpkg extract step ?! & goto exit)
if not exist "%unpack%\%cusa%\%cusa%-patch\sce_sys\playgo-chunk.dat" (echo Warning : missing "%unpack%\%cusa%\%cusa%-patch\sce_sys\playgo-chunk.dat" ... something wrong with fpkg extract step ?! & goto exit)

echo Succeed.
echo.


::: adding mods here :::

echo ::::: Mod ve Yamalar Ekleniyor :::::

robocopy /s "%root%\mods"  "%unpack%\%cusa%\%cusa%-patch"
copy /y "%MYFILES%\changeinfo.xml"  "%unpack%\%cusa%\%cusa%-patch\sce_sys\changeinfo"


::: generate new gp4 project :::

echo ::::: GenGP4 Projesi Olusturuluyor :::::

del /f /q "%unpack%\%cusa%\%cusa%-patch.gp4" >nul 2>&1

:: gengp4 is not really cmdline proof ;)
:: could certainly be done with orbis-pub-cmd.exe ?

if /i not [%verbose%] == [yes] (
  :: using start command to separate verbosity, work in a defined path, terminate process (induced popup)
  start "" /d "%unpack%\%cusa%" /wait cmd /c "%root%\bin\gengp4.exe" %cusa%-patch
  ) else (
  :: with verbosity without popup
  pushd "%unpack%\%cusa%"
  "%root%\bin\gengp4.exe" "%unpack%\%cusa%\%cusa%-patch"  | echo.
  popd
)

if exist "%unpack%\%cusa%\%cusa%-patch.gp4" (echo Succeed. & echo.) else (echo Warning : something went wrong generating gengp4 project & goto exit)

:: in case of scenario problem, check for a proper base or update
:: scenario should not differ unless they've been edited ?!

::: rebuild fpkg update based on previous created gp4 project :::

echo ::::: Yamali Patch Dosyasi Paketleniyor :::::
echo.

:: repack keeping original update filename 
set repack=%patch%

:: repack adding suffix -repack (to disable just comment line below)
set repack=%patch:.pkg=-repack.pkg%

:: update app_path with the correct path and filename
"%root%\bin\orbis-pub-cmd.exe" gp4_proj_update --app_path "%root%\game\%game%" "%unpack%\%cusa%\%cusa%-patch.gp4"

:: launch rebuild process

if /i not [%verbose%] == [yes] (
  :: separate verbosity with popup
  start "" /wait cmd /c ""%root%\bin\orbis-pub-cmd.exe" img_create --tmp_path "%temp%" "%unpack%\%cusa%\%cusa%-patch.gp4" "%root%\repack\%repack%" || (pause & exit /b 1)"
  if not !errorlevel! equ 0 (echo Warning : something went wrong creating new fpkg update ?^^! & goto exit)
  ) else (
  :: with verbosity without popup
  "%root%\bin\orbis-pub-cmd.exe" img_create --tmp_path "%temp%" "%unpack%\%cusa%\%cusa%-patch.gp4" "%root%\repack\%repack%"
  if not !errorlevel! equ 0 goto exit
)
  
:: using findstr to decrease verbosity conflict with progress bar :(
:"%root%\bin\orbis-pub-cmd.exe" img_create --tmp_path "%temp%" "%unpack%\%cusa%\%cusa%-patch.gp4" "%root%\repack\%repack%" | findstr /i /v "debug warn"

echo Succeed.
echo.
echo ::::: Yamali Patch Dosyasi Ozellikleri :::::
echo.
echo Repack file: "%root%\repack\%repack%"
"%root%\bin\orbis-pub-cmd.exe" img_info "%root%\repack\%repack%" | findstr /i /c:"title name (default)" /c:"content" /c:"version" /c:"volume"

echo :                                                                 :  
echo ::::::::::::::::: Yama Basarili Sekilde Uygulandi :::::::::::::::::           
echo ::::: Yamali Patch Dosyasini Repack Klasorunde Bulabilirsiniz :::::
echo :                                                                 : 
color 2f

:exit
endlocal
echo.
pause
