@echo off
title RenameFiles Alpha 3.0 [By yyfll] [ReplaceBatch V4-Mini]
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

echo [Main] RenameFilesBatch Alpha 3.0
echo [Include] Module_ReplaceBatch V4-Mini
echo.

set /p indir=目录：

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
	ping -n 4 -w 1000 127.0.0.1 >nul
	goto :EOF
) else if %errorlevel%==1 ( 
	Call :Module_UNDO "%indir%rename-undo.log"
	goto Main
)

:no_undolog

set /p filter=文件过滤：
set /p from=替换目标：
set /p to=替换为：

rem if defined attribute goto :EOF

if not defined filter set filter=*
if not defined from goto :EOF

for /r "%indir%" %%a in ("*rename*.log") do del /q "%%~a"

for /r "%indir%" %%a in ("%filter%") do (
	if exist "%%~a" (
		echo [CHECK] 正在检查文件名"%%~nxa"...
		Call :Module_ReplaceBatch "%%~na" "%from%" "%to%"
		for /f "usebackq tokens=*" %%b in ("%USERPROFILE%\rforbat.log") do (
			if not exist "%indir%rename-log.log" (
				(echo FastRenameFiles-LogFile
				echo [INFORMATION]
				echo DIR: "%indir%"
				echo FILTER: "%filter%"
				echo TARGET: "%from%"
				echo REPLACE: "%to%"
				echo [INFORMATION END]
				echo.)>>"%indir%rename-log.log"
			) else (
			rem	for /f "tokens=*" %%c in ('echo [%date% %time%]') do (
			rem		(echo %%~c
			rem		echo.)>>"%indir%rename-log.log"
			rem	)
				call :Write_Time "%indir%rename-log.log"
			)
			
			if not "%%~b"=="%%~na" (
				rename "%%~a" "%%~b%%~xa" 2>>"%indir%rename-log.log"
				if exist "%%~dpa%%~b%%~xa" (
					echo [SUCCESS] 成功重命名为"%%~b%%~xa"
					(echo [SUCCESS]
					echo [Dir] "%%~dpa"
					echo [Before] "%%~nxa"
					echo [Rename] "%%~b%%~xa")>>"%indir%rename-log.log"
					(echo "%%~dpa%%~b%%~xa"^|"%%~nxa")>>"%indir%rename-undo.log"
				) else (
					echo [ERROR] 发生错误
					(echo [ERROR]
					echo [Dir] "%%~dpa"
					echo [Input] "%%~nxa"
					echo [TryRename] "%%~b%%~xa")>>"%indir%rename-log.log"
				)
			) else (
				echo [SKIP] 跳过不符合的目标"%%~nxa"
				(echo [NOFIND]
				echo [Dir] "%%~dpa"
				echo [Skip] "%%~nxa")>>"%indir%rename-log.log"
			)
			echo.
		)
	)
)
pause
goto Main
:Write_Time
(echo [%date% %time%]
echo.)>>"%~1"
goto :EOF
:Module_UNDO
cls
set "log=%~1"

for /f "usebackq tokens=1,2 delims=^|" %%a in ("%log%") do (
	if exist "%%~a" (
		rename "%%~a" "%%~b" 2>>"%%~dpaundorename-error.log"
		if not exist "%%~dpa%%~b" (
			echo [ERROR] 未成功恢复"%%~b"
			set "error=1"
			for /f "tokens=*" %%c in ('echo %time%') do (
				(echo [%%~c]
				echo FILE: "%%~a"
				echo.)>>"%%~dpaundorename-error.log"
			)
		) else echo [SUCCESS] 已复原"%%~b"
	) else (
		for /f "tokens=*" %%c in ('echo %time%') do (
			(echo FILE NOT FOUND
			echo [%%~c]
			echo FILE: "%%~a"
			echo.)>>"%%~dpaundorename-error.log"
		)
	)
)
for /r "%~dp1" %%a in ("undorename-error.log") do (
	if exist "%%~a" (
		if not "%%~za"=="" ( 
			if %%~za==0 del /q "%%~a"
		) else del /q "%%~a"
	)
)
if not defined error del /q "%log%"
pause
goto :EOF
:Module_ReplaceBatch
if "%~1"=="" (
	goto RB.error_input
) else if "%~2"=="" (
	goto RB.error_input
)
set "input_string=%~1"
if "%input_string:~0,1%"=="" (
	echo [ERROR] 您没有输入任何字符！
	goto RB.error_input
)
set "for_delims=%~2"
if "%for_delims%"=="" (
	echo [ERROR] 您没有输入任何要替换的字符！
	goto RB.error_input
)
set "replace_to=%~3"
setlocal enabledelayedexpansion

