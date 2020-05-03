@echo off
chcp 65001
title RenameFiles END Ver.2 [(c)yyfll] [System + RB_V3SP] [UTF8]
:Module_DEBUG
if not defined debug (
	set "debug=0"
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

set "test=aba"
if not "%test:b=a%"=="aaa" (
	echo [ERROR] 您的Windows系统版本太旧，不支持VE版本
	pause
	goto :EOF
)

echo [Ver] RenameFilesBatch END_Ver.2_UTF8
echo [Use] CMD default + ReplaceBatch V3SP
echo [Dev] Copyright(c) 2019-2020 yyfll L:MIT
echo.

echo 【工作目录即您的文件所存放在的目录】
echo 【可以直接从资源管理器把目录拖进CMD窗口】
echo 【也可以点击资源管理器上方的路径栏拷贝路径】
set /p indir=工作目录 :

cmd /c if "%indir%"=="%indir%" echo. 2>NUL
if "%errorlevel%"=="0" (
	set "indir=%indir%"
	goto check_input
)

cmd /c if "%indir:~1%"=="%indir:~1%" echo. 2>NUL
if "%errorlevel%"=="0" (
	set "indir=%indir:~1%"
	goto check_input
)

cmd /c if "%indir:~0,-1%"=="%indir:~0,-1%" echo. 2>NUL
if "%errorlevel%"=="0" (
	set "indir=%indir:~0,-1%"
	goto check_input
)

cmd /c if "%indir:~1,-1%"=="%indir:~1,-1%" echo. 2>NUL
if "%errorlevel%"=="0" (
	set "indir=%indir:~1,-1%"
	goto check_input
)

:check_input

if not exist "%indir%" (
	if not defined indir (
		echo [ERROR] 您没有输入路径
	) else echo [ERROR] 找不到"%indir%"
	pause
	goto Main
)

for /f "tokens=1,2 delims=*" %%a in ("%indir%") do (
	if not "%indir:~-1%"=="*" (
		if "%%~b"=="" goto check_dir
	)
)

set "list_count=0"
for /d %%a in ("%indir%") do if exist "%%~a" call :write_list "%%~a"
goto show_list

:write_list
set "indir%list_count%=%~1"
set /a list_count=list_count+1
goto :EOF

:show_list
if %list_count%==1 (
	set "indir=%indir0%"
	goto check_dir
) else if %list_count%==0 (
	echo [ERROR] 没有找到匹配"%indir%"的目录
	pause
	goto Main
)

cls
echo FRF通配路径选择器
echo.
set "indir="
for /f "tokens=1* delims==" %%a in ('set indir') do (
	call :show_list_2 "%%~a" "%%~b"
)
echo.
:re_choose
echo 请选择您要输入的目录(填路径前括号内的数字)
set /p indir_count=:
if defined indir%indir_count% (
	for /f "tokens=1* delims==" %%a in ('set indir%indir_count%') do (
		set "dircache=%%~b"
	)
	for /f "tokens=1* delims==" %%a in ('set indir') do set "%%~a="
) else (
	echo [ERROR] 找不到"indir%indir_count%"
	goto re_choose
)
set "indir=%dircache%"
set "dircache="
set "listitem="
set "listitem2="
cls
echo 工作目录 :"%indir%"
goto check_dir

:show_list_2
set "listitem=%~1"
set "listitem2=%~2"
echo [%listitem:~5%] "%listitem2%"
goto :EOF

:check_dir

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

echo.
echo 【替换目标即您要换掉的字符】
echo 【比如换掉"AAA(1).txt"中的"(1)"就输入"(1)"】
set /p from=替换目标 :
if not defined from goto :no_undolog
echo.
echo 【文件过滤默认为 "*%from%*"】
echo 【该过滤器非常简单 仅允许使用通配符】
set /p filter=文件过滤 :
if not defined filter （
	set "filter=*%from%*"
	cls
	echo 工作目录 :"%indir%"
	echo 替换目标 :"%from%"
	echo 文件过滤 :"*%from%*"
)
echo.
echo 【替换目标即您要换成的字符】
echo 【比如将"%from%"换成"(2)"就输入"(2)"】
echo 【直接删除"%from%"就留空本空】
set /p to=替换为 :
echo.
echo 【子目录搜索即搜索指定目录下的所有目录】
echo 【比如在"A"文件夹下有"B"文件夹】
echo 【那么禁用该选项后将不搜索"B"中的文件】
echo 【【【输入y来启用该选项】】】
set /p subdir=子目录搜索 :

if /i "%subdir%" NEQ "y" set "subdir="

rem if defined attribute goto :EOF

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

for /f "tokens=1* delims=%%" %%a in ("%from%") do (
	if "%%~b"=="" (
		if not "%from:~-1%"=="%%" (
			goto check_from_end
		)
	)
)

call :Module_ReplaceBatchSP "from"
for /f "usebackq tokens=*" %%a in ("%USERPROFILE%\rforbat.log") do (
	set "from=%%~a"
)

:check_from_end

if not "%indir:~-1%"=="\" set "indir=%indir%\"

