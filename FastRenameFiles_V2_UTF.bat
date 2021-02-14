@echo off
chcp 65001
echo [Load] Loading DEBUG module
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
		) else title %ComSpec%
		set "debug="
		goto :EOF
	)
) else set "debug="
:Main
cls

rem set "indir="
set "attribute="
rem set "filter="
rem set "from="
set "to="
set "log="
set "old="

set "test=aba"
if not "%test:b=a%"=="aaa" (
	set "old="
)

echo [Ver] RenameFilesBatch V2 [UTF8]
echo [Dev] Copyright(c) 2019-2021 yyfll L:MIT
if not defined old (
	echo [Use] CMD inside
	title RenameFiles V2 [^(c^)yyfll] [Mixed] [UTF8]
) else (
	title RenameFiles V2 [^(c^)yyfll] [ReplaceBatch] [UTF8]
	echo [Use] ReplaceBatch V4F3_3a 
	echo.
	echo [Nti] 您的CMD似乎并不支持原生Replace，已切换为ReplaceBatch
)
echo.

echo 【工作目录即您的文件所存放在的目录】
echo 【可以直接从资源管理器把目录拖进CMD窗口】
echo 【也可以点击资源管理器上方的路径栏拷贝路径】
if defined indir echo 上次目录: "%indir%"，直接按"Enter"继续应用
set /p indir=工作目录 :

cmd /c if exist "%indir:~1,-1%"=="%indir:~1,-1%" echo. 2>NUL
if "%errorlevel%"=="0" if exist "%indir:~1,-1%" (
	set "indir=%indir:~1,-1%"
	goto check_input
)

cmd /c if "%indir%"=="%indir%" echo. 2>NUL
if "%errorlevel%"=="0" if exist "%indir%" (
	set "indir=%indir%"
	goto check_input
)

cmd /c if "%indir:~0,-1%"=="%indir:~0,-1%" echo. 2>NUL
if "%errorlevel%"=="0" if exist "%indir:~0,-1%" (
	set "indir=%indir:~0,-1%"
	goto check_input
)

cmd /c if "%indir:~1%"=="%indir:~1%" echo. 2>NUL
if "%errorlevel%"=="0" if exist "%indir:~1%" (
	set "indir=%indir:~1%"
	goto check_input
)

:check_input

if not exist "%indir%" (
	if not defined indir (
		echo [ERROR] 您没有输入路径
	) else echo [ERROR] 找不到"%indir%"
	set "indir="
	pause
	goto Main
) else echo 已应用上次目录"%indir%"

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
	echo [FRFC] 自动套用唯一匹配文件夹"%indir0%"
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
if exist "%indir%rename-undo*.log" (
	choice /C YN /M 检测到UNDO记录，是否要恢复原名？
) else goto no_undolog
if %errorlevel%==0 (
	echo [ERROR] CTRL+C
	ping -n 4 -w 1000 127.0.0.1 >nul 2>nul
	goto :EOF
) else if %errorlevel%==1 ( 
	Call :Module_UNDO "%indir%"
	goto Main
)

:no_undolog

echo.
echo 【替换目标即您要换掉的字符】
echo 【比如换掉"AAA(1).txt"中的"(1)"就输入"(1)"】
if defined from echo 上次目标: "%from%"，直接按"Enter"继续应用
set /p from=替换目标 :
if not defined from goto no_undolog
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

set "subdir="
echo 【如果目标文件夹下还有文件夹】
echo 【那么启用搜索子目录时会继续搜索子文件夹】
echo 【输入任意值来启用该功能，直接回车以禁用该功能】
set /p subdir=搜索子目录 :

cls

:time_format
for /f "tokens=*" %%a in ('time /T') do (
	for /f "delims=: tokens=1,2*" %%b in ("%%a:%time:~6,2%%time:~9,2%") do (
		set "work_time=%%b%%c%%d"
	)
)
:date_format
for /f "delims=/ tokens=1,2,3" %%a in ('date /T') do (
	set "work_date_1=%%~a"
	set "work_date_2=%%~b"
	set "work_date_3=%%~c"
	for /f "tokens=1,2 delims= " %%d in ("%%~a") do if not "%%~d"=="%%~e" (
		if "%%~d" GTR "%%~e" (
			if not "%%~e"=="" set "work_date_1=%%e"
		) else if not "%%~d"=="" set "work_date_1=%%d"
	)
	for /f "tokens=1,2 delims= " %%d in ("%%~b") do if not "%%~d"=="%%~e" (
		if "%%~d" GTR "%%~e" (
			if not "%%~e"=="" set "work_date_2=%%e"
		) else if not "%%~d"=="" set "work_date_2=%%d"
	)
	for /f "tokens=1,2 delims= " %%d in ("%%~c") do if not "%%~d"=="%%~e" (
		if "%%~d" GTR "%%~e" (
			if not "%%~e"=="" set "work_date_3=%%e"
		) else if not "%%~d"=="" set "work_date_3=%%d"
	)
)

