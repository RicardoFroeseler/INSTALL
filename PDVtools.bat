 rem Variable initialization
echo OFF
cls
set "Language=BR"
set "ProgramName0=EmissorFiscal"		:: EmissorFiscal - main software
set "ProgramName1=EmissorFiscalSync"	:: EmissorFiscalSync - synchronization/communication software
set "ServiceName0=EmissorFiscal"		:: EmissorFiscalService - hardware communication service
set "ToolsName=PDVtools"
set "HttpAddr=127.0.0.1"
set "HttpPort00=81"						:: EmissorFiscal main port
set "HttpPort01=8081"					:: EmissorFiscal secondary port
set "HttpPort10=82"						:: EmissorFiscalSync main port
set "HttpPort11=8082"					:: EmissorFiscalSync secondary port
set "ServicePort0=8888"					:: EmissorFiscalService Port
set "VpnPort=10245"						:: porta tunel VPN para receber impressoes do servidor

set "ServiceFileName0=%ServiceName0%Svc"
set "ServiceFullName0=%ServiceName0%Service"
set "SqlBinPath="
set "SqlDataPath="
set "SqlProgPath="
set "BinPath=%SystemDrive%\inetpub\%ProgramName0%\bin"
set "SqlInstance=ACRONYM"
set "keyFile=%TEMP%\keys.txt"
set "LogFile=%SystemDrive%\inetpub\%ProgramName0%\Log\%ToolsName%.log"
set "LogInstall=nul"
set "BarTitle="
set "ChromePath="
SET "ScriptFile=%TEMP%\Script.vbs"
for /f "tokens=4-5 delims=. " %%i in ('ver') do set WinVersion=%%i.%%j

if /I "%1%" == "/?" (
echo.
echo   BACKUP              backup da base de dados para arquivo
echo   RESTORE             restaurar base de dados do arquivo
echo   SQLCLEAN            desinstalar e limpar SQL
echo   SERVICEINSTALL      instala o servico do Emissor Fiscal
echo   SERVICEINSTALLDELAY instala o servico do Emissor Fiscal com atraso
echo   W10CLEAN            remover funcionalidades basicas W10
echo   W10RESTORE          reativar funcionalidades basicas W10
echo   IISCLEAN            desinstalar o IIS e limpesa dos componentes do Windows
echo   IISINSTALL          instalar/ativar os componentes do IIS
echo   IISREPAIR           remover e reinstalar o IIS
echo   ICON                trocar o Icon do Emissor Fiscal
echo   TLSFIX              repara o windows para utilizacao de certificados TLS
echo   PDVDROID            utilitarios ADB para PDVdroid
goto :EOF
)

if not exist "%SystemDrive%\inetpub\%ProgramName0%\" (set "LogFile=%SystemDrive%\%ToolsName%.log")

if [%PROCESSOR_ARCHITECTURE%] == [x86] (set "SysWowPath=%WINDIR%\system32" && set "SetACL=SetACL_x86.exe") else ( set "SysWowPath=%WINDIR%\SysWOW64" && set "SetACL=SetACL_x64.exe" )
set "SetACL_x=%SystemDrive%\inetpub\%ProgramName0%\bin\%SetACL%"

if exist "%userprofile%\Desktop" (SET "UserDesktop=%userprofile%\Desktop") else (SET "UserDesktop=%systemdrive%\Users\%USERNAME%\Desktop")
if exist "%systemdrive%\Users\Public\Desktop" (SET "PublicDesktop=%systemdrive%\Users\Public\Desktop") else (SET "PublicDesktop=%systemdrive%\Documents and Settings\All Users\Desktop")

:: Get the current SQL folders  (SqlBinPath) (SqlDataPath) (SqlProgPath)
if exist "%ProgramFiles(x86)%\Microsoft SQL Server\90\Tools\Binn\sqlcmd.exe" (call :SETPATHS "%ProgramFiles(x86)%\Microsoft SQL Server\90\Tools\Binn" "%ProgramFiles(x86)%\Microsoft SQL Server\MSSQL11.%SqlInstance%\MSSQL\DATA" "%ProgramFiles(x86)%")
if exist "%ProgramFiles(x86)%\Microsoft SQL Server\110\Tools\Binn\sqlcmd.exe" (call :SETPATHS "%ProgramFiles(x86)%\Microsoft SQL Server\110\Tools\Binn" "%ProgramFiles(x86)%\Microsoft SQL Server\MSSQL11.%SqlInstance%\MSSQL\DATA" "%ProgramFiles(x86)%")
if exist "%ProgramFiles%\Microsoft SQL Server\90\Tools\Binn\sqlcmd.exe" (call :SETPATHS "%ProgramFiles%\Microsoft SQL Server\90\Tools\Binn" "%ProgramFiles%\Microsoft SQL Server\MSSQL11.%SqlInstance%\MSSQL\DATA" "%ProgramFiles%")
if exist "%ProgramFiles%\Microsoft SQL Server\110\Tools\Binn\sqlcmd.exe" (call :SETPATHS "%ProgramFiles%\Microsoft SQL Server\110\Tools\Binn" "%ProgramFiles%\Microsoft SQL Server\MSSQL11.%SqlInstance%\MSSQL\DATA" "%ProgramFiles%")

REM Check if windows is PT or EN version
net user Administrator 2>NUL >NUL
IF %errorlevel%==0 GOTO WIN_EN
REM Portuguese version
SET Lang=PT
SET Admin=Administradores
SET sysAdmin=SISTEMA
GOTO WIN_VERSION
:WIN_EN
REM Ingles version
SET Lang=EN
SET Admin=Administrators
SET sysAdmin=SYSTEM
:WIN_VERSION


REM check_Permissions
net session >nul 2>&1
if %errorLevel% == 0 goto GOT_PRIVILEGES

REM get priveleges 
set "params=%*"
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )

:GOT_PRIVILEGES
IF /I "%1%" == "BACKUP" GOTO SQL_BACKUP_AUTO
IF /I "%1%" == "RESTORE" GOTO SQL_RESTORE_AUTO
IF /I "%1%" == "SQLCLEAN" GOTO SQL_CLEAN
IF /I "%1%" == "RESTOREWIN10" GOTO RESTOREWIN10
IF /I "%1%" == "ICON" GOTO MENU_ICONS
IF /I "%1%" == "IISCLEAN" GOTO IIS_CLEAN
IF /I "%1%" == "IISINSTALL" GOTO IIS_INSTALL
IF /I "%1%" == "SERVICEINSTALL" GOTO SERVICE_INSTALL
IF /I "%1%" == "SERVICEINSTALLDELAY" GOTO SERVICE_INSTALL
IF /I "%1%" == "TLSFIX" GOTO TLS_FIX
IF /I "%1%" == "W10CLEAN" GOTO W10_CLEAN
IF /I "%1%" == "W10RESTORE" GOTO W10_RESTORE
IF /I "%1%" == "KILLEXPLORER" GOTO KILL_EXPLORER
IF /I "%1%" == "IISREPAIR" GOTO IIS_REPAIR_STEP1
IF /I "%1%" == "IISREPAIRSTEP2" GOTO IIS_REPAIR_STEP2
IF /I "%1%" == "IISREPAIRSTEP3" GOTO IIS_REPAIR_STEP3
IF /I "%1%" == "PDVDROID" GOTO MENU_PDVDROID
IF /I "%1%" == "" GOTO INSTRUCTION_OK
ECHO ERRO! Comando '%1%' invalido! && GOTO EOF
:INSTRUCTION_OK

chcp 65001 >NUL
MODE 80,30
TITLE %ToolsName%



:MENU
REM ..............................................................................
CALL :MESSAGE_HEADER "Batch auxiliar para %ProgramName0%"
ECHO.
ECHO   1 - IIS Stop (Parar servidor do %ProgramName0%)
ECHO   2 - IIS Start (Iniciar servidor do %ProgramName0%)
ECHO     -
ECHO   3 - Service Stop (Parar servico do %ProgramName0%)
ECHO   4 - Service Start (Iniciar servico do %ProgramName0%)
ECHO     -
ECHO   5 - SQL Stop (Parar servicos SQL)
ECHO   6 - SQL Start (Iniciar servicos SQL)
ECHO     -
ECHO   7 - Copiar Log do %ProgramName0% para Desktop
ECHO   8 - Copiar base de dados para Desktop
ECHO   9 - Excluir documentos de Impressao
ECHO     -
ECHO   U - Utilitarios (Command)
ECHO   W - Utilitarios (Windows)
ECHO     -
ECHO   T - Testar Instalacao
ECHO   R - Reiniciar software (IIS + Servico)
ECHO     -
ECHO   S - SAIR
ECHO.
CALL :MESSAGE_LINE_
ECHO.
choice /n /c 123456789uwtrs /m "Pressione 1, 2, 3 ..."
if %errorlevel%==1 call :IIS_STOP
if %errorlevel%==2 call :IIS_START
if %errorlevel%==3 call :SERVICE_STOP
if %errorlevel%==4 call :SERVICE_START
if %errorlevel%==5 call :SQL_STOP
if %errorlevel%==6 call :SQL_START
if %errorlevel%==7 call :LOG_BACKUP
if %errorlevel%==8 call :SQL_BACKUP
if %errorlevel%==9 call :DELPRINTER
if %errorlevel%==10 goto :MENU_UTIL
if %errorlevel%==11 goto :MENU_WIN
if %errorlevel%==12 call :INSTALATION_TEST
if %errorlevel%==13 call :IIS_SERVICE_STOP_START
if %errorlevel%==14 goto :END_OF_FILE
GOTO MENU















:IIS_SERVICE_STOP_START
REM ..............................................................................
call :WRITE_LOG "♦ R - Reiniciar software (IIS + Servico)"
MODE 80,4
SET "BarTitle=Reiniciar software (IIS + Servico)"

call :PROGRESS_BAR 10 "IIS Stop (%ProgramName0%)"
REM  iisreset /stop
NET STOP w3svc >nul 2>nul

call :PROGRESS_BAR 20 "Service Stop (%ProgramName0%)"
REM Stop the Service  ...
Taskkill /F /IM %ServiceFileName0%.exe >nul 2>nul

REM Stop chromedriver ...
Taskkill /F /IM chromedriver.exe >nul 2>nul
REM Stop wacs ...
Taskkill /F /IM wacs.exe >nul 2>nul

REM IIS setup ...
%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].processModel.loadUserProfile:true" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='%ProgramName0%'].processModel.idleTimeout:00:00:00" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].processModel.maxProcesses:0" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.limit:80000" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.action:Throttle" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.resetInterval:00:01:00" >nul 2>nul

REM Reset Log folder 
cd / >nul 2>nul
cd %SystemDrive%\inetpub\%ProgramName0%\Log\ >nul 2>nul

attrib %ToolsName%.log +r > NUL
del /q "*" >nul 2>nul
echo Repositorio de logs>>Log.txt
if [%ProgramName0%] == [EmissorFiscal] (
	break>%ServiceFullName0%.log
	break>%ProgramName0%.log
	break>%ProgramName0%Messaging.log
	break>%ProgramName0%Sync.log
)
attrib %ToolsName%.log -r > NUL

call :PROGRESS_BAR 30 "IIS Start (%ProgramName0%)"
REM iisreset /start
NET START w3svc >nul 2>nul 

REM start the Service  ...
call :PROGRESS_BAR 40 "Service Start (%ProgramName0%)"
net start %ServiceFullName0% >nul 2>nul

REM confirm that the service is in STAR_PENDING state ...	
SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 50 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 60 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 70 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 80 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

:IIS_SERVICE_STOP_START0
SC QUERYEX %ServiceFullName0% | findstr "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] goto :IIS_SERVICE_STOP_START0	
	
REM Concluido
call :PROGRESS_BAR 100 "OK! ... "

timeout /t 2 /nobreak >nul 2>nul
MODE 80,30
TITLE %ToolsName%
ECHO. && EXIT /b






















:IIS_REPAIR_STEP1
MODE 80,4
SET "BarTitle=Utilitario de reparo do IIS"

:: Check if Windows 10
if not "%WinVersion%" == "10.0" (
	CALL :PROGRESS_BAR 0 "ERRO! ... Funcionalidade disponivel apenas para Windows 10 !"
	TIMEOUT /t 5 /nobreak 2>NUL >NUL
	GOTO :END_OF_FILE
)

:: Stop IIS
CALL :PROGRESS_BAR 4 "Parando o IIS"
NET STOP w3svc >nul 2>nul

:: Scan and repair
CALL :PROGRESS_BAR 5 "Reparo do windows"
sfc /scannow >nul 2>nul

:: Scanhealth
CALL :PROGRESS_BAR 15 "Limpesa dos componentes"
DISM.exe /Online /Cleanup-image /Scanhealth >nul 2>nul

:: Restorehealth
CALL :PROGRESS_BAR 25 "Restauro dos componentes"
DISM.exe /Online /Cleanup-image /Restorehealth >nul 2>nul

:: taking ownership
CALL :PROGRESS_BAR 28 "Permissoes de acesso"
:: Set owner of all files to current user = Administrators
takeown /f "%WINDIR%\System32\inetsrv" /r /d y >nul 2>nul
:: Grant access to all files to Administrators
icacls "%WINDIR%\System32\inetsrv" /grant %Admin%:F /T >nul 2>nul
:: Set owner of WindowsApps back to Administrators
icacls "%WINDIR%\System32\inetsrv" /setowner %Admin% >nul 2>nul

:: Set owner of all files to current user = Administrators
takeown /f "%WINDIR%\SysWOW64\inetsrv" /r /d y >nul 2>nul
:: Grant access to all files to Administrators
icacls "%WINDIR%\SysWOW64\inetsrv" /grant %Admin%:F /T >nul 2>nul
:: Set owner of WindowsApps back to Administrators
icacls "%WINDIR%\SysWOW64\inetsrv" /setowner %Admin% >nul 2>nul

:: disable and unistall all IIS features
call :IIS_DISABLE_UNISTALL_FEATURE

:: Prepara windows to automatic start this tool 
REG ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run" /v %ToolsName% /t REG_SZ /d "%SystemDrive%\inetpub\%ProgramName0%\%ToolsName%.bat IISREPAIRSTEP2" /f >nul 2>nul

:: Reeboot is needed
CALL :PROGRESS_BAR 100 "Aguardando para reiniciar o computador ..."
shutdown.exe /r /t 5 >nul
PAUSE >nul
GOTO :END_OF_FILE






:IIS_REPAIR_STEP2
MODE 80,4
SET "BarTitle=Utilitario de reparo do IIS"
CALL :PROGRESS_BAR 2 "Esperando ..."

:: Delay for windows to rebboot
TIMEOUT /t 10 /nobreak >nul 2>nul

:: Remove key from Regedit
REG DELETE "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run" /V %ToolsName% /F >nul 2>nul

:: Stop IIS
CALL :PROGRESS_BAR 4 "Parando o IIS"
NET STOP W3SVC >nul 2>nul


CALL :PROGRESS_BAR 10 "Reconfigurando o IIS"

:: Set owner of all files to current user = Administrators
takeown /f "%WINDIR%\System32\inetsrv\config" /r /d y >nul 2>nul
:: Grant access to all files to Administrators
icacls "%WINDIR%\System32\inetsrv\config" /grant %Admin%:F /T >nul 2>nul
:: Set owner of WindowsApps back to Administrators
icacls "%WINDIR%\System32\inetsrv\config" /setowner %Admin% >nul 2>nul

CALL :PROGRESS_BAR 20 "Reconstruindo arquivo o IIS"

:: Reconstruct redirection.config
call :IIS_RECONSTRUCT_CONFIG_FILE0

:: Reconstruct administration.config
IF EXIST "%WINDIR%\system32\inetsrv\config\administration.config.clean.install" ( copy "%WINDIR%\system32\inetsrv\config\administration.config.clean.install" "%WINDIR%\system32\inetsrv\config\administration.config" /y >nul 2>nul )

CALL :PROGRESS_BAR 30 "Reconstruindo arquivo o IIS"

:: Reconstruct applicationHost.config
call :IIS_RECONSTRUCT_CONFIG_FILE1

:: Reconstruct appcmd.xml
call :IIS_RECONSTRUCT_CONFIG_FILE2

:: delete MBSchema.*
del /q %WINDIR%\System32\inetsrv\MBSchema.* >nul 2>nul

CALL :PROGRESS_BAR 40 "Reconstruindo arquivo o IIS"

:: delete History
if exist "%WINDIR%\System32\inetsrv\History" (
	cd %WINDIR%\System32\inetsrv\History
	del /q . >nul 2>nul
)

CALL :PROGRESS_BAR 50 "Desinstalando funcionalidades do IIS"

:: disable and unistall all IIS features
call :IIS_DISABLE_UNISTALL_FEATURE

:: Prepara windows to automatic start this tool 
REG ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run" /v %ToolsName% /t REG_SZ /d "%SystemDrive%\inetpub\%ProgramName0%\%ToolsName%.bat IISREPAIRSTEP3" /f >nul 2>nul

:: Reeboot is needed
CALL :PROGRESS_BAR 100 "Aguardando para reiniciar o computador ..."
shutdown.exe /r /t 5 >nul
PAUSE >nul
GOTO :END_OF_FILE
















:IIS_REPAIR_STEP3
MODE 80,4
SET "BarTitle=Utilitario de reparo do IIS"
CALL :PROGRESS_BAR 2 "Esperando ..."

:: Delay for windows to rebboot
TIMEOUT /t 10 /nobreak >nul 2>nul

:: Remove key from Regedit
REG DELETE "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run" /V %ToolsName% /F

:: Stop IIS
CALL :PROGRESS_BAR 4 "Parando o IIS"
NET STOP w3svc >nul 2>nul

:: Deactivate IIS components
CALL :PROGRESS_BAR 25 "Desativar funcionalidades do IIS "
call :DISABLE_FEATURE_QUIET NetFx3 10	
call :DISABLE_FEATURE_QUIET NetFx3ServerFeatures 11
call :DISABLE_FEATURE_QUIET IIS-ManagementScriptingTools 12
call :DISABLE_FEATURE_QUIET IIS-IIS6ManagementCompatibility 13
call :DISABLE_FEATURE_QUIET IIS-Metabase 14
call :DISABLE_FEATURE_QUIET IIS-HostableWebCore 15
call :DISABLE_FEATURE_QUIET WCF-HTTP-Activation 16
call :DISABLE_FEATURE_QUIET WCF-NonHTTP-Activation 17
call :DISABLE_FEATURE_QUIET WCF-HTTP-Activation45 18
call :DISABLE_FEATURE_QUIET WCF-TCP-Activation45 19
call :DISABLE_FEATURE_QUIET WCF-Pipe-Activation45 20
call :DISABLE_FEATURE_QUIET WCF-MSMQ-Activation45 21
call :DISABLE_FEATURE_QUIET WCF-TCP-PortSharing45 22
call :DISABLE_FEATURE_QUIET IIS-WebSockets 23
call :DISABLE_FEATURE_QUIET IIS-ApplicationInit 24
call :DISABLE_FEATURE_QUIET IIS-ASPNET 25
call :DISABLE_FEATURE_QUIET IIS-CGI 26
call :DISABLE_FEATURE_QUIET IIS-ServerSideIncludes 27
call :DISABLE_FEATURE_QUIET IIS-ManagementService 28
call :DISABLE_FEATURE_QUIET IIS-WMICompatibility 29
call :DISABLE_FEATURE_QUIET IIS-LegacyScripts 30
call :DISABLE_FEATURE_QUIET IIS-LegacySnapIn 31
call :DISABLE_FEATURE_QUIET IIS-FTPServer 32
call :DISABLE_FEATURE_QUIET IIS-FTPSvc 33
call :DISABLE_FEATURE_QUIET IIS-FTPExtensibility 34
call :DISABLE_FEATURE_QUIET IIS-CertProvider 35
call :DISABLE_FEATURE_QUIET IIS-WindowsAuthentication 36
call :DISABLE_FEATURE_QUIET IIS-DigestAuthentication 37
call :DISABLE_FEATURE_QUIET IIS-ClientCertificateMappingAuthentication 38
call :DISABLE_FEATURE_QUIET IIS-IISCertificateMappingAuthentication 39
call :DISABLE_FEATURE_QUIET IIS-ODBCLogging 40
call :DISABLE_FEATURE_QUIET IIS-IPSecurity 41
call :DISABLE_FEATURE_QUIET IIS-URLAuthorization 42
call :DISABLE_FEATURE_QUIET IIS-HttpCompressionDynamic 43
call :DISABLE_FEATURE_QUIET IIS-Performance 44
CALL :PROGRESS_BAR 45 "Ativar IIS e .NET Framework"
call :ENABLE_FEATURE_QUIET IIS-WebServerRole 45
call :ENABLE_FEATURE_QUIET IIS-WebServer 46
call :ENABLE_FEATURE_QUIET IIS-CommonHttpFeatures 47
call :ENABLE_FEATURE_QUIET IIS-StaticContent 48
call :ENABLE_FEATURE_QUIET IIS-DefaultDocument 49
call :ENABLE_FEATURE_QUIET IIS-HttpErrors 50
call :ENABLE_FEATURE_QUIET IIS-HttpRedirect 51
call :ENABLE_FEATURE_QUIET IIS-ApplicationDevelopment 52
call :ENABLE_FEATURE_QUIET NetFx4-AdvSrvs 53
call :ENABLE_FEATURE_QUIET NetFx4Extended-ASPNET45 54
call :ENABLE_FEATURE_QUIET IIS-NetFxExtensibility45 55
call :ENABLE_FEATURE_QUIET IIS-ISAPIExtensions 56
call :ENABLE_FEATURE_QUIET IIS-ISAPIFilter 57
call :ENABLE_FEATURE_QUIET IIS-ASPNET45 58
call :ENABLE_FEATURE_QUIET IIS-ASP 59
call :ENABLE_FEATURE_QUIET IIS-HealthAndDiagnostics 60
call :ENABLE_FEATURE_QUIET IIS-LoggingLibraries 61
call :ENABLE_FEATURE_QUIET IIS-RequestMonitor 62
call :ENABLE_FEATURE_QUIET IIS-HttpTracing 63
call :ENABLE_FEATURE_QUIET IIS-Security 64
call :ENABLE_FEATURE_QUIET IIS-BasicAuthentication 65
call :ENABLE_FEATURE_QUIET IIS-RequestFiltering 66
call :ENABLE_FEATURE_QUIET IIS-WebServerManagementTools 67
call :ENABLE_FEATURE_QUIET IIS-ManagementConsole 68
CALL :PROGRESS_BAR 70 "Desativar funcionalidades do IIS "
call :DISABLE_FEATURE_QUIET IIS-DirectoryBrowsing 69
call :DISABLE_FEATURE_QUIET WCF-Services45 70
call :DISABLE_FEATURE_QUIET IIS-HttpLogging 71
call :DISABLE_FEATURE_QUIET IIS-HttpCompressionStatic 72

CALL :PROGRESS_BAR 80 "Configurando IIS"

:: Start IIS so some of the instructions can Work
NET START w3svc >nul 2>nul

:: Delay for windows to rebboot
TIMEOUT /t 10 /nobreak >nul 2>nul

REM Configure Individual App Pool
%windir%\System32\inetsrv\appcmd.exe stop apppool "DefaultAppPool" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe delete apppool ".NET v2.0 Classic" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe delete apppool ".NET v2.0" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe delete apppool "Classic .NET AppPool" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe delete apppool ".NET v4.5" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe delete apppool ".NET v4.5 Classic" >nul 2>nul

REM try to recover damaged %WINDIR%\system32\inetsrv\config\administration.config / remove unused modules 
%windir%\system32\inetsrv\appcmd.exe uninstall module CgiModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module FastCgiModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module ServerSideIncDISABLE_FEATUREludeModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module CustomLoggingModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module WindowsAuthenticationModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module DigestAuthenticationModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module CertificateMappingAuthenticationModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module IISCertificateMappingAuthenticationModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module UrlAuthorizationModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module IpRestrictionModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module DynamicIpRestrictionModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module DynamicCompressionModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module WebDAVModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module HttpLoggingModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module StaticCompressionModule >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe uninstall module DirectoryListingModule >nul 2>nul

REM remove port 80 from Default Web Site
if '%Language%' == 'BR' (
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:"Default Web Site" /-bindings.[protocol='http',bindingInformation='*:80:'] >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:TimeReport /-bindings.[protocol='http',bindingInformation='*:80:'] >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:EmissorFiscal /-bindings.[protocol='http',bindingInformation='*:80:'] >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:EmissorFiscal /-bindings.[protocol='http',bindingInformation='*:8085:'] >nul 2>nul
	REM Delete default web site 
	%windir%\system32\inetsrv\appcmd.exe delete site "Default Web Site" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe delete AppPool ".NET v4.5" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe delete AppPool ".NET v4.5 Classic" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe delete AppPool "DefaultAppPool" >nul 2>nul
)