for /r "%indir%" %%a in ("%filter%") do (
	if exist "%%~a" (
		echo [CHECK] 正在检查文件名"%%~nxa"...
		set "file=%%~a"
		if not defined subdir (
			call :Module_ReplaceBatchSP "file"
			for /f "usebackq tokens=*" %%b in ("%USERPROFILE%\rforbat.log") do (
				if not "%%~b"=="%%~a" (
					call :Class_REPLACE "%%~b" "0"
				) else (
					call :Class_REPLACE "%%~b"
				)
			)
		) else (
			if "%%~dpa"=="%indir%" (
				call :Module_ReplaceBatchSP "file"
				for /f "usebackq tokens=*" %%b in ("%USERPROFILE%\rforbat.log") do (
					if not "%%~b"=="%%~a" (
						call :Class_REPLACE "%%~b" "0"
					) else (
						call :Class_REPLACE "%%~b"
					)
				)
			) else (
				echo [Subdir] 跳过子目录文件"%%~nxa"
			)
		)
	)
)

(echo [FILE SEARCHING END]
echo.)>>"%rename_log%"
goto Class_PREVIEW
:Class_REPLACE
set "fullp=%~1"

setlocal ENABLEDELAYEDEXPANSION
set "last_count=1"
:get_filename
set "loop_r=!fullp:~-%last_count%!"
if "%loop_r:~0,1%"=="\" (
	set "fn=%loop_r:~1%"
	goto got_filename
)
set /a last_count=last_count+1
goto get_filename
:got_filename
setlocal DISABLEDELAYEDEXPANSION
set "fn=%fn:!=???%"

setlocal ENABLEDELAYEDEXPANSION
set "fnc=!fn:%from%=%to%!"

if not "%fnc%"=="%fn%" (
	call :Find_FILE "%~1" "%fnc%" "%~2"
) else (
	call :Skip_FILE "%~1" "%~2"
)

setlocal DISABLEDELAYEDEXPANSION
goto :EOF
:Find_FILE
set "ff=%~2"
set "fff=%~1"

if not "%~3"=="" (
	call :Module_ReplaceBatchBACK "fff"
	for /f "usebackq tokens=*" %%a in ("%USERPROFILE%\rforbat.log") do (
		set "fff=%%~a"
	)
)

setlocal DISABLEDELAYEDEXPANSION
set "ff=%ff:???=!%"

for /f "tokens=*" %%a in ("%fff%") do (
	echo [FIND] 找到匹配目标"%%~nxa"
	echo "%%~a"^|"%%~dpa%ff%">>"%rename_cache%"
	(echo "%%~nxa"
	echo --^> "%ff%"
	echo.) >>"%rename_prev%"
	(echo [FIND]
	echo [Dir] "%%~dpa"
	echo [File] "%%~nxa")>>"%rename_log%"
)

call :Write_Time "%rename_log%"
setlocal ENABLEDELAYEDEXPANSION
goto :EOF
:Skip_FILE
set "skf=%~1"
if not "%~2"=="" (
	call :Module_ReplaceBatchBACK "skf"
	for /f "usebackq tokens=*" %%a in ("%USERPROFILE%\rforbat.log") do (
		set "skf=%%~a"
	)
)
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

:Module_ReplaceBatchSP
if "%~1"=="" (
	goto RB.error_input
)
set "input_string=%~1"
if "%input_string:~0,1%"=="" (
	echo [ERROR] 您没有输入任何字符！
	goto RB.error_input
)

setlocal EnableDelayedExpansion

if defined %input_string% set "input_string=!%input_string%!"

for /f "tokens=1* delims=%%" %%a in ("%input_string%") do (
	if "%%~b"=="" (
		if not "%input_string:~-1%"=="%%" (
			echo "%input_string%">"%USERPROFILE%\rforbat.log"
			goto RB.end_clear
		)
	)
)
set "output_string="
set "loop=-1"
:RB.re_replace
set /a loop=loop+1
set "RB_cache=!input_string:~%loop%,1!"
if "%RB_cache%"=="" goto RB.replace_finish

if "%RB_cache%"=="%%" (
	set "output_string=%output_string%*"
) else set "output_string=%output_string%%RB_cache%"

goto RB.re_replace
:RB.replace_finish
echo "%output_string%">"%USERPROFILE%\rforbat.log"
:RB.end_clear
setlocal DisableDelayedExpansion
set "RB_cache="
set "input_string="
set "output_string="
set "for_delims="
set "loop="
goto :EOF
:RB.error_input
echo [ERROR] 输入无效
pause
goto RB.end_clear

:Module_ReplaceBatchBACK
if "%~1"=="" (
	goto RB2.error_input
)
set "input_string=%~1"
if "%input_string:~0,1%"=="" (
	echo [ERROR] 您没有输入任何字符！
	goto RB2.error_input
)

if defined %input_string% set "input_string=!%input_string%!"

for /f "tokens=1* delims=*" %%a in ("%input_string%") do (
	if "%%~a%%~b"=="%input_string%" (
		echo "%input_string%">"%USERPROFILE%\rforbat.log"
		goto RB2.end_clear
	)
)

set "output_string="
set "loop=-1"
:RB2.re_replace
set /a loop=loop+1
set "RB2.cache=!input_string:~%loop%,1!"
if "%RB2.cache%"=="" goto RB2.replace_finish
if "%RB2.cache%"=="*" (
	set "output_string=%output_string%%%"
) else set "output_string=%output_string%%RB2.cache%"
goto RB2.re_replace
:RB2.replace_finish
echo "%output_string%">"%USERPROFILE%\rforbat.log"
:RB2.end_clear
setlocal DisableDelayedExpansion
set "RB2.cache="
set "input_string="
set "output_string="
set "for_delims="
set "loop="
goto :EOF
:RB2.error_input
echo [ERROR] 输入无效
pause
goto RB2.end_clear