set "test_input=%work_date_1%%work_date_2%%work_date_3%"
:format_del_space
set "space_cache=%test_input:~-1%"
if "%space_cache%"==" " (
	set "test_input=%test_input:~0,-1%"
) else (
	set "work_date=%test_input%"
	goto format_out_space_del
)
goto format_del_space
:format_out_space_del

set "work_log=%work_date%%work_time%"
set "rename_cache=%TEMP%\working_rename-%work_log%.log"
set "rename_prev=%TEMP%\preview_rename-%work_log%.log"
set "rename_log=%TEMP%\rename-log_%work_log%.log"
set "rename_undo=%indir%rename-undo_%work_log%.log"
set "temp_replace=%USERPROFILE%\rforbat.log"

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

if not defined old (
	set "from=%from:!=???%"
)	

for /f "tokens=1* delims=%%" %%a in ("A%from%A") do (
	if not "%%~b"=="" (
		echo [ERROR] BATCH不支持带百分号的替换
	)
)
if defined to (
	for /f "tokens=1* delims=%%" %%a in ("A%to%A") do (
		if not "%%~b"=="" (
		    echo [ERROR] BATCH不支持带百分号的替换
		)
	)
)

set "dir_add="
if defined subdir (
	set "dir_add=/S"
)
for /f "tokens=*" %%a in ('dir "%indir%" /A:-D /B %dir_add%') do (
	if exist "%indir%%%~nxa" (
		echo [CHECK] 正在检查文件名"%%~nxa"...
		for /f "tokens=1,2 delims=%%" %%b in ("A%%~nxaA") do (
			if not "%%~c"=="" (
				echo [ERROR] BATCH不支持带百分号的文件名
			) else call :Class_REPLACE "%indir%%%~nxa"
		)
	)
)

(echo [FILE SEARCHING END]
echo.)>>"%rename_log%"
goto Class_PREVIEW
:Class_REPLACE
set "fn=%~nx1"
if not defined old (
	set "fn=%fn:!=???%"
)

if defined old goto Old_Search

setlocal ENABLEDELAYEDEXPANSION
set "fn_out=!fn:%from%=%to%!"
setlocal DISABLEDELAYEDEXPANSION

if not defined old (
	set "fn_out=%fn_out:???=!%"
	set "fn=%fn:???=!%"
)

for /f "tokens=* delims=^|" %%a in ("%fn_out%") do (
	if not "%%~na"=="" (
		if not "%%~a"=="%fn%" (
			call :Find_FILE "%indir%%fn%" "%%~a"
		) else (
			call :Skip_FILE "%indir%%fn%"
		)		
	) else (
		echo [SKIP] 跳过替换后文件名为空的目标"%fn%"
		(echo [ILLEGAL]
		echo [Dir] "%%~dpa"
		echo [Skip] "%fn%")>>"%rename_log%"
		call :Write_Time "%rename_log%"
	)
)

goto :EOF

:Old_Search
call :Module_ReplaceBatchV4 "%fn%" "%from%" "%to%"
for /f "tokens=* usebackq" %%a in ("%temp_replace%") do (
	if not "%%~na"=="" (
		if not "%%~a"=="%~1" (
			call :Find_FILE "%~1" "%%~a"
		) else call :Skip_FILE "%~1"
	) else (
		echo [SKIP] 跳过替换后文件名为空的目标"%fn%"
		(echo [ILLEGAL]
		echo [Dir] "%%~dpa"
		echo [Skip] "%fn%")>>"%rename_log%"
		call :Write_Time "%rename_log%"
	)
)
goto :EOF

