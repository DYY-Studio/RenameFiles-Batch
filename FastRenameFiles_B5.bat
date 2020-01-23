@echo off
title RenameFiles Alpha 5.0 [By yyfll] [ReplaceBatch V4F2+V3F2]
:Module_DEBUG
if not defined debug (
	set debug=0
	cmd /c call "%~0"
	if "%~1"=="" (
		echo [Module_DEBUG] �밴������˳�... 
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

echo [Version] RenameFilesBatch Alpha 5.0
echo [Include] Module_ReplaceBatch V4F2+V3F2
echo [Developer] COPYRIGHT(C) 2019-2020 yyfll
echo.

set /p indir=Ŀ¼: 

if exist "%indir:~1,-1%" (
	set "indir=%indir:~1,-1%"
) else set "indir=%indir%"
if not exist "%indir%" (
	if not defined indir (
		echo [ERROR] ��û������·��
	) else echo [ERROR] �Ҳ���"%indir%"
	pause
	goto Main
)

for %%a in ("%indir%") do (
	set "attribute=%%~aa"
)
if /i "%attribute:~0,1%" NEQ "d" (
	echo [ERROR] ����·������Ŀ¼
	pause
	goto Main
)

if "%indir:~-1%" NEQ "\" set "indir=%indir%\"
if exist "%indir%rename-undo.log" (
	choice /C YN /M ��⵽UNDO��¼���Ƿ�Ҫ�ָ�ԭ����
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

set /p filter=�ļ�����: 
set /p from=�滻Ŀ��: 
set /p to=�滻Ϊ: 

rem if defined attribute goto :EOF

if not defined filter set filter=*
if not defined from goto :EOF

for /r "%indir%" %%a in ("*rename*.log") do del /q "%%~a"

for /r "%indir%" %%a in ("%filter%") do (
	if exist "%%~a" (
		echo [CHECK] ���ڼ���ļ���"%%~nxa"...
		Call :Module_ReplaceBatch "%%~na" "%from%" "%to%"
		for /f "usebackq tokens=*" %%b in ("%USERPROFILE%\rforbat.log") do (
			if not exist "%indir%rename-log.log" (
				(echo FastRenameFiles-LogFile
				echo [INFO]
				echo DIR: "%indir%"
				echo FILTER: "%filter%"
				echo TARGET: "%from%"
				echo REPLACE: "%to%"
				echo [END]
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
					echo [SUCCESS] �ɹ�������Ϊ"%%~b%%~xa"
					(echo [SUCCESS]
					echo [Dir] "%%~dpa"
					echo [Before] "%%~nxa"
					echo [Rename] "%%~b%%~xa")>>"%indir%rename-log.log"
					(echo "%%~dpa%%~b%%~xa"^|"%%~nxa")>>"%indir%rename-undo.log"
				) else (
					echo [ERROR] ��������
					(echo [ERROR]
					echo [Dir] "%%~dpa"
					echo [Input] "%%~nxa"
					echo [TryRename] "%%~b%%~xa")>>"%indir%rename-log.log"
				)
			) else (
				echo [SKIP] ���������ϵ�Ŀ��"%%~nxa"
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
			echo [ERROR] δ�ɹ��ָ�"%%~b"
			set "error=1"
			for /f "tokens=*" %%c in ('echo %time%') do (
				(echo [%%~c]
				echo FILE: "%%~a"
				echo.)>>"%%~dpaundorename-error.log"
			)
		) else echo [SUCCESS] �Ѹ�ԭ"%%~b"
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
	echo [ERROR] ��û�������κ��ַ���
	goto RB.error_input
)
set "for_delims=%~2"
if "%for_delims%"=="" (
	echo [ERROR] ��û�������κ�Ҫ�滻���ַ���
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
	echo [ERROR] �����ַ������ܱȱ��滻�ַ�����!
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
	if %~1 GEQ 0%RB_next% (
		set "RB_next="
	)
) else (
	if "%RB_list_cache%"=="%for_delims%" (
		set "output_string=%output_string%%replace_to%"
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
echo [ERROR] ������Ч
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