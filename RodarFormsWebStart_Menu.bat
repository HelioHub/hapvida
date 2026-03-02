@echo off
REM ===============================================
REM Forms Web Start Launcher - Ultra Clickable (corrigido)
REM ===============================================

REM --- CONFIGURAÇÕES ---
set FRM_WEBSTART=C:\Oracle\Middleware\Oracle_Home\bin\frmweb.exe
set JAVAWS=C:\Program Files\Java\latest\jre-1.8\bin\javaws.exe
set DEST_FORMS_DIR=C:\Oracle\Middleware\Oracle_Home\user_projects\domains\base_domain\config\fmwconfig\servers\WLS_FORMS\applications\formsapp_12.2.1\forms
set FORMS_PATH=C:\Oracle\Middleware\Oracle_Home\user_projects\domains\base_domain\config\fmwconfig\servers\WLS_FORMS\applications\formsapp_12.2.1\forms
set DB_USER=DEVAPP
set DB_PASS=dev123
set DB_SERVICE=ORCLPDB
set CONFIG=webstart
set WIDTH=1024
set HEIGHT=768

REM --- LISTA OS FORMS ---
echo =============================================
echo Menu de Forms disponíveis:
echo =============================================
set COUNT=0
for %%F in (*.fmx) do (
    set /A COUNT+=1
    call :showform %%F %COUNT%
)
if %COUNT%==0 (
    echo Nenhum arquivo .fmx encontrado nesta pasta!
    pause
    exit /b
)

REM --- ESCOLHA ---
:ESCOLHA
set /p escolha=Escolha o número do form: 
set IDX=0
set FORM=
for %%F in (*.fmx) do (
    set /A IDX+=1
    if "%escolha%"=="%IDX%" set FORM=%%F
)
if "%FORM%"=="" (
    echo Escolha invalida. Tente novamente.
    goto ESCOLHA
)

REM --- COPIA PARA PASTA FORMS ---
echo Copiando %FORM% para a pasta forms...
copy /Y "%FORM%" "%DEST_FORMS_DIR%"
if errorlevel 1 (
    echo ERRO ao copiar o arquivo. Verifique se a pasta "%DEST_FORMS_DIR%" existe.
    pause
    exit /b
)

REM --- EXECUTA COM JAVA WEB START ---
echo Gerando JNLP e abrindo via Java Web Start...
echo "http://localhost:9001/forms/frmservlet?form=%FORM%&userid=%DB_USER%/%DB_PASS%@%DB_SERVICE%&config=%CONFIG%&width=%WIDTH%&height=%HEIGHT%"
"%JAVAWS%" "http://localhost:9001/forms/frmservlet?form=%FORM%&userid=%DB_USER%/%DB_PASS%@%DB_SERVICE%&config=%CONFIG%&width=%WIDTH%&height=%HEIGHT%"
echo "%JAVAWS%"


echo =============================================
echo Iniciado! Aguarde a aplicacao carregar...
echo =============================================
pause
exit /b

:showform
echo %2) %1
exit /b