:Find_FILE
set "ff=%~2"
set "test_ff=%~n1"
if "%~x1"==".log" (
	if "%test_ff:~0,11%"=="rename-undo" (
		echo [SKIP] 跳过UNDO文件"%~nx1"
		(echo [UNDO_FILE]
		echo [Dir] "%~dp1"
		echo [Skip] "%~nx1")>>"%rename_log%"
		call :Write_Time "%rename_log%"
		goto :EOF
    ) else if "%test_ff:~0,10%"=="rename-log" (
		echo [SKIP] 跳过LOG文件"%~nx1"
		(echo [LOG_FILE]
		echo [Dir] "%~dp1"
		echo [Skip] "%~nx1")>>"%rename_log%"
		call :Write_Time "%rename_log%"
		goto :EOF
	) else if "%test_ff:~0,16%"=="undorename-error" (
		echo [SKIP] 跳过LOG文件"%~nx1"
		(echo [LOG_FILE]
		echo [Dir] "%~dp1"
		echo [Skip] "%~nx1")>>"%rename_log%"
		call :Write_Time "%rename_log%"
		goto :EOF
	)
)
echo [FIND] 找到匹配目标"%~nx1"
echo "%~1"^|"%~dp1%ff%">>"%rename_cache%"
(echo "%~nx1"
echo --^> "%ff%"
echo.) >>"%rename_prev%"
(echo [FIND]
echo [Dir] "%~dp1"
echo [File] "%~nx1")>>"%rename_log%"
call :Write_Time "%rename_log%"
goto :EOF


:Skip_FILE
set "skf=%~1"
for /f "tokens=*" %%a in ("%skf%") do (
	echo [SKIP] 跳过不符合的目标"%%~nxa"
	(echo [NOFIND]
	echo [Dir] "%%~dpa"
	echo [Skip] "%%~nxa")>>"%rename_log%"
)
call :Write_Time "%rename_log%"
goto :EOF


:Class_PREVIEW
echo.
set "do_rename="
if exist "%rename_prev%" (
    echo [RENAME PREVIEW]
    echo.
    type "%rename_prev%"
    echo.
    echo 重命名预览显示完毕
	echo.
	echo 输入任意值以执行重命名，
	echo 不输入值直接回车或关闭窗口以放弃重命名
	set /p do_rename=:
) else (
	echo [ERROR] 没有任何匹配的文件需要重命名
	echo 按任意键结束本次运行...
	pause>nul
	goto Main
)
if not defined do_rename (
	if exist "%rename_prev%" del /q "%rename_prev%"
	if exist "%rename_cache%" del /q "%rename_cache%"
	if exist "%rename_log%" del /q "%rename_log%"
	goto Main
)

cls
for /f "usebackq tokens=1,2 delims=^|" %%a in ("%rename_cache%") do (
	if not exist "%%~b" (
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
	) else (
		echo [ERROR] 文件名重复！
		(echo [ERROR]
		echo [Dir] "%%~dpa"
		echo [Input] "%%~nxa"
		echo [Duplicate] "%%~nxb")>>"%rename_log%"
		call :Write_Time "%rename_log%"
	)
	
)

if exist "%rename_cache%" move /y "%rename_cache%" "%rename_undo%" 1>nul 2>nul
move /y "%rename_log%" "%indir%" 1>nul 2>nul
if exist "%rename_prev%" del /q "%rename_prev%"

echo 按任意键结束本次运行...
pause>nul
goto Main
:Write_Time
(echo [%date% %time%]
echo.)>>"%~1"
goto :EOF
:Module_UNDO
cls
set "logdir=%~1"

set "log_count=-1"
for /f "tokens=*" %%a in ('dir "%logdir%rename-undo_*.log" /A:-D /B /O:-N') do (
	call :undo.add_list "%%~nxa"
)
if %log_count%==0 (
	for /f "tokens=1* delims==" %%a in ('set loglist[0]') do (
		call :undo_start "%%~b"
	)
	goto :EOF
)
echo UNDO_LOG选择器
echo.
for /l %%a in (0,1,%log_count%) do (
	for /f "tokens=1* delims==" %%b in ('set loglist[%%~a]') do (
		call :undo.show_list "%%~b" "%%~c"
	)
)
echo.
:re_choose
echo 【RenameFiles的撤销功能会从第0个一直撤销至您所选的记录】
echo 请选择您要恢复到的记录 (填路径前括号内的数字)
set /p log_sele=:
if defined loglist[%log_sele%] (
    for /l %%a in (0,1,%log_sele%) do (
        for /f "tokens=1* delims==" %%b in ('set loglist[%%~a]') do (
            call :undo_start "%%~c"
		)
	)
) else (
	echo [ERROR] 找不到"loglist[%log_sele%]"
	goto re_choose
)