if exist "%SystemDrive%\inetpub\%ProgramName0%\" (
	REM Create the website for %ProgramName0%
	%windir%\system32\inetsrv\appcmd.exe add site /name:%ProgramName0% /physicalPath:%SystemDrive%\inetpub\%ProgramName0% /bindings:http/*:%HttpPort00%: >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /+bindings.[protocol='http',bindingInformation='*:%HttpPort00%:'] >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /+bindings.[protocol='http',bindingInformation='*:%HttpPort01%:'] >nul 2>nul
	REM Setup App Pool/ fine tunning
	%windir%\system32\inetsrv\appcmd.exe add apppool /name:%ProgramName0% >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /[path='/'].applicationPool:%ProgramName0% >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set apppool /apppool.name:%ProgramName0% /managedRuntimeVersion:v4.0 >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set apppool %ProgramName0% /autoStart:true /startMode:AlwaysRunning >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].processModel.loadUserProfile:true" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='%ProgramName0%'].processModel.idleTimeout:00:00:00" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='%ProgramName0%'].processModel.maxProcesses:0" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.limit:80000" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.action:Throttle" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.resetInterval:00:01:00" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config "%ProgramName0%" /section:globalization /culture:pt-BR >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config "%ProgramName0%" /section:globalization /uiCulture:pt-BR >nul 2>nul
	REM enable HTTP on default website
	%windir%\system32\inetsrv\appcmd.exe set app "%ProgramName0%/" /enabledProtocols:http >nul 2>nul
	REM start default application tools and site
	%windir%\System32\inetsrv\appcmd.exe start apppool "%ProgramName0%">nul 2>nul
	%windir%\System32\inetsrv\appcmd.exe start sites "%ProgramName0%">nul 2>nul
)

if not exist "%SystemDrive%\inetpub\%ProgramName0%\" (
	REM Delete the website for %ProgramName1%
    %windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /-bindings.[protocol='http',bindingInformation='*:%HttpPort10%:'] >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /-bindings.[protocol='http',bindingInformation='*:%HttpPort11%:'] >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe delete apppool "%ProgramName0%" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe delete site "%ProgramName0%" >nul 2>nul
)

if exist "%SystemDrive%\inetpub\%ProgramName1%\" (
	REM Create the website for %ProgramName1%
	%windir%\system32\inetsrv\appcmd.exe add site /name:%ProgramName1% /physicalPath:%SystemDrive%\inetpub\%ProgramName1% /bindings:http/*:%HttpPort10%: >nul 2>nul
    %windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName1% /+bindings.[protocol='http',bindingInformation='*:%HttpPort10%:'] >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName1% /+bindings.[protocol='http',bindingInformation='*:%HttpPort11%:'] >nul 2>nul
	REM Setup App Pool/ fine tunning
	%windir%\system32\inetsrv\appcmd.exe add apppool /name:%ProgramName1% >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName1% /[path='/'].applicationPool:%ProgramName1% >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set apppool /apppool.name:%ProgramName1% /managedRuntimeVersion:v4.0 >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set apppool %ProgramName1% /autoStart:true /startMode:AlwaysRunning >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName1%'].processModel.loadUserProfile:true" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='%ProgramName1%'].processModel.idleTimeout:00:00:00" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='%ProgramName1%'].processModel.maxProcesses:0" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName1%'].cpu.limit:80000" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName1%'].cpu.action:Throttle" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName1%'].cpu.resetInterval:00:01:00" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config "%ProgramName1%" /section:globalization /culture:pt-BR >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set config "%ProgramName1%" /section:globalization /uiCulture:pt-BR >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe add vdir /app.name:"%ProgramName1%/" /path:/Content /physicalPath:%SystemDrive%\inetpub\%ProgramName0%\Content >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe add vdir /app.name:"%ProgramName1%/" /path:/Orders /physicalPath:%SystemDrive%\inetpub\%ProgramName0%\Orders >nul 2>nul
	REM enable HTTP on default website
	%windir%\system32\inetsrv\appcmd.exe set app "%ProgramName1%/" /enabledProtocols:http >nul 2>nul
	REM start default application tools and site
	%windir%\System32\inetsrv\appcmd.exe start apppool "%ProgramName1%">nul 2>nul
	%windir%\System32\inetsrv\appcmd.exe start sites "%ProgramName1%">nul 2>nul
)

if not exist "%SystemDrive%\inetpub\%ProgramName1%\" (
	REM Delete the website for %ProgramName1%
    %windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName1% /-bindings.[protocol='http',bindingInformation='*:%HttpPort10%:'] >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName1% /-bindings.[protocol='http',bindingInformation='*:%HttpPort11%:'] >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe delete apppool "%ProgramName1%" >nul 2>nul
	%windir%\system32\inetsrv\appcmd.exe delete site "%ProgramName1%" >nul 2>nul
)

REM Add port 80 to this new instalation 
if '%Language%' == 'BR' (
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /+bindings.[protocol='http',bindingInformation='*:80:'] >nul 2>nul
)

:: Reeboot may be needed
CALL :PROGRESS_BAR 100 "Concluido ... A reiniciar o computador ..."
shutdown.exe /r /t 5 >nul
PAUSE >nul
GOTO :END_OF_FILE









:IIS_RECONSTRUCT_CONFIG_FILE0
:: Reconstruct redirection.config
SET "ConfigFile=%WINDIR%\System32\inetsrv\config\redirection.cfg"
ECHO ^<configuration^>>%ConfigFile%
ECHO     ^<configSections^>>>%ConfigFile%
ECHO         ^<section name="configurationRedirection" /^>>>%ConfigFile%
ECHO     ^</configSections^>>>%ConfigFile%
ECHO     ^<configProtectedData^>>>%ConfigFile%
ECHO         ^<providers^>>>%ConfigFile%
:: ECHO            ^<add name="IISRsaProvider" type="" description="Uses RsaCryptoServiceProvider to encrypt and decrypt" keyContainerName="iisConfigurationKey" cspProviderName="" useMachineContainer="true" useOAEP="false" /^>>>%ConfigFile%
:: ECHO             ^<add name="IISCngProvider" type="Microsoft.ApplicationHost.CngProtectedConfigurationProvider" description="Uses Win32 Crypto CNG to encrypt and decrypt" keyContainerName="iisCngConfigurationKey" useMachineContainer="true" /^>>>%ConfigFile%
ECHO         ^</providers^>>>%ConfigFile%
ECHO     ^</configProtectedData^>>>%ConfigFile%
ECHO     ^<configurationRedirection /^>>>%ConfigFile%
ECHO ^</configuration^>>>%ConfigFile%
copy %ConfigFile% %WINDIR%\System32\inetsrv\config\redirection.config /y >nul 2>nul
del /q %ConfigFile% >nul 2>nul
EXIT /B 0







:IIS_RECONSTRUCT_CONFIG_FILE1
:: Reconstruct applicationHost.config
SET "ConfigFile=%WINDIR%\System32\inetsrv\config\applicationHost.cfg"
del /q %ConfigFile% >nul 2>nul
ECHO ^<?xml version="1.0" encoding="UTF-8"?^>>%ConfigFile%
ECHO ^<!-->>%ConfigFile%
ECHO     IIS configuration sections.>>%ConfigFile%
ECHO     For schema documentation, see>>%ConfigFile%
ECHO     %windir%\system32\inetsrv\config\schema\IIS_schema.xml.>>%ConfigFile%
ECHO     Please make a backup of this file before making any changes to it.>>%ConfigFile%
ECHO --^>>>%ConfigFile%
ECHO ^<configuration^>>>%ConfigFile%
ECHO     ^<!-->>%ConfigFile%
ECHO         The ^<configSections^> section controls the registration of sections.>>%ConfigFile%
ECHO         Section is the basic unit of deployment, locking, searching and>>%ConfigFile%
ECHO         containment for configuration settings.>>%ConfigFile%
ECHO         Every section belongs to one section group.>>%ConfigFile%
ECHO         A section group is a container of logically-related sections.>>%ConfigFile%
ECHO         Sections cannot be nested.>>%ConfigFile%
ECHO         Section groups may be nested.>>%ConfigFile%
ECHO         ^<section>>%ConfigFile%
ECHO             name=""  [Required, Collection Key] [XML name of the section]>>%ConfigFile%
ECHO             allowDefinition="Everywhere" [MachineOnly^|MachineToApplication^|AppHostOnly^|Everywhere] [Level where it can be set]>>%ConfigFile%
ECHO             overrideModeDefault="Allow"  [Allow^|Deny] [Default delegation mode]>>%ConfigFile%
ECHO             allowLocation="true"  [true^|false] [Allowed in location tags]>>%ConfigFile%
ECHO         /^>>>%ConfigFile%
ECHO         The recommended way to unlock sections is by using a location tag:>>%ConfigFile%
ECHO         ^<location path="Default Web Site" overrideMode="Allow"^>>>%ConfigFile%
ECHO             ^<system.webServer^>>>%ConfigFile%
ECHO                 ^<asp /^>>>%ConfigFile%
ECHO             ^</system.webServer^>>>%ConfigFile%
ECHO         ^</location^>>>%ConfigFile%
ECHO     --^>>>%ConfigFile%
ECHO     ^<configSections^>>>%ConfigFile%
ECHO         ^<sectionGroup name="system.applicationHost"^>>>%ConfigFile%
ECHO             ^<section name="applicationPools" allowDefinition="AppHostOnly" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="configHistory" allowDefinition="AppHostOnly" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="customMetadata" allowDefinition="AppHostOnly" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="listenerAdapters" allowDefinition="AppHostOnly" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="log" allowDefinition="AppHostOnly" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="serviceAutoStartProviders" allowDefinition="AppHostOnly" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="sites" allowDefinition="AppHostOnly" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="webLimits" allowDefinition="AppHostOnly" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO         ^</sectionGroup^>>>%ConfigFile%
ECHO         ^<sectionGroup name="system.webServer"^>>>%ConfigFile%
ECHO             ^<section name="asp" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="caching" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^<section name="cgi" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="defaultDocument" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^<section name="directoryBrowse" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^<section name="fastCgi" allowDefinition="AppHostOnly" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="globalModules" allowDefinition="AppHostOnly" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="handlers" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="httpCompression" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^<section name="httpErrors" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^<section name="httpLogging" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="httpProtocol" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^<section name="httpRedirect" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^<section name="httpTracing" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="isapiFilters" allowDefinition="MachineToApplication" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="modules" allowDefinition="MachineToApplication" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="applicationInitialization" allowDefinition="MachineToApplication" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^<section name="odbcLogging" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<sectionGroup name="security"^>>>%ConfigFile%
ECHO                 ^<section name="access" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                 ^<section name="applicationDependencies" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                 ^<sectionGroup name="authentication"^>>>%ConfigFile%
ECHO                     ^<section name="anonymousAuthentication" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                     ^<section name="basicAuthentication" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                     ^<section name="clientCertificateMappingAuthentication" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                     ^<section name="digestAuthentication" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                     ^<section name="iisClientCertificateMappingAuthentication" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                     ^<section name="windowsAuthentication" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                 ^</sectionGroup^>>>%ConfigFile%
ECHO                 ^<section name="authorization" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO                 ^<section name="ipSecurity" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                 ^<section name="dynamicIpSecurity" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                 ^<section name="isapiCgiRestriction" allowDefinition="AppHostOnly" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                 ^<section name="requestFiltering" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^</sectionGroup^>>>%ConfigFile%
ECHO             ^<section name="serverRuntime" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="serverSideInclude" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<section name="staticContent" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^<sectionGroup name="tracing"^>>>%ConfigFile%
ECHO                 ^<section name="traceFailedRequests" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO                 ^<section name="traceProviderDefinitions" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^</sectionGroup^>>>%ConfigFile%
ECHO             ^<section name="urlCompression" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^<section name="validation" overrideModeDefault="Allow" /^>>>%ConfigFile%
ECHO             ^<sectionGroup name="webdav"^>>>%ConfigFile%
ECHO                 ^<section name="globalSettings" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                 ^<section name="authoring" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                 ^<section name="authoringRules" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^</sectionGroup^>>>%ConfigFile%
ECHO             ^<section name="webSocket" overrideModeDefault="Deny"/^>>>%ConfigFile%
ECHO         ^</sectionGroup^>>>%ConfigFile%
ECHO         ^<sectionGroup name="system.ftpServer"^>>>%ConfigFile%
ECHO             ^<section name="log" overrideModeDefault="Deny" allowDefinition="AppHostOnly" /^>>>%ConfigFile%
ECHO             ^<section name="firewallSupport" overrideModeDefault="Deny" allowDefinition="AppHostOnly" /^>>>%ConfigFile%
ECHO             ^<section name="caching" overrideModeDefault="Deny" allowDefinition="AppHostOnly" /^>>>%ConfigFile%
ECHO             ^<section name="providerDefinitions" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^<sectionGroup name="security"^>>>%ConfigFile%
ECHO                 ^<section name="ipSecurity" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                 ^<section name="requestFiltering" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                 ^<section name="authorization" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO                 ^<section name="authentication" overrideModeDefault="Deny" /^>>>%ConfigFile%
ECHO             ^</sectionGroup^>>>%ConfigFile%
ECHO             ^<section name="serverRuntime" overrideModeDefault="Deny" allowDefinition="AppHostOnly" /^>>>%ConfigFile%
ECHO         ^</sectionGroup^>>>%ConfigFile%
ECHO     ^</configSections^>>>%ConfigFile%
ECHO     ^<configProtectedData^>>>%ConfigFile%
ECHO         ^<providers^>>>%ConfigFile%
ECHO             ^<add name="IISCngProvider" type="Microsoft.ApplicationHost.CngProtectedConfigurationProvider" description="Uses Win32 Crypto CNG to encrypt and decrypt" keyContainerName="iisCngConfigurationKey" useMachineContainer="true" /^>>>%ConfigFile%
ECHO             ^<add name="IISWASOnlyCngProvider" type="Microsoft.ApplicationHost.CngProtectedConfigurationProvider" description="(WAS Only) Uses Win32 Crypto CNG to encrypt and decrypt" keyContainerName="iisCngWasKey" useMachineContainer="true" /^>>>%ConfigFile%
ECHO         ^</providers^>>>%ConfigFile%
ECHO     ^</configProtectedData^>>>%ConfigFile%
ECHO     ^<system.applicationHost^>>>%ConfigFile%
ECHO         ^<applicationPools /^>>>%ConfigFile%
ECHO         ^<!-- The ^<customMetadata^> section is used internally by the Admin Base Objects (ABO) Compatibility component. Please do not modify its content. --^>>>%ConfigFile%
ECHO         ^<customMetadata /^>>>%ConfigFile%
ECHO         ^<!-- The ^<listenerAdapters^> section defines the protocols with which the Windows Process Activation Service (WAS) binds. --^>>>%ConfigFile%
ECHO         ^<listenerAdapters /^>>>%ConfigFile%
ECHO         ^<log /^>>>%ConfigFile%
ECHO         ^<sites /^>>>%ConfigFile%
ECHO         ^<webLimits /^>>>%ConfigFile%
ECHO     ^</system.applicationHost^>>>%ConfigFile%
ECHO     ^<system.webServer^>>>%ConfigFile%
ECHO         ^<asp /^>>>%ConfigFile%
ECHO         ^<caching /^>>>%ConfigFile%
ECHO         ^<cgi /^>>>%ConfigFile%
ECHO         ^<defaultDocument /^>>>%ConfigFile%
ECHO         ^<directoryBrowse /^>>>%ConfigFile%
ECHO         ^<fastCgi /^>>>%ConfigFile%
ECHO         ^<!-- The ^<globalModules^> section defines all native-code modules. To enable a module, specify it in the ^<modules^> section. --^>>>%ConfigFile%
ECHO         ^<globalModules /^>>>%ConfigFile%
ECHO         ^<handlers /^>>>%ConfigFile%
ECHO         ^<httpCompression /^>>>%ConfigFile%
ECHO         ^<httpErrors /^>>>%ConfigFile%
ECHO         ^<httpLogging /^>>>%ConfigFile%
ECHO         ^<httpProtocol /^>>>%ConfigFile%
ECHO         ^<httpRedirect /^>>>%ConfigFile%
ECHO         ^<httpTracing /^>>>%ConfigFile%
ECHO         ^<isapiFilters /^>>>%ConfigFile%
ECHO         ^<modules /^>>>%ConfigFile%
ECHO         ^<odbcLogging /^>>>%ConfigFile%
ECHO         ^<security^>>>%ConfigFile%
ECHO             ^<access /^>>>%ConfigFile%
ECHO             ^<applicationDependencies /^>>>%ConfigFile%
ECHO             ^<authentication^>>>%ConfigFile%
ECHO                 ^<anonymousAuthentication /^>>>%ConfigFile%
ECHO                 ^<basicAuthentication /^>>>%ConfigFile%
ECHO                 ^<clientCertificateMappingAuthentication /^>>>%ConfigFile%
ECHO                 ^<digestAuthentication /^>>>%ConfigFile%
ECHO                 ^<iisClientCertificateMappingAuthentication /^>>>%ConfigFile%
ECHO                 ^<windowsAuthentication /^>>>%ConfigFile%
ECHO             ^</authentication^>>>%ConfigFile%
ECHO             ^<authorization /^>>>%ConfigFile%
ECHO             ^<ipSecurity /^>>>%ConfigFile%
ECHO             ^<isapiCgiRestriction /^>>>%ConfigFile%
ECHO             ^<requestFiltering /^>>>%ConfigFile%
ECHO         ^</security^>>>%ConfigFile%
ECHO         ^<serverRuntime /^>>>%ConfigFile%
ECHO         ^<serverSideInclude /^>>>%ConfigFile%
ECHO         ^<staticContent /^>>>%ConfigFile%
ECHO         ^<tracing^>>>%ConfigFile%
ECHO             ^<traceFailedRequests /^>>>%ConfigFile%
ECHO             ^<traceProviderDefinitions /^>>>%ConfigFile%
ECHO         ^</tracing^>>>%ConfigFile%
ECHO         ^<urlCompression /^>>>%ConfigFile%
ECHO         ^<validation /^>>>%ConfigFile%
ECHO     ^</system.webServer^>>>%ConfigFile%
ECHO ^</configuration^>>>%ConfigFile%
copy %ConfigFile% %WINDIR%\System32\inetsrv\config\applicationHost.config /y >nul 2>nul
del /q %ConfigFile% >nul 2>nul
EXIT /B 0







:IIS_RECONSTRUCT_CONFIG_FILE2
:: Reconstruct appcmd.xml
SET "ConfigFile=%WINDIR%\System32\inetsrv\appcmd.x"
del /q %ConfigFile% >nul 2>nul
ECHO ^<appcmd^>>%ConfigFile%
ECHO     ^<object name="site" alias="sites" classId="DefaultSiteObject" ^>>>%ConfigFile%
ECHO         ^<verb name="list" classId="DefaultSiteObject" /^>>>%ConfigFile%
ECHO         ^<verb name="set" classId="DefaultSiteObject" /^>>>%ConfigFile%
ECHO         ^<verb name="add" classId="DefaultSiteObject" /^>>>%ConfigFile%
ECHO         ^<verb name="delete" classId="DefaultSiteObject" /^>>>%ConfigFile%
ECHO         ^<verb name="start" classId="DefaultSiteObject" /^>>>%ConfigFile%
ECHO         ^<verb name="stop" classId="DefaultSiteObject" /^>>>%ConfigFile%
ECHO     ^</object^>>>%ConfigFile%
ECHO     ^<object name="app" alias="apps" classId="DefaultAppObject" ^>>>%ConfigFile%
ECHO         ^<verb name="list" description="List applications" classId="DefaultAppObject" /^>>>%ConfigFile%
ECHO         ^<verb name="set" classId="DefaultAppObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="add" classId="DefaultAppObject" /^>>>%ConfigFile%
ECHO         ^<verb name="delete" classId="DefaultAppObject" /^>>>%ConfigFile%
ECHO     ^</object^>>>%ConfigFile%
ECHO     ^<object name="vdir" alias="vdirs" classId="DefaultDirObject" ^>>>%ConfigFile%
ECHO         ^<verb name="list" description="List virtual directories" classId="DefaultDirObject" /^>>>%ConfigFile%
ECHO         ^<verb name="set" classId="DefaultDirObject" /^>>>%ConfigFile%
ECHO         ^<verb name="add" classId="DefaultDirObject" /^>>>%ConfigFile%
ECHO         ^<verb name="delete" classId="DefaultDirObject" /^>>>%ConfigFile%
ECHO     ^</object^>>>%ConfigFile%
ECHO     ^<object name="apppool" alias="apppools" classId="DefaultAppPoolObject" ^>>>%ConfigFile%
ECHO         ^<verb name="list" classId="DefaultAppPoolObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="set" classId="DefaultAppPoolObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="add" classId="DefaultAppPoolObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="delete" classId="DefaultAppPoolObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="start" classId="DefaultAppPoolObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="stop" classId="DefaultAppPoolObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="recycle" classId="DefaultAppPoolObject"  /^>>>%ConfigFile%
ECHO     ^</object^>>>%ConfigFile%
ECHO     ^<object name="config" alias="configs" classId="DefaultConfigObject" ^>>>%ConfigFile%
ECHO         ^<verb name="list" classId="DefaultConfigObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="set" classId="DefaultConfigObject" /^>>>%ConfigFile%
ECHO         ^<verb name="search" classId="DefaultConfigObject" /^>>>%ConfigFile%
ECHO         ^<verb name="lock" classId="DefaultConfigObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="unlock" classId="DefaultConfigObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="clear" classId="DefaultConfigObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="reset" classId="DefaultConfigObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="migrate" classId="DefaultConfigObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="register" classId="DefaultConfigObject" /^>>>%ConfigFile%
ECHO         ^<verb name="deregister" classId="DefaultConfigObject" /^>>>%ConfigFile%
ECHO     ^</object^>>>%ConfigFile%
ECHO     ^<object name="wp" alias="wps" classId="DefaultWorkerProcessObject" ^>>>%ConfigFile%
ECHO         ^<verb name="list" classId="DefaultWorkerProcessObject"  /^>>>%ConfigFile%
ECHO     ^</object^>>>%ConfigFile%
ECHO     ^<object name="request" alias="requests" classId="DefaultRequestObject" ^>>>%ConfigFile%
ECHO         ^<verb name="list" classId="DefaultRequestObject"  /^>>>%ConfigFile%
ECHO     ^</object^>>>%ConfigFile%
ECHO     ^<object name="module" alias="modules" classId="DefaultModuleObject" ^>>>%ConfigFile%
ECHO         ^<verb name="list" classId="DefaultModuleObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="set" classId="DefaultModuleObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="add" classId="DefaultModuleObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="delete" classId="DefaultModuleObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="install" classId="DefaultModuleObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="uninstall" classId="DefaultModuleObject"  /^>>>%ConfigFile%
ECHO     ^</object^>>>%ConfigFile%
ECHO     ^<object name="backup" alias="backups" classId="DefaultBackupObject" ^>>>%ConfigFile%
ECHO         ^<verb name="list" classId="DefaultBackupObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="add" classId="DefaultBackupObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="delete" classId="DefaultBackupObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="restore" classId="DefaultBackupObject"  /^>>>%ConfigFile%
ECHO     ^</object^>>>%ConfigFile%    
ECHO     ^<object name="trace" alias="traces" classId="DefaultTraceObject" ^>>>%ConfigFile%
ECHO         ^<verb name="list" classId="DefaultTraceObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="configure" classId="DefaultTraceObject"  /^>>>%ConfigFile%
ECHO         ^<verb name="inspect" classId="DefaultTraceObject"  /^>>>%ConfigFile%
ECHO     ^</object^>>>%ConfigFile%
ECHO     ^<object name="binding" alias="bindings" classId="DefaultBindingObject" ^>>>%ConfigFile%
ECHO         ^<verb name="renew" classId="DefaultBindingObject"  /^>>>%ConfigFile%
ECHO     ^</object^>>>%ConfigFile%
ECHO ^</appcmd^>>>%ConfigFile%
copy %ConfigFile% %WINDIR%\System32\inetsrv\appcmd.xml /y >nul 2>nul
del /q %ConfigFile% >nul 2>nul
EXIT /B 0







:IIS_DISABLE_UNISTALL_FEATURE
:: ..............................................................................
CALL :PROGRESS_BAR 35 "Desinstalar IIS e .NET Framework ... "
call :DISABLE_FEATURE_QUIET NetFx3
call :DISABLE_FEATURE_QUIET NetFx3ServerFeatures
call :DISABLE_FEATURE_QUIET IIS-WebServerRole
call :DISABLE_FEATURE_QUIET IIS-WebServer
call :DISABLE_FEATURE_QUIET IIS-CommonHttpFeatures
call :DISABLE_FEATURE_QUIET IIS-HttpErrors
call :DISABLE_FEATURE_QUIET IIS-HttpRedirect
call :DISABLE_FEATURE_QUIET IIS-ApplicationDevelopment
call :DISABLE_FEATURE_QUIET IIS-NetFxExtensibility
call :DISABLE_FEATURE_QUIET IIS-NetFxExtensibility45
call :DISABLE_FEATURE_QUIET IIS-HealthAndDiagnostics
call :DISABLE_FEATURE_QUIET IIS-HttpLogging
call :DISABLE_FEATURE_QUIET IIS-LoggingLibraries
call :DISABLE_FEATURE_QUIET IIS-RequestMonitor
CALL :PROGRESS_BAR 40 "Desinstalar IIS e .NET Framework ... "
call :DISABLE_FEATURE_QUIET IIS-HttpTracing
call :DISABLE_FEATURE_QUIET IIS-Security
call :DISABLE_FEATURE_QUIET IIS-URLAuthorization
call :DISABLE_FEATURE_QUIET IIS-RequestFiltering
call :DISABLE_FEATURE_QUIET IIS-IPSecurity
call :DISABLE_FEATURE_QUIET IIS-Performance
call :DISABLE_FEATURE_QUIET IIS-HttpCompressionDynamic
call :DISABLE_FEATURE_QUIET IIS-WebServerManagementTools
call :DISABLE_FEATURE_QUIET IIS-ManagementScriptingTools
call :DISABLE_FEATURE_QUIET IIS-IIS6ManagementCompatibility
call :DISABLE_FEATURE_QUIET IIS-Metabase
call :DISABLE_FEATURE_QUIET IIS-HostableWebCore
call :DISABLE_FEATURE_QUIET WCF-HTTP-Activation
call :DISABLE_FEATURE_QUIET WCF-NonHTTP-Activation
call :DISABLE_FEATURE_QUIET WCF-Services45
CALL :PROGRESS_BAR 45 "Desinstalar IIS e .NET Framework ... "
call :DISABLE_FEATURE_QUIET WCF-HTTP-Activation45
call :DISABLE_FEATURE_QUIET WCF-TCP-Activation45
call :DISABLE_FEATURE_QUIET WCF-Pipe-Activation45
call :DISABLE_FEATURE_QUIET WCF-MSMQ-Activation45
call :DISABLE_FEATURE_QUIET WCF-TCP-PortSharing45
call :DISABLE_FEATURE_QUIET IIS-StaticContent
call :DISABLE_FEATURE_QUIET IIS-DefaultDocument
call :DISABLE_FEATURE_QUIET IIS-DirectoryBrowsing
call :DISABLE_FEATURE_QUIET IIS-WebDAV
call :DISABLE_FEATURE_QUIET IIS-WebSockets
call :DISABLE_FEATURE_QUIET IIS-ApplicationInit
call :DISABLE_FEATURE_QUIET IIS-ASPNET
call :DISABLE_FEATURE_QUIET IIS-ASPNET45
call :DISABLE_FEATURE_QUIET IIS-ASP
call :DISABLE_FEATURE_QUIET IIS-CGI
call :DISABLE_FEATURE_QUIET IIS-ISAPIExtensions
call :DISABLE_FEATURE_QUIET IIS-ISAPIFilter
call :DISABLE_FEATURE_QUIET IIS-ServerSideIncludes
call :DISABLE_FEATURE_QUIET IIS-CustomLogging
CALL :PROGRESS_BAR 50 "Desinstalar IIS e .NET Framework ... "
call :DISABLE_FEATURE_QUIET IIS-BasicAuthentication
call :DISABLE_FEATURE_QUIET IIS-HttpCompressionStatic
call :DISABLE_FEATURE_QUIET IIS-ManagementConsole
call :DISABLE_FEATURE_QUIET IIS-ManagementService
call :DISABLE_FEATURE_QUIET IIS-WMICompatibility
call :DISABLE_FEATURE_QUIET IIS-LegacyScripts
call :DISABLE_FEATURE_QUIET IIS-LegacySnapIn
call :DISABLE_FEATURE_QUIET IIS-FTPServer
call :DISABLE_FEATURE_QUIET IIS-FTPSvc
call :DISABLE_FEATURE_QUIET IIS-FTPExtensibility
call :DISABLE_FEATURE_QUIET IIS-CertProvider
call :DISABLE_FEATURE_QUIET IIS-WindowsAuthentication
call :DISABLE_FEATURE_QUIET IIS-DigestAuthentication
call :DISABLE_FEATURE_QUIET IIS-ClientCertificateMappingAuthentication
call :DISABLE_FEATURE_QUIET IIS-IISCertificateMappingAuthentication
call :DISABLE_FEATURE_QUIET IIS-ODBCLogging
call :DISABLE_FEATURE_QUIET NetFx4-AdvSrvs
call :DISABLE_FEATURE_QUIET NetFx4Extended-ASPNET45
:: ..............................................................................
CALL :PROGRESS_BAR 55 "Desinstalar todos os modulos do IIS ... "
call :UNISTALL_MODULE_QUIET UriCacheModule
call :UNISTALL_MODULE_QUIET FileCacheModule
call :UNISTALL_MODULE_QUIET TokenCacheModule
call :UNISTALL_MODULE_QUIET ManagedEngine
call :UNISTALL_MODULE_QUIET HttpCacheModule
call :UNISTALL_MODULE_QUIET DynamicCompressionModule
call :UNISTALL_MODULE_QUIET StaticCompressionModule
call :UNISTALL_MODULE_QUIET DefaultDocumentModule
call :UNISTALL_MODULE_QUIET DirectoryListingModule
call :UNISTALL_MODULE_QUIET ProtocolSupportModule
call :UNISTALL_MODULE_QUIET HttpRedirectionModule
call :UNISTALL_MODULE_QUIET ServerSideIncludeModule
call :UNISTALL_MODULE_QUIET StaticFileModule
CALL :PROGRESS_BAR 60 "Desinstalar todos os modulos do IIS ... "
call :UNISTALL_MODULE_QUIET AnonymousAuthenticationModule
call :UNISTALL_MODULE_QUIET CertificateMappingAuthenticationModule
call :UNISTALL_MODULE_QUIET BasicAuthenticationModule
call :UNISTALL_MODULE_QUIET WindowsAuthenticationModule
call :UNISTALL_MODULE_QUIET DigestAuthenticationModule
call :UNISTALL_MODULE_QUIET IISCertificateMappingAuthenticationModule
call :UNISTALL_MODULE_QUIET UrlAuthorizationModule
call :UNISTALL_MODULE_QUIET IsapiModule
call :UNISTALL_MODULE_QUIET IsapiFilterModule
call :UNISTALL_MODULE_QUIET IpRestrictionModule
call :UNISTALL_MODULE_QUIET RequestFilteringModule
CALL :PROGRESS_BAR 65 "Desinstalar todos os modulos do IIS ... "
call :UNISTALL_MODULE_QUIET CustomLoggingModule
call :UNISTALL_MODULE_QUIET CustomErrorModule
call :UNISTALL_MODULE_QUIET HttpLoggingModule
call :UNISTALL_MODULE_QUIET FailedRequestsTracingModule
call :UNISTALL_MODULE_QUIET RequestMonitorModule
call :UNISTALL_MODULE_QUIET CgiModule
call :UNISTALL_MODULE_QUIET TracingModule
call :UNISTALL_MODULE_QUIET ConfigurationValidationModule
call :UNISTALL_MODULE_QUIET OutputCache
CALL :PROGRESS_BAR 70 "Desinstalar todos os modulos do IIS ... "
call :UNISTALL_MODULE_QUIET Session
call :UNISTALL_MODULE_QUIET WindowsAuthentication
call :UNISTALL_MODULE_QUIET FormsAuthentication
call :UNISTALL_MODULE_QUIET DefaultAuthentication
call :UNISTALL_MODULE_QUIET RoleManager
call :UNISTALL_MODULE_QUIET UrlAuthorization
call :UNISTALL_MODULE_QUIET AnonymousIdentification
call :UNISTALL_MODULE_QUIET Profile
call :UNISTALL_MODULE_QUIET UrlMappingsModule
EXIT /B 0

















:SERVICE_INSTALL
MODE 80,4
SET "BarTitle=Instalar e ativar servico"

set "DOTNETVER="
if exist %WINDIR%\Microsoft.NET\Framework\v1.0.3705\InstallUtil.exe set "DOTNETVER=v1.0.3705"
if exist %WINDIR%\Microsoft.NET\Framework\v1.1.4322\InstallUtil.exe set "DOTNETVER=v1.1.4322"
if exist %WINDIR%\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe set "DOTNETVER=v2.0.50727"
if exist %WINDIR%\Microsoft.NET\Framework\v3.0\InstallUtil.exe set "DOTNETVER=v3.0"
if exist %WINDIR%\Microsoft.NET\Framework\v3.5\InstallUtil.exe set "DOTNETVER=v3.5"
if exist %WINDIR%\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe set "DOTNETVER=v4.0.30319"

REM check if need to install and activate SERVICE 0
if not exist "%SystemDrive%\inetpub\%ProgramName0%\bin\%ServiceFileName0%.exe" goto :SERVICE_INSTALL1

REM install the Service  ...
call :PROGRESS_BAR 10 "Instalando o %ServiceFullName0% ..."
%WINDIR%\Microsoft.NET\Framework\%DOTNETVER%\InstallUtil.exe /name=%ServiceFullName0% "%SystemDrive%\inetpub\%ProgramName0%\bin\%ServiceFileName0%.exe" >>%LogFile% 2>nul
timeout /t 5 /nobreak >nul 2>nul

REM Start Service automatically / Take no action on failure
IF /I "%1%" == "SERVICEINSTALL" (
sc config %ServiceFullName0% start= auto
sc failure %ServiceFullName0% reset= 0 actions= //////
)

Rem Start Service automatically with delay and Restart the service on failure 
IF /I "%1%" == "SERVICEINSTALLDELAY" (
sc config %ServiceFullName0% start= delayed-auto
sc failure %ServiceFullName0% reset= 0  actions= restart/{resetAfter}/restart/{resetAfter}/restart/{resetAfter}
)

REM start the Service  ...
call :PROGRESS_BAR 30 "Iniciando o %ServiceFullName0% ..."
net start %ServiceFullName0% >>%LogFile%  2>nul

REM confirm that the service is in STAR_PENDING state ...	
call :TEST_SERVICE_START %ServiceFullName0%
if [%errorlevel%]==[0] ( call :PROGRESS_BAR 40 "Iniciando o %ServiceFullName0% ..." && timeout /t 15 /nobreak >nul 2>nul )
call :TEST_SERVICE_START %ServiceFullName0%
if [%errorlevel%]==[0] ( call :PROGRESS_BAR 50 "Iniciando o %ServiceFullName0% ..." && timeout /t 15 /nobreak >nul 2>nul )
call :TEST_SERVICE_START %ServiceFullName0%
if [%errorlevel%]==[0] ( call :PROGRESS_BAR 60 "Iniciando o %ServiceFullName0% ..." && timeout /t 15 /nobreak >nul 2>nul )
call :TEST_SERVICE_START %ServiceFullName0%
if [%errorlevel%]==[0] ( call :PROGRESS_BAR 70 "Iniciando o %ServiceFullName0% ..." && timeout /t 15 /nobreak >nul 2>nul )
call :TEST_SERVICE_START %ServiceFullName0%
if [%errorlevel%]==[0] ( call :PROGRESS_BAR 80 "Iniciando o %ServiceFullName0% ..." && timeout /t 15 /nobreak >nul 2>nul )
call :TEST_SERVICE_START %ServiceFullName0%
if [%errorlevel%]==[0] ( call :PROGRESS_BAR 90 "Iniciando o %ServiceFullName0% ..." && timeout /t 15 /nobreak >nul 2>nul )

:SERVICE_INSTALL0
SC QUERYEX %ServiceFullName0% | findstr "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] goto :SERVICE_INSTALL0	

REM Concluido
call :PROGRESS_BAR 100 "OK! ... %ServiceFullName0% instalado e ativado"

:SERVICE_INSTALL1

del /q "%SystemDrive%\inetpub\%ProgramName0%\InstallUtil.InstallLog" >nul 2>nul
timeout /t 5 /nobreak >nul 2>nul
goto :END_OF_FILE





call :TEST_SERVICE_START %ServiceFullName0%
if [%errorlevel%] == [0] (
	call :MESSAGE_HEADER "Service Start (Iniciar servico do %ProgramName0%)"
	echo.
	echo O servico do %ProgramName0% esta iniciando ...
)
REM confirm that the service is in RUNING state ...
call :TEST_SERVICE %ServiceFullName0%
if [%errorlevel%] == [0] (
	call :MESSAGE_HEADER "Service Start (Iniciar servico do %ProgramName0%)"
	echo.
	echo O servico do %ProgramName0% ja esta esta iniciando ...
)

















:INSTALATION_TEST
REM ..............................................................................
call :WRITE_LOG "♦ T - Testar Instalacao"
SET SqlTestMessage="Teste NET Framework"

SET SqlTestMessage="Teste da base de dados SQL"
REM Test if SQL is installed ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando SQL ...
SQLCMD -b -t "1" -Q "select getdate()"
SET "errorsql2=%errorlevel%"

REM Test if SQL instance is installed ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando Instancia ...
SQLCMD -b -t "5" -S %UserDomain%\%SqlInstance% -Q "select getdate()"
SET "errorsql3=%errorlevel%"
REM Test if SQL instance is installed ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando User ...
SQLCMD -b -t "5" -S %UserDomain%\%SqlInstance% -U sa -P Acronym_2015 -Q "select getdate()"
SET "errorsql4=%errorlevel%"
REM Test SQL service is instaled ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando se Servico SQL instalado...
call :FIND_SERVICE "MSSQL$%SqlInstance%"
SET "errorsql0=%errorlevel%"
REM Test SQL service is active ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando se Servico SQL funcionando...
call :TEST_SERVICE "MSSQL$%SqlInstance%"
SET "errorsql1=%errorlevel%"
REM Test SQL port 1433 ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando porta 1433 ...
call :TEST_TCP_PORT 1433
SET "errorsql5=%errorlevel%"

SET SqlTestMessage="Teste do Internet Information Services"
REM Test IIS service is instaled ...
if exist %WINDIR%\system32\inetsrv\InetMgr.exe (SET "errorsiis0=0") else (SET "errorsiis0=1")
REM Test if IIS is running
SC QUERY "W3SVC" | FINDSTR "RUNNING"
SET "errorsiis1=%errorlevel%"
REM Test IIS port %HttpPort00% ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando porta %HttpPort00% ...
call :TEST_TCP_PORT %HttpPort00%
SET "errorsiis2=%errorlevel%"
REM Test IIS port %HttpPort01% ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando porta %HttpPort01% ...
call :TEST_TCP_PORT %HttpPort01%
SET "errorsiis3=%errorlevel%"
REM Test IIS port %HttpPort10% ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando porta %HttpPort10% ...
call :TEST_TCP_PORT %HttpPort10%
SET "errorsiis4=%errorlevel%"
REM Test IIS port %HttpPort11% ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando porta %HttpPort11% ...
call :TEST_TCP_PORT %HttpPort11%
SET "errorsiis5=%errorlevel%"
SET SqlTestMessage="Teste do %ServiceFullName0%"
REM Test if file exists ...
if exist %SystemDrive%\inetpub\%ProgramName0%\bin\%ServiceFileName0%.exe (SET "errorservice3=0") else (SET "errorservice3=1")
REM Test if the Service is instaled ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando se %ServiceFullName0% esta instalado...
call :FIND_SERVICE "%ServiceFullName0%"
SET "errorservice0=%errorlevel%"
REM Test if the Service is active ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando se %ServiceFullName0% esta funcionando...
call :TEST_SERVICE "%ServiceFullName0%"
SET "errorservice1=%errorlevel%"


REM Test the Service port %ServicePort0% ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando porta %ServicePort0% ...
call :TEST_TCP_PORT %ServicePort0%
SET "errorservice2=%errorlevel%"


SET SqlTestMessage="Teste da NET Framework"
REM Test if NET Framework 4.0 is instaled ...
CLS && CALL :MESSAGE_HEADER %SqlTestMessage% && ECHO Testando NET Framework 4.0
CALL :TEST_FRAMEWORK
SET "errorNet1=%errorlevel%"
SET "versionNet1=%NetVer%"

SET SqlTestMessage="Teste do Google Chrome"
REM Test if Google Chrome is instaled ...
set "ChromeVersion="
set "ChromeName="
set "VPNServer="
rem setlocal enabledelayedexpansion
FOR %%A IN (
    {8A69D345-D564-463c-AFF1-A69D9E530F96},
    {8237E44A-0054-442C-B6B6-EA0509993955},
    {401C381F-E0DE-4B85-8BD8-3F3F14FBDA57}) DO (
  reg query "HKLM\Software\Google\Update\Clients\%%A" /s /v "name" /reg:32 2> nul >>%keyFile%
  reg query "HKLM\Software\Google\Update\Clients\%%A" /s /v "pv" /reg:32 2> nul >>%keyFile%
)
FOR %%A IN (
    {8A69D345-D564-463c-AFF1-A69D9E530F96},
    {8237E44A-0054-442C-B6B6-EA0509993955},
    {401C381F-E0DE-4B85-8BD8-3F3F14FBDA57},
    {4ea16ac7-fd5a-47c3-875b-dbf4a2008c20}) DO (
  reg query HKCU\Software\Google\Update\Clients\%%A /v "name" /reg:32 2> nul >>%keyFile%
  reg query HKCU\Software\Google\Update\Clients\%%A /v "pv" /reg:32 2> nul >>%keyFile%
)

for /f "delims=" %%a in ('findstr "pv" %keyFile%') do set ChromeVersion=%%a
set ChromeVersion=%ChromeVersion:*REG_SZ=%
for /f "tokens=* delims= " %%a in ("%ChromeVersion%") do set ChromeVersion=%%a

for /f "delims=" %%a in ('findstr "name" %keyFile%') do set ChromeName=%%a
set ChromeName=%ChromeName:*REG_SZ=%
for /f "tokens=* delims= " %%a in ("%ChromeName%") do set ChromeName=%%a

del /q %keyFile% >nul 2>nul

reg query "HKLM\SOFTWARE\WOW6432Node\Acronym\EmissorFiscal" /s /v "VPNServer" /reg:32 2> nul >>%keyFile%

for /f "delims=" %%a in ('findstr "VPNServer" %keyFile%') do set VPNServer=%%a

if "%VPNserver%"=="" goto :INSTALATION_TEST4
set VPNServer=%VPNServer:*REG_SZ=%
for /f "tokens=* delims= " %%a in ("%VPNServer%") do set VPNServer=%%a
:INSTALATION_TEST4

del /q %keyFile% >nul 2>nul

REM ..............................................................................
CALL :MESSAGE_HEADER "Resultados dos testes"
REM SQL display test information
if not [%errorsql0%] == [%errorsql1%] goto :INSTALATION_TEST0
call :MESSAGE_IF %errorsql2% "OK ... SQL Server esta instalado e a funcionar"				"ERRO ... SQL Server nao esta instalado ou funcionando!"
call :MESSAGE_IF %errorsql3% "OK ... SQL Instance %SqlInstance% detetada"					"ERRO ... SQL Instance %SqlInstance% nao foi detetada!"
call :MESSAGE_IF %errorsql4% "OK ... SQL Server com Senha e User correctamente configurada" "ERRO ... SQL Server com Senha e User incorreta!"
:INSTALATION_TEST0
call :MESSAGE_IF %errorsql0% "OK ... SQL Service esta instalado" 							"ERRO ... SQL Service nao esta instalado!"
if not [%errorsql0%] == [0] goto INSTALATION_TEST1
call :MESSAGE_IF %errorsql1% "OK ... SQL Service esta funcionando" 							"ERRO ... SQL Service esta desativado!"
if not [%errorsql0%] == [%errorsql1%] goto :INSTALATION_TEST1
call :MESSAGE_IF %errorsql5% "OK ... SQL Server porta 1433" 								"ERRO ... SQL Server porta 1433 nao esta aberta!"

REM IIS display test information
:INSTALATION_TEST1
call :MESSAGE_IF %errorsiis0% "OK ... IIS Service esta instalado" 							"ERRO ... IIS Service nao esta instalado!"
if not [%errorsiis0%] == [0] goto INSTALATION_TEST2
call :MESSAGE_IF %errorsiis1% "OK ... IIS Service esta inicializado" 						"ERRO ... IIS Service esta parado!"
if not [%errorsiis0%] == [%errorsiis1%] goto :INSTALATION_TEST2

if exist "%SystemDrive%\inetpub\%ProgramName0%\" (
	call :MESSAGE_IF %errorsiis2% "OK ... IIS %ProgramName0% porta %HttpPort00%" 			"ERRO ... IIS %ProgramName0% porta %HttpPort00% nao esta aberta!"
	call :MESSAGE_IF %errorsiis3% "OK ... IIS %ProgramName0% porta %HttpPort01%" 			"ERRO ... IIS %ProgramName0% porta %HttpPort01% nao esta aberta!"
)
if exist "%SystemDrive%\inetpub\%ProgramName1%\" (
	call :MESSAGE_IF %errorsiis4% "OK ... IIS %ProgramName1% porta %HttpPort10%" 			"ERRO ... IIS %ProgramName1% porta %HttpPort10% nao esta aberta!"
	call :MESSAGE_IF %errorsiis5% "OK ... IIS %ProgramName1% porta %HttpPort11%" 			"ERRO ... IIS %ProgramName1% porta %HttpPort11% nao esta aberta!"
)

:INSTALATION_TEST2

REM Service display test information
if [%errorservice3%] == [1] (
	echo ERRO ... %ServiceFileName0%.exe não foi encontrado
	goto INSTALATION_TEST3
)
call :MESSAGE_IF %errorservice0% "OK ... %ServiceFullName0% esta instalado" 				"ERRO ... %ServiceFullName0% nao esta instalado!"
if not [%errorservice0%] == [0] goto INSTALATION_TEST3
call :MESSAGE_IF %errorservice1% "OK ... %ServiceFullName0% esta funcionando" 				"ERRO ... %ServiceFullName0% esta desativado!"
if not [%errorservice1%] == [0] goto :INSTALATION_TEST3
call :MESSAGE_IF %errorservice2% "OK ... %ServiceFullName0% porta %ServicePort0%" 			"ERRO ... %ServiceFullName0% porta %ServicePort0% nao esta aberta!"
:INSTALATION_TEST3

REM Display NET Framework 4.0 ...
call :MESSAGE_IF %errorNet1% "OK ... Net Framework 4 detetada / versao %versionNet1%"		"ERRO ... Net Framework 4 nao esta instalada!"

REM Google Chrome display test information
if "%ChromeVersion%"=="" ( echo ERRO ... Google Chrome nao esta instalado! && echo %date% %time:~0,8% ERRO ... Google Chrome nao esta instalado! >>%LogFile% )
if not "%ChromeVersion%"=="" ( echo OK ... %ChromeName% / versao %ChromeVersion% && echo %date% %time:~0,8% OK ... %ChromeName% / versao %ChromeVersion% >>%LogFile% )


REM Check if numbers of precess is ok .. at least 2 
if %NUMBER_OF_PROCESSORS% gtr 1 ( echo OK ... Numero de processadores/nucleos %NUMBER_OF_PROCESSORS% && echo %date% %time:~0,8% OK ... Numero de processadores/nucleos %NUMBER_OF_PROCESSORS%  >>%LogFile% ) else ( echo ERRO ... Numero de processadores/nucleos insuficientes! && echo %date% %time:~0,8% ERRO ... Numero de processadores/nucleos insuficientes! >>%LogFile% )

if '%PROCESSOR_ARCHITECTURE%' == 'x86' ( echo OK ... Windows 32bit && echo %date% %time:~0,8% OK ... Windows 32bit>>%LogFile% ) else ( echo OK ... Windows 64bits && echo %date% %time:~0,8% OK ... Windows 64bits>>%LogFile%)

REM Check software version
set "content="
setlocal enabledelayedexpansion
SET "ConfFile=%SystemDrive%\inetpub\%ProgramName0%\web.config"
IF NOT EXIST %ConfFile% goto :INSTALATION_TEST5
	for /f "delims=" %%a in ('findstr "Owner" %ConfFile%') do set content=%%a
	set content=!content: =!
	set content=!content:*"=!
	set content=!content:*"=!
	set content=!content:*"=!
	for /l %%a in (1,1,150) do if not "!content:~-2!"=="/>" set content=!content:~0,-1!
	set content=!content:~0,-3!
:INSTALATION_TEST5

IF "!content!"=="" (
	echo OK ... Versao proprietaria nao foi detetada
	echo %date% %time:~0,8% OK ... Versao proprietaria nao foi detetada>>%LogFile%
) else (
	echo OK ... Instalado com a chave "!content!"
	echo %date% %time:~0,8% OK ... Instalado com a chave "!content!">>%LogFile%
)
endlocal

if not "%VPNserver%"=="" ( echo OK ... Conexão VPN configurada com %VPNserver% && echo %date% %time:~0,8% OK ... Conexão VPN configurada com %VPNserver% >>%LogFile% )

echo. && pause && exit /b













:SERVICE_STOP
REM ..............................................................................
call :WRITE_LOG "♦ 3 - Service Stop (Parar servico do %ProgramName0%)"
call :MESSAGE_HEADER "Service Stop (Parar servico do %ProgramName0%)"
REM Stop the Service  ...
Taskkill /F /IM %ServiceFileName0%.exe
REM return to main menu
echo. && pause && exit /b




:SERVICE_START
REM ..............................................................................
call :WRITE_LOG "♦ 4 - Service Start (Iniciar servico do %ProgramName0%)"
call :MESSAGE_HEADER "Service Start (Iniciar servico do %ProgramName0%)"
REM start the Service  ...
net start %ServiceFullName0%
REM confirm that the service is in STAR_PENDING state ...
call :TEST_SERVICE_START %ServiceFullName0%
if [%errorlevel%] == [0] (
	call :MESSAGE_HEADER "Service Start (Iniciar servico do %ProgramName0%)"
	echo.
	echo O servico do %ProgramName0% esta iniciando ...
)
:SERVICE_START0
SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] goto :SERVICE_START0	
REM confirm that the service is in RUNING state ...
call :TEST_SERVICE %ServiceFullName0%
if [%errorlevel%] == [0] (
	call :MESSAGE_HEADER "Service Start (Iniciar servico do %ProgramName0%)"
	echo.
	echo OK ... O servico %ProgramName0% iniciado !
)
REM return to main menu
echo. && pause && exit /b


:SQL_STOP
REM ..............................................................................
call :WRITE_LOG "♦ 5 - SQL Stop (Parar servicos SQL)"
call :MESSAGE_HEADER "SQL Stop (Parar servicos SQL)"
REM Para o servico SQL Server
call :SQL_STOP_COMMANDS
REM return to main menu
echo. && pause && exit /b

:SQL_START
REM ..............................................................................
call :WRITE_LOG "♦ 6 - SQL Start (Iniciar servicos SQL)"
call :MESSAGE_HEADER "SQL Start (Iniciar servicos SQL)"
REM Iniciar o servico SQL Server
call :SQL_START_COMMANDS
REM return to main menu
echo. && pause && exit /b




:LOG_BACKUP
REM ..............................................................................
call :WRITE_LOG "♦ 7 - Copiar Log do %ProgramName0% para Desktop"
call :MESSAGE_HEADER "Copiar Log do %ProgramName0% para Desktop"
REM Copiar Log's para o Desktop
set _my_logfolder=%date%
set _my_logfolder=%_my_logfolder: =_%
set _my_logfolder=%_my_logfolder%_%time%
set _my_logfolder=%_my_logfolder: =0%
set _my_logfolder=%_my_logfolder::=%
set _my_logfolder=%_my_logfolder:/=%
set _my_logfolder=%_my_logfolder:~0,-3%
for /f "tokens=1 delims=." %%a in ("%_my_logfolder%") do (set _my_logfolder=LOG_%%a)

REM %SystemDrive%\inetpub\%ProgramName0%\Log
if exist "%SystemDrive%\inetpub\%ProgramName0%\" (
	%SystemDrive%
	if not exist "%temp%\%_my_logfolder%" md "%temp%\%_my_logfolder%"
	xcopy "%SystemDrive%\inetpub\%ProgramName0%\Log\" "%temp%\%_my_logfolder%" /E /I /Y
	del /q "%SystemDrive%\inetpub\%ProgramName0%\Log\*"
	echo Repositorio de logs>>%SystemDrive%\inetpub\%ProgramName0%\Log\Log.txt
	break>%SystemDrive%\inetpub\%ProgramName0%\Log\%ProgramName0%.log
	break>%SystemDrive%\inetpub\%ProgramName0%\Log\%ServiceFullName0%.log
)
if exist "%SystemDrive%\inetpub\%ProgramName1%\" (
	%SystemDrive%
	if not exist "%temp%\%_my_logfolder%" md "%temp%\%_my_logfolder%"
	xcopy "%SystemDrive%\inetpub\%ProgramName1%\Log\" "%temp%\%_my_logfolder%" /E /I /Y
	del /q "%SystemDrive%\inetpub\%ProgramName1%\Log\*"
	echo Repositorio de logs>>%SystemDrive%\inetpub\%ProgramName1%\Log\Log.txt
)

%BinPath%\7z a -aoa %UserDesktop%\%_my_logfolder%.zip "%temp%\%_my_logfolder%\."
rmdir "%temp%\%_my_logfolder%" /S /Q

echo .
echo .Reset dos Log's
start %UserDesktop%\%_my_logfolder%.zip
REM return to main menu
echo. && timeout /t 3 /nobreak 2>nul >nul  && exit /b


:DELPRINTER
REM ..............................................................................
call :WRITE_LOG "♦ 9 - Excluir documentos de Impressao"
MODE 80,4
SET "BarTitle=Excluir documentos de Impressao"

call :PROGRESS_BAR 10 "Service Stop (%ProgramName0%)"
REM Stop the Service  ...
Taskkill /F /IM %ServiceFileName0%.exe >nul 2>nul 

call :PROGRESS_BAR 20 "Excluir documentos de Impressao"
REM Parar Stop print spooler
net stop LPDSVC >nul 2>nul
net stop spooler >nul 2>nul
REM Clear print spooler
del /q %systemroot%\System32\spool\printers\* >nul 2>nul
REM Excluir documentos de Impressao
if [%ProgramName0%] == [EmissorFiscal] (
	del /q "%SystemDrive%\inetpub\%ProgramName0%\CFe\Printer\*.pdf" >nul 2>nul
	del /q "%SystemDrive%\inetpub\%ProgramName0%\NFe\Printer\*.pdf" >nul 2>nul
	del /q "%SystemDrive%\inetpub\%ProgramName0%\CTe\Printer\*.pdf" >nul 2>nul
	del /q "%SystemDrive%\inetpub\%ProgramName0%\NFST\Printer\*.pdf" >nul 2>nul
	del /q "%SystemDrive%\inetpub\%ProgramName0%\NFSe\Printer\*.pdf" >nul 2>nul
	del /q "%SystemDrive%\inetpub\%ProgramName0%\MDFe\Printer\*.pdf" >nul 2>nul
	del /q "%SystemDrive%\inetpub\%ProgramName0%\Orders\Printer\*.pdf" >nul 2>nul
)
REM Start print spooler
net start spooler >nul 2>nul

REM start the Service  ...
call :PROGRESS_BAR 40 "Service Start (%ProgramName0%)"
net start %ServiceFullName0% >nul 2>nul

REM confirm that the service is in STAR_PENDING state ...	
SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 50 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 60 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 70 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 80 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

:DELPRINTER0
SC QUERYEX %ServiceFullName0% | findstr "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] goto :DELPRINTER0	
	
REM Concluido
call :PROGRESS_BAR 100 "OK! ... "

timeout /t 2 /nobreak >nul 2>nul
MODE 80,30
TITLE %ToolsName%
ECHO. && EXIT /b
















:MENU_WIN
REM ..............................................................................
call :WRITE_LOG "♦ W - Utilitarios (Windows)"
CALL :MESSAGE_HEADER "Utilitarios Windows"
ECHO.
ECHO   0 - Sql Server Configuration Manager 
ECHO   1 - Internet Information Services (IIS) Manager
ECHO   2 - Services
ECHO   3 - Event Viewer
ECHO   4 - Certificates Management - Local machine
ECHO   5 - Local Security Policy
ECHO   6 - Optional Features
ECHO   7 - Task Scheduler
ECHO     -
ECHO   S - SAIR
ECHO.
CALL :MESSAGE_LINE_
ECHO.
choice /n /c 01234567s /m "Pressione 0, 1, 2, 3 ..."
if %errorlevel%==1 goto :MENU_WIN_1
if %errorlevel%==2 goto :MENU_WIN_2
if %errorlevel%==3 goto :MENU_WIN_3
if %errorlevel%==4 goto :MENU_WIN_4
if %errorlevel%==5 goto :MENU_WIN_5
if %errorlevel%==6 goto POLICY
if %errorlevel%==7 goto :MENU_WIN_7
if %errorlevel%==8 goto :MENU_WIN_8
if %errorlevel%==9 goto :MENU
goto MENU_WIN
REM ..............................................................................
:MENU_WIN_1
call :WRITE_LOG "♦ 0 - Sql Server Configuration Manager"
mode 20,1 && cls && %SysWowPath%\SQLServerManager11.msc && exit
REM ..............................................................................
:MENU_WIN_2
call :WRITE_LOG "♦ 1 - Internet Information Services (IIS) Manager"
mode 20,1 && cls && %WINDIR%\system32\inetsrv\InetMgr.exe && exit
REM ..............................................................................
:MENU_WIN_3
call :WRITE_LOG "♦ 2 - Services"
mode 20,1 && cls && %SysWowPath%\services.msc && exit
REM ..............................................................................
:MENU_WIN_4
call :WRITE_LOG "♦ 3 - Event Viewer"
mode 20,1 && cls && %SysWowPath%\eventvwr.msc && exit
REM ..............................................................................
:MENU_WIN_5
call :WRITE_LOG "♦ 4 - Certificates Management - Local machine"
mode 20,1 && cls && %WINDIR%\System32\Certlm.msc && exit
REM ..............................................................................
:MENU_WIN_7
call :WRITE_LOG "♦ 6 - Optional Features"
mode 20,1 && cls && %WINDIR%\system32\OptionalFeatures.exe && exit
REM ..............................................................................
:MENU_WIN_8
call :WRITE_LOG "♦ 7 - Task Scheduler"
mode 20,1 && cls && %windir%\system32\taskschd.msc && exit










:MENU_UTIL
REM ..............................................................................
call :WRITE_LOG "♦ U - Utilitarios (Command)"
COLOR 7 && MODE 80,30 && TITLE Utilitarios Command Prompt
CALL :MESSAGE_HEADER "Utilitarios Command Prompt"
ECHO.
ECHO   9 - Criar icons do %ProgramName0% no Desktop
ECHO     -
ECHO   V - Configurar impressora por VPN
ECHO     -
ECHO   D - SQL Dettach (Desagregar base de dados)
ECHO   A - SQL Attach (Agregar base de dados)
ECHO     -
ECHO   3 - Excluir Bases de Dados
ECHO   5 - Desinstalar SQL Server
ECHO     -
ECHO   8 - Scan/Fix e Reboot
ECHO     -
ECHO   I - Instalar IIS e Framework
ECHO     -
ECHO   S - SAIR
ECHO.
CALL :MESSAGE_LINE_
ECHO.
choice /n /c 9VDA358is /m "Pressione 9, V, D, A ..."
if %errorlevel%==1 call :MENU_ICONS
if %errorlevel%==2 call :VPN_PRINTER
if %errorlevel%==3 call :SQL_DETTACH
if %errorlevel%==4 call :SQL_ATTACH
if %errorlevel%==5 call :SQL_DELETEDB
if %errorlevel%==6 call :SQL_UNISTALL
if %errorlevel%==7 call :SCANFIXREBOOT
if %errorlevel%==8 call :IIS_INSTALL_
if %errorlevel%==9 goto :MENU
GOTO MENU_UTIL












:VPN_PRINTER
REM pedir o IP ou URL do Servidor onde o EmissorFiscal esta instalado
call :WRITE_LOG "♦ V - Configurar impressora por VPN"
ECHO . 
set "VpnAddr="
set /P VpnAddr=Digite ip ou URL (Ex: IdServidor.ddns.net) :

REM calcular tamanho do URL
set "result="
call :strlen result VpnAddr
REM URL = NULL desligar servico de VPN
if [%result%] == [0] goto :VPN_PRINTER1
if %result% lss 5 goto :VPN_PRINTER2

MODE 80,4
SET "BarTitle=Reiniciar software (IIS + Servico)"

call :PROGRESS_BAR 20 "Service Stop (%ProgramName0%)"
REM Stop the Service  ...
Taskkill /F /IM %ServiceFileName0%.exe >nul 2>nul
timeout /t 2 /nobreak >nul 2>nul

call :PROGRESS_BAR 30 "Conexao VPN com o servidor %VpnAddr%:%VpnPort%"
REM modificar/adicionar chave no regedit VPNServer
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Acronym\EmissorFiscal" /v VPNServer /t REG_SZ /d "%VpnAddr%" /f >nul 2>nul
REM excluir a chave do registro VPNPrinter
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Acronym\EmissorFiscal" /v VPNPrinter /f >nul 2>nul

timeout /t 2 /nobreak >nul 2>nul

REM start the Service  ...
call :PROGRESS_BAR 40 "Service Start (%ProgramName0%)"
net start %ServiceFullName0% >nul 2>nul

REM confirm that the service is in STAR_PENDING state ...	
SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 50 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 60 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 70 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 80 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

:VPN_PRINTER0
SC QUERYEX %ServiceFullName0% | findstr "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] goto :VPN_PRINTER0
REM Concluido
call :PROGRESS_BAR 100 "OK! ... "
timeout /t 2 /nobreak >nul 2>nul
MODE 80,30
TITLE %ToolsName%
ECHO. && EXIT /b

:VPN_PRINTER1:
REM excluir a chave do registro para desligar a VPN
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Acronym\EmissorFiscal" /v VPNServer /f >nul 2>nul
CALL :MESSAGE_HEADER "Servidor que tem instalado o EmissorFiscal"
ECHO . 
ECHO OK ... Servico de VPN desligado
timeout /t 2 /nobreak >nul 2>nul
MODE 80,30
TITLE %ToolsName%
ECHO. && EXIT /b

:VPN_PRINTER2
REM excluir a chave do registro para desligar a VPN
CALL :MESSAGE_HEADER "Servidor que tem instalado o EmissorFiscal"
ECHO . 
ECHO ERR ... Digite um IP ou URL valido
timeout /t 2 /nobreak >nul 2>nul
MODE 80,30
TITLE %ToolsName%
ECHO. && EXIT /b






REM ********* function *****************************
:strlen <resultVar> <stringVar>
(   
    setlocal EnableDelayedExpansion
    (set^ tmp=!%~2!)
    if defined tmp (
        set "len=1"
        for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
            if "!tmp:~%%P,1!" NEQ "" ( 
                set /a "len+=%%P"
                set "tmp=!tmp:~%%P!"
            )
        )
    ) ELSE (
        set len=0
    )
)
( 
    endlocal
    set "%~1=%len%"
    exit /b
)







:IIS_SERVICE_STOP_START
MODE 80,4
SET "BarTitle=Reiniciar software (IIS + Servico)"

call :PROGRESS_BAR 10 "IIS Stop (%ProgramName0%)"
REM  iisreset /stop
NET STOP w3svc >nul 2>nul

call :PROGRESS_BAR 20 "Service Stop (%ProgramName0%)"
REM Stop the Service  ...
Taskkill /F /IM %ServiceFileName0%.exe >nul 2>nul

REM Stop chromedriver ...
Taskkill /F /IM chromedriver.exe >nul 2>nul
REM Stop wacs ...
Taskkill /F /IM wacs.exe >nul 2>nul

REM IIS setup ...
%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].processModel.loadUserProfile:true" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='%ProgramName0%'].processModel.idleTimeout:00:00:00" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].processModel.maxProcesses:0" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.limit:80000" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.action:Throttle" >nul 2>nul
%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.resetInterval:00:01:00" >nul 2>nul

REM Reset Log folder 
cd / >nul 2>nul
cd %SystemDrive%\inetpub\%ProgramName0%\Log\ >nul 2>nul
del /q "*" >nul 2>nul
echo Repositorio de logs>>Log.txt
break>%ServiceFullName0%.log
break>%ProgramName0%.log
if [%ToolsName%] == [PDVtools] (
	break>%ProgramName0%Messaging.log
	break>%ProgramName0%Sync.log
)

call :PROGRESS_BAR 30 "IIS Start (%ProgramName0%)"
REM iisreset /start
NET START w3svc >nul 2>nul 

REM start the Service  ...
call :PROGRESS_BAR 40 "Service Start (%ProgramName0%)"
net start %ServiceFullName0% >nul 2>nul

REM confirm that the service is in STAR_PENDING state ...	
SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 50 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 60 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 70 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

SC QUERYEX %ServiceFullName0% | FINDSTR "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] ( call :PROGRESS_BAR 80 "Iniciando o %ServiceFullName0% ..." && timeout /t 5 /nobreak >nul 2>nul )

:IIS_SERVICE_STOP_START0
SC QUERYEX %ServiceFullName0% | findstr "RUNNING" >nul 2>nul
if not [%errorlevel%] == [0] goto :IIS_SERVICE_STOP_START0	
	
REM Concluido
call :PROGRESS_BAR 100 "OK! ... "

timeout /t 2 /nobreak >nul 2>nul
MODE 80,30
TITLE %ToolsName%
ECHO. && EXIT /b

























:POLICY
call :WRITE_LOG "♦ 5 - Local Security Policy"
REM Chekc if file exists 
if exist "%WINDIR%\system32\secpol.msc" (
	mode 20,1 && cls
	%WINDIR%\System32\secpol.msc
	exit
)
REM Activate this fuction on Windows 10 
MODE 80,4
SET "BarTitle=Ativar funcionalidades do windows"
pushd "%~dp0" 
call :PROGRESS_BAR 20 "Ativar funcionalidades do windows ..."
dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum >nul 2>nul
call :PROGRESS_BAR 30 "Ativar funcionalidades do windows ..."
dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum >nul 2>nul
call :PROGRESS_BAR 50 "Ativar funcionalidades do windows ..."
for /f %%i in ('findstr /i . List.txt 2^>nul') do dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i" 
mode 20,1 && cls
%WINDIR%\System32\secpol.msc
exit







REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################


:IIS_STOP
REM ..............................................................................
call :WRITE_LOG "♦ 1 - IIS Stop (Parar servidor do %ProgramName0%)"
CALL :MESSAGE_HEADER "IIS Stop (Parar servidor do %ProgramName0%)"
REM Stop IIS ...
REM  iisreset /stop
NET STOP w3svc
REM return to main menu
ECHO. && PAUSE && EXIT /b



:IIS_START
REM ..............................................................................
call :WRITE_LOG "♦ 2 - IIS Start (Iniciar servidor do %ProgramName0%)"
CALL :MESSAGE_HEADER "IIS Start (Iniciar servidor do %ProgramName0%)"
REM Start IIS ...
REM iisreset /start
NET START w3svc
REM return to main menu
ECHO. && PAUSE && EXIT /b



:IIS_CLEAN
@ECHO OFF
MODE 80,4
CD %WINDIR%\system32
SET "DoReboot=0"

SET "BarTitle=Utilitario de limpeza do IIS"
REM prepara Log file
rem IF EXIST "%LogFile%" ( del /q %LogFile% >NUL 2>NUL )

REM Check if Windows 10
if not "%WinVersion%" == "10.0" (
	CALL :PROGRESS_BAR 0 "ERRO! ... Funcionalidade disponivel apenas para Windows 10 !"
	TIMEOUT /t 5 /nobreak 2>NUL >NUL
	GOTO :END_OF_FILE
)
REM Check if IIS is Running
CALL :CHECK_IIS_RUNING
if '%errorlevel%' == '0' ( 
	CALL :PROGRESS_BAR 4 "NOTA ... Parando o Internet Information Service / IIS"
	NET STOP w3svc >nul 2>nul
)
REM Check if Service is Running
call :FIND_SERVICE "%ServiceFullName0%"
if '%errorlevel%' == '1' ( 
	CALL :PROGRESS_BAR 6 "NOTA ... Parando o %ServiceFullName0%"
	Taskkill /F /IM %ServiceFileName0%.exe >nul 2>nul
)
REM Check if Service is Running
call :FIND_SERVICE "%ServiceFullName1%"
if '%errorlevel%' == '1' ( 
	CALL :PROGRESS_BAR 8 "NOTA ... Parando o %ServiceFullName1%"
	Taskkill /F /IM %ServiceFileName1%.exe >nul 2>nul
)

REM ..............................................................................
CALL :PROGRESS_BAR 10 "Limpeza dos componentes do windows ... "
Dism.exe /online /Cleanup-Image /StartComponentCleanup >nul 2>nul 

:: disable and unistall all IIS features
call :IIS_DISABLE_UNISTALL_FEATURE

CALL :PROGRESS_BAR 95 "Excluindo configuracoes do IIS ... "

:: Set owner of all files to current user = Administrators
takeown /f "%WINDIR%\System32\inetsrv\config" /r /d y 2>NUL >NUL
:: Grant access to all files to Administrators
icacls "%WINDIR%\System32\inetsrv\config" /grant %Admin%:F /T 2>NUL >NUL
:: Set owner of WindowsApps back to Administrators
icacls "%WINDIR%\System32\inetsrv\config" /setowner %Admin% 2>NUL >NUL

:: Reconstruct administration.config
IF EXIST "%WINDIR%\system32\inetsrv\config\administration.config.clean.install" ( copy "%WINDIR%\system32\inetsrv\config\administration.config.clean.install" "%WINDIR%\system32\inetsrv\config\administration.config" /y >nul 2>nul )

:: Reconstruct applicationHost.config
IF EXIST "%WINDIR%\system32\inetsrv\config\applicationhost.config.clean.install" (
	copy "%WINDIR%\system32\inetsrv\config\applicationhost.config.clean.install" "%WINDIR%\system32\inetsrv\config\applicationhost.config" /y >nul 2>nul
) else (
	call :IIS_RECONSTRUCT_CONFIG_FILE1
)

:: Reconstruct redirection.config
IF EXIST "%WINDIR%\system32\inetsrv\config\redirection.config.clean.install" (
	copy "%WINDIR%\system32\inetsrv\config\redirection.config.clean.install" "%WINDIR%\system32\inetsrv\config\redirection.config" /y >nul 2>nul
) else (
	call :IIS_RECONSTRUCT_CONFIG_FILE0
)

:: Reconstruct appcmd.xml
call :IIS_RECONSTRUCT_CONFIG_FILE2

REM delete inetpub content
IF EXIST "%SystemDrive%\inetpub\%ProgramName0%\%ToolsName%.bat" (
	cd %SystemDrive%\inetpub\%ProgramName0% >nul 2>nul
	for %%i in (*) do if not "%%~i"=="%ToolsName%.bat" del /F/Q/S "%%~i" >nul 2>nul
	for /D %%p in ("*.*") do if not "%%~p"=="bin" rmdir "%%p" /s /q >nul 2>nul
	cd %SystemDrive%\inetpub\%ProgramName0%\bin >nul 2>nul
	for %%i in (*) do if not "%%~i"=="%SetACL%" del /F/Q/S "%%~i" >nul 2>nul
	cd..
	cd..
	for /D %%p in ("*.*") do if not "%%~p"=="%ProgramName0%" rmdir "%%p" /s /q >nul 2>nul
	for %%i in (*) do del /F/Q/S "%%~i" >nul 2>nul
	call :ICONS_DEL
)

REM reeboot is needed
CALL :PROGRESS_BAR 100 "Aguardando para reiniciar o computador ..."
shutdown.exe /r /t 5 >nul
PAUSE >nul
GOTO :EOF
























:: this is called by [%ToolsName% IISINSTALL] 
:IIS_INSTALL
MODE 80,4
SET "BarTitle=Utilitario instalador do IIS"
REM Prepare log install file for installSheld
set "LogInstall=%SystemDrive%\inetpub\%ProgramName0%\iisInstall.log"
if exist "%LogInstall%" ( del /q %LogInstall% >NUL 2>NUL )
echo [0] ... A inicializar >%LogInstall%
:: Check if it is connected to the internet
:: %SystemRoot%\system32\ping.exe -n 1 www.google.com >nul
:: if '%errorlevel%' == '1' (
:: 	CALL :PROGRESS_BAR 1 "ERRO ... sem ligacao a internet "
:: )

:: this is called by the PDVtool Menu
:IIS_INSTALL_
call :WRITE_LOG "♦ I - Instalar IIS e Framework"
cd \
cd %WINDIR%\system32
set "DoReboot=0"
rem IF EXIST "%LogFile%" ( del /q %LogFile% >NUL 2>NUL )

REM Check if IIS is Running
call :CHECK_IIS_RUNING
if '%errorlevel%' == '0' (
	call :MESSAGE_BAR_OR_HEADER 2 "Parando o Internet Information Service / IIS"
	NET STOP w3svc >>%LogFile% 2>>NUL
)

REM Stop the Service ...
call :MESSAGE_BAR_OR_HEADER 2 "Service Stop (Parar o %ServiceFullName0%)"
Taskkill /F /IM %ServiceFileName0%.exe >>%LogFile% 2>>NUL
TIMEOUT /t 4 /nobreak >>%LogFile% 2>>NUL
Taskkill /F /IM %ServiceFileName1%.exe >>%LogFile% 2>>NUL

REM change list Separator in windows for EXCEL to generate compatible CSV files 
REG ADD "HKEY_CURRENT_USER\Control Panel\International" /v sList /t REG_SZ /d ; /f 2>NUL >NUL

REM ..............................................................................
REM CALL :PROGRESS_BAR 5 "Limpeza dos componentes do Windows"
REM Dism.exe /online /Cleanup-Image /StartComponentCleanup >nul 2>nul

:: Disable non used features
call :MESSAGE_BAR_OR_HEADER 10 "Desativar funcionalidades do IIS "
call :DISABLE_FEATURE NetFx3 10	
call :DISABLE_FEATURE NetFx3ServerFeatures 11
call :DISABLE_FEATURE IIS-ManagementScriptingTools 12
call :DISABLE_FEATURE IIS-IIS6ManagementCompatibility 13
call :DISABLE_FEATURE IIS-Metabase 14
call :DISABLE_FEATURE IIS-HostableWebCore 15
call :DISABLE_FEATURE WCF-HTTP-Activation 16
call :DISABLE_FEATURE WCF-NonHTTP-Activation 17
call :DISABLE_FEATURE WCF-HTTP-Activation45 18
call :DISABLE_FEATURE WCF-TCP-Activation45 19
call :DISABLE_FEATURE WCF-Pipe-Activation45 20
call :DISABLE_FEATURE WCF-MSMQ-Activation45 21
call :DISABLE_FEATURE WCF-TCP-PortSharing45 22
call :DISABLE_FEATURE IIS-WebSockets 23
call :DISABLE_FEATURE IIS-ApplicationInit 24
call :DISABLE_FEATURE IIS-ASPNET 25
call :DISABLE_FEATURE IIS-CGI 26
call :DISABLE_FEATURE IIS-ServerSideIncludes 27
call :DISABLE_FEATURE IIS-ManagementService 28
call :DISABLE_FEATURE IIS-WMICompatibility 29
call :DISABLE_FEATURE IIS-LegacyScripts 30
call :DISABLE_FEATURE IIS-LegacySnapIn 31
call :DISABLE_FEATURE IIS-FTPServer 32
call :DISABLE_FEATURE IIS-FTPSvc 33
call :DISABLE_FEATURE IIS-FTPExtensibility 34
call :DISABLE_FEATURE IIS-CertProvider 35
call :DISABLE_FEATURE IIS-WindowsAuthentication 36
call :DISABLE_FEATURE IIS-DigestAuthentication 37
call :DISABLE_FEATURE IIS-ClientCertificateMappingAuthentication 38
call :DISABLE_FEATURE IIS-IISCertificateMappingAuthentication 39
call :DISABLE_FEATURE IIS-ODBCLogging 40
call :DISABLE_FEATURE IIS-IPSecurity 41
call :DISABLE_FEATURE IIS-URLAuthorization 42
call :DISABLE_FEATURE IIS-HttpCompressionDynamic 43
call :DISABLE_FEATURE IIS-Performance 44

:: ativar todas as funcionalidades do IIS e framework
call :MESSAGE_BAR_OR_HEADER 45 "Ativar IIS e .NET Framework"
call :ENABLE_FEATURE IIS-WebServerRole 45
call :ENABLE_FEATURE IIS-WebServer 46
call :ENABLE_FEATURE IIS-CommonHttpFeatures 47
call :ENABLE_FEATURE IIS-StaticContent 48
call :ENABLE_FEATURE IIS-DefaultDocument 49
call :ENABLE_FEATURE IIS-HttpErrors 50
call :ENABLE_FEATURE IIS-HttpRedirect 51
call :ENABLE_FEATURE IIS-ApplicationDevelopment 52
call :ENABLE_FEATURE NetFx4-AdvSrvs 53
call :ENABLE_FEATURE NetFx4Extended-ASPNET45 54
call :ENABLE_FEATURE IIS-NetFxExtensibility45 55
call :ENABLE_FEATURE IIS-ISAPIExtensions 56
call :ENABLE_FEATURE IIS-ISAPIFilter 57
call :ENABLE_FEATURE IIS-ASPNET45 58
call :ENABLE_FEATURE IIS-ASP 59
call :ENABLE_FEATURE IIS-HealthAndDiagnostics 60
call :ENABLE_FEATURE IIS-LoggingLibraries 61
call :ENABLE_FEATURE IIS-RequestMonitor 62
call :ENABLE_FEATURE IIS-HttpTracing 63
call :ENABLE_FEATURE IIS-Security 64
call :ENABLE_FEATURE IIS-BasicAuthentication 65
call :ENABLE_FEATURE IIS-RequestFiltering 66
call :ENABLE_FEATURE IIS-WebServerManagementTools 67
call :ENABLE_FEATURE IIS-ManagementConsole 68
:: ..............................................................................
:: Disable non used features
call :MESSAGE_BAR_OR_HEADER 69 "Desativar funcionalidades do IIS"
call :DISABLE_FEATURE IIS-DirectoryBrowsing 69
call :DISABLE_FEATURE WCF-Services45 70
call :DISABLE_FEATURE IIS-HttpLogging 71
call :DISABLE_FEATURE IIS-HttpCompressionStatic 72

call :MESSAGE_BAR_OR_HEADER 75 "Configurando IIS"
:: Start IIS so some of the instructions can Work
echo [75]Iniciando o IIS ... OK > %LogInstall%
echo %date% %time:~0,8% [75]Iniciando o IIS ... OK >>%LogFile%

NET START w3svc >>%LogFile% 2>>NUL

:: Delay for windows to rebboot
TIMEOUT /t 10 /nobreak >>%LogFile% 2>nul

echo [80]Configurando o IIS ... OK > %LogInstall%
echo %date% %time:~0,8% [80]Configurando o IIS ... OK >>%LogFile%

:: Configure Individual App Pool
%windir%\System32\inetsrv\appcmd.exe stop apppool "DefaultAppPool" >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe delete apppool ".NET v2.0 Classic" >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe delete apppool ".NET v2.0" >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe delete apppool "Classic .NET AppPool" >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe delete apppool ".NET v4.5" >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe delete apppool ".NET v4.5 Classic" >>%LogFile% 2>>NUL
echo [85]IIS AppPoll... OK > %LogInstall%
echo %date% %time:~0,8% [85]IIS AppPoll... OK >> %LogFile%

:: try to recover damaged %WINDIR%\system32\inetsrv\config\administration.config / remove unused modules 
%windir%\system32\inetsrv\appcmd.exe uninstall module CgiModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module FastCgiModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module ServerSideIncDISABLE_FEATUREludeModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module CustomLoggingModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module WindowsAuthenticationModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module DigestAuthenticationModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module CertificateMappingAuthenticationModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module IISCertificateMappingAuthenticationModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module UrlAuthorizationModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module IpRestrictionModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module DynamicIpRestrictionModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module DynamicCompressionModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module WebDAVModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module HttpLoggingModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module StaticCompressionModule >>%LogFile% 2>>NUL
%windir%\system32\inetsrv\appcmd.exe uninstall module DirectoryListingModule >>%LogFile% 2>>NUL
echo [90]IIS Modules... OK > %LogInstall%
echo %time%  %time:~0,8% [90]IIS Modules... OK >> %LogFile%

REM remove port 80 from Default Web Site
if '%Language%' == 'BR' (
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:"Default Web Site" /-bindings.[protocol='http',bindingInformation='*:80:'] >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:TimeReport /-bindings.[protocol='http',bindingInformation='*:80:'] >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:EmissorFiscal /-bindings.[protocol='http',bindingInformation='*:80:'] >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:EmissorFiscal /-bindings.[protocol='http',bindingInformation='*:8085:'] >>%LogFile% 2>>NUL
	REM Delete default web site 
	%windir%\system32\inetsrv\appcmd.exe delete site "Default Web Site" >>%LogFile% 2>>nul
	%windir%\system32\inetsrv\appcmd.exe delete AppPool ".NET v4.5" >>%LogFile% 2>>nul
	%windir%\system32\inetsrv\appcmd.exe delete AppPool ".NET v4.5 Classic" >>%LogFile% 2>>nul
	%windir%\system32\inetsrv\appcmd.exe delete AppPool "DefaultAppPool" >>%LogFile% 2>>nul
)

if exist "%SystemDrive%\inetpub\%ProgramName0%\" (
	REM Create the website for %ProgramName0%
	%windir%\system32\inetsrv\appcmd.exe add site /name:%ProgramName0% /physicalPath:%SystemDrive%\inetpub\%ProgramName0% /bindings:http/*:%HttpPort00%: >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /+bindings.[protocol='http',bindingInformation='*:%HttpPort00%:'] >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /+bindings.[protocol='http',bindingInformation='*:%HttpPort01%:'] >>%LogFile% 2>>NUL
	REM Setup App Pool/ fine tunning
	%windir%\system32\inetsrv\appcmd.exe add apppool /name:%ProgramName0% >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /[path='/'].applicationPool:%ProgramName0% >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set apppool /apppool.name:%ProgramName0% /managedRuntimeVersion:v4.0 >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set apppool %ProgramName0% /autoStart:true /startMode:AlwaysRunning >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].processModel.loadUserProfile:true" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='%ProgramName0%'].processModel.idleTimeout:00:00:00" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='%ProgramName0%'].processModel.maxProcesses:0" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.limit:80000" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.action:Throttle" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName0%'].cpu.resetInterval:00:01:00" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config "%ProgramName0%" /section:globalization /culture:pt-BR >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config "%ProgramName0%" /section:globalization /uiCulture:pt-BR >>%LogFile% 2>>NUL
	REM enable HTTP on default website
	%windir%\system32\inetsrv\appcmd.exe set app "%ProgramName0%/" /enabledProtocols:http >>%LogFile% 2>>NUL
	REM start default application tools and site
	%windir%\System32\inetsrv\appcmd.exe start apppool "%ProgramName0%">>%LogFile% 2>>NUL
	%windir%\System32\inetsrv\appcmd.exe start sites "%ProgramName0%">>%LogFile% 2>>NUL
)

if not exist "%SystemDrive%\inetpub\%ProgramName0%\" (
	REM Delete the website for %ProgramName1%
    %windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /-bindings.[protocol='http',bindingInformation='*:%HttpPort10%:'] >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /-bindings.[protocol='http',bindingInformation='*:%HttpPort11%:'] >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe delete apppool "%ProgramName0%" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe delete site "%ProgramName0%"
)

if exist "%SystemDrive%\inetpub\%ProgramName1%\" (
	REM Create the website for %ProgramName1%
	%windir%\system32\inetsrv\appcmd.exe add site /name:%ProgramName1% /physicalPath:%SystemDrive%\inetpub\%ProgramName1% /bindings:http/*:%HttpPort10%: >>%LogFile% 2>>NUL
    %windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName1% /+bindings.[protocol='http',bindingInformation='*:%HttpPort10%:'] >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName1% /+bindings.[protocol='http',bindingInformation='*:%HttpPort11%:'] >>%LogFile% 2>>NUL
	REM Setup App Pool/ fine tunning
	%windir%\system32\inetsrv\appcmd.exe add apppool /name:%ProgramName1% >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName1% /[path='/'].applicationPool:%ProgramName1% >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set apppool /apppool.name:%ProgramName1% /managedRuntimeVersion:v4.0 >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set apppool %ProgramName1% /autoStart:true /startMode:AlwaysRunning >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName1%'].processModel.loadUserProfile:true" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='%ProgramName1%'].processModel.idleTimeout:00:00:00" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='%ProgramName1%'].processModel.maxProcesses:0" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName1%'].cpu.limit:80000" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName1%'].cpu.action:Throttle" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config -section:applicationPools "/[name='%ProgramName1%'].cpu.resetInterval:00:01:00" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config "%ProgramName1%" /section:globalization /culture:pt-BR >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set config "%ProgramName1%" /section:globalization /uiCulture:pt-BR >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe add vdir /app.name:"%ProgramName1%/" /path:/Content /physicalPath:%SystemDrive%\inetpub\%ProgramName0%\Content >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe add vdir /app.name:"%ProgramName1%/" /path:/Orders /physicalPath:%SystemDrive%\inetpub\%ProgramName0%\Orders >>%LogFile% 2>>NUL
	REM enable HTTP on default website
	%windir%\system32\inetsrv\appcmd.exe set app "%ProgramName1%/" /enabledProtocols:http >>%LogFile% 2>>NUL
	REM start default application tools and site
	%windir%\System32\inetsrv\appcmd.exe start apppool "%ProgramName1%">>%LogFile% 2>>NUL
	%windir%\System32\inetsrv\appcmd.exe start sites "%ProgramName1%">>%LogFile% 2>>NUL
)

if not exist "%SystemDrive%\inetpub\%ProgramName1%\" (
	REM Delete the website for %ProgramName1%
    %windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName1% /-bindings.[protocol='http',bindingInformation='*:%HttpPort10%:'] >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName1% /-bindings.[protocol='http',bindingInformation='*:%HttpPort11%:'] >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe delete apppool "%ProgramName1%" >>%LogFile% 2>>NUL
	%windir%\system32\inetsrv\appcmd.exe delete site "%ProgramName1%"
)

REM Add port 80 to this new instalation 
if '%Language%' == 'BR' (
	%windir%\system32\inetsrv\appcmd.exe set site /site.name:%ProgramName0% /+bindings.[protocol='http',bindingInformation='*:80:'] >>%LogFile% 2>>NUL
)

echo [95]IIS reconfigurado ... OK > %LogInstall%
echo %date% %time:~0,8% [95]IIS reconfigurado ... OK >> %LogFile%

rem if called by external function do Exit now
if '%LogInstall%' == '%SystemDrive%\inetpub\%ProgramName0%\iisInstall.log' (
	if '%DoReboot%' == '1' (
		echo [100]Reboot necessario... > %LogInstall%
		CALL :PROGRESS_BAR 100 "Reboot necessario... OK"
	) else (
		echo [100]Concluido ... OK > %LogInstall%
		CALL :PROGRESS_BAR 100 "Concluido ..."
	)
) else (
	if '%DoReboot%' == '1' (	
		CALL :MESSAGE_HEADER "Aguardando para reiniciar o computador ..."
		shutdown.exe /r /t 5 >nul
		PAUSE >nul
	) else (
		CALL :MESSAGE_HEADER "Concluido ..."
	)
)

TIMEOUT /t 3 /nobreak 2>NUL >NUL
del /q %LogInstall% >NUL 2>NUL
TITLE Command Prompt && COLOR 7 && MODE 80,30 && cd %CurrentPath%
EXIT /b





:SQL_DETTACH
@echo OFF
mode 80,4
cd %WINDIR%\system32
set "BarTitle=SQL Dettach (Desagregar base de dados)"
call :WRITE_LOG "♦ D - SQL Dettach (Desagregar base de dados)"
REM ..............................................................................
REM TimeStudio...
call :PROGRESS_BAR 20 "SQL Dettach (TimeStudio)" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
IF EXIST "%SqlDataPath%\TimeStudio.mdf" ( "%SqlBinPath%\sqlcmd.exe" -S %UserDomain%\%SqlInstance% -Q "sp_detach_db 'TimeStudio'" )

REM TimeReport...
CALL :PROGRESS_BAR 40 "SQL Dettach (TimeReport)" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
IF EXIST "%SqlDataPath%\TimeReport.mdf" ( "%SqlBinPath%\sqlcmd.exe" -S %UserDomain%\%SqlInstance% -Q "sp_detach_db 'TimeReport'" )

REM Acronym...
CALL :PROGRESS_BAR 60 "SQL Dettach (Acronym)" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
IF EXIST "%SqlDataPath%\Acronym.mdf" ( "%SqlBinPath%\sqlcmd.exe" -S %UserDomain%\%SqlInstance% -Q "sp_detach_db 'Acronym'" )

REM EmissorFiscal...
CALL :PROGRESS_BAR 80 "SQL Dettach (EmissorFiscal)" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
IF EXIST "%SqlDataPath%\EmissorFiscal.mdf" ( "%SqlBinPath%\sqlcmd.exe" -S %UserDomain%\%SqlInstance% -Q "sp_detach_db 'EmissorFiscal'" )

CALL :PROGRESS_BAR 100 "SQL Dettached ... OK" 
PAUSE && EXIT /b




:SQL_ATTACH
@echo OFF
mode 80,4
cd %WINDIR%\system32
set "BarTitle=SQL Attach (Agregar base de dados)"
call :WRITE_LOG "♦ A - SQL Attach (Agregar base de dados)"
REM ..............................................................................
REM Time Studio...
call :PROGRESS_BAR 20 "SQL Attach (TimeStudio)" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
IF EXIST "%SqlDataPath%\TimeStudio.mdf" ( "%SqlBinPath%\sqlcmd.exe" -S %UserDomain%\%SqlInstance% -Q "CREATE DATABASE [TimeStudio] ON ( FILENAME = N'%SqlDataPath%\TimeStudio.mdf' ), ( FILENAME = N'%SqlDataPath%\TimeStudio_log.LDF' ) FOR ATTACH ;" )

REM TimeReport...
CALL :PROGRESS_BAR 40 "SQL Attach (TimeReport)" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
IF EXIST "%SqlDataPath%\TimeReport.mdf" ( "%SqlBinPath%\sqlcmd.exe" -S %UserDomain%\%SqlInstance% -Q "CREATE DATABASE [TimeReport] ON ( FILENAME = N'%SqlDataPath%\TimeReport.mdf' ), ( FILENAME = N'%SqlDataPath%\TimeReport_log.LDF' ) FOR ATTACH ;" )

REM Acronym...
CALL :PROGRESS_BAR 60 "SQL Attach (Acronym)" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
IF EXIST "%SqlDataPath%\Acronym.mdf" ( "%SqlBinPath%\sqlcmd.exe" -S %UserDomain%\%SqlInstance% -Q "CREATE DATABASE [Acronym] ON ( FILENAME = N'%SqlDataPath%\Acronym.mdf' ), ( FILENAME = N'%SqlDataPath%\Acronym_log.LDF' ) FOR ATTACH ;" )

REM EmissorFiscal...
CALL :PROGRESS_BAR 80 "SQL Attach (EmissorFiscal)" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
IF EXIST "%SqlDataPath%\EmissorFiscal.mdf" ( "%SqlBinPath%\sqlcmd.exe" -S %UserDomain%\%SqlInstance% -Q "CREATE DATABASE [EmissorFiscal] ON ( FILENAME = N'%SqlDataPath%\EmissorFiscal.mdf' ), ( FILENAME = N'%SqlDataPath%\EmissorFiscal_log.LDF' ) FOR ATTACH ;" )

CALL :PROGRESS_BAR 100 "SQL Attached ... OK" 
PAUSE && EXIT /b






:SQL_DELETEDB
@echo OFF
mode 80,4
cd %WINDIR%\system32
set "BarTitle=Excluir Bases de Dados"
call :WRITE_LOG "♦ 3 - Excluir Bases de Dados"
REM ..............................................................................
call :PROGRESS_BAR 20 "Parar Servicos SQL"
call :SQL_STOP_COMMANDS silent
REM .Excluir arquivos
call :PROGRESS_BAR 50 "Excluir pasta de dados" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
TIMEOUT /t 2 /nobreak 2>NUL >NUL
rmdir /s /q "%SqlDataPath%" >nul 2>nul
REM return to menu
call :PROGRESS_BAR 100 "Bases de Dados escluida ... OK" 
PAUSE && EXIT /b




:SQL_UNISTALL
@echo OFF
mode 80,4
cd %WINDIR%\system32
set "BarTitle=Microsoft SQL Server ..."
call :WRITE_LOG "♦ 5 - Desinstalar SQL Server"
REM ..............................................................................
call :PROGRESS_BAR 10 "Procurando por Microsoft SQL Server"
REM find all SQL programs
if exist "%keyFile%" ( del %keyFile% >nul 2>nul )
REM if [%PROCESSOR_ARCHITECTURE%] == [x86] ( 
	call :VBS_LIST_SQL_APPS
REM ) else (
REM	wmic product get description | findstr /C:"SQL" >>%keyFile% 2>nul
REM )
REM Unistall all SQL programs
if exist "%keyFile%" (
	for /F "usebackq delims=" %%A in ("%keyFile%") do (
		CALL :UNISTALL_WMIC "%%A" 20
	)
)

REM ..............................................................................
CALL :PROGRESS_BAR 25 "Desinstalar Microsoft SQL Server 2012 RsFx Driver" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
MsiExec.exe /X{DFB059F4-DBB2-497F-999E-AD86FA90E6DD} /qb >nul

CALL :PROGRESS_BAR 30 "Desinstalar SQL Server 2012 Common Files" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
MsiExec.exe /X{124D51A1-F3C2-45AE-B812-D3CA71247093} /qb >nul

CALL :PROGRESS_BAR 35 "Desinstalar SQL Server 2012 Common Files" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
MsiExec.exe /X{7D29ED63-84F9-4EC7-B49F-994A3A3195B2} /qb >nul

CALL :PROGRESS_BAR 40 "Desinstalar SQL Server 2012 Database Engine Services" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
MsiExec.exe /X{87D50333-E534-493A-8E98-0A49BC28F64B} /qb >nul

CALL :PROGRESS_BAR 45 "Desinstalar SQL Server 2012 Database Engine Shared" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
MsiExec.exe /X{54F84805-0116-467F-8713-899DFC472235} /qb >nul

CALL :PROGRESS_BAR 50 "Desinstalar Sql Server Customer Experience Improvement Program" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
MsiExec.exe /X{30CA21F2-901A-44DB-A43F-FC31CD0F2493} /qb >nul

CALL :PROGRESS_BAR 55 "Desinstalar SQL Server Browser for SQL Server 2012" && TIMEOUT /t 1 /nobreak 2>NUL >NUL
MsiExec.exe /X{4B9E6EB0-0EED-4E74-9479-F982C3254F71} /qb >nul

REM ..............................................................................
CALL :PROGRESS_BAR 60 "Desinstalar SQL"
IF EXIST "%SqlProgPath%\Microsoft SQL Server\90\Setup Bootstrap\ARPWrapper.exe" ( "%SqlProgPath%\Microsoft SQL Server\90\Setup Bootstrap\ARPWrapper.exe" /Remove)
IF EXIST "%SqlProgPath%\Microsoft SQL Server\110\Setup Bootstrap\SQLServer2012\setup.exe" ( "%SqlProgPath%\Microsoft SQL Server\110\Setup Bootstrap\SQLServer2012\setup.exe" /ACTION=UNINSTALL /FEATURES=Tools)
REM return to menu
CALL :PROGRESS_BAR 100 "SQL desinstalado ... OK" 
PAUSE && EXIT /b





:SCANFIXREBOOT
@echo OFF
mode 80,4
cd %WINDIR%\system32
set "BarTitle=Scan/Fix e Reboot ..."
call :WRITE_LOG "♦ 8 - Scan/Fix e Reboot"
REM ..............................................................................
call :PROGRESS_BAR 50 "Scan/Fix ..."
REM Scan/Fix e Reboot
sfc /scannow  >nul 2>nul
call :PROGRESS_BAR 100 "Concluido e Reboot ..."
pause
shutdown.exe /r /t 00  >nul 2>nul
REM return to menu
echo. && PAUSE && EXIT /b



:SQL_BACKUP
REM ..............................................................................
call :WRITE_LOG "♦ 8 - Copiar base de dados para Desktop"
CALL :MESSAGE_HEADER "Copiar base de dados %SqlInstance% para Desktop"
REM preparar nome da pasta
set _my_datafolder=%date%
set _my_datafolder=%_my_datafolder: =_%
set _my_datafolder=%_my_datafolder%_%time%
set _my_datafolder=%_my_datafolder: =0%
set _my_datafolder=%_my_datafolder::=%
set _my_datafolder=%_my_datafolder:/=%
set _my_datafolder=%_my_datafolder:~0,-3%
for /f "tokens=1 delims=." %%a in ("%_my_datafolder%") do (set _my_datafolder=DATA_%%a)
REM Parar servicos SQL
call :SQL_STOP_COMMANDS
REM Copiar arquivos
xcopy "%SqlDataPath%" "%temp%\%_my_datafolder%" /E /I
REM Iniciar servicos SQL
call :SQL_START_COMMANDS
REM compactar pasta
%BinPath%\7z a -aoa -mx=2 -mmt=on %UserDesktop%\%_my_datafolder%.zip %temp%\%_my_datafolder%\.
REM excluir pasta
rmdir "%temp%\%_my_datafolder%" /S /Q
REM Abrir pasta com arquivos
explorer %UserDesktop%\%_my_datafolder%.zip
REM return to main menu
echo. && timeout /t 3 /nobreak 2>nul >nul  && exit /b































:SQL_CLEAN
@ECHO OFF
MODE 80,4
SET "BarTitle=Utilitario de limpeza"
REM prepara Log file
SET "LogFile=%cd%\sqlclean.log"
rem IF EXIST "%LogFile%" ( del /q %LogFile% >nul 2>nul )


REM ..............................................................................
if exist [%SqlBinPath%\sqlcmd] (
	call :PROGRESS_BAR 2 "Copiar Base de dados"
	echo [2]Copiar BD %SystemDrive%\Backup > %LogFile%
	cd\ >nul 2>nul
	md Backup >nul 2>nul
	"%SqlBinPath%\sqlcmd" -S %UserDomain% -Q "BACKUP DATABASE EmissorFiscal TO DISK='C:\Backup\EmissorFiscal.bak' WITH INIT" >nul 2>nul
)

REM ..............................................................................
CALL :PROGRESS_BAR 4 "Parar Servicos SQL"
echo [4]Parar Servicos SQL >%LogFile%
CALL :SQL_STOP_COMMANDS silent >nul 2>nul

REM ..............................................................................
CALL :PROGRESS_BAR 6 "Excluir Servicos SQL"
echo [6]Excluir Servicos SQL >%LogFile%
sc delete MSSQL$%SqlInstance% >nul 2>nul
sc delete SQLAgent$%SqlInstance% >nul 2>nul
sc delete SQLBrowser >nul 2>nul
sc delete SQLWriter >nul 2>nul

REM ..............................................................................
CALL :PROGRESS_BAR 8 "Desinstalar SQL"
echo [8]Desinstalar SQL > %LogFile%
IF EXIST [%SqlProgPath%\Microsoft SQL Server\90\Setup Bootstrap\ARPWrapper.exe] ( "%SqlProgPath%\Microsoft SQL Server\90\Setup Bootstrap\ARPWrapper.exe" /Remove >nul 2>nul )
CALL :PROGRESS_BAR 16 "Desinstalar SQL"
IF EXIST [%SqlProgPath%\Microsoft SQL Server\110\Setup Bootstrap\SQLServer2012\setup.exe] ( "%SqlProgPath%\Microsoft SQL Server\110\Setup Bootstrap\SQLServer2012\setup.exe" /ACTION=UNINSTALL /FEATURES=Tools >nul 2>nul )

REM ..............................................................................
CALL :PROGRESS_BAR 20 "Procurando por Microsoft SQL Server"
echo [20]Procurando por Microsoft SQL Server > %LogFile%
REM find all SQL programs
if exist "%keyFile%" ( del %keyFile% >nul 2>nul )
REM if [%PROCESSOR_ARCHITECTURE%] == [x86] ( 
	call :VBS_LIST_SQL_APPS
REM ) else (
REM	wmic product get description | findstr /C:"SQL" >>%keyFile% 2>nul
REM )
REM Unistall all SQL programs
if exist "%keyFile%" (
	for /F "usebackq delims=" %%A in ("%keyFile%") do (
		CALL :UNISTALL_WMIC "%%A" 20
	)
)

REM .............................................................................
CALL :PROGRESS_BAR 29 "Excluir pastas e Arquivos SQL"
echo [29]Excluir pastas e Arquivos SQL > %LogFile%
IF EXIST "%ProgramFiles(x86)%\Microsoft SQL Server" ( rmdir "%ProgramFiles(x86)%\Microsoft SQL Server" /s /q >nul 2>nul )
IF EXIST "%ProgramFiles%\Microsoft SQL Server" ( rmdir "%ProgramFiles%\Microsoft SQL Server" /s /q >nul 2>nul )
CALL :PROGRESS_BAR 30 "Excluir pastas e Arquivos SQL"
IF EXIST "%ProgramFiles%\Common Files\Microsoft shared\SQL Debugging" ( rmdir "%ProgramFiles%\Common Files\Microsoft shared\SQL Debugging" /s /q >nul 2>nul )
IF EXIST "%ProgramFiles(x86)%\Common Files\Microsoft shared\SQL Debugging" ( rmdir "%ProgramFiles(x86)%\Common Files\Microsoft shared\SQL Debugging" /s /q >nul 2>nul )
del %SystemDrive%\Windows\SysWOW64\SQLServerManager.msc >nul 2>nul

REM 15% ..............................................................................
CALL :SQL_REG_DELETE

REM 60% ..............................................................................
CALL :PROGRESS_BAR 65 "Limpar imagem do Windows ..."
echo [65]Limpar imagem do Windows ... > %LogFile%
DISM.exe /Online /Cleanup-image /Restorehealth >nul 2>nul 

REM 80% ..............................................................................
CALL :PROGRESS_BAR 80 "Scan/Fix ..."
echo [80]Scan/Fix ... > %LogFile%
sfc /scannow >nul 2>nul 

REM 100%.............................................................................
CALL :PROGRESS_BAR 100 "Aguardando para reiniciar o computador ..."
echo [100]Reboot necessario... > %LogFile%
TIMEOUT /t 2 /nobreak 2>NUL >NUL
rem del /q %LogFile% >NUL 2>NUL
shutdown.exe /r /t 10
cls
GOTO EOF





:UNISTALL_WMIC
setlocal EnableDelayedExpansion 2>nul >nul
set str=%1 2>nul >nul
set str=!str:~1,-1! 2>nul >nul
for /l %%a in (1,1,125) do if "!str:~-1!"==" " set str=!str:~0,-1! 2>nul >nul
IF NOT "%2"=="0" (
	CALL :PROGRESS_BAR %2 "Desinstalando !str!"
)
wmic product where "description='!str!'" uninstall >nul 2>nul
endlocal
EXIT /B 0





:SQL_BACKUP_AUTO
@ECHO OFF
REM ............................................................................
MODE 80,4
set Script=%temp%\backupSql.sql
set backupName=EmissorFiscal_%date%.bak
set backupName=%backupName:/=_%

SET "BarTitle=Backup Base Dados"..

IF EXIST "%2\%backupName%" ( 
	del /q %2\%backupName% 2>NUL >NUL 
	call :PROGRESS_BAR 10 "Excluindo %backupName%"
	TIMEOUT /t 1 /nobreak 2>NUL >NUL
) else (
	md %2 >nul 2>nul
)
REM ..............................................................................
CALL :PROGRESS_BAR 20 "Backup da Base de dados..."
rem "%SqlBinPath%\sqlcmd" -S %UserDomain% -Q "BACKUP DATABASE EmissorFiscal TO DISK = '%2\EmissorFiscal.bak' WITH INIT" 2>NUL >NUL

ECHO DECLARE @pathName NVARCHAR(512)  > "%Script%"
ECHO SET @pathName = '%2\%backupName%'  >> "%Script%"
ECHO BACKUP DATABASE [EmissorFiscal] TO DISK = @pathName WITH NOFORMAT, NOINIT, NAME = N'db_backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10 >> "%Script%"
"%SqlBinPath%\sqlcmd" -S localhost -U sa -P Acronym_2015 -i "%Script%" 2>NUL >NUL
del /q %Script% 2>NUL >NUL 

REM ..............................................................................
IF EXIST "%2\%backupName%" ( 
	CALL :PROGRESS_BAR 100 "OK ... Backup concluido."
	TIMEOUT /t 1 /nobreak 2>NUL >NUL
) else (
	CALL :PROGRESS_BAR 20 "ERRO! ... "
	TIMEOUT /t 1 /nobreak 2>NUL >NUL
)
REM .............................................................................
GOTO :END_OF_FILE






:SQL_RESTORE_AUTO
@ECHO OFF
MODE 80,4
set CurrentPath=%cd%
SET "BarTitle=Restaurar Base Dados"
REM ..............................................................................
REM Chekc if file exists 
IF NOT EXIST "%2\EmissorFiscal.bak" (
	CALL :PROGRESS_BAR 10 "ERRO! Arquivo %2\EmissorFiscal.bak nao foi localizado!"
	TIMEOUT /t 1 /nobreak 2>NUL >NUL
	GOTO :END_OF_FILE
)
REM ..............................................................................
REM Stop SQL engine
CALL :PROGRESS_BAR 20 "A desligar Base de Dados! "
CALL :SQL_STOP_COMMANDS silent
REM ..............................................................................
CALL :PROGRESS_BAR 30 "Copia seguranca da Base de Dados atual. "
TIMEOUT /t 1 /nobreak 2>NUL >NUL
CD %SqlDataPath%
IF EXIST "EmissorFiscal_log.ldf" ( 
	DEL /s /q EmissorFiscal_log.bk 2>NUL >NUL
	RENAME EmissorFiscal_log.ldf EmissorFiscal_log.bk 2>NUL >NUL
)
IF EXIST "EmissorFiscal.mdf" (
	DEL /s /q EmissorFiscal.bk 2>NUL >NUL
	RENAME EmissorFiscal.mdf EmissorFiscal.bk 2>NUL >NUL
)
REM .............................................................................
REM Start SQL engine
CALL :PROGRESS_BAR 40 "A desligar Base de Dados! "
CALL :SQL_START_COMMANDS silent
REM .............................................................................
REM restore data base 
CALL :PROGRESS_BAR 50 "Restaurar Base de Dados! "
CD %SqlBinPath%
SQLCMD -S %UserDomain% -Q "RESTORE DATABASE [EmissorFiscal] FROM DISK = N'%2\EmissorFiscal.bak' WITH FILE = 1, MOVE N'EmissorFiscal' TO N'%SqlDataPath%\EmissorFiscal.mdf', MOVE N'EmissorFiscal_log' TO N'%SqlDataPath%\EmissorFiscal_log.ldf', NOUNLOAD" 2>NUL >NUL
REM .............................................................................
CALL :PROGRESS_BAR 100 "OK ... Restauro concluido."
TIMEOUT /t 1 /nobreak 2>NUL >NUL
REM .............................................................................
GOTO :END_OF_FILE




:SQL_STOP_COMMANDS
if "%~1"=="" (
	SC QUERY "MSSQL$%SqlInstance%" | FINDSTR "RUNNING"
	if "%errorlevel%"=="0" ( net stop MSSQL$%SqlInstance% )
	SC QUERY "SQLAgent$%SqlInstance%" | FINDSTR "RUNNING"
	if "%errorlevel%"=="0" ( net stop SQLAgent$%SqlInstance% )
	SC QUERY "SQLBrowser" | FINDSTR "RUNNING"
	if "%errorlevel%"=="0" ( net stop SQLBrowser )
	SC QUERY "SQLWriter" | FINDSTR "RUNNING"
	if "%errorlevel%"=="0" ( net stop SQLWriter )
) else (
	SC QUERY "MSSQL$%SqlInstance%" | FINDSTR "RUNNING" >nul 2>nul
	if "%errorlevel%"=="0" ( net stop MSSQL$%SqlInstance% >nul 2>nul )
	SC QUERY "SQLAgent$%SqlInstance%" | FINDSTR "RUNNING" >nul 2>nul
	if "%errorlevel%"=="0" ( net stop SQLAgent$%SqlInstance% >nul 2>nul )
	SC QUERY "SQLBrowser" | FINDSTR "RUNNING" >nul 2>nul
	if "%errorlevel%"=="0" ( net stop SQLBrowser >nul 2>nul )
	SC QUERY "SQLWriter" | FINDSTR "RUNNING" >nul 2>nul
	if "%errorlevel%"=="0" ( net stop SQLWriter >nul 2>nul )
)
EXIT /b




:SQL_START_COMMANDS

IF "%~1"=="" (
	SC QUERY "MSSQL$%SqlInstance%" | FINDSTR "STOPPED"
	IF "%errorlevel%"=="0" ( net start MSSQL$%SqlInstance% )

) ELSE (
	SC QUERY "MSSQL$%SqlInstance%" | FINDSTR "STOPPED"
	IF "%errorlevel%"=="0" ( net start MSSQL$%SqlInstance% ) >nul 2>nul )
)
EXIT /b











REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################
REM #######################################################################################################################




REM delets Register keys  option to show progress bar
:SQL_REG_DELETE 

SET "BarTitle=Utilitario de limpeza"
REM Start auxiliary files 
del %keyFile% >nul 2>nul

REM .........................................................................................................................
REM Get Product key number and store them in %temp%\temp.txt
CALL :PROGRESS_BAR 31 "Obter chaves do Produto"
echo [31]Obter Chaves do Produto > %LogFile%
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\ /f "Microsoft SQL Server" /s /d 2>nul | FINDSTR "REG_SZ" >%keyFile% 2>nul

REM clean %keyFile% , leaving only the keys
call :CLEAN_KEYFILE_1
copy %keyFile% %temp%\temp.txt >nul 2>nul

REM Get all product keys in HKEY_CLASSES_ROOT 
CALL :PROGRESS_BAR 33 "Excluir Chaves do Produto"
del %keyFile% >nul 2>nul
setlocal enabledelayedexpansion
if exist "%temp%\temp.txt" (
	for /F "usebackq delims=" %%A in ("%temp%\temp.txt") do (
		REG QUERY HKEY_CLASSES_ROOT\Installer\ /f "%%A" /s /k 2>nul | FINDSTR "HKEY_" >>%keyFile%
	)
)
endlocal

REM Get all product keys in HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer
setlocal enabledelayedexpansion
if exist "%temp%\temp.txt" (
	for /F "usebackq delims=" %%A in ("%temp%\temp.txt") do (
		REG HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer /f "%%A" /s /k 2>nul | FINDSTR "HKEY_" >>%keyFile%
	)
)
endlocal

REM Get all product keys in HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\
setlocal enabledelayedexpansion
if exist "%temp%\temp.txt" (
	for /F "usebackq delims=" %%A in ("%temp%\temp.txt") do (
		REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\ /f "%%A" /s /k 2>nul | FINDSTR "HKEY_" >>%keyFile%
	)
)
endlocal

REM Get all product keys in HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\
setlocal enabledelayedexpansion
if exist "%temp%\temp.txt" (
	for /F "usebackq delims=" %%A in ("%temp%\temp.txt") do (
		REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\ /f "%%A" /s /k 2>nul | FINDSTR "HKEY_" >>%keyFile%
	)
)
endlocal

REM Get all product keys in HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\UpgradeCodes\
setlocal enabledelayedexpansion
if exist "%temp%\temp.txt" (
	for /F "usebackq delims=" %%A in ("%temp%\temp.txt") do (
		REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\ /f "%%A" /s /k 2>nul | FINDSTR "HKEY_" >>%keyFile%
	)
)
endlocal

REM Get all product keys in QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\
setlocal enabledelayedexpansion
if exist "%temp%\temp.txt" (
	for /F "usebackq delims=" %%A in ("%temp%\temp.txt") do (
		REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\ /f "%%A" /s 2>nul | FINDSTR "HKEY_" >>%keyFile%
	)
)
endlocal

del %temp%\temp.txt >nul 2>nul
CALL :DELETE_KEYS_

REM .........................................................................................................................
CALL :PROGRESS_BAR 39 "Excluir Chaves HKLM\SYSTEM\Setup\FirstBoot\Services"
REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\Setup\FirstBoot\Services\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
CALL :DELETE_KEYS

REM CLSID keys 
CALL :PROGRESS_BAR 39 "Excluir Chaves CLSID"
echo [39]Excluir Chaves CLSID > %LogFile%
REG QUERY HKEY_CLASSES_ROOT\CLSID\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY HKEY_CLASSES_ROOT\WOW6432Node\CLSID\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Classes\WOW6432Node\CLSID\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
CALL :DELETE_KEYS

REM Interface keys 
CALL :PROGRESS_BAR 41 "Excluir chaves de Interface"
echo [41]Excluir chaves de Interface > %LogFile%
REG QUERY HKEY_CLASSES_ROOT\Interface\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY HKEY_CLASSES_ROOT\WOW6432Node\Interface\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Classes\WOW6432Node\Interface\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
CALL :DELETE_KEYS

REM Dependencies keys 
CALL :PROGRESS_BAR 43 "Excluir chaves dependencias"
echo [43]Excluir chaves dependencias > %LogFile%
REG QUERY HKEY_CLASSES_ROOT\Installer\Dependencies\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Dependencies\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
REM Dependencies Products 
REG QUERY HKEY_CLASSES_ROOT\Installer\Products\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Products\ /f "SQL" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
CALL :DELETE_KEYS

REM Miscellaneous Keys
CALL :PROGRESS_BAR 45 "Excluir chaves diversas"
echo [45]Excluir chaves diversas > %LogFile%
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\REGISTRY\MACHINE\Software\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\ /f "SQL Server" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\ /f "SQL Server" /s /d 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RADAR\HeapLeakDetection\DiagnosedApplications\ /f "SQL" /k 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing" /f "SQL" /s /k 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /f "SQL" /k /s 2>nul | FINDSTR "HKEY_" | FINDSTR /V "NET" >>%keyFile%
REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft" /f "SQL" /k /s 2>nul | FINDSTR "HKEY_" | FINDSTR /V "NET" | FINDSTR /V "SideBySide" | FINDSTR /V "Office"  >>%keyFile%
CALL :DELETE_KEYS

REM .........................................................................................................................
REM Classes
REM REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Classes\ /f "SQL" /k | FINDSTR "HKEY_" >>%keyFile%
REM Classes
REM QUERY HKEY_CLASSES_ROOT /f "SQL" /k | FINDSTR "HKEY_" >>%keyFile%

REM Classes
CALL :PROGRESS_BAR 47 "Excluir em HKCR e HKLM\SOFTWARE\Classes\"
echo [47]Excluir em HKCR e HKLM\SOFTWARE\Classes\ > %LogFile%
CALL :REG_QUERY_CLASSES "SQLLITE"
CALL :REG_QUERY_CLASSES "MSDASQL"
CALL :REG_QUERY_CLASSES "MSDASQLEnumerator"
CALL :REG_QUERY_CLASSES "SQLOLEDB"
CALL :REG_QUERY_CLASSES "SQLXMLX"
CALL :REG_QUERY_CLASSES "SqlClient"
CALL :DELETE_KEYS

REM SQL 2008 Classes
CALL :PROGRESS_BAR 49 "Excluir chaves SQL 2008"
echo [49]Excluir chaves SQL 2008 > %LogFile%
CALL :REG_QUERY_CLASSES "SqlServer"
CALL :REG_QUERY_CLASSES "SQLDistribution"
CALL :REG_QUERY_CLASSES "SQLiteManager"
CALL :REG_QUERY_CLASSES "SQLManager"
CALL :REG_QUERY_CLASSES "SQLMerge"
CALL :REG_QUERY_CLASSES "SQLNCLI11"
CALL :REG_QUERY_CLASSES "SQLReplError"
CALL :REG_QUERY_CLASSES "SQLReplErrors"
CALL :REG_QUERY_CLASSES "SqlServerLogShipping"
CALL :REG_QUERY_CLASSES "SqlServerReplication"
CALL :REG_QUERY_CLASSES "SQLTaskConnections"
CALL :REG_QUERY_CLASSES "sqlwep110"
CALL :REG_QUERY_CLASSES "SQLActiveScriptHost"
CALL :REG_QUERY_CLASSES "SQLDMO"
CALL :REG_QUERY_CLASSES "sqlwep"
CALL :REG_QUERY_CLASSES "Microsoft SQL"
CALL :DELETE_KEYS

REM Miscellaneous unique Keys
@echo HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Acronym>>%keyFile%
@echo HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Aclogik>>%keyFile%
@echo HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Acronym\BasesDadosSQL\%ProgramName0%>>%keyFile%

CALL :DELETE_KEYS

REM .........................................................................................................................
REM initialize key file
if exist "%keyFile%" ( del /q %keyFile% )

CALL :PROGRESS_BAR 53 "Excluir chaves ..."
echo [53]Excluir chaves ... > %LogFile%
REG QUERY "HKEY_CLASSES_ROOT\Installer\Assemblies\Global" /f "SqlServer" /t REG_MULTI_SZ 2>nul | FINDSTR "REG_MULTI_SZ" >>%keyFile%
CALL :CLEAN_FILE_REG_MULTI_SZ
CALL :REG_DEL_KEY_VALUES "HKEY_CLASSES_ROOT\Installer\Assemblies\Global"

REM CALL :PROGRESS_BAR 54 "Excluir chaves ..."
REM REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders" 2>nul | FINDSTR "SQL" >>%keyFile%
REM CALL :CLEAN_KEYFILE_REG_SZ
REM CALL :REG_DEL_KEY_VALUES "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders"

CALL :PROGRESS_BAR 55 "Excluir chaves ..."
echo [55]Excluir chaves ... > %LogFile%
REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components" /f "Microsoft SQL" /s | FINDSTR "HKEY_LOCAL_MACHINE" 2>nul >>%keyFile%
CALL :DELETE_KEYS

CALL :PROGRESS_BAR 56 "Excluir chaves ..."
echo [56]Excluir chaves ... > %LogFile%
REG QUERY "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" /f "Microsoft SQL" /t REG_SZ 2>nul | FINDSTR "REG_SZ" >>%keyFile%
CALL :CLEAN_KEYFILE_REG_SZ
CALL :REG_DEL_KEY_VALUES "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths"

CALL :PROGRESS_BAR 57 "Excluir chaves ..."
echo [57]Excluir chaves ... > %LogFile%
REG QUERY "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\UFH\SHC" /f "Microsoft SQL" /t REG_MULTI_SZ 2>nul | FINDSTR "REG_MULTI_SZ" >>%keyFile%
CALL :CLEAN_FILE_REG_MULTI_SZ
CALL :REG_DEL_KEY_VALUES "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\UFH\SHC"

CALL :PROGRESS_BAR 58 "Excluir chaves ..."
echo [58]Excluir chaves ... > %LogFile%
REG QUERY "HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store" /f "Microsoft SQL" /t REG_BINARY 2>nul | FINDSTR "REG_BINARY" >>%keyFile%
call :CLEAN_FILE_REG_BINARY
CALL :REG_DEL_KEY_VALUES "HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store"

CALL :PROGRESS_BAR 59 "Excluir chaves ..."
echo [59]Excluir chaves ... > %LogFile%
REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Assemblies\Global" /f "SqlServer" /t REG_MULTI_SZ 2>nul | FINDSTR "REG_MULTI_SZ" >>%keyFile%
CALL :CLEAN_FILE_REG_MULTI_SZ
CALL :REG_DEL_KEY_VALUES "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Assemblies\Global"

CALL :PROGRESS_BAR 60 "Excluir chaves ..."
echo [60]Excluir chaves ... > %LogFile%
REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Fusion\GACChangeNotification\Default" /f "Microsoft.SqlServer" /t REG_BINARY 2>nul | FINDSTR "REG_BINARY" >>%keyFile%
call :CLEAN_FILE_REG_BINARY
CALL :REG_DEL_KEY_VALUES "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Fusion\GACChangeNotification\Default"

CALL :PROGRESS_BAR 60 "Excluir chaves ..."
REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\bam\State\UserSettings\S-1-5-21-4064423456-240537014-2333259987-1001" /f "SQL" /t REG_BINARY 2>nul | FINDSTR "REG_BINARY" >>%keyFile%
call :CLEAN_FILE_REG_BINARY
CALL :REG_DEL_KEY_VALUES "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\bam\State\UserSettings\S-1-5-21-4064423456-240537014-2333259987-1001"

CALL :PROGRESS_BAR 62 "Excluir chaves ..."
echo [62]Excluir chaves ... > %LogFile%

REM .........................................................................................................................
REM find keys 
REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /f "Microsoft SQL" /s /t REG_SZ 2>nul | FINDSTR "HKEY_LOCAL_MACHINE" >>%keyFile%
copy %keyFile% %temp%\temp_.txt >nul 2>nul
CALL :DELETE_KEYS
copy %temp%\temp_.txt %keyFile% >nul 2>nul

REM CALL :PROGRESS_BAR 63 "Excluir chaves ..."
REM call :CLEAN_KEYFILE_HEX
REM copy %keyFile% %temp%\temp_.txt >nul 2>nul
REM Get ande delete keys 
REM del %keyFile% >nul 2>nul
REM REM setlocal enabledelayedexpansion
REM if exist "%temp%\temp_.txt" (
REM 	for /F "usebackq delims=" %%A in ("%temp%\temp_.txt") do (
REM 	REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders" /f "%%A" /t REG_SZ 2>nul | FINDSTR "REG_SZ"  >>%keyFile%
REM 	)
REM )
REM if exist "%keyFile%" (
REM 	CALL :CLEAN_KEYFILE_REG_SZ
REM 	CALL :REG_DEL_KEY_VALUES "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders"
REM )
REM endlocal


CALL :PROGRESS_BAR 64 "Excluir chaves ..."
echo [64]Excluir chaves ... > %LogFile%
REM Get ande delete keys
del %keyFile% >nul 2>nul
setlocal enabledelayedexpansion
if exist "%temp%\temp_.txt" (
	for /F "usebackq delims=" %%A in ("%temp%\temp_.txt") do (
		REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\UFH\ARP" /f "%%A" /t REG_MULTI_SZ 2>nul | FINDSTR "REG_MULTI_SZ"  >>%keyFile%
	)
)
if exist "%keyFile%" (
	CALL :CLEAN_FILE_REG_MULTI_SZ
	CALL :REG_DEL_KEY_VALUES "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\UFH\ARP"
)
endlocal

REM .........................................................................................................................
del %keyFile% >nul 2>nul
EXIT /b



:REG_SET_OWNER
REM ..## implement variable Administrator name 
%SetACL_x% -on "%~1" -ot reg -actn setowner -ownr "n:%Admin%" -rec cont >nul 2>nul
%SetACL_x% -on "%~1" -ot reg -actn ace -ace "n:%Admin%;p:full" -rec cont >nul 2>nul
%SetACL_x% -on "%~1" -ot reg -actn setowner -ownr "n:Administradores" -rec cont >nul 2>nul
%SetACL_x% -on "%~1" -ot reg -actn ace -ace "n:Administradores;p:full" -rec cont >nul 2>nul
EXIT /b




:REG_DEL_KEY_VALUES
%SetACL_x% -on "%~1" -ot reg -actn setowner -ownr "n:%Admin%" -rec cont >nul 2>nul
%SetACL_x% -on "%~1" -ot reg -actn ace -ace "n:%Admin%;p:full" -rec cont >nul 2>nul

if exist "%keyFile%" (
	for /F "usebackq delims=" %%A in ("%keyFile%") do (
	REG DELETE "%~1" /V %%A /F >nul 2>nul
	REG DELETE "%~1" /V "%%A" /F >nul 2>nul
	CALL :WRITE_LOG "Delete Value: %%~A"
	)
	del /q %keyFile%
)
EXIT /b




:REG_QUERY_CLASSES
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Classes\ /f "%~1" /k 2>nul | FINDSTR "HKEY_" >>%keyFile%
REG QUERY HKEY_CLASSES_ROOT /f "%~1" /k 2>nul | FINDSTR "HKEY_" >>%keyFile%
EXIT /b


:DELETE_KEYS 
REM unlock register keys
if exist "%keyFile%" (
	for /F "usebackq delims=" %%A in ("%keyFile%") do (
		CALL :WRITE_LOG "Delete Key: %%~A"
		%SetACL_x% -on "%%~A" -ot reg -actn setowner -ownr "n:%Admin%" -rec cont >nul 2>nul
		%SetACL_x% -on "%%~A" -ot reg -actn ace -ace "n:%Admin%;p:full" -rec cont >nul 2>nul
	)
)
:DELETE_KEYS_
REM Delete register keys
if exist "%keyFile%" (
	for /F "usebackq delims=" %%A in ("%keyFile%") do ( REG DELETE "%%~A" /f >nul 2>nul )
)
REM Delete Keys file
del %keyFile% >nul 2>nul
REM Wait 1 second
timeout /t 1 /nobreak >nul
EXIT /b









:W10_RESTORE
@ECHO OFF
MODE 80,4
CD %WINDIR%\system32
SET "BarTitle=Restauro do Windows"
TITLE %BarTitle%


REM .............................................................................. 
call :MESSAGE_ATENCTION "O Windows vai ser modificado de forma irreversivel."

REM Select program icon statup mode
SET /P M=Continuar ? S (Sim) ou N (Nao) seguido de ENTER:
IF /I %M%==S GOTO W10RESTORE0
IF /I %M%==N CLS && EXIT /b
GOTO W10_RESTORE
:W10RESTORE0

REM ..............................................................................
REM Check if Windows 10 
if not "%WinVersion%" == "10.0" (
	CALL :PROGRESS_BAR 100 "ERRO ... Funconalidade disponivel apenas para Windows 10 !"
	TIMEOUT /t 10 /nobreak 2>NUL >NUL
	TITLE Command Prompt && COLOR 7 && MODE 80,30 && cd %CurrentPath%
	EXIT /b
)

REM ..............................................................................
CALL :PROGRESS_BAR 10 "Reativar funcionalidades Basicas"
REM Enable explorer
REM call :REG_SET_OWNER "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
REM REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f >nul 2>nul
REM Disable Auto Start of the program
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v %ProgramName0% /f 2>NUL >NUL
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v KillExplorer /f 2>NUL >NUL

REM Ativar Windows Update
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows\AU" /f 2>NUL >NUL
REM Ativar Antimalware Service Executable"
SC config "MsMpSvc" start= enabled 2>NUL >NUL
REM ..............................................................................
REM turn Firewall on
NetSh Advfirewall set allprofiles state on 2>NUL >NUL
REM ..............................................................................
REM enable windows defender 
call :REG_SET_OWNER "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender"
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 0 /f >nul 2>nul
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 0 /f >nul 2>nul
REM ..............................................................................
REM enable SecurityHealthService
call :REG_SET_OWNER "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SecurityHealthService"
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v Start /t REG_DWORD /d 2 /f 2>NUL >NUL
REM ..............................................................................
REM enable SecurityHealthService
call :REG_SET_OWNER "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 1 /f 2>NUL >NUL
TIMEOUT /T 3 /NOBREAK 2>NUL >NUL

REM ..............................................................................
CALL :PROGRESS_BAR 30 "Reconfigurar Task Bar"
REM Hide task bar 
REG DELETE "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAutoHideInTabletMode /f 2>NUL >NUL
REM Remove Task view button
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 1 /f 2>NUL >NUL
REM custom Explorer.exe setings 
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableStartMenu /t REG_DWORD /d 1 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarSmallIcons /t REG_DWORD /d 0 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowStatusBar /t REG_DWORD /d 1 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowInfoTip /t REG_DWORD /d 1 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f 2>NUL >NUL
rem Hide All Notification Icons in Tablet Mode
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V UseTabletModeNotificationIcons /F 2>NUL >NUL
REM Dont hide desktop icon
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideIcons /t REG_DWORD /d 0 /f 2>NUL >NUL
REM Turn OFF Always show all icons in the notification area
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v EnableAutoTray /f 2>NUL >NUL
REG DELETE "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer" /v EnableAutoTray /f 2>NUL >NUL
REM To Disable "Always show all icons in the notification area" for All Users
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V NoAutoTrayNotify /F 2>NUL >NUL
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V NoAutoTrayNotify /F 2>NUL >NUL
REM Disable Active Desktop
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoActiveDesktop /F 2>NUL >NUL
REG DELETE "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoActiveDesktop /F 2>NUL >NUL
REM Enabble the Clock Icon
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V HideClock /F 2>NUL >NUL
REM Disable the Network Icon
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V HideSCANetwork /F 2>NUL >NUL
REM Disable the Power (battery) Icon
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V HideSCAPower /F 2>NUL >NUL
REM Disable the Volume Icon
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V HideSCAVolume /F 2>NUL >NUL
REM Disable notification center 
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /F 2>NUL >NUL

REM Reset and Clear Taskbar Toolbars in Windows 10
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams\Desktop" /V TaskbarWinXP /F 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams\Desktop" /v TaskbarWinXP /t REG_BINARY /d 0c000000080000000100000000000000aa4f2868486ad0118c7800c04fd918b400000000400d0000000000002400000000000000000000003e0000000000000001000000 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /F 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband\AuxilliaryPins" /F 2>NUL >NUL

TIMEOUT /T 2 /NOBREAK 2>NUL >NUL

REM ..............................................................................
if exist %WINDIR%\SystemApps\Emissor.changed GOTO :W10RESTORE1
goto :W10RESTORE2
:W10RESTORE1
CALL :PROGRESS_BAR 60 "Restaurar aplicativos do Windows"
REM Set owner of all files to current user = Administrators
takeown /f "%WINDIR%\SystemApps" /r /d y 2>NUL >NUL
REM Grant access to all files to Administrators
icacls "%WINDIR%\SystemApps" /grant %Admin%:F /T 2>NUL >NUL
REM Set owner of WindowsApps back to Administrators
icacls "%WINDIR%\SystemApps" /setowner %Admin% 2>NUL >NUL
REM SystemApps 
cd \
cd %WINDIR%\SystemApps 2>NUL >NUL
REM Rename menu SystemApps 
for /d %%i in (_ShellExperienceHost_*) do CALL :REMOVE_1ST_CHR %%i  2>NUL >NUL
REM remove tag to signal that windows was changed
del /q "Emissor.changed" 2>NUL >NUL
REM set ownership back to Admin
icacls "%WINDIR%\SystemApps" /setowner "%sysAdmin%" 2>NUL >NUL
:W10RESTORE2
REM ..............................................................................
CALL :PROGRESS_BAR 100 "Aguardando para reiniciar o computador ..."
shutdown.exe /r /t 10 2>NUL >NUL
PAUSE  2>NUL >NUL
GOTO :EOF


























:W10_CLEAN
@ECHO OFF
MODE 80,4
CD %WINDIR%\system32
SET "BarTitle=Optimizacao do Windows"
TITLE %BarTitle%

REM ..............................................................................
REM alerta 
call :MESSAGE_ATENCTION "O Windows vai ser modificado de forma irreversivel."

REM Select the program icon statup mode
SET /P M=Continuar ? S (Sim) ou N (Nao) seguido de ENTER:
IF /I %M%==S GOTO W10CLEAN0
IF /I %M%==N CLS && EXIT /b
GOTO W10_CLEAN
:W10CLEAN0
REM ..............................................................................
REM Check if Windows 10 
if not "%WinVersion%" == "10.0" (
	CALL :PROGRESS_BAR 100 "ERRO ... Funconalidade disponivel apenas para Windows 10 !"
	TIMEOUT /t 10 /nobreak 2>NUL >NUL
	TITLE Command Prompt && COLOR 7 && MODE 80,30 && cd %CurrentPath%
	EXIT /b
)
REM ..............................................................................
REM Clean space in disk for windows 10 / 32bits
if [%PROCESSOR_ARCHITECTURE%] == [x86] ( 
	CALL :PROGRESS_BAR 5 "Liberando espaco no W10 / 32bit!"
	rmdir "%SystemDrive%\windows\Installer" /s /q >nul 2>nul
	rmdir "%SystemDrive%\windows\SoftwareDistribution\Download" /s /q >nul 2>nul
	rmdir "%SystemDrive%\ProgramData\Adobe\Setup" /s /q >nul 2>nul
)
REM ..............................................................................
REM check if IIS is instaled
FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq w3wp.exe"') DO IF NOT %%x==w3wp.exe (
	CALL :PROGRESS_BAR 100 "ERRO ... O IIS nao esta instalado !"
	TIMEOUT /t 10 /nobreak 2>NUL >NUL
	TITLE Command Prompt && COLOR 7 && MODE 80,30 && cd %CurrentPath%
	EXIT /b
)
REM Check if SQL is running
call :TEST_SERVICE MSSQL$%SqlInstance%
if '%errorlevel%' == '1' (
	CALL :PROGRESS_BAR 100 "ERRO ... SQL Instance %SqlInstance% nao foi detetada !"
	TIMEOUT /t 10 /nobreak 2>NUL >NUL
	TITLE Command Prompt && COLOR 7 && MODE 80,30 && cd %CurrentPath%
	EXIT /b
)
REM Check if Chrome is instaled 
call :GET_CHROME_PATH
if "%ChromePath%" == "" (
	CALL :PROGRESS_BAR 100 "ERRO ... Google Chrome nao esta instalado !"
	TIMEOUT /t 10 /nobreak 2>NUL >NUL
	TITLE Command Prompt && COLOR 7 && MODE 80,30 && cd %CurrentPath%
	EXIT /b
)

REM ..............................................................................
CALL :PROGRESS_BAR 5 "Desligar aplicativos instalados !"
TIMEOUT /t 3 /nobreak 2>NUL >NUL
REM kill explorer.exe
Taskkill /IM explorer.exe /F 2>NUL >NUL

REM delete explorer form regestry
call :REG_SET_OWNER "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /V Shell /F 2>NUL >NUL

REM ..............................................................................
call :REG_SET_OWNER "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
REM delete all RUN keys
REG DELETE HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run /f 2>NUL >NUL
REG ADD HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run 2>NUL >NUL
REG DELETE HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce /f 2>NUL >NUL
REG ADD HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce 2>NUL >NUL
REG DELETE HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /f 2>NUL >NUL
REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run 2>NUL >NUL
REG DELETE HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /f 2>NUL >NUL
REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce 2>NUL >NUL
REM Auto Start the program in Select mode 
REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /f /v %ProgramName0% /t REG_SZ /d "\"%ChromePath%\Application\chrome.exe\" --kiosk \"http://%HttpAddr%:%HttpPort01%\select"" 2>NUL >NUL
REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /f /v KillExplorer /t REG_SZ /d "\"%SystemDrive%\inetpub\%ProgramName0%\%ToolsName%\" KILLEXPLORER" 2>NUL >NUL



REM ..............................................................................
CALL :PROGRESS_BAR 10 "Excluir todo o Desktop"
TIMEOUT /t 3 /nobreak 2>NUL >NUL
REM delete all files
cd /
cd %UserDesktop%
For %%# in (
    "%UserDesktop%\*"
) Do (
    If /I not "%%~x#" EQU ".lnk" (
        Del /Q "%%#" 2>NUL >NUL
    )
)
Del /Q *.* 2>NUL >NUL
REM Delete all folders
cd /
cd %UserDesktop%\
for /d %%i in (*.*) do rmdir -rf "%%i" /s /q  2>NUL >NUL
REM delete all shortcuts
cd /
for /F "delims=" %%i in ('dir /b "%PUBLIC%\.."') do del /Q /F "%systemdrive%\Users\%%i\Desktop\*.*"  2>NUL >NUL


REM ..............................................................................
CALL :PROGRESS_BAR 15 "Criar Icon no Desktop"
TIMEOUT /t 2 /nobreak 2>NUL >NUL
REM prepare CreateShortcut.vbs script file 
ECHO set WshShell = WScript.CreateObject("WScript.Shell") > "%temp%\CreateShortcut.vbs"
ECHO set oShellLink = WshShell.CreateShortcut("%ProgramName0%.lnk") >> "%temp%\CreateShortcut.vbs"
ECHO oShellLink.TargetPath = "%ChromePath%\Application\chrome.exe" >> "%temp%\CreateShortcut.vbs" 
ECHO oShellLink.IconLocation = "%SystemDrive%\inetpub\%ProgramName0%\content\img\icon.ico" >> "%temp%\CreateShortcut.vbs" 
ECHO oShellLink.Arguments = "--kiosk http://%HttpAddr%:%HttpPort01%\select" >> "%temp%\CreateShortcut.vbs"
ECHO oShellLink.WindowStyle = 1 >> "%temp%\CreateShortcut.vbs"
ECHO oShellLink.Description = "Software de NF-e, NFC-e" >> "%temp%\CreateShortcut.vbs" 
ECHO oShellLink.HotKey = "ALT+CTRL+F" >> "%temp%\CreateShortcut.vbs"
ECHO oShellLink.Description = "%ProgramName0%" >> "%temp%\CreateShortcut.vbs" 
ECHO oShellLink.Save >> "%temp%\CreateShortcut.vbs"
REM run script 
cd/
cd %UserDesktop%\
"%SystemRoot%\System32\WScript.exe" "%temp%\CreateShortcut.vbs"  2>NUL >NUL

REM ..............................................................................
CALL :PROGRESS_BAR 18 "Limpar lixeira"
TIMEOUT /t 2 /nobreak 2>NUL >NUL
REM Empty recycle bin
cd /
cd \$RECYCLE.BIN
if exist %systemdrive%\$RECYCLE.BIN (
    pushd %systemdrive%\$RECYCLE.BIN   2>NUL >NUL
    DEL /s /q . 2>NUL >NUL
    popd 2>NUL >NUL
)
cd /

REM ..............................................................................
CALL :PROGRESS_BAR 30 "Desativar Windows Update / Antimalware / Security"
call :REG_SET_OWNER "HKLM\SOFTWARE\Policies\Microsoft\Windows\AU"
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\AU" /f  2>NUL >NUL
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\AU" /v AUOptions /t REG_DWORD /d 2 /f  2>NUL >NUL
REM ..............................................................................
REM Desativar Software Protection
call :REG_SET_OWNER "HKLM\SYSTEM\CurrentControlSet\Services\sppsvc"
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\sppsvc" /v Start /t REG_DWORD /d 4 /f  2>NUL >NUL
REM ..............................................................................
REM "Desativar Antimalware Service Executable"
REM kill Antimalware Service
taskkill /IM msseces.exe /F /t  2>NUL >NUL
taskkill /IM MsMpEng.exe /F /t  2>NUL >NUL
NET STOP MsMpSVc  2>NUL >NUL
SC config "MsMpSvc" start= disabled  2>NUL >NUL

REM turn Firewall off
NetSh Advfirewall set allprofiles state off  2>NUL >NUL
REM disable windows defender 
call :REG_SET_OWNER "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender"
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>nul
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f >nul 2>nul
REM ..............................................................................
REM "Desativar Windows Security Health Service"
REM kill SecurityHealthService
taskkill /IM SecurityHealthService.exe /F /t  2>NUL >NUL
REM Regedit desactivation key 
call :REG_SET_OWNER "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SecurityHealthService"
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v Start /t REG_DWORD /d 4 /f 2>NUL >NUL
REM ..............................................................................
REM "Desativar Microsoft Compatibility Telemetry"
REM kill SecurityHealthService
sc delete DiagTrack 2>NUL >NUL
sc delete dmwappushservice 2>NUL >NUL
REM Regedit desactivation key 
call :REG_SET_OWNER "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f 2>NUL >NUL
REM ..............................................................................
REM "Excluir KMS-R@1n.exe"
REM kill KMS-R@1n Service
taskkill /IM KMS-R@1n.exe /F /t 2>NUL >NUL
REM delete KMS-R@1n.exe 
IF EXIST "%SystemRoot%\KMS-R@1n.exe" ( DEL /s /q "%SystemRoot%\KMS-R@1n.exe" 2>NUL >NUL )
IF EXIST "%systemdrive%\KMS-R@1n.exe" ( DEL /s /q "%systemdrive%\KMS-R@1n.exe" 2>NUL >NUL )
REG DELETE "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\KMS-R@1n" /f 2>NUL >NUL
REM ..............................................................................
REM "Desativar servicos no RegEdit"
REM Desable services in RegEdit
call :REG_SET_OWNER "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d Off /f 2>NUL >NUL
call :REG_SET_OWNER "HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter"
REG ADD "HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter" /v EnabledV9 /t REG_DWORD /d 00000000 /f 2>NUL >NUL
call :REG_SET_OWNER "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\AppHost"
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\AppHost" /v EnableWebContentEvaluation /t REG_DWORD /d 00000000 /f 2>NUL >NUL
call :REG_SET_OWNER "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend"
REG DELETE "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend\Security" /f 2>NUL >NUL
REG DELETE "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend" /f 2>NUL >NUL




REM ..............................................................................
CALL :PROGRESS_BAR 50 "Desativar Task Bar"
TIMEOUT /t 2 /nobreak 2>NUL >NUL
REM set tablet mode
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v ConvertibleSlateModePromptPreference /t REG_DWORD /d 2 /f 2>NUL >NUL
REM Hide task bar in tablet mode
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAutoHideInTabletMode /t REG_DWORD /d 1 /f 2>NUL >NUL
REM Hide task bar in normal mode
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" /V Settings /F 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" /v Settings /t REG_BINARY /d 30000000feffffff03100000030000003e0000001E00000000000000E202000000000000000300006000000001000000 /f 2>NUL >NUL

REM Remove Task view button
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f 2>NUL >NUL
Rem Remove People Button from Taskbar
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v PeopleBand /t REG_DWORD /d 0 /f 2>NUL >NUL
REM remove Searc icon from taskbar
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f 2>NUL >NUL
REM custom Explorer.exe setings 
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableStartMenu /t REG_DWORD /d 0 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarSmallIcons /t REG_DWORD /d 1 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableStartMenu /t REG_DWORD /d 0 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowStatusBar /t REG_DWORD /d 0 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowInfoTip /t REG_DWORD /d 0 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f 2>NUL >NUL
rem Hide All Notification Icons in Tablet Mode
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V UseTabletModeNotificationIcons /T REG_DWORD /D 1 /F 2>NUL >NUL
REM Dont hide desktop icon
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideIcons /t REG_DWORD /d 0 /f 2>NUL >NUL
REM Turn OFF Always show all icons in the notification area
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v EnableAutoTray /t REG_DWORD /d 1 /f 2>NUL >NUL
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer" /v EnableAutoTray /t REG_DWORD /d 1 /f 2>NUL >NUL
REM To Disable "Always show all icons in the notification area" for All Users
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V NoAutoTrayNotify /F 2>NUL >NUL
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V NoAutoTrayNotify /F 2>NUL >NUL
REM Disable Active Desktop
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoActiveDesktop /t REG_DWORD /d 0 /f 2>NUL >NUL
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoActiveDesktop /t REG_DWORD /d 0 /f 2>NUL >NUL
REM Reset and Clear Taskbar Toolbars in Windows 10
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams\Desktop" /F 2>NUL >NUL
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /F 2>NUL >NUL
REM Enabble the Clock Icon
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V HideClock /F 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideClock /t REG_DWORD /d 0 /f 2>NUL >NUL
REM Disable the Network Icon
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V HideSCANetwork /F 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCANetwork /t REG_DWORD /d 1 /f 2>NUL >NUL
REM Disable the Power (battery) Icon
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V HideSCAPower /F 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCAPower /t REG_DWORD /d 1 /f 2>NUL >NUL
REM Disable the Volume Icon
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V HideSCAVolume /F 2>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCAVolume /t REG_DWORD /d 1 /f 2>NUL >NUL
REM Disable notification center 
REG ADD "HKCU\Software\Policies\Microsoft\Windows\Explorer" /f 2>NUL >NUL
REG ADD "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableNotificationCenter /t REG_DWORD /d 1 /f 2>NUL >NUL

REM ..............................................................................
if exist %WINDIR%\SystemApps\Emissor.changed GOTO :W10CLEAN3
CALL :PROGRESS_BAR 60 "Desativar e Excluir SystemApps (Windows 10)"


REM Set owner of all files to current user = Administrators
takeown /f "%WINDIR%\SystemApps" /r /d y 2>NUL >NUL
REM Grant access to all files to Administrators
icacls "%WINDIR%\SystemApps" /grant %Admin%:F /T 2>NUL >NUL
REM Set owner of WindowsApps back to Administrators
icacls "%WINDIR%\SystemApps" /setowner %Admin% 2>NUL >NUL

REM Kill possible open process 
Taskkill /IM ShellExperienceHost.exe /F 2>NUL >NUL
Taskkill /IM chrome.exe /F 2>NUL >NUL
Taskkill /IM smartscreen.exe /F 2>NUL >NUL
Taskkill /IM SearchUI.exe /F 2>NUL >NUL

REM SystemApps 
cd \
cd %WINDIR%\SystemApps
REM Rename menu SystemApps 
for /d %%i in (ShellExperienceHost_*) do ren "%%i" "_%%i"  2>NUL >NUL
REM Delete all SystemApps 
for /d %%i in (InputApp_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Windows.Cortana_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Windows.PeopleExperienceHost_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.XboxGameCallableUI_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (ParentalControls_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.BioEnrollment_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.MicrosoftEdge_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.PPIProjection_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Windows.AddSuggestedFoldersToLibraryDialog_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.AAD.BrokerPlugin_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
REM place tag to signal that windows was changed
copy nul > Emissor.changed 2>NUL >NUL
REM set ownership back to Admin
icacls "%WINDIR%\SystemApps" /setowner "%sysAdmin%" 2>NUL >NUL
:W10CLEAN3
REM ..............................................................................
CALL :PROGRESS_BAR 80 "Desativar e Excluir Windows Apps (Windows 10)"

REM Set owner of all files to current user = Administrators
takeown /f "%ProgramFiles%\WindowsApps" /r /d y 2>NUL >NUL
REM Grant access to all files to Administrators
icacls "%ProgramFiles%\WindowsApps" /grant %Admin%:F /T 2>NUL >NUL
REM Set owner of WindowsApps back to Administrators
icacls "%ProgramFiles%\WindowsApps" /setowner %Admin% 2>NUL >NUL

REM Kill possible open process 
Taskkill /IM HxTsr.exe /F 2>NUL >NUL
Taskkill /IM HxOutlook.exe /F 2>NUL >NUL
Taskkill /IM MSASCuiL.exe /F 2>NUL >NUL
Taskkill /IM OfficeClickToRun.exe /F 2>NUL >NUL
Taskkill /IM SkypeHost.exe /F 2>NUL >NUL

REM Delete all WindowsApps 
cd \
cd %ProgramFiles%\WindowsApps

for /d %%i in (Microsoft.YourPhone_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.3DBuilder_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Advertising.Xaml_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Appconnector_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.BingFinance_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.BingSports_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.BingWeather_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.BingNews_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.CommsPhone_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.ConnectivityStore_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.DesktopAppInstaller_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.GetHelp_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Getstarted_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Microsoft3DViewer_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.MicrosoftOfficeHub*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.MicrosoftSolitaireCollection_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.MicrosoftStickyNotes_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.MSPaint_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Office.OneNote_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Office.Sway_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.OneConnect_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.People_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Print3D_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Services.Store.Engagement_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.StorePurchaseApp_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Wallet_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Windows.Photos_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.WindowsAlarms_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (microsoft.windowscommunicationsapps_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.WindowsFeedbackHub_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.WindowsMaps_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.WindowsPhone_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.WindowsSoundRecorder_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.WindowsStore_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Xbox.TCUI_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.XboxApp_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.XboxGameOverlay_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.XboxIdentityProvider_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.XboxSpeechToTextOverlay_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.XboxGameOverlay_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.ZuneMusic_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.ZuneVideo_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.SkypeApp_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.RemoteDesktop_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Microsoft.Microsoft PowerBIforWindows_*) do rmdir -rf "%%i" /s /q 2>NUL >NUL
for /d %%i in (Windows.ContactSupport) do rmdir -rf "%%i" /s /q 2>NUL >NUL
REM Set owner of WindowsApps back to TrustedInstaller
icacls "%ProgramFiles%\WindowsApps" /setowner "NT Service\TrustedInstaller" 2>NUL >NUL

REM ..............................................................................
CALL :PROGRESS_BAR 100 "Aguardando para reiniciar o computador ..."
shutdown.exe /r /t 10 2>NUL >NUL
PAUSE  2>NUL >NUL
GOTO :EOF













































:TLS_FIX
REM Check if Windows 10 
if not "%WinVersion%" == "10.0" (
	echo ERRO ... Funconalidade disponivel apenas para Windows 10 !
	ECHO. && PAUSE && EXIT /b
)
REM ..............................................................................
MODE 80,4
SET "BarTitle=Fix TLS 1.2"
SET "RegFile=%TEMP%\tlsFix.reg"

REM ..............................................................................
SET "BarTitle=Utilitario correcao do TLS 1.2"
CALL :PROGRESS_BAR 10 "Preparando correcoes ... "
TIMEOUT /t 1 /nobreak 2>NUL >NUL

ECHO Windows Registry Editor Version 5.00>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local]>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001]>>%RegFile%
ECHO @="CRYPT_CIPHER_INTERFACE">>%RegFile%
ECHO "Functions"=hex(7):41,00,45,00,53,00,00,00,33,00,44,00,45,00,53,00,00,00,33,00,44,00,45,00,53,00,5f,00,31,00,31,00,32,00,00,00,58,00,54,00,53,00,2d,00,41,00,45,00,53,00,00,00,44,00,45,00,53,00,58,00,00,00,44,00,45,00,53,00,00,00,52,00,43,00,32,00,00,00,52,00,43,00,34,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\3DES]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\3DES\Properties]>>%RegFile%
ECHO "KeyLength"=hex:80,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\3DES_112]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\3DES_112\Properties]>>%RegFile%
ECHO "KeyLength"=hex:70,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\AES]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\AES\Properties]>>%RegFile%
ECHO "KeyLength"=hex:80,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\DES]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\DES\Properties]>>%RegFile%
ECHO "KeyLength"=hex:80,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\DESX]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\DESX\Properties]>>%RegFile%
ECHO "KeyLength"=hex:80,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\RC2]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\RC2\Properties]>>%RegFile%
ECHO "KeyLength"=hex:80,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\RC4]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\RC4\Properties]>>%RegFile%
ECHO "KeyLength"=hex:80,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000001\XTS-AES]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000002]>>%RegFile%
ECHO @="CRYPT_HASH_INTERFACE">>%RegFile%
ECHO "Functions"=hex(7):53,00,48,00,41,00,32,00,35,00,36,00,00,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,53,00,48,00,41,00,35,00,31,00,32,00,00,00,53,00,48,00,41,00,31,00,00,00,4d,00,44,00,35,00,00,00,4d,00,44,00,34,00,00,00,4d,00,44,00,32,00,00,00,41,00,45,00,53,00,2d,00,47,00,4d,00,41,00,43,00,00,00,41,00,45,00,53,00,2d,00,43,00,4d,00,41,00,43,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000002\AES-CMAC]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000002\AES-GMAC]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000002\MD2]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000002\MD4]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000002\MD5]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000002\SHA1]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000002\SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000002\SHA384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000002\SHA512]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000003]>>%RegFile%
ECHO @="CRYPT_ASYMMETRIC_ENCRYPTION_INTERFACE">>%RegFile%
ECHO "Functions"=hex(7):52,00,53,00,41,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000003\RSA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000003\RSA\Properties]>>%RegFile%
ECHO "KeyLength"=hex:00,04,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000004]>>%RegFile%
ECHO @="CRYPT_SECRET_AGREEMENT_INTERFACE">>%RegFile%
ECHO "Functions"=hex(7):44,00,48,00,00,00,45,00,43,00,44,00,48,00,5f,00,50,00,32,00,35,00,36,00,00,00,45,00,43,00,44,00,48,00,5f,00,50,00,33,00,38,00,34,00,00,00,45,00,43,00,44,00,48,00,5f,00,50,00,35,00,32,00,31,00,00,00,45,00,43,00,44,00,48,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000004\DH]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000004\DH\Properties]>>%RegFile%
ECHO "KeyLength"=hex:00,04,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000004\ECDH]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000004\ECDH_P256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000004\ECDH_P256\Properties]>>%RegFile%
ECHO "KeyLength"=hex:00,01,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000004\ECDH_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000004\ECDH_P384\Properties]>>%RegFile%
ECHO "KeyLength"=hex:80,01,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000004\ECDH_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000004\ECDH_P521\Properties]>>%RegFile%
ECHO "KeyLength"=hex:09,02,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005]>>%RegFile%
ECHO @="CRYPT_SIGNATURE_INTERFACE">>%RegFile%
ECHO "Functions"=hex(7):52,00,53,00,41,00,5f,00,53,00,49,00,47,00,4e,00,00,00,45,00,43,00,44,00,53,00,41,00,5f,00,50,00,32,00,35,00,36,00,00,00,45,00,43,00,44,00,53,00,41,00,5f,00,50,00,33,00,38,00,34,00,00,00,45,00,43,00,44,00,53,00,41,00,5f,00,50,00,35,00,32,00,31,00,00,00,45,00,43,00,44,00,53,00,41,00,00,00,44,00,53,00,41,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005\DSA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005\DSA\Properties]>>%RegFile%
ECHO "KeyLength"=hex:00,04,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005\ECDSA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005\ECDSA_P256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005\ECDSA_P256\Properties]>>%RegFile%
ECHO "KeyLength"=hex:00,01,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005\ECDSA_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005\ECDSA_P384\Properties]>>%RegFile%
ECHO "KeyLength"=hex:80,01,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005\ECDSA_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005\ECDSA_P521\Properties]>>%RegFile%
ECHO "KeyLength"=hex:09,02,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005\RSA_SIGN]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000005\RSA_SIGN\Properties]>>%RegFile%
ECHO "KeyLength"=hex:00,04,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000006]>>%RegFile%
ECHO @="CRYPT_RNG_INTERFACE">>%RegFile%
ECHO "Functions"=hex(7):52,00,4e,00,47,00,00,00,46,00,49,00,50,00,53,00,31,00,38,00,36,00,44,00,53,00,41,00,52,00,4e,00,47,00,00,00,44,00,55,00,41,00,4c,00,45,00,43,00,52,00,4e,00,47,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000006\DUALECRNG]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000006\FIPS186DSARNG]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000006\RNG]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000007]>>%RegFile%
ECHO @="CRYPT_KEY_DERIVATION_INTERFACE">>%RegFile%
ECHO "Functions"=hex(7):53,00,50,00,38,00,30,00,30,00,5f,00,31,00,30,00,38,00,5f,00,43,00,54,00,52,00,5f,00,48,00,4d,00,41,00,43,00,00,00,53,00,50,00,38,00,30,00,30,00,5f,00,35,00,36,00,41,00,5f,00,43,00,4f,00,4e,00,43,00,41,00,54,00,00,00,50,00,42,00,4b,00,44,00,46,00,32,00,00,00,43,00,41,00,50,00,49,00,5f,00,4b,00,44,00,46,00,00,00,54,00,4c,00,53,00,31,00,5f,00,31,00,5f,00,4b,00,44,00,46,00,00,00,54,00,4c,00,53,00,31,00,5f,00,32,00,5f,00,4b,00,44,00,46,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000007\CAPI_KDF]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000007\PBKDF2]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000007\SP800_108_CTR_HMAC]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000007\SP800_56A_CONCAT]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000007\TLS1_1_KDF]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00000007\TLS1_2_KDF]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,50,00,72,00,69,00,6d,00,69,00,74,00,69,00,76,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010001]>>%RegFile%
ECHO @="CRYPT_KEY_STORAGE_INTERFACE">>%RegFile%
ECHO "Functions"=hex(7):4b,00,45,00,59,00,5f,00,53,00,54,00,4f,00,52,00,41,00,47,00,45,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010001\KEY_STORAGE]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,6f,00,66,00,74,00,77,00,61,00,72,00,65,00,20,00,4b,00,65,00,79,00,20,00,53,00,74,00,6f,00,72,00,61,00,67,00,65,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002]>>%RegFile%
ECHO @="NCRYPT_SCHANNEL_INTERFACE">>%RegFile%
ECHO "Functions"=hex(7):54,00,4c,00,53,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,33,00,44,00,45,00,53,00,5f,00,45,00,44,00,45,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,4e,00,55,00,4c,00,4c,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,4e,00,55,00,4c,00,4c,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,4e,00,55,00,4c,00,4c,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,4e,00,55,00,4c,00,4c,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\SSL_CK_DES_192_EDE3_CBC_WITH_MD5]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\SSL_CK_DES_64_CBC_WITH_MD5]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\SSL_CK_RC4_128_EXPORT40_WITH_MD5]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\SSL_CK_RC4_128_WITH_MD5]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_AES_128_GCM_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_AES_256_GCM_SHA384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_DHE_DSS_EXPORT1024_WITH_DES_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_DHE_DSS_WITH_AES_128_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_DHE_DSS_WITH_AES_128_CBC_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_DHE_DSS_WITH_AES_256_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_DHE_DSS_WITH_AES_256_CBC_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_DHE_DSS_WITH_DES_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_DHE_RSA_WITH_AES_128_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_DHE_RSA_WITH_AES_128_GCM_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_DHE_RSA_WITH_AES_256_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_DHE_RSA_WITH_AES_256_GCM_SHA384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256_P256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA_P256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA_P256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P521]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_PSK_WITH_AES_128_CBC_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_PSK_WITH_AES_128_GCM_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_PSK_WITH_AES_256_CBC_SHA384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_PSK_WITH_AES_256_GCM_SHA384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_PSK_WITH_NULL_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_PSK_WITH_NULL_SHA384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_EXPORT1024_WITH_DES_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_EXPORT1024_WITH_RC4_56_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_EXPORT_WITH_RC4_40_MD5]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_3DES_EDE_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_AES_128_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_AES_128_CBC_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_AES_128_GCM_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_AES_256_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_AES_256_CBC_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_AES_256_GCM_SHA384]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_DES_CBC_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_NULL_MD5]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_NULL_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_NULL_SHA256]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_RC4_128_MD5]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010002\TLS_RSA_WITH_RC4_128_SHA]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,53,00,53,00,4c,00,20,00,50,00,72,00,6f,00,74,00,6f,00,63,00,6f,00,6c,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010004]>>%RegFile%
ECHO @="NCRYPT_KEY_PROTECTION_INTERFACE">>%RegFile%
ECHO "Functions"=hex(7):53,00,49,00,44,00,00,00,53,00,44,00,44,00,4c,00,00,00,4c,00,4f,00,43,00,41,00,4c,00,00,00,57,00,45,00,42,00,43,00,52,00,45,00,44,00,45,00,4e,00,54,00,49,00,41,00,4c,00,53,00,00,00,4d,00,53,00,49,00,44,00,43,00,52,00,4c,00,00,00,44,00,52,00,41,00,43,00,45,00,52,00,54,00,49,00,46,00,49,00,43,00,41,00,54,00,45,00,00,00,43,00,45,00,52,00,54,00,49,00,46,00,49,00,43,00,41,00,54,00,45,00,00,00,56,00,41,00,55,00,4c,00,54,00,43,00,52,00,45,00,44,00,45,00,4e,00,54,00,49,00,41,00,4c,00,53,00,00,00,4b,00,45,00,59,00,46,00,49,00,4c,00,45,00,00,00,4c,00,4f,00,43,00,4b,00,45,00,44,00,43,00,52,00,45,00,44,00,45,00,4e,00,54,00,49,00,41,00,4c,00,53,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010004\CERTIFICATE]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,4b,00,65,00,79,00,20,00,50,00,72,00,6f,00,74,00,65,00,63,00,74,00,69,00,6f,00,6e,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010004\DRACERTIFICATE]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,4b,00,65,00,79,00,20,00,50,00,72,00,6f,00,74,00,65,00,63,00,74,00,69,00,6f,00,6e,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010004\KEYFILE]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,4b,00,65,00,79,00,20,00,50,00,72,00,6f,00,74,00,65,00,63,00,74,00,69,00,6f,00,6e,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010004\LOCAL]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,4b,00,65,00,79,00,20,00,50,00,72,00,6f,00,74,00,65,00,63,00,74,00,69,00,6f,00,6e,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010004\LOCKEDCREDENTIALS]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):57,00,69,00,6e,00,64,00,6f,00,77,00,73,00,20,00,43,00,6c,00,69,00,65,00,6e,00,74,00,20,00,4b,00,65,00,79,00,20,00,50,00,72,00,6f,00,74,00,65,00,63,00,74,00,69,00,6f,00,6e,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010004\MSIDCRL]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):57,00,69,00,6e,00,64,00,6f,00,77,00,73,00,20,00,43,00,6c,00,69,00,65,00,6e,00,74,00,20,00,4b,00,65,00,79,00,20,00,50,00,72,00,6f,00,74,00,65,00,63,00,74,00,69,00,6f,00,6e,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010004\SDDL]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,4b,00,65,00,79,00,20,00,50,00,72,00,6f,00,74,00,65,00,63,00,74,00,69,00,6f,00,6e,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010004\SID]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,4b,00,65,00,79,00,20,00,50,00,72,00,6f,00,74,00,65,00,63,00,74,00,69,00,6f,00,6e,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010004\VAULTCREDENTIALS]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,4b,00,65,00,79,00,20,00,50,00,72,00,6f,00,74,00,65,00,63,00,74,00,69,00,6f,00,6e,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\Default\00010004\WEBCREDENTIALS]>>%RegFile%
ECHO "Flags"=dword:00000000>>%RegFile%
ECHO "Providers"=hex(7):4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,20,00,4b,00,65,00,79,00,20,00,50,00,72,00,6f,00,74,00,65,00,63,00,74,00,69,00,6f,00,6e,00,20,00,50,00,72,00,6f,00,76,00,69,00,64,00,65,00,72,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\SSL]>>%RegFile%
ECHO "Flags"=dword:00000001>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\SSL\00010002]>>%RegFile%
ECHO @="NCRYPT_SCHANNEL_INTERFACE">>%RegFile%
ECHO "EccCurves"=hex(7):63,00,75,00,72,00,76,00,65,00,32,00,35,00,35,00,31,00,39,00,00,00,4e,00,69,00,73,00,74,00,50,00,32,00,35,00,36,00,00,00,4e,00,69,00,73,00,74,00,50,00,33,00,38,00,34,00,00,00,00,00>>%RegFile%
ECHO "Functions"=hex(7):54,00,4c,00,53,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,45,00,43,00,44,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,45,00,43,00,44,00,48,00,45,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,\35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,\54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,33,00,44,00,45,00,53,00,5f,00,45,00,44,00,45,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,4e,00,55,00,4c,00,4c,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,52,00,53,00,41,00,5f,00,57,00,49,00,54,00,48,00,5f,00,4e,00,55,00,4c,00,4c,00,5f,00,53,00,48,00,41,00,00,00,54,00,4c,00,53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,47,00,43,00,4d,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,32,00,35,00,36,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,\53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,41,00,45,00,53,00,5f,00,31,00,32,00,38,00,5f,00,43,00,42,00,43,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,54,00,4c,00,53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,4e,00,55,00,4c,00,4c,00,5f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,54,00,4c,00,53,00,5f,00,50,00,53,00,4b,00,5f,00,57,00,49,00,54,00,48,00,5f,00,4e,00,55,00,4c,00,4c,00,5f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,00,00>>%RegFile%
ECHO [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Cryptography\Configuration\Local\SSL\00010003]>>%RegFile%
ECHO @="NCRYPT_SCHANNEL_SIGNATURE_INTERFACE">>%RegFile%
ECHO "Functions"=hex(7):52,00,53,00,41,00,2f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,52,00,53,00,41,00,2f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,52,00,53,00,41,00,2f,00,53,00,48,00,41,00,31,00,00,00,45,00,43,00,44,00,53,00,41,00,2f,00,53,00,48,00,41,00,32,00,35,00,36,00,00,00,45,00,43,00,44,00,53,00,41,00,2f,00,53,00,48,00,41,00,33,00,38,00,34,00,00,00,45,00,43,00,44,00,53,00,41,00,2f,00,53,00,48,00,41,00,31,00,00,00,44,00,53,00,41,00,2f,00,53,00,48,00,41,00,31,00,00,00,52,00,53,00,41,00,2f,00,53,00,48,00,41,00,35,00,31,00,32,00,00,00,45,00,43,00,44,00,53,00,41,00,2f,00,53,00,48,00,41,00,35,00,31,00,32,00,00,00,00,00>>%RegFile%

REM ..............................................................................
CALL :PROGRESS_BAR 80 "Efetuando correcoes ... "
REM Change regestry keys
TIMEOUT /t 1 /nobreak 2>NUL >NUL
regedit.exe /S %RegFile% >NUL 2>NUL
del /q %RegFile% >NUL 2>NUL

REM Delete all caches and settings
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 4351>NUL >NUL

REM prepare script.vbs script file to  Restore advanced settings
echo set shell = CreateObject("WScript.Shell") > "%ScriptFile%"
echo shell.run"RunDll32.exe InetCpl.cpl,ResetIEtoDefaults">> "%ScriptFile%"
echo WScript.Sleep 200>> "%ScriptFile%"
echo shell.SendKeys"{TAB}">> "%ScriptFile%"
echo shell.SendKeys" ">> "%ScriptFile%"
echo shell.SendKeys"{TAB}">> "%ScriptFile%"
echo shell.SendKeys"{TAB}">> "%ScriptFile%"
echo WScript.Sleep 50>> "%ScriptFile%"
echo shell.SendKeys"%(R)">> "%ScriptFile%"
echo shell.SendKeys" ">> "%ScriptFile%"
echo WScript.Sleep 1000>> "%ScriptFile%"
echo shell.SendKeys"{ENTER}">> "%ScriptFile%"
REM run script 
"%SystemRoot%\System32\WScript.exe" "%ScriptFile%" >NUL 2>NUL
del /q %ScriptFile% >NUL 2>NUL

REM fine tunning on Internet setings 
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "WarnonZoneCrossing" /t REG_DWORD /d 0 /f>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "WarnOnPostRedirect" /t REG_DWORD /d 0 /f>NUL >NUL
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "WarnOnBadCertRecving" /t REG_DWORD /d 0 /f>NUL >NUL
TIMEOUT /t 1 /nobreak 2>NUL >NUL

REM ..............................................................................
CALL :PROGRESS_BAR 100 "Concluido ... "
TIMEOUT /t 1 /nobreak 2>NUL >NUL

shutdown.exe /r /t 00




:MENU_ICONS
call :WRITE_LOG "♦ 9 - Criar icons do %ProgramName0% no Desktop"
REM ..............................................................................
REM check if need to change icon file name 
set "IconFile=%SystemDrive%\inetpub\%ProgramName0%\content\img\icon.ico"
if /I '%2'=='icon' set IconFile=%3
if exist %IconFile% (copy %IconFile% %SystemDrive%\inetpub\%ProgramName0%\content\img\favicon.ico) else ( call :MESSAGE_ERROR "Icon nao encontrado !" && pause && exit /b )
call :GET_CHROME_PATH
if "%ChromePath%" == "" ( call :MESSAGE_ERROR "ERRO ... Google Chrome nao esta instalado !" && PAUSE && exit /b )
REM ..............................................................................
:MENU_ICONS_LOOP
CALL :MESSAGE_HEADER "Icons de Desktop"
ECHO.
ECHO   0 - Icons padrao (Atalho de Internet)
ECHO   1 - Icons para iniciar software modo App
ECHO   2 - Icons para iniciar software modo TelaCheia
ECHO     -
ECHO   3 - Alterar IP/URL do software de localhost para IP especifico
ECHO     -
ECHO   S - SAIR
ECHO.
CALL :MESSAGE_LINE_
ECHO.
choice /n /c 0123S /m "Pressione 0, 1, 2, 3 ..."
if %errorlevel%==1 call :ICONS_STANDARD
if %errorlevel%==2 call :ICONS_APP
if %errorlevel%==3 call :ICONS_FULL
if %errorlevel%==4 call :ICONS_IP
if %errorlevel%==5 (set "errorlevel=0" && exit /b)
GOTO MENU_ICONS_LOOP










:ICONS_STANDARD
REM criar icons standard
call :ICONS_DEL
call :WRITE_LOG "♦ 0 - Icons padrao (Atalho de Internet)"
call :MESSAGE_HEADER "Criar Icons padrao (Atalho de Internet)"
call :VBS_URL_ICONS "http://%HttpAddr%:%HttpPort01%" "%ProgramName0%"
if [%ToolsName%] == [PDVtools] (call :VBS_URL_ICONS "http://%HttpAddr%:%HttpPort01%/POS" "PDV")
REM return to menu11
ECHO. && PAUSE && EXIT /b

:ICONS_APP
REM Create icons on Desktop / app mode
call :ICONS_DEL
call :WRITE_LOG "♦ 1 - Icons para iniciar software modo App"
call :MESSAGE_HEADER "Criar Icons no Desktop (modo App)"
call :VBS_LNK_ICONS "-app=http://%HttpAddr%:%HttpPort01%" "%ProgramName0%"
if [%ToolsName%] == [PDVtools] (call :VBS_LNK_ICONS "-app=http://%HttpAddr%:%HttpPort01%/POS" "PDV")
REM return to menu
ECHO. && PAUSE && EXIT /b

:ICONS_FULL
REM Create icons on Desktop / full screen mode
call :ICONS_DEL
call :WRITE_LOG "♦ 2 - Icons para iniciar software modo TelaCheia"
call :MESSAGE_HEADER "Criar Icons no Desktop (modo TelaCheia)"
call :VBS_LNK_ICONS "--kiosk http://%HttpAddr%:%HttpPort01%" "%ProgramName0%"
if [%ToolsName%] == [PDVtools] (call :VBS_LNK_ICONS "--kiosk http://%HttpAddr%:%HttpPort01%/POS" "PDV")
REM return to menu
ECHO. && PAUSE && EXIT /b

:ICONS_IP
REM Alterar url dos icons
call :WRITE_LOG "♦ 3 - Alterar IP/URL do software de localhost para IP especifico"
CALL :MESSAGE_HEADER "Digite ip ou URL"
SET /P HttpAddr=Digite ip ou URL (Ex: 192.168.0.55 ou idLoja.ddns.net):
ECHO . 
ECHO Novos Icons do %ProgramName0% vao agora aceder a http://%HttpAddr%:%HttpPort01%
REM return to menu
ECHO. && PAUSE && EXIT /b

:ICONS_DEL
REM del all icons
cd %UserDesktop%
del /q "%ProgramName0%.lnk"
del /q "%ProgramName0%.url"
if [%ToolsName%] == [PDVtools] (
	del /q "PDV.lnk"
	del /q "PDV.url"
)
cd %PublicDesktop%
del /q "%ProgramName0%.url"
if [%ToolsName%] == [PDVtools] (
	del /q "PDV.url"
)
cls
EXIT /b


:VBS_LNK_ICONS
REM prepare script.vbs script file 
ECHO set WshShell = WScript.CreateObject("WScript.Shell") > "%ScriptFile%"
ECHO set oShellLink = WshShell.CreateShortcut("%~2.lnk") >> "%ScriptFile%"
ECHO oShellLink.TargetPath = "%ChromePath%\Application\chrome.exe" >> "%ScriptFile%"
ECHO oShellLink.IconLocation = "%SystemDrive%\inetpub\%ProgramName0%\content\img\icon.ico" >> "%ScriptFile%"
ECHO oShellLink.Arguments = "%~1" >> "%ScriptFile%"
ECHO oShellLink.WindowStyle = 1 >> "%ScriptFile%"
ECHO oShellLink.Description = "Software de NF-e, NFC-e" >> "%ScriptFile%"
ECHO oShellLink.HotKey = "ALT+CTRL+F" >> "%ScriptFile%"
ECHO oShellLink.Description = "%~2" >> "%ScriptFile%"
ECHO oShellLink.Save >> "%ScriptFile%"
REM run script 
cd/
cd %UserDesktop%\
"%SystemRoot%\System32\WScript.exe" "%ScriptFile%"
del /q %ScriptFile%
exit /b

:VBS_URL_ICONS
REM prepare script.vbs script file 
ECHO Set WshShell = CreateObject("WScript.Shell") > "%ScriptFile%"
ECHO strUserDesktop = WshShell.SpecialFolders("Desktop") >> "%ScriptFile%"
ECHO Set objShortcutUrl = WshShell.CreateShortcut("%UserDesktop%\%~2.lnk") >> "%ScriptFile%"
ECHO objShortcutUrl.TargetPath = "%~1" >> "%ScriptFile%"
ECHO objShortcutUrl.IconLocation = "%IconFile%" >> "%ScriptFile%"
ECHO objShortcutUrl.Save >> "%ScriptFile%"
REM run script 
cd/
cd %UserDesktop%\
"%SystemRoot%\System32\WScript.exe" "%ScriptFile%"
del /q %ScriptFile%
exit /b


:VBS_LIST_SQL_APPS
REM prepare script.vbs script file 
ECHO strComputer = "."> "%ScriptFile%"
ECHO Const HKLM = ^&h80000002>> "%ScriptFile%"
ECHO Set objCtx = CreateObject("WbemScripting.SWbemNamedValueSet")>> "%ScriptFile%"
ECHO objCtx.Add "__ProviderArchitecture", 32>> "%ScriptFile%"
ECHO objCtx.Add "__RequiredArchitecture", TRUE >> "%ScriptFile%"
ECHO Set objLocator = CreateObject("Wbemscripting.SWbemLocator") >> "%ScriptFile%"
ECHO Set objServices = objLocator.ConnectServer("","root\default","","",,,,objCtx) >> "%ScriptFile%"
ECHO Set objStdRegProv = objServices.Get("StdRegProv") >> "%ScriptFile%"
ECHO Call GetApplications  >> "%ScriptFile%"
ECHO objCtx.Add "__ProviderArchitecture", 64 >> "%ScriptFile%"
ECHO objCtx.Add "__RequiredArchitecture", TRUE >> "%ScriptFile%"
ECHO Set objLocator = CreateObject("Wbemscripting.SWbemLocator") >> "%ScriptFile%"
ECHO Set objServices = objLocator.ConnectServer("","root\default","","",,,,objCtx) >> "%ScriptFile%"
ECHO Set objStdRegProv = objServices.Get("StdRegProv") >> "%ScriptFile%"
ECHO Call GetApplications >> "%ScriptFile%"
ECHO Sub GetApplications >> "%ScriptFile%"
ECHO Dim stringcmp >> "%ScriptFile%"
ECHO Set Inparams = objStdRegProv.Methods_("EnumKey").Inparameters >> "%ScriptFile%"
ECHO Inparams.Hdefkey = HKLM >> "%ScriptFile%"
ECHO Inparams.Ssubkeyname = "Software\Microsoft\Windows\CurrentVersion\Uninstall\" >> "%ScriptFile%"
ECHO set Outparams = objStdRegProv.ExecMethod_("EnumKey", Inparams,,objCtx) >> "%ScriptFile%"
ECHO For Each strSubKey In Outparams.snames >> "%ScriptFile%"
ECHO Set Inparams = objStdRegProv.Methods_("GetStringValue").Inparameters >> "%ScriptFile%"
ECHO Inparams.Hdefkey = HKLM >> "%ScriptFile%"
ECHO Inparams.Ssubkeyname = "Software\Microsoft\Windows\CurrentVersion\Uninstall\" ^& strSubKey >> "%ScriptFile%"
ECHO Inparams.Svaluename = "DisplayName" >> "%ScriptFile%"
ECHO set Outparams = objStdRegProv.ExecMethod_("GetStringValue", Inparams,,objCtx) >> "%ScriptFile%"
ECHO if not (stringcmp) = (Outparams.SValue) then >> "%ScriptFile%"
ECHO If InStr(Outparams.SValue,"SQL") Then >> "%ScriptFile%"
ECHO wscript.echo Outparams.SValue >> "%ScriptFile%"
ECHO stringcmp = Outparams.SValue >> "%ScriptFile%"
ECHO End If >> "%ScriptFile%"
ECHO If InStr(Outparams.SValue,"Sql") Then >> "%ScriptFile%"
ECHO wscript.echo Outparams.SValue >> "%ScriptFile%"
ECHO End If >> "%ScriptFile%"
ECHO End If >> "%ScriptFile%"
ECHO Next >> "%ScriptFile%"
ECHO End Sub >> "%ScriptFile%"
REM run script 
cd/
cd %UserDesktop%\
"%SystemRoot%\System32\cscript.exe" //NoLogo "%ScriptFile%" >%keyFile%
del /q %ScriptFile%
exit /b









:CLEAN_KEYFILE_1
REM clean %keyFile% , leaving only the keys
del %temp%\temp.txt >nul 2>nul
set oldproductkey=" "
setlocal enabledelayedexpansion
if exist "%keyFile%" (
	for /F "usebackq delims=" %%A in ("%keyFile%") do (
		set LN=%%A
		set LN=!LN: =!
		set LN=!LN:~0,32!
		if not "!LN!"=="!oldproductkey!" ( 
			if not "!LN!"=="00000000000000000000000000000000" (
				if not "!LN!"=="10000000000000000000000000000000" (
					if not "!LN!"=="20000000000000000000000000000000" (
						if not "!LN!"=="30000000000000000000000000000000" (
							if not "!LN!"=="40000000000000000000000000000000" (
								if not "!LN!"=="50000000000000000000000000000000" (
									echo !LN!>>%temp%\temp.txt
								)
							)
						)
					)
				)
			)
			set oldproductkey=!LN!
		)
	)
)
endlocal
copy %temp%\temp.txt %keyFile% >nul 2>nul
del %temp%\temp.txt >nul 2>nul

REM delete duplicated lines
sort "%keyFile%">"%temp%\temp.txt"
del /q "%keyFile%"
setlocal EnableDelayedExpansion
for /F "usebackq delims=" %%A IN ("%temp%\temp.txt") DO (
	if not [%%A]==[!LN!] (
		set "LN=%%A"
		echo %%A>>"%keyFile%"
		CALL :WRITE_LOG "Product key found %%A"
	)
)
endlocal
del %temp%\temp.txt >nul 2>nul
exit /b






:CLEAN_KEYFILE_HEX
REM clean %keyFile% , leaving only the compleat paths 
IF NOT EXIST "%keyFile%" exit /b
DEL %temp%\temp.txt >nul 2>nul

setlocal enabledelayedexpansion
for /f "useback delims=" %%A in ("%keyFile%")	do (
	set "LN=%%A"
	REM trim 
	set LN=!LN:~-38!
	REM save line in tempfile
	echo !LN!>>%temp%\temp.txt
)
endlocal

copy %temp%\temp.txt %keyFile% >nul 2>nul
del %temp%\temp.txt >nul 2>nul
exit /b














:CLEAN_KEYFILE_REG_SZ
REM clean %keyFile% , leaving only the compleat paths 
IF NOT EXIST "%keyFile%" exit /b
DEL %temp%\temp.txt >nul 2>nul

setlocal enabledelayedexpansion
for /f "useback delims=" %%A in ("%keyFile%")	do (
	set "LN=%%A"
	REM trim end of the string
	for /l %%a in (1,1,300) do if NOT "!LN:~-6!"=="REG_SZ" set LN=!LN:~0,-1!
	SET LN=!LN:    REG_SZ=!

	REM clean other characters
	SET LN=!LN:    =!
	SET LN=!LN:   =!
	SET LN=!LN:  =!

	REM save line in tempfile
	echo !LN!>>%temp%\temp.txt
)
endlocal

copy %temp%\temp.txt %keyFile% >nul 2>nul
del %temp%\temp.txt >nul 2>nul
exit /b




:CLEAN_FILE_REG_MULTI_SZ
REM clean %keyFile% , leaving only the compleat paths 
IF NOT EXIST "%keyFile%" exit /b
DEL %temp%\temp.txt >nul 2>nul
setlocal enabledelayedexpansion

for /f "useback delims=" %%A in ("%keyFile%")	do (
	set "LN=%%A"	

	REM trim end of the string
	for /l %%a in (1,1,300) do if NOT "!LN:~-12!"=="REG_MULTI_SZ" set LN=!LN:~0,-1!
	SET LN=!LN:    REG_MULTI_SZ=!

	REM clean other characters
	SET LN=!LN:    =!
	SET LN=!LN:   =!
	SET LN=!LN:  =!
	SET LN=!LN:  =!
	SET LN=!LN:"=\"!

	REM save line in tempfile
	echo !LN!>>%temp%\temp.txt
)
endlocal

copy %temp%\temp.txt %keyFile% >nul 2>nul
del %temp%\temp.txt >nul 2>nul
exit /b





:CLEAN_FILE_REG_BINARY
REM clean %keyFile% , leaving only the compleat paths 
IF NOT EXIST "%keyFile%" exit /b
DEL %temp%\temp.txt >nul 2>nul
setlocal enabledelayedexpansion

for /f "useback delims=" %%A in ("%keyFile%")	do (
	set "LN=%%A"	

	REM trim end of the string
	for /l %%a in (1,1,350) do if NOT "!LN:~-10!"=="REG_BINARY" set LN=!LN:~0,-1!
	SET LN=!LN:    REG_BINARY=!

	REM clean other characters
	SET LN=!LN:    =!
	SET LN=!LN:   =!
	SET LN=!LN:  =!
	SET LN=!LN:  =!
	SET LN=!LN:"=\"!

	REM save line in tempfile
	echo !LN!>>%temp%\temp.txt
)
endlocal

copy %temp%\temp.txt %keyFile% >nul 2>nul
del %temp%\temp.txt >nul 2>nul
exit /b



:REMOVE_1ST_CHR
set name=%1
ren "%name%" "%name:~1%"
exit /b



:MESSAGE_ATENCTION
cls
color C
if "%WinVersion%" == "10.0" (
	call :MESSAGE_LINE ┌──────────────────────────────────!ATENCAO!───────────────────────────────────┐
	call :MESSAGE_ %1
	call :MESSAGE_LINE └──────────────────────────────────────────────────────────────────────────────┘
) else (
	call :MESSAGE_LINE ----------------------------------- ATENCAO -----------------------------------
	call :MESSAGE_ %1
	call :MESSAGE_LINE -------------------------------------------------------------------------------
)
exit /b

:MESSAGE_ERROR
cls
color C
if "%WinVersion%" == "10.0" (
	call :MESSAGE_LINE ┌────────────────────────────────────!ERRO!────────────────────────────────────┐
	call :MESSAGE_ %1
	call :MESSAGE_LINE └──────────────────────────────────────────────────────────────────────────────┘

) else (
	call :MESSAGE_LINE ------------------------------------ ERRO -------------------------------------
	call :MESSAGE_ %1
	call :MESSAGE_LINE -------------------------------------------------------------------------------
)
exit /b


:MESSAGE_HEADER
cls
color E
if "%WinVersion%" == "10.0" (
	call :MESSAGE_LINE ┌──────────────────────────────────────────────────────────────────────────────┐
	call :MESSAGE_ %1
	call :MESSAGE_LINE └──────────────────────────────────────────────────────────────────────────────┘
) else (
	call :MESSAGE_LINE -------------------------------------------------------------------------------
	call :MESSAGE_ %1
	call :MESSAGE_LINE -------------------------------------------------------------------------------	
)
exit /b


:MESSAGE_LINE_
if "%WinVersion%" == "10.0" (
	echo ├──────────────────────────────────────────────────────────────────────────────┤
) else (
	echo -------------------------------------------------------------------------------
)
exit /b


:MESSAGE_LINE
	echo %~1
	echo %date% %time:~0,8% %~1>> %LogFile%
exit /b


:MESSAGE_
SET "nick=            %~1            "
if not "%WinVersion%" == "10.0" goto :MESSAGE_W7
rem .................................................
:MESSAGE_00
IF "%nick:~77,1%" neq "" GOTO MESSAGE_01
SET "nick=%nick% "
IF "%nick:~77,1%%" neq "" GOTO MESSAGE_01
SET "nick= %nick%"
GOTO MESSAGE_00
:MESSAGE_01
echo │%nick%│
echo %date% %time:~0,8% ^|%nick%^|>> %LogFile%
exit /b
rem .................................................
:MESSAGE_W7:
:MESSAGE_02
IF "%nick:~76%" neq "" GOTO MESSAGE_03
SET "nick=%nick% "
IF "%nick:~76%" neq "" GOTO MESSAGE_03
SET "nick= %nick%"
GOTO MESSAGE_02
:MESSAGE_03
echo ^|%nick%^|
echo %date% %time:~0,8% ^|%nick%^|>> %LogFile%
exit /b


:MESSAGE_IF
if [%1] == [0] ( echo %~2 && echo %date% %time:~0,8% %~2>> %LogFile% && exit /b) 
if [%1] == [1] ( 
if not "%~3" == "" ( echo %~3 && echo %date% %time:~0,8% %~3>> %LogFile% && exit /b)
)
if not "%4" == "" echo %~4
echo %date% %time:~0,8% %~4>> %LogFile%
exit /b


:TEST_SERVICE
setlocal EnableDelayedExpansion
SC QUERYEX %1 | FINDSTR "RUNNING" >nul 2>nul
endlocal
exit /b

:TEST_SERVICE_START
SC QUERYEX %1 | FINDSTR "START_PENDING" >nul 2>nul
IF /I "%errorlevel%" == "0" ( exit /B 0 ) else ( exit /B 1 )


rem :TEST_SERVICE_START
rem setlocal EnableDelayedExpansion
rem SC QUERYEX %1 | FINDSTR "START_PENDING" >nul 2>nul
rem echo %~2  ===   %errorlevel%
rem endlocal
rem IF /I "%errorlevel%" == "0" ( set "%~2=0" && echo eu 0 ) else ( set "%~2=1" && echo eu 1 )
rem exit /b

:FIND_SERVICE
SC QUERYEX %1 > NUL 
IF /I "%errorlevel%" == "0" ( exit /B 0 ) else ( exit /B 1 )




:ENABLE_FEATURE
setlocal EnableDelayedExpansion
set "changed=0"
set "disabled=0"
if [%DoReboot%] == [1] ( set "reboot=1" ) else ( set "reboot=0" )
for /F %%i in ('DISM.exe /Online /Get-featureInfo /FeatureName:"%1" ^| FINDSTR "Disabled Desabilitado"') do set "disabled=1"
if [!disabled!] == [1] (
	DISM.exe /Quiet /enable-feature /all /online /FeatureName:"%1" /NoRestart >>%LogFile% 2>>NUL
	set "changed=1"
	REM Restart only .NET feature Activated
	if [%1%] == [NetFx3] set "reboot=1"
	if [%1%] == [NetFx4-AdvSrvs] set "reboot=1"
	if [%1%] == [NetFx4Extended-ASPNET45] set "reboot=1"
	if [%1%] == [HttpCompressionStatic] set "reboot=1"
	if [%1%] == [HttpCompressionDynamic] set "reboot=1"
	REM Timer
	timeout /T 1 /NOBREAK >nul 2>nul	
	REM 2nd test
	set "disabled=0"
	for /F %%i in ('DISM.exe /Online /Get-featureInfo /FeatureName:"%1" ^| FINDSTR "Disabled Desabilitado"') do set "disabled=1"
)
REM Print message / Log file 
if [%LogInstall%] == [%SystemDrive%\inetpub\%ProgramName0%\iisInstall.log] (
	if [!disabled!] == [0] ( if [!changed!] == [1] ( ECHO [%2]%1 ... ATIVADO >%LogInstall% && ECHO %date% %time:~0,8% [%2]%1 ... ATIVADO >>%LogFile% ) else ( ECHO [%2]%1 ... OK >%LogInstall% && ECHO %date% %time:~0,8% [%2]%1 ... OK >>%LogFile% )) else ( ECHO [%2]%1 ... ERRO >%LogInstall% && ECHO %date% %time:~0,8% [%2]%1 ... ERRO >>%LogFile% )
) else (
	if [!disabled!] == [0] ( if [!changed!] == [1] (echo "OK ... %1 ... ENABLED") else (echo "OK ... %1") ) else (echo "ERRO ... %1")
)
endlocal & set "DoReboot=%reboot%"
exit /b


:ENABLE_FEATURE_QUIET
setlocal EnableDelayedExpansion
set "disabled=0"
for /F %%i in ('DISM.exe /Online /Get-featureInfo /FeatureName:"%1" ^| FINDSTR "Disabled Desabilitado"') do set "disabled=1"
if [!disabled!] == [1] ( 
	DISM.exe /Quiet /enable-feature /all /online /FeatureName:"%1" /NoRestart >>%LogFile% 2>>NUL
	call :WRITE_LOG "OK ... %1 ... ENABLED"
) else ( call :WRITE_LOG "OK ... %1 ... ALREADY ENABLED" )
endlocal
exit /b 


:DISABLE_FEATURE
setlocal EnableDelayedExpansion
set "changed=0"
set "enabled=0"
if [%DoReboot%] == [1] ( set "reboot=1" ) else ( set "reboot=0" )
for /F %%i in ('DISM.exe /Online /Get-featureInfo /FeatureName:"%1" ^| FINDSTR "Enabled Habilitado"') do set "enabled=1"
if [!enabled!] == [1] (
	DISM.exe /Quiet /disable-feature /online /FeatureName:"%1" /Remove /NoRestart >>%LogFile% 2>>NUL
	set "changed=1"
	REM Restart only .NET feature Activated	
	if [%1%] == [NetFx3] set "reboot=1"
	if [%1%] == [NetFx4-AdvSrvs] set "reboot=1"
	if [%1%] == [NetFx4Extended-ASPNET45] set "reboot=1"
	if [%1%] == [HttpCompressionStatic] set "reboot=1"
	if [%1%] == [HttpCompressionDynamic] set "reboot=1"
	REM Timer
	timeout /T 1 /NOBREAK >nul 2>nul
	REM 2nd test
	set "enabled=0"
	for /F %%i in ('DISM.exe /Online /Get-featureInfo /FeatureName:"%1" ^| FINDSTR "Enabled Habilitado"') do set "enabled=1"
)
REM Print message / Log file 
if [%LogInstall%] == [%SystemDrive%\inetpub\%ProgramName0%\iisInstall.log] (
	if [!enabled!] == [0] ( if [!changed!] == [1] ( ECHO [%2]%1 ... DESATIVADO >%LogInstall% && ECHO %date% %time:~0,8% [%2]%1 ... DESATIVADO >>%LogFile% ) else ( ECHO [%2]%1 ... OK >%LogInstall% && ECHO %date% %time:~0,8% [%2]%1 ... OK >>%LogFile% ) ) else ( ECHO [%2]%1 ... ERRO >%LogInstall% && ECHO %date% %time:~0,8% [%2]%1 ... ERRO >>%LogFile% )
) else (
	if [!enabled!] == [0] (if [!changed!] == [1] (echo "OK ... %1 ... DISABLED") else (echo "OK ... %1")) else (echo "ERRO ... %1")
)
endlocal & set "DoReboot=%reboot%"
exit /b


:DISABLE_FEATURE_QUIET
setlocal EnableDelayedExpansion
set "enabled=0"
for /F %%i in ('DISM.exe /Online /Get-featureInfo /FeatureName:"%1" ^| FINDSTR "Enabled Habilitado"') do set "enabled=1"
if [!enabled!] == [1] ( 
	DISM.exe /disable-feature /online /FeatureName:"%1" /Remove /NoRestart >>%LogFile% 2>>NUL
	call :WRITE_LOG "OK ... %1 ... DISABLED"
) else ( call :WRITE_LOG "OK ... %1 ... ALREADY DISABLED" )
endlocal
exit /b 


:UNISTALL_MODULE_QUIET
%windir%\system32\inetsrv\appcmd.exe uninstall module %1 >>%LogFile%
if [%errorlevel%] == [0] ( call :WRITE_LOG "OK ... %1 ... UNINSTALED" ) else ( call :WRITE_LOG "OK ... %1 ... ALREADY UNINSTALED" )
exit /b 



:REVERSE_KEYS
copy %keyFile% %TEMP%\temp.txt >nul
del %keyFile% >nul
setlocal enabledelayedexpansion
set I=0
for /F "usebackq delims=" %%k in ("%TEMP%\temp.txt") do (
	set /A I=!I! + 1
	set LINE!I!=%%k
)
for /L %%c in (!I!,-1,1) do ( echo !LINE%%c! >> %keyFile% )
del %TEMP%\temp.txt >nul
endlocal
EXIT /b




:CHECK_IIS_RUNING
REM check if IIS is running
SC QUERY "W3SVC" | FINDSTR "RUNNING"
exit /b


:GET_CHROME_PATH
IF EXIST "%LOCALAPPDATA%\Google\Chrome\Application\" set "ChromePath=%LOCALAPPDATA%\Google\Chrome"
IF EXIST "%ProgramFiles(x86)%\Google\Chrome\Application\" set "ChromePath=%ProgramFiles(x86)%\Google\Chrome"
IF EXIST "%ProgramFiles%\Google\Chrome\Application\" set "ChromePath=%ProgramFiles%\Google\Chrome"
exit /b


:TEST_TCP_PORT
REM Check open port
netstat -a -n -p TCP | FINDSTR "0.0.0.0:%1 " >nul 
if /I "%errorlevel%" == "0" ( exit /B 0 ) else ( exit /B 1 )


:TEST_FRAMEWORK
REG QUERY "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
IF /I "%errorlevel%" == "0" ( 
		call :GET_FRAMEWORK_VERSION
		exit /B 0 
	) else ( exit /B 1 )
:GET_FRAMEWORK_VERSION
FOR /F "usebackq tokens=1-3" %%A IN (`^(REG QUERY "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /s /v "Version" ^| findstr "Version"^) 2^> nul`) DO ( SET NetVer=%%C && exit /b )
exit /b

 
 

:WRITE_LOG
SET "logtxt=%~1"
echo %date% %time:~0,8% %logtxt%>>%LogFile%
exit /b


:PROGRESS_BAR
if not "%WinVersion%" == "10.0" GOTO BAR_W7

	setlocal enabledelayedexpansion
	chcp 65001 >NUL
	CLS
	COLOR E
	ECHO ┌──────────────────────────────────────────────────────────────────────────────┐
	CALL :WRITE_LOG ┌──────────────────────────────────────────────────────────────────────────────┐
	TITLE %BarTitle% %~1^%%
	SET /A "val=(%1*78)/100"
	SET /A "cnt=1"
	SET "bar="
	FOR /l %%a in (1,1,%val%) do ( SET "bar=█!bar!" )
	FOR /l %%a in (%val%,1,77) do ( SET "bar=!bar!░" )
	ECHO │%bar%│
	CALL :WRITE_LOG │%bar%│
	endlocal
	IF "%~2" == "" EXIT /b
	SET "txt=───── %~2 ─────"
	:BAR01
	IF "%txt:~77,1%" neq "" GOTO BAR02
	SET txt=%txt%─
	IF "%txt:~77,1%" neq "" GOTO BAR02
	SET txt=─%txt%
	GOTO BAR01
	:BAR02
	ECHO └%txt%┘
	echo %date% %time:~0,8% └%txt%┘>> %LogFile%
	EXIT /b

:BAR_W7
	setlocal enabledelayedexpansion
	chcp 850 2>NUL >NUL
	CLS
	COLOR E
	echo.
	echo %date% %time:~0,8% .>> %LogFile%
	TITLE %BarTitle% %~1^%%
	if 	%1==0 (echo. && goto BAR13)
	SET /A "val=(%1*78)/100"
	SET /A "cnt=1"
	SET "bar="
	FOR /l %%a in (1,1,%val%) do ( SET "bar=*!bar!" )
	FOR /l %%a in (%val%,1,77) do ( SET "bar=!bar! " )
	ECHO  %bar%
	CALL :WRITE_LOG %bar%
	endlocal
	:BAR13
	IF "%~2" == "" EXIT /b
	SET "txt=      %~2      "
	:BAR11
	IF "%txt:~76%" neq "" GOTO BAR12
	SET txt=%txt% 
	IF "%txt:~76%" neq "" GOTO BAR12
	SET txt= %txt%
	GOTO BAR11
	:BAR12
	ECHO  %txt% 
	echo %date% %time:~0,8% %txt%>> %LogFile%
	EXIT /b



:MESSAGE_BAR_OR_HEADER
if '%LogInstall%' == '%SystemDrive%\inetpub\%ProgramName0%\iisInstall.log' goto MESSAGE_BAR_OR_HEADER0
call :MESSAGE_HEADER %2
exit /b
:MESSAGE_BAR_OR_HEADER0
call :PROGRESS_BAR %1 %2
exit /b	exit /b


:KILL_EXPLORER
Taskkill /IM explorer.exe /F 2>NUL >NUL
exit







:MENU_PDVDROID
call :WRITE_LOG "♦ Menu do PDVdroid"
chcp 65001 >null
mode 80,30
title PDVdroid 2 Tools
set "PDVdroidIP="
rem set "PDVdroidIPport="
set "PDVdroidID="
set "PDVdroidIPdetected=0"
set "PDVdroidReply="
set "PDVdroidAPKfile="
set "PDVdroidAPKname="
set "PDVdroidXMLfile="
set "PDVdroidXMLfileName="
set "PDVdroidDevicename="

Rem check if ip address is present in command 
rem if not "%2"=="" %BinPath%\adb connect %2%

cls
REM ..............................................................................
set "a="
set "b="
cd /d "%~dp0"
Rem find apk file in local folder or desktop
for %%a in (PDVdroid*.apk) do set PDVdroidAPKname=%%a
if not "%PDVdroidAPKname%"=="" set PDVdroidAPKfile=%~dp0%PDVdroidAPKname%
if not "%PDVdroidAPKname%"=="" goto :MENU_PDVDROID0
pushd %UserDesktop%
for %%a in (PDVdroid_v*.apk) do set PDVdroidAPKname=%%a
if not "%PDVdroidAPKname%"=="" set PDVdroidAPKfile=%UserDesktop%\%PDVdroidAPKname%
popd
:MENU_PDVDROID0
Rem find xml file in local folder or desktop
for %%a in (*.xml) do set PDVdroidXMLfileName=%%a
if not "%PDVdroidXMLfileName%"=="" set PDVdroidXMLfile=%~dp0%PDVdroidXMLfileName%
if not "%PDVdroidXMLfileName%"=="" goto :MENU_PDVDROID1

pushd %UserDesktop%
for %%a in (*.xml) do set PDVdroidXMLfileName=%%a
if not "%PDVdroidXMLfileName%"=="" set PDVdroidXMLfile=%UserDesktop%\%PDVdroidXMLfileName%
popd
if "%PDVdroidXMLfileName%"=="" goto :MENU_PDVDROID2
:MENU_PDVDROID1

:: ..............................................................................
:: validate XML file using schema file PDVdroid.xsd
call :PDVDROID_VALIDATE_XML
:MENU_PDVDROID2
:: ..............................................................................
%BinPath%\adb kill-server
%BinPath%\adb start-server
REM ..............................................................................
:MENU_PDVDROID_LOOP
call :MESSAGE_HEADER "Utilitario ADB para PDVdroid 2"
echo.

set a=%PDVdroidAPKfile:~0,60%
if not "%PDVdroidAPKfile%"=="" echo   APK disponivel: %a%
set a=%PDVdroidXMLfile:~0,60%
if not "%PDVdroidXMLfile%"=="" echo   XML disponivel: %a%
Rem check it is conected by IP


call :PDVDROID_GET_DEVICE_ID_OR_IP
REM if not "%2"=="" if not "%PDVdroidIP%"=="" set "PDVdroidIPport=%2"
if not "%PDVdroidIP%"=="" echo   Ligado por IP: %PDVdroidIP%     Device: %PDVdroidDevicename%
if not "%PDVdroidID%"=="" echo   Ligado por USB: %PDVdroidID%     Device: %PDVdroidDevicename%

echo.
call :MESSAGE_LINE_
echo.

if not "%PDVdroidID%"=="" goto :MENU_PDVDROID_LOOP0
if "%PDVdroidIP%"=="" echo   0 - Conectar ao Android por IP
if "%PDVdroidIP%"=="" goto :MENU_PDVDROID_LOOP1

:MENU_PDVDROID_LOOP0

if not "%PDVdroidAPKfile%"=="" ( echo   1 - Instalar PDVdroid2 )
echo   2 - Iniciar configuracoes
if not "%PDVdroidXMLfile%"=="" ( echo   3 - Enviar XML de layout + Reset)
echo     -
echo   4 - Parar PDVdroid2
echo   5 - Iniciar PDVdroid2
echo     -
echo   6 - Copiar Log para Desktop
echo     -
echo   7 - Opcoes avançadas

:MENU_PDVDROID_LOOP1
echo     -
echo   S - SAIR
echo.
call :MESSAGE_LINE_
echo.
choice /n /c 01234567S /m "Pressione 1, 2, 3 ..."
if %errorlevel%==1 call :PDVDROID_IP
if %errorlevel%==2 call :PDVDROID_INSTALL
if %errorlevel%==3 call :PDVDROID_SETUP
if %errorlevel%==4 call :PDVDROID_SEND_XML
if %errorlevel%==5 call :PDVDROID_STOP
if %errorlevel%==6 call :PDVDROID_START
if %errorlevel%==7 call :PDVDROID_GET_LOGS
if %errorlevel%==8 goto :PDVDROID_MENU_OPTIONS
if %errorlevel%==9 goto :END_OF_FILE
goto :MENU_PDVDROID_LOOP




:PDVDROID_VALIDATE_XML
:: validate XML file using schema file PDVdroid.xsd
%BinPath%\xml val -e -s %SystemDrive%\inetpub\%ProgramName0%\Content\schema\PDVdroid.xsd %PDVdroidXMLfile% >%temp%\ValidateXML0.txt 2>%temp%\ValidateXML1.txt
findstr /c:"- valid" %temp%\ValidateXML0.txt >nul 2>nul										:: find invalid 
if [%errorlevel%] == [0] exit /b
call :MESSAGE_HEADER "Erros no arquivo %PDVdroidXMLfileName%"
setlocal EnableDelayedExpansion >nul 2>nul
for /f "tokens=*" %%a in (%temp%\ValidateXML1.txt) do (
	set c=%%a
	set b=!c:*.xml:=!
	if "!b:~0,1!"=="0" echo.
	if "!b:~0,1!"=="1" echo.
	if "!b:~0,1!"=="2" echo.
	if "!b:~0,1!"=="3" echo.
	if "!b:~0,1!"=="4" echo.
	if "!b:~0,1!"=="5" echo.
	if "!b:~0,1!"=="6" echo.
	if "!b:~0,1!"=="7" echo.
	if "!b:~0,1!"=="8" echo.
	if "!b:~0,1!"=="9" echo.
	echo !b!
)
endlocal
echo.
del /q %temp%\ValidateXML0.txt >nul 2>nul
del /q %temp%\ValidateXML1.txt >nul 2>nul
set "errorlevel="
choice /n /c RC /m "Pressione (C) para Continuar, (R) para Repetir ..."
if %errorlevel%==1 goto :PDVDROID_VALIDATE_XML
if %errorlevel%==2 exit /b
goto :PDVDROID_VALIDATE_XML





:PDVDROID_SEND_XML
:: validate XML file using schema file PDVdroid.xsd
call :PDVDROID_VALIDATE_XML

call :WRITE_LOG "♦ 3 - Enviar XML de layout + Reset"
call :MESSAGE_HEADER "Enviar XML de layout + Reset do PDVdroid2 ..."
echo.
%BinPath%\adb shell am force-stop pt.acronyn.pdvdroid
timeout /t 2
%BinPath%\adb push %PDVdroidXMLfile% /sdcard/
timeout /t 2
%BinPath%\adb shell am start -n pt.acronyn.pdvdroid/.activities.MainActivity
timeout /t 2
echo. && timeout /t 3 /nobreak 2>nul >nul && exit /b






:PDVDROID_INSTALL
call :WRITE_LOG "♦ 1 - Instalar PDVdroid2"
call :MESSAGE_HEADER "Instalar PDVdroid2 ..."
echo.
echo Aguarde ...
echo.
%BinPath%\adb shell am force-stop pt.acronyn.pdvdroid
timeout /t 1 /nobreak 2>nul >nul
%BinPath%\adb uninstall pt.acronyn.pdvdroid
timeout /t 1 /nobreak 2>nul >nul
echo ... 
call :MESSAGE_HEADER "Instalar PDVdroid2 ..."
echo.
echo Enviando...
echo.
%BinPath%\adb push -p %PDVdroidAPKfile% /data/local/tmp
echo.
echo Instalando...
echo.
%BinPath%\adb shell pm install -r -d /data/local/tmp/%PDVdroidAPKname%
timeout /t 1 /nobreak 2>nul >nul
%BinPath%\adb shell rm /data/local/tmp/%PDVdroidAPKname%
REM return to menu
echo. && timeout /t 3 /nobreak 2>nul >nul && exit /b

:PDVDROID_START
call :WRITE_LOG "♦ 5 - Iniciar PDVdroid2"
call :MESSAGE_HEADER "Iniciando o PDVdroid2 ..."
echo.
%BinPath%\adb shell am force-stop pt.acronyn.pdvdroid
timeout /t 1 /nobreak 2>nul >nul
%BinPath%\adb shell am start -n pt.acronyn.pdvdroid/.activities.MainActivity
timeout /t 2 /nobreak 2>nul >nul
echo. && timeout /t 3 /nobreak 2>nul >nul && exit /b

:PDVDROID_STOP
call :WRITE_LOG "♦ 4 - Parar PDVdroid2"
call :MESSAGE_HEADER "Parando o PDVdroid2 ..."
echo.
%BinPath%\adb shell am force-stop pt.acronyn.pdvdroid
timeout /t 1 /nobreak 2>nul >nul
echo. && timeout /t 3 /nobreak 2>nul >nul && exit /b

:PDVDROID_SETUP
call :WRITE_LOG "♦ 2 - Iniciar configuracoes"
call :MESSAGE_HEADER "Iniciar configuracoes do PDVdroid2 ..."
echo.
%BinPath%\adb shell am force-stop pt.acronyn.pdvdroid
timeout /t 1 /nobreak 2>nul >nul
%BinPath%\adb shell am start -n pt.acronyn.pdvdroid/.activities.SetupActivity
timeout /t 2 /nobreak 2>nul >nul
echo. && timeout /t 3 /nobreak 2>nul >nul && exit /b


:PDVDROID_GET_LOGS
call :WRITE_LOG "♦ 6 - Copiar Log para Desktop"
call :MESSAGE_HEADER "Baixando Logs para o Desktop..."
echo.
%BinPath%\adb pull "/sdcard/Android/data/pt.acronyn.pdvdroid/logs"
Rem Zipar Logs no desktop
set _my_logfolder=%date%
set _my_logfolder=%_my_logfolder: =_%
set _my_logfolder=%_my_logfolder%_%time%
set _my_logfolder=%_my_logfolder: =0%
set _my_logfolder=%_my_logfolder::=%
set _my_logfolder=%_my_logfolder:/=%
set _my_logfolder=%_my_logfolder:~0,-3%
for /f "tokens=1 delims=." %%a in ("%_my_logfolder%") do (set _my_logfolder=LOG_PDVDROID_%%a)
%BinPath%\7Z a -aoa %UserDesktop%\%_my_logfolder%.zip *.log
del *.log
Rem excluiri pasta logs no Android 
%BinPath%\adb shell rm -r "/sdcard/Android/data/pt.acronyn.pdvdroid/logs"
echo. 
echo Arquivos Log disponiveis em PDVdroidLogs.zip
REM return to menu
echo. && timeout /t 5 /nobreak 2>nul >nul  && exit /b

:PDVDROID_IP
REM Alterar url dos icons
call :WRITE_LOG "♦ 0 - Conectar ao PDVdroid2 por IP"
call :MESSAGE_HEADER "Digite ip do dispositivo Android"
echo.
REM check if only one device  detected
for /f "skip=1 delims=" %%a in ('%BinPath%\adb devices') do set "PDVdroidID=%%a"
for /f "skip=2 delims=" %%a in ('%BinPath%\adb devices') do set "PDVdroidIP=%%a"
if not "%PDVdroidIP%"=="" (
	echo   ERRO: Um outro disposivivo ja esta conectado
	echo   Dispositivo: %PDVdroidID%
	set "PDVdroidIP="
	set "PDVdroidID="
	timeout /t 5 /nobreak 2>nul >nul
	exit /b
)
set "PDVdroidIP="
set "PDVdroidID="

set /P PDVdroidIP=Digite ip (Ex: 192.168.0.55):

REM check if %PDVdroidIP% string contains 3 points
set "DotCount=-1"
for %%a in ("%PDVdroidIP:.=" "%") do set /A DotCount+=1
if not [%DotCount%]==[3] (set "PDVdroidIP=" && exit /b)

REM exit if not pingable
call :IS_PINGABLE %PDVdroidIP% && (set "PDVdroidIPdetected=1") || (set "PDVdroidIPdetected=0") 
if [%PDVdroidIPdetected%]==[0] (
	echo *
	echo * No device detected on IP %PDVdroidIP%
	set "PDVdroidIP="
    timeout /t 3 /nobreak 2>nul >nul && exit /b
)

REM check if it is already conected 
%BinPath%\adb devices | Find "%PDVdroidIP%">nul >>nul
if %errorlevel% equ 0 (
	echo *
	echo * Already connected to %PDVdroidIP%
    timeout /t 3 /nobreak 2>nul >nul && exit /b
) 

echo *
%BinPath%\adb kill-server
%BinPath%\adb start-server
echo *
rem check replay for connect request
%BinPath%\adb connect %PDVdroidIP% | Find "unable">nul >>nul
if [%errorlevel%] == [1] ( timeout /t 3 /nobreak 2>nul >nul  && exit /b )


set "PDVdroidIP="
set "PDVdroidIPdetected=0
echo * No device detected! No connection established ...
REM return to menu
:PDVDROID_IP_
echo * && timeout /t 3 /nobreak 2>nul >nul  && exit /b


:PDVDROID_GET_DEVICE_ID_OR_IP
REM get trird line string
set "PDVdroidID="
for /f "skip=2 delims=" %%a in ('%BinPath%\adb devices') do set "PDVdroidID=%%a"
if not "%PDVdroidID%"=="" (	
	echo   ERRO: Apenas 1 dispositivo pode estar ligado!
	set "PDVdroidIP="
	set "PDVdroidID="
	exit /b
)

REM get second line string2
for /f "skip=1 delims=" %%a in ('%BinPath%\adb devices') do set "PDVdroidID=%%a"
if "%PDVdroidID%"=="" exit /b

REM Get device Name 
for /f "tokens=* USEBACKQ" %%a in (`%BinPath%\adb devices -l`) do set PDVdroidDevicename=%%a
for /f "tokens=5 delims=:" %%a in ("%PDVdroidDevicename%") do set PDVdroidDevicename=%%a

REM trim strint to find possible IP
for /f "delims=þ" %%a in ("%PDVdroidID::=þ%") do set "PDVdroidIP=%%a"
REM validate number of dots in IP
set "DotCount=-1"
for %%a in ("%PDVdroidIP:.=" "%") do set /A DotCount+=1
if [%DotCount%]==[3] (
	%BinPath%\adb start-server
	%BinPath%\adb connect %PDVdroidIP%>nul >>nul
	set "PDVdroidID="
	exit /b)

REM trim strint to find USB ID
set "PDVdroidIP="
for /F %%a in ("%PDVdroidID%") do set "PDVdroidID=%%a
for /f "tokens=4 delims=:" %%a in ("%PDVdroidDevicename%") do set PDVdroidDevicename=%%a
exit /b


:IS_PINGABLE <comp>
ping -n 1 -w 3000 -4 -l 8 "%~1" | Find "TTL=">nul >>nul
exit /b


:REMOVE_APPS
call :WRITE_LOG "♦9 - Remover Apps preinstaladas"
call :MESSAGE_HEADER "Remover Apps preinstaladas..."
echo.
call :MESSAGE_ATENCTION "Remover apps essenciais ao funcionamento do Android"
set /P M=Continuar ? S (Sim) ou N (Nao) seguido de ENTER:
if /I %M%==S goto :REMOVE_APPS0
exit /b
:REMOVE_APPS0
for %%a in (
"com.bluestacks.bsxlauncher"
"com.bluestacks.gamecenter"
"com.bluestacks.launcher"
"com.bluestacks.filemanager"
"com.bluestacks.nowgg"
"com.bluestacks.piggy"
"com.bluestacks.quest"
"com.bluestacks.settings"

"com.android.camera2"
"com.android.deskclock"
"com.android.contacts"
"com.android.documentsui"
"com.google.android.syncadapters.calendar"
"com.google.android.play.games"
"com.android.calendar"
"com.android.dialer"
"com.bluestacks.launcher"
"gg.now.billing.service2"
"gg.now.accounts"
"gg.now.billing.service"
"com.android.gallery3d"
"com.ldmnq.launcher3"
"com.android.ld.appstore"
"com.android.vpndialogs"
"com.android.launcher3"
"com.android.calculator2"
"com.android.cts.priv.ctsshim"
"com.android.rockchip"

"com.cyanogenmod.filemanager"

"com.google.android.apps.docs"
"com.google.android.apps.maps"
"com.google.android.apps.photos"
"com.google.android.apps.tachyon"
"com.google.android.feedback"
"com.google.android.gm"
"com.google.android.googlequicksearchbox"
"com.google.android.marvin.talkback"
"com.google.android.music"
"com.google.android.syncadapters.calendar"
"com.google.android.syncadapters.contacts"
"com.google.android.talk"
"com.google.android.tts"
"com.google.android.videos"
"com.google.android.youtube"
"com.google.android.youtube.tv"
"com.google.android.gsm"
"com.google.android.play.games"

"com.facebook.services"
"com.facebook.system"
"com.facebook.appmanager"
"com.facebook.katana"

"com.droidlogic"
"com.droidlogic.tv.settings"
"com.droidlogic.appinstall"
"com.droidlogic.mediacenter"
"com.droidlogic.FileBrower"
"com.droidlogic.videoplayer"
"com.droidlogic.imageplayer"
"com.droidlogic.miracast"
"com.droidlogic.BluetoothRemote"
"com.droidlogic.SubTitleService"
"com.droidlogic.videoplayer"

"com.rockchips.dlna"
"com.rockchips.devicetest"
"com.rockchips.mediacenter"

"com.mi.android.globalpersonalassistant"
"com.mi.global.shop"
"com.mi.global.bbs"
"com.mi.webkit.core"
"com.mipay.wallet.in"
"com.miui.analytics"
"com.miui.android.fashiongallery"
"com.miui.bugreport"
"com.miui.cloudbackup"
"com.miui.cloudservice"
"com.miui.cloudservice.sysbase"
"com.miui.hybrid.accessory"
"com.miui.klo.bugreport"
"com.miui.miwallpaper"
"com.miui.player"
"com.miui.providers.weather"
"com.miui.screenrecorder"
"com.miui.translationservice"
"com.miui.translation.kingsoft"
"com.miui.translation.youdao"
"com.miui.touchassistant"
"com.miui.videoplayer"
"com.miui.virtualsim"
"com.miui.weather2"
"com.miui.yellowpage"
"com.xiaomi.account"
"com.xiaomi.discover"
"com.xiaomi.micloud.sdk"
"com.xiaomi.midrop"
"com.xiaomi.mipicks"
"com.xiaomi.oversea.ecom"
"com.xiaomi.payment"
"com.xiaomi.finddevice"
"com.xiaomi.xmsf"

"com.swiftkey.languageprovider"
"com.swiftkey.swiftkeyconfigurator"

"com.hkw.simplelauncher"
"com.mbx.settingsmbox"
"com.cghs.stresstest"
"com.example.a"
"com.mfashiongallery.emag"
"com.waxrain.airplaydmr"
"com.netflix.mediaclient"
"com.topjohnwu.magisk"
"com.ftest"
"com.swe.dgbluancher"
"com.pekall.fmradio"
"com.amaze.filemanager"

"apptech.win.launcher"
"ru.andr7e.deviceinfohw"
"org.xbmc.kodi"
"cm.aptoide.pt"
"ua.droidsft.btdevinfoad"
"me.thomastv.rebootupdate"

) do (
	echo . %%a
	%BinPath%\adb shell am force-stop %%a>nul 2>nul
	%BinPath%\adb shell pm uninstall %%a>nul 2>nul
	%BinPath%\adb shell pm uninstall --user 0 %%a>nul 2>nul
	%BinPath%\adb shell pm hide %%a>nul 2>nul
)


REM enable google play
%BinPath%\adb shell pm unhide com.android.vending>nul 2>nul

echo . && timeout /t 3 /nobreak 2>nul >nul  && exit /b




:PDVDROID_MENU_SIZE
call :WRITE_LOG "♦ 9 - Ajustar resolucao e dpi da tela"
REM ..............................................................................
:PDVDROID_MENU_SIZE_LOOP
call :MESSAGE_HEADER "Ajustar resolucao e dpi da tela"
echo.
set "PDVdroidSize="
for /f "delims=" %%i in ('%BinPath%\adb shell wm size') do set PDVdroidSize=%%i
if "%PDVdroidSize%"=="" exit /b
set "PDVdroidSize=%PDVdroidSize:: =" & set "PDVdroidSize=%"
echo   Resolucao atual: %PDVdroidSize%

set "PDVdroidDensity="
for /f "delims=" %%i in ('%BinPath%\adb shell wm density') do set PDVdroidDensity=%%i
if "%PDVdroidDensity%"=="" exit /b
set "PDVdroidDensity=%PDVdroidDensity:: =" & set "PDVdroidDensity=%"
echo   Dpi atual: %PDVdroidDensity%dpi

echo.
call :MESSAGE_LINE_
echo.
echo   0 - Reset resolucao                                          A - Reset dpi
echo   1 - 1920x1080                                                B - 160dpi
echo   2 - 1280x720                                                 C - 240dpi
echo   3 - 1280x800                                                 D - 320dpi
echo   4 - 720x1280                                                 E - 480dpi
echo     -                                                          F - 640dpi
echo   8 - Scaling on                                               
echo   9 - Scaling off
echo     -
echo   S - SAIR
echo.
call :MESSAGE_LINE_
echo.
setlocal
choice /n /c 01234abcdef89s /m "Pressione 0, 1, 2, 3 ..."
set "choice=%errorlevel%" && set "errorlevel=0"
if %choice%==1 (%BinPath%\adb shell wm size reset)
if %choice%==2 (%BinPath%\adb shell wm size 1920x1080)
if %choice%==3 (%BinPath%\adb shell wm size 1280x720)
if %choice%==4 (%BinPath%\adb shell wm size 1280x800)
if %choice%==5 (%BinPath%\adb shell wm size 720x1280)
if %choice%==6 (%BinPath%\adb shell wm density reset)
if %choice%==7 (%BinPath%\adb shell wm density 160)
if %choice%==8 (%BinPath%\adb shell wm density 240)
if %choice%==9 (%BinPath%\adb shell wm density 320)
if %choice%==10 (%BinPath%\adb shell wm density 480)
if %choice%==11 (%BinPath%\adb shell wm density 640)
if %choice%==12 (%BinPath%\adb shell wm scaling auto)
if %choice%==13 (%BinPath%\adb shell wm scaling off)
if %choice%==14 (endlocal && goto :PDVDROID_MENU_OPTIONS)
timeout /t 1 /nobreak 2>nul >nul
endlocal
goto :PDVDROID_MENU_SIZE_LOOP




:PDVDROID_MENU_OPTIONS
call :WRITE_LOG "♦ 8 - Opcoes avançadas"
REM ..............................................................................
:PDVDROID_MENU_OPTIONS_LOOP
call :MESSAGE_HEADER "Opcoes avançadas"
echo.
echo   0 - Configuracoes do Android
echo   1 - Ligar Bluetooth
echo   2 - Configuracoes Bluetooth
echo     - 
echo   3 - Reconfigurar Default Launcher
echo     - 
echo   4 - Reiniciar o Android
echo     - 
echo   5 - Print de tela para Desktop
echo     - 
echo   6 - Ajustar resolução e dpi da tela
echo     - 
echo   7 - Remover Apps pré-instaladas 
echo     - 
echo   S - SAIR
echo.
call :MESSAGE_LINE_
echo.
setlocal
choice /n /c 01234567s /m "Pressione 0, 1, 2, 3 ..."
set "choice=%errorlevel%" && set "errorlevel=0"
if %choice%==1 (%BinPath%\adb shell am start -a android.settings.SETTINGS)
if %choice%==2 (%BinPath%\adb shell settings put global bluetooth_on 1)
if %choice%==3 (%BinPath%\adb shell am start -a android.settings.BLUETOOTH_SETTINGS)
if %choice%==4 (%BinPath%\adb shell am start -a android.intent.action.MAIN)
if %choice%==5 (%BinPath%\adb reboot)
if %choice%==6 (%BinPath%\adb shell screencap -p /sdcard/screenshot.png && %BinPath%\adb pull "/sdcard/screenshot.png" %UserDesktop%)
if %choice%==7 (endlocal && goto :PDVDROID_MENU_SIZE)
if %choice%==8 (call :REMOVE_APPS)
if %choice%==9 (endlocal && goto :MENU_PDVDROID_LOOP)
timeout /t 1 /nobreak 2>nul >nul
endlocal
goto :PDVDROID_MENU_OPTIONS_LOOP























:SETPATHS
set SqlBinPath=%~1
set SqlDataPath=%~2
set SqlProgPath=%~3
exit /b

 
:END_OF_FILE
chcp 850 2>NUL >NUL
title Command Prompt
COLOR 7
mode 80,30
cd %CurrentPath%
cls

:EOF
REM CHCP 850 2>NUL >NUL
REM cls
echo %date% %time:~0,8% ♦ S - SAIR>> %LogFile%