@echo off
chcp 65001
title RenameFiles VER1.0.1 [(c)yyfll] [ReplaceBatch V_SP3+4_P] [UTF8]
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

echo [Ver] RenameFilesBatch VER1.0.1_UTF8
echo [Use] Module_ReplaceBatch V_SP3+4_P
echo [Dev] Copyright(c) 2019-2020 yyfll
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
		Call :Module_ReplaceBatch "%%~na" "%from%" "%to%"
		for /f "usebackq tokens=*" %%b in ("%USERPROFILE%\rforbat.log") do (
			if not "%%~b"=="%%~na" (
				echo [FIND] 找到匹配目标"%%~nxa"
				echo "%%~a"^|"%%~dpa%%~b%%~xa">>"%rename_cache%"
				(echo "%%~nxa"
				echo --^> "%%~b%%~xa"
				echo.) >>"%rename_prev%"
				(echo [FIND]
				echo [Dir] "%%~dpa"
				echo [File] "%%~nxa")>>"%rename_log%"
				call :Write_Time "%rename_log%"
			) else (
				echo [SKIP] 跳过不符合的目标"%%~nxa"
				(echo [NOFIND]
				echo [Dir] "%%~dpa"
				echo [Skip] "%%~nxa")>>"%rename_log%"
				call :Write_Time "%rename_log%"
			)
		)
	)
)

(echo [FILE SEARCHING END]
echo.)>>"%rename_log%"

:Class_PREVIEW
rem cls
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

:RB.delims_len
call :RB.long_string "%for_delims%" "delims_len"

if "%delims_len%"=="1" (
	setlocal disabledelayedexpansion
	goto RB.replaceV3F2
)

:RB.input_len
call :RB.long_string "%input_string%" "input_len"

if not defined replace_to (
	set "replace_len=0"
	goto RB.nocheck_re
)
:RB.replace_len
call :RB.long_string "%replace_to%" "replace_len"

:RB.nocheck_re
if %input_len% LSS %delims_len% (
	echo [ERROR] 输入字符串不能比被替换字符串短!
	goto RB.error_input
)
setlocal disabledelayedexpansion

set "work_string=%input_string%"
set "work_string2=%work_string%"
:RB.list_input
set "RB_list_cache="
set "list_start=0"

for /l %%a in (1,1,%input_len%) do (
	for /l %%b in (1,1,%delims_len%) do (
		call :RB.list_input_get
		if "%%~b"=="%delims_len%" call :RB.list_add "%%~a"
	)
	call :RB.add_work_string
)
goto RB.replace_finish

:RB.list_input_get
if not defined work_string2 goto :EOF
set "RB_list_cache=%RB_list_cache%%work_string2:~0,1%"
set "work_string2=%work_string2:~1%"
goto :EOF
:RB.list_add
if not defined RB_list_cache goto :EOF

if defined RB_next (
	if %~10 GEQ %RB_next%0 (
		set "RB_next="
	)
) else (
	if "%RB_list_cache%"=="%for_delims%" (
		set "output_string=%output_string%%replace_to%"
		set "RB_list_cache="
		set /a RB_next=%~1+delims_len-1
	) else (
		if %~1 GEQ %input_len% (
			set "output_string=%output_string%%RB_list_cache%"
		) else set "output_string=%output_string%%RB_list_cache:~0,1%"
	)
)

goto :EOF
:RB.add_work_string
if not defined work_string goto :EOF
set /a list_start=list_start+1
set "work_string=%work_string:~1%"
set "work_string2=%work_string%"
set "RB_list_cache="
goto :EOF

:RB.replace_finish
echo "%output_string%">"%USERPROFILE%\rforbat.log"
:RB.end_clear
set "RB_cache="
set "work_string="
set "work_string2="
set "input_string="
set "output_string="
set "RB_list_cache="
set "for_delims="
set "list_start="
set "list_end="
set "loop="
set "same_char="
:RB.clear_list
for /f "tokens=1* delims==" %%a in ('set RB_list[ 2^>nul') do (
	if not "%%~b"=="" set "%%~a="
)
goto :EOF
:RB.error_input
echo [ERROR] 输入无效
pause
goto RB.end_clear

rem call :RB.long_string "[string]" "[return]"
:RB.long_string
if "%~1"=="" goto :EOF
if "%~2"=="" goto :EOF
set "string_long=0"
set "string_in=%~1"
if not defined ls_step set "ls_step=5"
if %ls_step% LSS 1 goto :EOF
:RB.long_string_loop
set /a string_long=string_long+ls_step
set "ls_check=!string_in:~%string_long%!"
if defined ls_check (
	goto RB.long_string_loop
)
set /a string_long=string_long-ls_step
set "ls_check=!string_in:~%string_long%!"
set "ls_lcheck=0"
:RB.long_string_l2
set "ls_lcheck_s=!ls_check:~%ls_lcheck%!"
if not "%ls_lcheck_s%"=="" (
	set /a string_long=string_long+1
) else goto RB.long_string_return
set /a ls_lcheck=ls_lcheck+1
goto RB.long_string_l2
:RB.long_string_return
set "ls_lcheck_s="
set "ls_lcheck="
set "ls_check="
set "string_in="
set "%~2=%string_long%"
set "string_long="
goto :EOF

:RB.replaceV3F2
set "search_step=5"
set "output_string="

set "work_string=%~1"
:RB_V3.re_replace
set "RB_V3_cache="
set "RB_V3_need_replace="

if not defined work_string goto RB.replace_finish
for /l %%a in (1,1,%search_step%) do call :RB_V3.get_string
goto RB_V3.get_string_end
:RB_V3.get_string
if not defined work_string goto :EOF
set "RB_V3_cache=%RB_V3_cache%%work_string:~0,1%"
if "%work_string:~0,1%"=="%for_delims%" set "RB_V3_need_replace=0"
set "work_string=%work_string:~1%"
goto :EOF
:RB_V3.get_string_end

if "%RB_V3_cache%"=="" goto RB.replace_finish

if not defined RB_V3_need_replace (
	set "output_string=%output_string%%RB_V3_cache%"
	goto RB_V3.re_replace
)

set "RB_V3_working=%RB_V3_cache%"
set "RB_V3_cache2=%RB_V3_working%"
:RB_V3.re_replace2
if not defined RB_V3_working goto RB_V3.re_replace
set "RB_V3_cache2=%RB_V3_working:~0,1%"
if "%RB_V3_cache2%"=="" goto RB_V3.re_replace

if "%RB_V3_cache2%"=="%for_delims%" (
	set "output_string=%output_string%%replace_to%"
) else set "output_string=%output_string%%RB_V3_cache2%"

set "RB_V3_working=%RB_V3_working:~1%"

goto RB_V3.re_replace2