set "RB_str_len=0"
:RB.delims_len
set "RB_len=!for_delims:~%RB_str_len%!"
if not "%RB_len%"=="" (
	set /a RB_str_len=RB_str_len+1
	goto RB.delims_len
) else set "delims_len=%RB_str_len%"

set "RB_str_len=0"
:RB.input_len
set "RB_inlen=!input_string:~%RB_str_len%!"
if not "%RB_inlen%"=="" (
	set /a RB_str_len=RB_str_len+1
	goto RB.input_len
) else set "input_len=%RB_str_len%"

set "RB_str_len=0"
if not defined replace_to (
	set "replace_len=0"
	goto RB.nocheck_re
)
:RB.replace_len
set "RB_relen=!replace_to:~%RB_str_len%!"
if not "%RB_relen%"=="" (
	set /a RB_str_len=RB_str_len+1
	goto RB.replace_len
) else set "replace_len=%RB_str_len%"

:RB.nocheck_re
set "RB_str_len="
if %input_len% LEQ %delims_len% (
	echo [ERROR] 输入字符串不能与替换字符串等长!
	goto RB.error_input
)

set /a gap=replace_len-delims_len
set "step=1"
set "all_gap=0"
:RB.list_input
set /a list_end=input_len-delims_len
set /a list_start=0
for /l %%a in (%list_start%,%step%,%list_end%) do (
	set "RB_List[%%a]=!input_string:~%%a,%delims_len%!"
	for /f "tokens=*" %%b in ('set /a %%a+%delims_len%') do (
		set "RB_range[%%a]=%%a,%%b"
	)
)
rem echo [%delims_len%]^|[%input_len%]^|[%replace_len%]
rem set RB_
rem pause

set /a loop=list_start-1
set /a loop_end=list_end+1
:RB.replace_start
set /a loop=loop+1 
if "%loop%"=="%loop_end%" goto RB.replace_end
set "replace=!RB_List[%loop%]!"
if not "%replace%"=="%for_delims%" goto RB.replace_start
for /f "tokens=1* delims==" %%a in ('set RB_range[%loop%]') do (
	for /f "tokens=1,2 delims=," %%c in ("%%~b") do (
		if not defined all_gap (
			set "range[0]=%%c"
			set "range[1]=%%d"
		) else (
			set /a range[0]=%%c+all_gap
			set /a range[1]=%%d+all_gap
			set /a all_gap=all_gap+gap
		)
	)
)
set "input_string=!input_string:~0,%range[0]%!%replace_to%!input_string:~%range[1]%!"
goto RB.replace_start
:RB.replace_end
if defined all_gap (
	set "all_gap="
	set "output_string=%input_string%"
	goto RB.replace_finish
)
:RB.replace_finish
echo "%output_string%">"%USERPROFILE%\rforbat.log"
:RB.end_clear
setlocal disabledelayedexpansion
set "RB_cache="
rem echo %input_string%[%gap%]
rem echo %output_string%
set "input_string="
set "output_string="
set "for_delims="
set "loop="
goto :EOF
:RB.error_input
echo [ERROR] 输入无效
pause
goto RB.end_clear