set "listitem="
set "listitem2="
pause
goto Main

:undo.show_list
set "listitem=%~1"
set "listitem2=%~2"
echo %listitem:~7% "%listitem2%"
goto :EOF
:undo.add_list
set /a log_count=log_count+1
set "loglist[%log_count%]=%~1"
goto :EOF

:undo_start
set "log=%logdir%%~1"
set "log_time=%~n1"
set "log_time=%log_time:~12%"
echo.
echo [UNDO] 正在恢复 %log_time:~0,4%/%log_time:~4,2%/%log_time:~6,2% %log_time:~8,2%:%log_time:~10,2%:%log_time:~12,2% 的记录
set "undo_error=%logdir%undorename-error_%log_time%.log"
for /f "usebackq tokens=1,2 delims=^|" %%a in ("%log%") do (
	if exist "%%~b" (
		rename "%%~b" "%%~nxa" 2>>"%undo_error%"
		if not exist "%%~a" (
			echo [ERROR] 未成功恢复"%%~nxa"
			set "error=1"
			for /f "tokens=*" %%c in ('echo %time%') do (
				(echo [%%~c]
				echo FILE: "%%~nxa"
				echo.)>>"%undo_error%"
			)
		) else echo [SUCCESS] 已复原"%%~nxa"
	) else (
		for /f "tokens=*" %%c in ('echo %time%') do (
			(echo FILE NOT FOUND
			echo [%%~c]
			echo FILE: "%%~nxa"
			echo.)>>"%undo_error%"
		)
	)
)
for /f "tokens=*" %%a in ("%undo_error%") do (
	if exist "%%~a" (
		if not "%%~za"=="" ( 
			if %%~za0==0 del /q "%%~a"
		) else del /q "%%~a"
	)
)
if not defined error (
    if exist "%log%" (
		del /q "%log%"
		echo [REMOVE] 已删除完成撤销的记录"%~1"
	)
)
goto :EOF

rem Call :Module_ReplaceBatchV4 "[input_string]" "[to_be_replaced_string]" "[replace_to_string]"
:Module_ReplaceBatchV4
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

:RB.delims_len
call :RB.long_string "%for_delims%" "delims_len"
set /a delims_len=delims_len-1
set "len_check=!input_string:~0,%delims_len%!"
if not defined len_check (
	echo "%input_string%">"%USERPROFILE%\rforbat.log"
	goto RB.end_clear
)
set /a delims_len=delims_len+1
call :RB.long_string "%input_string%" "input_len"

set "work_string=%input_string%"
set "work_string2=%work_string%"
:RB.list_input
set "RB_list_cache="
set "list_start=0"

for /l %%a in (1,1,%input_len%) do (
	for /l %%b in (1,1,%delims_len%) do (
		call :RB.list_input_get
		if "%%~b"=="%delims_len%" (
			call :RB.list_add "%%~a"
		)
	)
	call :RB.add_work_string
)

goto RB.replace_finish

:RB.delims_cut

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
)

if "%RB_list_cache%"=="%for_delims%" (
	set "output_string=%output_string%%replace_to%"
	set "RB_list_cache="
	set /a RB_next=%~1+delims_len-1
) else (
	if %~10 GEQ %input_len%0 (
		set "output_string=%output_string%%RB_list_cache%"
	) else set "output_string=%output_string%%RB_list_cache:~0,1%"
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
set "len_check="
set "delims_len="
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
if %ls_step% LSS 1 set "ls_step=5"
set "ls_work=%string_in%"
:RB.long_string_loop
for /l %%a in (1,1,%ls_step%) do (
	call :RB.ls_cutString
)
if defined ls_work (
	goto RB.long_string_loop
) else echo "%output_string%">"%USERPROFILE%\rforbat.log"
:RB.long_string_return
set "string_in="
set "%~2=%string_long%"
set "string_long="
goto :EOF
:RB.ls_cutString
if not defined ls_work goto :EOF
set /a string_long=string_long+1
set "ls_work=%ls_work:~1%"
goto :EOF