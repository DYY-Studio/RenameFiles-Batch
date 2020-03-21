@echo off
chcp 65001
title RenameFiles END [(c)yyfll] [System] [UTF8]
:Module_DEBUG
if not defined debug (
	set debug=0
	cmd /c call "%~0"
	if "%~1"=="" (
		echo [Module_DEBUG] 请按任意键退出... 
		pause>nul
		exit
	) else (
		if defined title (
			title %title%
		) else title Command Shell
		set "debug="
		goto :EOF
	)
) else set "debug="
:Main
cls

set "indir="
set "attribute="
set "filter="
set "from="
set "to="
set "log="

echo [Ver] RenameFilesBatch END_UTF8
echo [Use] CMD default
echo [Dev] Copyright(c) 2019-2020 yyfll L:MIT
echo.

set /p indir=目录: 

if exist "%indir:~1,-1%" (
	set "indir=%indir:~1,-1%"
) else set "indir=%indir%"
if not exist "%indir%" (
	if not defined indir (
		echo [ERROR] 您没有输入路径
	) else echo [ERROR] 找不到"%indir%"
	pause
	goto Main
)

for %%a in ("%indir%") do (
	set "attribute=%%~aa"
)
if /i "%attribute:~0,1%" NEQ "d" (
	echo [ERROR] 输入路径不是目录
	pause
	goto Main
)

if "%indir:~-1%" NEQ "\" set "indir=%indir%\"
if exist "%indir%rename-undo.log" (
	choice /C YN /M 检测到UNDO记录，是否要恢复原名？
) else goto no_undolog
if %errorlevel%==0 (
	echo [ERROR] CTRL+C
	ping -n 4 -w 1000 127.0.0.1 >nul 2>nul
	goto :EOF
) else if %errorlevel%==1 ( 
	Call :Module_UNDO "%indir%rename-undo.log"
	goto Main
)

:no_undolog

set /p filter=文件过滤: 
set /p from=替换目标: 
set /p to=替换为: 

rem if defined attribute goto :EOF

if not defined filter set filter=*
if not defined from goto :EOF

cls

set "rename_cache=%TEMP%\working_rename.log"
set "rename_prev=%TEMP%\preview_rename.log"
set "rename_log=%indir%rename-log.log"
set "rename_undo=%indir%rename-undo.log"

if exist "%rename_cache%" del /q "%rename_cache%"
if exist "%rename_prev%" del /q "%rename_prev%"

for /r "%indir%" %%a in ("*rename*.log") do if exist "%%~a" del /q "%%~a"

if not exist "%rename_log%" (
	(echo FastRenameFiles-LogFile
	echo [INFO]
	echo DIR:     "%indir%"
	echo FILTER:  "%filter%"
	echo TARGET:  "%from%"
	echo REPLACE: "%to%"
	echo [INFO]
	echo.)>>"%rename_log%"
)

for /r "%indir%" %%a in ("%filter%") do (
	if exist "%%~a" (
		echo [CHECK] 正在检查文件名"%%~nxa"...
		for /f "tokens=1,2 delims=%%" %%b in ("%%~a") do (
			if not "%%~c"=="" (
				echo [ERROR] 哦~这个版本并不支持"%%"这个该死的符号！
			) else call :Class_REPLACE "%%~a"
		)
	)
)

(echo [FILE SEARCHING END]
echo.)>>"%rename_log%"
goto Class_PREVIEW
:Class_REPLACE
set "fn=%~n1"
set "fn=%fn:!=???%"

setlocal ENABLEDELAYEDEXPANSION
for /f "tokens=*" %%b in ("!fn:%from%=%to%!") do (
	if not "%%~b"=="%~1" (
		call :Find_FILE "%~1" "%%~b"
	) else (
		call :Skip_FILE "%~1"
	)
)

setlocal DISABLEDELAYEDEXPANSION
goto :EOF
:Find_FILE
setlocal DISABLEDELAYEDEXPANSION
set "ff=%~2"
set "ff=%ff:???=!%"
echo [FIND] 找到匹配目标"%~nx1"
echo "%~1"^|"%~dp1%ff%%~x1">>"%rename_cache%"
(echo "%~nx1"
echo --^> "%ff%%~x1"
echo.) >>"%rename_prev%"
(echo [FIND]
echo [Dir] "%~dp1"
echo [File] "%~nx1")>>"%rename_log%"
call :Write_Time "%rename_log%"
setlocal ENABLEDELAYEDEXPANSION
goto :EOF
:Skip_FILE
set "skf=%~1"
setlocal DISABLEDELAYEDEXPANSION
set "skf=%skf:???=!%"
for /f "tokens=*" %%a in ("%skf%") do (
	echo [SKIP] 跳过不符合的目标"%%~nxa"
	(echo [NOFIND]
	echo [Dir] "%%~dpa"
	echo [Skip] "%%~nxa")>>"%rename_log%"
)
call :Write_Time "%rename_log%"
setlocal ENABLEDELAYEDEXPANSION
goto :EOF
:Class_PREVIEW
cls
echo [RENAME PREVIEW]
echo.
type "%rename_prev%"
echo.
echo 重命名预览显示完毕
echo 按任意键来执行重命名...
pause>nul

cls
for /f "usebackq tokens=1,2 delims=^|" %%a in ("%rename_cache%") do (
	rename "%%~a" "%%~nxb"
	if exist "%%~b" (
		echo [SUCCESS] 成功重命名为"%%~b"
		(echo [SUCCESS]
		echo [Dir] "%%~dpa"
		echo [Before] "%%~nxa"
		echo [Rename] "%%~nxb")>>"%rename_log%"
		call :Write_Time "%rename_log%"
	) else (
		echo [ERROR] 发生错误
		(echo [ERROR]
		echo [Dir] "%%~dpa"
		echo [Input] "%%~nxa"
		echo [TryRename] "%%~nxb")>>"%rename_log%"
		call :Write_Time "%rename_log%"
	)
)

if exist "%rename_cache%" move /y "%rename_cache%" "%rename_undo%" 1>nul 2>nul

echo 按任意键结束本次运行...
pause>nul
goto Main
:Write_Time
(echo [%date% %time%]
echo.)>>"%~1"
goto :EOF
:Module_UNDO
cls
set "log=%~1"

for /f "usebackq tokens=1,2 delims=^|" %%a in ("%log%") do (
	if exist "%%~b" (
		rename "%%~b" "%%~nxa" 2>>"%%~dpaundorename-error.log"
		if not exist "%%~a" (
			echo [ERROR] 未成功恢复"%%~nxa"
			set "error=1"
			for /f "tokens=*" %%c in ('echo %time%') do (
				(echo [%%~c]
				echo FILE: "%%~nxa"
				echo.)>>"%%~dpaundorename-error.log"
			)
		) else echo [SUCCESS] 已复原"%%~nxa"
	) else (
		for /f "tokens=*" %%c in ('echo %time%') do (
			(echo FILE NOT FOUND
			echo [%%~c]
			echo FILE: "%%~nxa"
			echo.)>>"%%~dpaundorename-error.log"
		)
	)
)
for /r "%~dp1" %%a in ("undorename-error.log") do (
	if exist "%%~a" (
		if not "%%~za"=="" ( 
			if 0%%~za==0 del /q "%%~a"
		) else del /q "%%~a"
	)
)
if not defined error if exist "%log%" del /q "%log%"
pause
goto :EOF