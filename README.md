# Projeto Teste Técnico HAPVIDA - Hélio Marques

CRUD de Clientes utilizando ORACLE FORM e PL/SQL.

## Motagem do Ambiente de Desenvolvimento (Download efetuado direto no Portal da ORACLE)

	### Instalação do Banco de dados ORACLE 21c XE:
![## Banco](https://github.com/HelioHub/hapvida/blob/main/images/Banco21cXE.PNG)

	### Instalação do ORACLE Forms 12.2.1.19.0:
![## Banco](https://github.com/HelioHub/hapvida/blob/main/images/OracleForms.PNG)

	### Instalação do Form Builder Configuration (Conexão Form com o Banco de dados):
![## Banco](https://github.com/HelioHub/hapvida/blob/main/images/FormBuilderConfig.PNG)

	### Configuração TNSNAMES.ORA do Builder:
	
		XE21C =
		
		  (DESCRIPTION =
		  
			(ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
			
			(CONNECT_DATA =
			
			  (SERVICE_NAME = XEPDB1)
			  
			)
			
		  )
		
		Obs.: minha pasta no caso 'C:\Oracle\Middleware\Builder'.
		  
	### Instalçao e Configuração do SQL Developer:
![## Banco](https://github.com/HelioHub/hapvida/blob/main/images/SQLDeveloper.PNG)
		password SYSTEM/ORACLE@XE;

## GITHub

	echo "# hapvida" >> README.md
	git init
	git add README.md
	git commit -m "first commit"
	git branch -M main
	git remote add origin git@github.com:HelioHub/hapvida.git
	git push -u origin main
	
## US01 - Modelagem de Objetos de Banco

	### Representação conceitual
		+--------------------------------------+
		|              TB_CLIENTE              |
		+--------------------------------------+
		| PK ID_CLIENTE : NUMBER(10)           |
		| NOME : VARCHAR2(150) {NOT NULL}      |
		| EMAIL : VARCHAR2(150) {UNIQUE}       |
		| CEP : VARCHAR2(8)                    |
		| LOGRADOURO : VARCHAR2(200)           |
		| BAIRRO : VARCHAR2(100)               |
		| CIDADE : VARCHAR2(100)               |
		| UF : CHAR(2) {CHECK Estados BR}      |
		| ATIVO : NUMBER(1) {0/1}              |
		| DT_CRIACAO : TIMESTAMP               |
		| DT_ATUALIZACAO : TIMESTAMP           |
		+--------------------------------------+	

	### Observações importantes (pensando já no Forms)
		✔ PK numérica com sequence → ideal para Data Block Wizard
		✔ EMAIL unique → valida automaticamente no banco
		✔ UF com CHECK → Forms já mostra erro automático
		✔ ATIVO 0/1 → perfeito para checkbox
		✔ DT_ATUALIZACAO via trigger → controle automático

	### Scripts create.sql (criação) e drop.sql (remoção):

			..\scripts\create.sql: 
			-- =========================================
			-- CREATE OBJECTS - USER no Banco pluggable (XEPDB1) 
			-- =========================================
			CONN SYSTEM/ORACLE@XE;

			ALTER SESSION SET CONTAINER = XEPDB1;

			DROP USER DEVAPP CASCADE;

			CREATE USER DEVAPP
			IDENTIFIED BY dev123
			DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;

			GRANT CREATE SESSION TO DEVAPP;
			GRANT RESOURCE TO DEVAPP;
			GRANT CONNECT TO DEVAPP;
			GRANT DBA TO DEVAPP; 
	
	        OBS.:
	        ---- NÃO É RECOMENDADO TOTAL PODER DE 'DBA' PARA O USUÁRIO DEV, CORRETO FORNECER SOMENTE OS GRANTS NECESSÁRIOS. MAS, SÓ TESTE AQUI...
			----

			..\scripts\tnsnames.ora: 
			-- =========================================
			-- CREATE SERVICE_NAME XEDEV NO TNSNAMES.ORA (C:\app\hislindo\product\21c\homes\OraDB21Home1\network\admin\tnsnames.ora - minha pasta no meu caso)
			-- =========================================
			XEDEV =
			  (DESCRIPTION =
				(ADDRESS = (PROTOCOL = TCP)(HOST = HELIOSONY)(PORT = 1521))
				(CONNECT_DATA =
				  (SERVER = DEDICATED)
				  (SERVICE_NAME = XEPDB1)
				)
			  )

	
			..\scripts\create.sql: 
			-- =========================================
			-- CREATE OBJECTS - TB_CLIENTE
			-- =========================================

			-- 1. TABELA
			CREATE TABLE TB_CLIENTE (
				ID_CLIENTE        NUMBER(10)         NOT NULL,
				NOME              VARCHAR2(150)      NOT NULL,
				EMAIL             VARCHAR2(150),
				CEP               VARCHAR2(8),
				LOGRADOURO        VARCHAR2(200),
				BAIRRO            VARCHAR2(100),
				CIDADE            VARCHAR2(100),
				UF                CHAR(2),
				ATIVO             NUMBER(1) DEFAULT 1 NOT NULL,
				DT_CRIACAO        TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
				DT_ATUALIZACAO    TIMESTAMP
			);

			-- 2. CONSTRAINTS

			ALTER TABLE TB_CLIENTE ADD CONSTRAINT PK_TB_CLIENTE 
			PRIMARY KEY (ID_CLIENTE);

			ALTER TABLE TB_CLIENTE ADD CONSTRAINT UK_TB_CLIENTE_EMAIL 
			UNIQUE (EMAIL);

			ALTER TABLE TB_CLIENTE ADD CONSTRAINT CK_TB_CLIENTE_UF 
			CHECK (UF IN (
			'AC','AL','AP','AM','BA','CE','DF','ES','GO',
			'MA','MT','MS','MG','PA','PB','PR','PE','PI',
			'RJ','RN','RS','RO','RR','SC','SP','SE','TO'
			));

			ALTER TABLE TB_CLIENTE ADD CONSTRAINT CK_TB_CLIENTE_ATIVO
			CHECK (ATIVO IN (0,1));

			-- 3. SEQUENCE
			CREATE SEQUENCE SEQ_CLIENTE
			START WITH 1
			INCREMENT BY 1
			NOCACHE
			NOCYCLE;

			-- 4. TRIGGER BEFORE INSERT
			CREATE OR REPLACE TRIGGER TRG_CLIENTE_BI
			BEFORE INSERT ON TB_CLIENTE
			FOR EACH ROW
			BEGIN
				IF :NEW.ID_CLIENTE IS NULL THEN
					SELECT SEQ_CLIENTE.NEXTVAL
					INTO   :NEW.ID_CLIENTE
					FROM   DUAL;
				END IF;

				IF :NEW.DT_CRIACAO IS NULL THEN
					:NEW.DT_CRIACAO := SYSTIMESTAMP;
				END IF;
			END;
			/

			-- 5. TRIGGER BEFORE UPDATE (boa prática)
			CREATE OR REPLACE TRIGGER TRG_CLIENTE_BU
			BEFORE UPDATE ON TB_CLIENTE
			FOR EACH ROW
			BEGIN
				:NEW.DT_ATUALIZACAO := SYSTIMESTAMP;
			END;
			/			

			
			..\drop.sql:
			-- =========================================
			-- DROP OBJECTS - TB_CLIENTE
			-- =========================================

			DROP TRIGGER TRG_CLIENTE_BU;
			DROP TRIGGER TRG_CLIENTE_BI;
			DROP TABLE TB_CLIENTE CASCADE CONSTRAINTS;
			DROP SEQUENCE SEQ_CLIENTE;


## US02 — Camada PL/SQL (Package de Negócio)			
		
			
	### Arquitetura: API PL/SQL será consumido pelo Forms, não na tabela direta.
	
	-- =========================================
	PKG_CLIENTE – SPEC:
	..\pkg_cliente_spec.sql
	-- =========================================
	CREATE OR REPLACE PACKAGE PKG_CLIENTE AS

		-- FUNÇÕES UTILITÁRIAS
		-- =========================================

		FUNCTION FN_VALIDAR_EMAIL (
			p_email VARCHAR2
		) RETURN NUMBER;

		FUNCTION FN_NORMALIZAR_CEP (
			p_cep VARCHAR2
		) RETURN VARCHAR2;


		-- CRUD
		-- =========================================

		PROCEDURE PRC_INSERIR_CLIENTE (
			p_nome        VARCHAR2,
			p_email       VARCHAR2,
			p_cep         VARCHAR2,
			p_logradouro  VARCHAR2,
			p_bairro      VARCHAR2,
			p_cidade      VARCHAR2,
			p_uf          VARCHAR2,
			p_ativo       NUMBER,
			p_id_cliente  OUT NUMBER
		);

		PROCEDURE PRC_ATUALIZAR_CLIENTE (
			p_id_cliente  NUMBER,
			p_nome        VARCHAR2,
			p_email       VARCHAR2,
			p_cep         VARCHAR2,
			p_logradouro  VARCHAR2,
			p_bairro      VARCHAR2,
			p_cidade      VARCHAR2,
			p_uf          VARCHAR2,
			p_ativo       NUMBER
		);

		PROCEDURE PRC_DELETAR_CLIENTE (
			p_id NUMBER
		);

		PROCEDURE PRC_LISTAR_CLIENTES (
			p_nome  VARCHAR2,
			p_email VARCHAR2,
			p_rc    OUT SYS_REFCURSOR
		);

	END PKG_CLIENTE;
	/	

	-- =========================================
	PKG_CLIENTE – BODY:
	..\pkg_cliente_body.sql
	-- =========================================
	CREATE OR REPLACE PACKAGE BODY PKG_CLIENTE AS

		-- CONSTANTES DE ERRO
		-- =========================================
		c_erro_nome_obrigatorio   CONSTANT NUMBER := -20001;
		c_erro_email_invalido     CONSTANT NUMBER := -20002;
		c_erro_cep_invalido       CONSTANT NUMBER := -20003;
		c_erro_uf_invalida        CONSTANT NUMBER := -20004;
		c_erro_cliente_nao_existe CONSTANT NUMBER := -20005;


		-- FUNÇÃO VALIDAR EMAIL
		-- =========================================
		FUNCTION FN_VALIDAR_EMAIL (
			p_email VARCHAR2
		) RETURN NUMBER
		IS
		BEGIN
			IF p_email IS NULL THEN
				RETURN 1;
			END IF;

			IF REGEXP_LIKE(
				   p_email,
				   '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
			   )
			THEN
				RETURN 1;
			ELSE
				RETURN 0;
			END IF;
		END;


		-- FUNÇÃO NORMALIZAR CEP
		-- =========================================
		FUNCTION FN_NORMALIZAR_CEP (
			p_cep VARCHAR2
		) RETURN VARCHAR2
		IS
			v_cep VARCHAR2(8);
		BEGIN
			IF p_cep IS NULL THEN
				RETURN NULL;
			END IF;

			v_cep := REGEXP_REPLACE(p_cep, '[^0-9]', '');

			IF LENGTH(v_cep) <> 8 THEN
				RAISE_APPLICATION_ERROR(
					c_erro_cep_invalido,
					'CEP deve conter exatamente 8 dígitos.'
				);
			END IF;

			RETURN v_cep;
		END;


		-- PROCEDURE VALIDAR DADOS (INTERNA)
		-- =========================================
		PROCEDURE VALIDAR_DADOS (
			p_nome  VARCHAR2,
			p_email VARCHAR2,
			p_cep   VARCHAR2,
			p_uf    VARCHAR2
		)
		IS
			v_dummy VARCHAR2(8);
		BEGIN
			IF p_nome IS NULL THEN
				RAISE_APPLICATION_ERROR(
					c_erro_nome_obrigatorio,
					'Nome é obrigatório.'
				);
			END IF;

			IF FN_VALIDAR_EMAIL(p_email) = 0 THEN
				RAISE_APPLICATION_ERROR(
					c_erro_email_invalido,
					'E-mail inválido.'
				);
			END IF;

			IF p_cep IS NOT NULL THEN
				v_dummy := FN_NORMALIZAR_CEP(p_cep);
			END IF;

			IF p_uf IS NOT NULL AND
			   p_uf NOT IN (
			   'AC','AL','AP','AM','BA','CE','DF','ES','GO',
			   'MA','MT','MS','MG','PA','PB','PR','PE','PI',
			   'RJ','RN','RS','RO','RR','SC','SP','SE','TO')
			THEN
				RAISE_APPLICATION_ERROR(
					c_erro_uf_invalida,
					'UF inválida.'
				);
			END IF;
		END;


		-- INSERIR
		-- =========================================
		PROCEDURE PRC_INSERIR_CLIENTE (
			p_nome        VARCHAR2,
			p_email       VARCHAR2,
			p_cep         VARCHAR2,
			p_logradouro  VARCHAR2,
			p_bairro      VARCHAR2,
			p_cidade      VARCHAR2,
			p_uf          VARCHAR2,
			p_ativo       NUMBER,
			p_id_cliente  OUT NUMBER
		)
		IS
			v_cep VARCHAR2(8);
		BEGIN
			VALIDAR_DADOS(p_nome, p_email, p_cep, p_uf);

			v_cep := FN_NORMALIZAR_CEP(p_cep);

			INSERT INTO TB_CLIENTE (
				ID_CLIENTE,
				NOME,
				EMAIL,
				CEP,
				LOGRADOURO,
				BAIRRO,
				CIDADE,
				UF,
				ATIVO
			)
			VALUES (
				SEQ_CLIENTE.NEXTVAL,
				p_nome,
				p_email,
				v_cep,
				p_logradouro,
				p_bairro,
				p_cidade,
				p_uf,
				NVL(p_ativo,1)
			)
			RETURNING ID_CLIENTE INTO p_id_cliente;

		END;


		-- ATUALIZAR
		-- =========================================
		PROCEDURE PRC_ATUALIZAR_CLIENTE (
			p_id_cliente  NUMBER,
			p_nome        VARCHAR2,
			p_email       VARCHAR2,
			p_cep         VARCHAR2,
			p_logradouro  VARCHAR2,
			p_bairro      VARCHAR2,
			p_cidade      VARCHAR2,
			p_uf          VARCHAR2,
			p_ativo       NUMBER
		)
		IS
			v_cep VARCHAR2(8);
			v_count NUMBER;
		BEGIN
			SELECT COUNT(*)
			INTO v_count
			FROM TB_CLIENTE
			WHERE ID_CLIENTE = p_id_cliente;

			IF v_count = 0 THEN
				RAISE_APPLICATION_ERROR(
					c_erro_cliente_nao_existe,
					'Cliente não encontrado.'
				);
			END IF;

			VALIDAR_DADOS(p_nome, p_email, p_cep, p_uf);

			v_cep := FN_NORMALIZAR_CEP(p_cep);

			UPDATE TB_CLIENTE
			   SET NOME       = p_nome,
				   EMAIL      = p_email,
				   CEP        = v_cep,
				   LOGRADOURO = p_logradouro,
				   BAIRRO     = p_bairro,
				   CIDADE     = p_cidade,
				   UF         = p_uf,
				   ATIVO      = p_ativo
			 WHERE ID_CLIENTE = p_id_cliente;

		END;


		-- DELETAR
		-- =========================================
		PROCEDURE PRC_DELETAR_CLIENTE (
			p_id NUMBER
		)
		IS
		BEGIN
			DELETE FROM TB_CLIENTE
			WHERE ID_CLIENTE = p_id;

			IF SQL%ROWCOUNT = 0 THEN
				RAISE_APPLICATION_ERROR(
					c_erro_cliente_nao_existe,
					'Cliente não encontrado.'
				);
			END IF;
		END;


		-- LISTAR
		-- =========================================
		PROCEDURE PRC_LISTAR_CLIENTES (
			p_nome  VARCHAR2,
			p_email VARCHAR2,
			p_rc    OUT SYS_REFCURSOR
		)
		IS
		BEGIN
			OPEN p_rc FOR
				SELECT *
				  FROM TB_CLIENTE
				 WHERE (p_nome  IS NULL OR UPPER(NOME)  LIKE UPPER('%' || p_nome || '%'))
				   AND (p_email IS NULL OR UPPER(EMAIL) LIKE UPPER('%' || p_email || '%'))
				 ORDER BY NOME;
		END;

	END PKG_CLIENTE;
	/		

	..\synonym.sql:
	-- =========================================
	-- SYNONYM OBJECTS 
	-- =========================================
	CREATE PUBLIC SYNONYM TB_CLIENTE FOR DEVAPP.TB_CLIENTE;
	CREATE PUBLIC SYNONYM PKG_CLIENTE FOR DEVAPP.PKG_CLIENTE;
	CREATE PUBLIC SYNONYM SEQ_CLIENTE FOR DEVAPP.SEQ_CLIENTE;

	### Arquitetura
		✔ API completa
		✔ Validação centralizada
		✔ Insert / Update / Delete
		✔ Listagem com filtros
		✔ Sem commit interno
		✔ Erros padronizados
		✔ Pronto para Forms chamar via:

## US03 — Tela Oracle Forms (Cadastro de Cliente)

	### Conexão do FORM com o Banco XE 21c baseado do TNSNAMES.ORA conforme imagem abaixo:
![## Form](https://github.com/HelioHub/hapvida/blob/main/images/ConexaoFORMcomBANCOXE.PNG)

	### Instalção do WebLogic Server para Excutar o Form C:\HelioMarques\fmw_12.2.1.4.0_infrastructure\fmw_12.2.1.4.0_infrastructure.jar
![## Form](https://github.com/HelioHub/hapvida/blob/main/images/WebLogicServer.PNG)
	
	### Criação do .BAT 'RodarFormsWebStart_Menu.bat' para rodar o FORM EXECUTANDO NO JAVA WEB START:
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
		
	

## Cadastro de Cliente: 
![## Form](https://github.com/HelioHub/hapvida/blob/main/images/CadastroCliente.PNG)

		Arquitetura:
		✔ UI simples
		✔ API centralizada no package
		✔ Transação controlada no Forms
		✔ Validação dupla (UI + banco)
		✔ Separação clara de responsabilidades	

## US04 — Tratamento de Erros e Logging

		### PADRONIZAÇÃO DE ERROS
		Tabela de Códigos
		Código	Tipo
		-20001	Validação de entrada
		-20002	Violação de unicidade
		-20003	Registro não encontrado
		-20004	Regra de negócio
		-20005	Erro inesperado
		

		### TABELA DE LOG (Opcional recomendado)
		..\scripts\tb_log_erro.sql
		
		CREATE TABLE TB_LOG_ERRO (
			ID_LOG     NUMBER GENERATED BY DEFAULT AS IDENTITY,
			DT_EVENTO  TIMESTAMP DEFAULT SYSTIMESTAMP,
			USUARIO    VARCHAR2(50),
			ORIGEM     VARCHAR2(100),
			COD_ERRO   NUMBER,
			MENSAGEM   VARCHAR2(4000)
		);
		
		

		### PROCEDURE DE LOG (Autonomous Transaction)
		..\scripts\pkg_log_spec.sql
		
		CREATE OR REPLACE PACKAGE PKG_LOG AS
		   PROCEDURE PRC_LOG_ERRO(
			  p_origem   VARCHAR2,
			  p_cod_erro NUMBER,
			  p_msg      VARCHAR2
		   );
		END PKG_LOG;
		/
		
		..\scripts\pkg_log_body.sql
		CREATE OR REPLACE PACKAGE BODY PKG_LOG AS

		   PROCEDURE PRC_LOG_ERRO(
			  p_origem   VARCHAR2,
			  p_cod_erro NUMBER,
			  p_msg      VARCHAR2
		   ) IS
			  PRAGMA AUTONOMOUS_TRANSACTION;
		   BEGIN
			  INSERT INTO TB_LOG_ERRO (
				 USUARIO,
				 ORIGEM,
				 COD_ERRO,
				 MENSAGEM
			  )
			  VALUES (
				 USER,
				 p_origem,
				 p_cod_erro,
				 SUBSTR(p_msg,1,4000)
			  );

			  COMMIT;
		   END;

		END PKG_LOG;
		/

		✔ Usa AUTONOMOUS_TRANSACTION
		✔ Não interfere na transação principal
		✔ Ideal para produção


		### Exemplo dentro de qualquer procedure:
		..\scripts\pkg_cliente_body.sql
		EXCEPTION
		   WHEN DUP_VAL_ON_INDEX THEN
			  PKG_LOG.PRC_LOG_ERRO('PRC_INSERIR_CLIENTE',
								   -20002,
								   SQLERRM);

			  RAISE_APPLICATION_ERROR(-20002,
				 'Já existe cliente com este email.');

		   WHEN NO_DATA_FOUND THEN
			  PKG_LOG.PRC_LOG_ERRO('PRC_ATUALIZAR_CLIENTE',
								   -20003,
								   SQLERRM);

			  RAISE_APPLICATION_ERROR(-20003,
				 'Registro não encontrado.');

		   WHEN OTHERS THEN
			  PKG_LOG.PRC_LOG_ERRO('PRC_INSERIR_CLIENTE',
								   -20005,
								   SQLERRM);

			  RAISE_APPLICATION_ERROR(-20005,
				 'Erro interno. Contate o suporte.');
		END;


		### ON-ERROR no Forms (Centralizado)
		Trigger ON-ERROR no Form:
		DECLARE
		   v_code NUMBER := ERROR_CODE;
		   v_msg  VARCHAR2(4000) := SQLERRM;
		BEGIN

		   IF v_code BETWEEN 20000 AND 20999 THEN

			  MESSAGE(REPLACE(v_msg,'ORA-',''));
			  MESSAGE(' ');

		   ELSE

			  MESSAGE('Erro inesperado. Procure o suporte.');
			  MESSAGE(' ');
		   END IF;

		END;

## US05 — Regras e Validações de Dados

		### Centralizando todas as validações na procedure PRC_VALIDAR_CLIENTE:
		
		..\scripts\pkg_cliente_spec_v2.sql
		CREATE OR REPLACE PACKAGE PKG_CLIENTE AS

		   -- =============================
		   -- FUNÇÕES UTILITÁRIAS
		   -- =============================
		   FUNCTION FN_VALIDAR_EMAIL(p_email VARCHAR2) RETURN NUMBER;
		   FUNCTION FN_NORMALIZAR_CEP(p_cep VARCHAR2) RETURN VARCHAR2;

		   -- =============================
		   -- VALIDAÇÃO CENTRAL
		   -- =============================
		   PROCEDURE PRC_VALIDAR_CLIENTE(
			  p_id_cliente IN NUMBER,
			  p_nome       IN VARCHAR2,
			  p_email      IN VARCHAR2,
			  p_cep        IN VARCHAR2,
			  p_uf         IN VARCHAR2,
			  p_ativo      IN NUMBER
		   );

		   -- =============================
		   -- CRUD
		   -- =============================
		   PROCEDURE PRC_INSERIR_CLIENTE(
			  p_nome        IN  VARCHAR2,
			  p_email       IN  VARCHAR2,
			  p_cep         IN  VARCHAR2,
			  p_logradouro  IN  VARCHAR2,
			  p_bairro      IN  VARCHAR2,
			  p_cidade      IN  VARCHAR2,
			  p_uf          IN  VARCHAR2,
			  p_ativo       IN  NUMBER DEFAULT 1,
			  p_id_cliente  OUT NUMBER
		   );

		   PROCEDURE PRC_ATUALIZAR_CLIENTE(
			  p_id_cliente  IN  NUMBER,
			  p_nome        IN  VARCHAR2,
			  p_email       IN  VARCHAR2,
			  p_cep         IN  VARCHAR2,
			  p_logradouro  IN  VARCHAR2,
			  p_bairro      IN  VARCHAR2,
			  p_cidade      IN  VARCHAR2,
			  p_uf          IN  VARCHAR2,
			  p_ativo       IN  NUMBER
		   );

		   PROCEDURE PRC_DELETAR_CLIENTE(p_id NUMBER);

		   PROCEDURE PRC_LISTAR_CLIENTES(
			  p_nome   IN  VARCHAR2,
			  p_email  IN  VARCHAR2,
			  p_rc     OUT SYS_REFCURSOR
		   );

		END PKG_CLIENTE;
		/		
		
		
		..\scripts\pkg_cliente_body_v2.sql
		CREATE OR REPLACE PACKAGE BODY PKG_CLIENTE AS

		   -- =============================
		   -- CONSTANTES DE ERRO
		   -- =============================
		   c_erro_validacao CONSTANT NUMBER := -20001;
		   c_erro_unique    CONSTANT NUMBER := -20002;
		   c_erro_notfound  CONSTANT NUMBER := -20003;
		   c_erro_interno   CONSTANT NUMBER := -20005;


		   -- =============================
		   -- UF VALIDA
		   -- =============================
		   FUNCTION FN_UF_VALIDA(p_uf VARCHAR2) RETURN BOOLEAN IS
		   BEGIN
			  RETURN UPPER(p_uf) IN (
				 'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA',
				 'MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN',
				 'RS','RO','RR','SC','SP','SE','TO'
			  );
		   END;


		   -- =============================
		   -- EMAIL
		   -- =============================
		   FUNCTION FN_VALIDAR_EMAIL(p_email VARCHAR2) RETURN NUMBER IS
		   BEGIN
			  IF p_email IS NULL THEN
				 RETURN 1;
			  END IF;

			  IF REGEXP_LIKE(p_email,
				 '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
			  THEN
				 RETURN 1;
			  END IF;

			  RETURN 0;
		   END;


		   -- =============================
		   -- CEP
		   -- =============================
		   FUNCTION FN_NORMALIZAR_CEP(p_cep VARCHAR2) RETURN VARCHAR2 IS
			  v_cep VARCHAR2(8);
		   BEGIN
			  IF p_cep IS NULL THEN
				 RETURN NULL;
			  END IF;

			  v_cep := REGEXP_REPLACE(p_cep, '[^0-9]', '');

			  IF LENGTH(v_cep) != 8 THEN
				 RAISE_APPLICATION_ERROR(c_erro_validacao,
					'CEP deve conter 8 dígitos.');
			  END IF;

			  RETURN v_cep;
		   END;


		   -- =============================
		   -- VALIDAÇÃO CENTRAL
		   -- =============================
		   PROCEDURE PRC_VALIDAR_CLIENTE(
			  p_id_cliente IN NUMBER,
			  p_nome       IN VARCHAR2,
			  p_email      IN VARCHAR2,
			  p_cep        IN VARCHAR2,
			  p_uf         IN VARCHAR2,
			  p_ativo      IN NUMBER
		   ) IS
		   BEGIN

			  IF p_nome IS NULL THEN
				 RAISE_APPLICATION_ERROR(c_erro_validacao,
					'Nome é obrigatório.');
			  END IF;

			  IF FN_VALIDAR_EMAIL(p_email) = 0 THEN
				 RAISE_APPLICATION_ERROR(c_erro_validacao,
					'Email inválido.');
			  END IF;

			  IF p_uf IS NOT NULL AND NOT FN_UF_VALIDA(p_uf) THEN
				 RAISE_APPLICATION_ERROR(c_erro_validacao,
					'UF inválida.');
			  END IF;

			  IF p_ativo NOT IN (0,1) THEN
				 RAISE_APPLICATION_ERROR(c_erro_validacao,
					'ATIVO deve ser 0 ou 1.');
			  END IF;

			  -- Normalização CEP
			  IF p_cep IS NOT NULL THEN
				 FN_NORMALIZAR_CEP(p_cep);
			  END IF;

		   END;


		   -- =============================
		   -- INSERT
		   -- =============================
		   PROCEDURE PRC_INSERIR_CLIENTE(
			  p_nome        IN  VARCHAR2,
			  p_email       IN  VARCHAR2,
			  p_cep         IN  VARCHAR2,
			  p_logradouro  IN  VARCHAR2,
			  p_bairro      IN  VARCHAR2,
			  p_cidade      IN  VARCHAR2,
			  p_uf          IN  VARCHAR2,
			  p_ativo       IN  NUMBER,
			  p_id_cliente  OUT NUMBER
		   ) IS
			  v_cep VARCHAR2(8);
		   BEGIN

			  PRC_VALIDAR_CLIENTE(NULL,p_nome,p_email,p_cep,p_uf,p_ativo);

			  v_cep := FN_NORMALIZAR_CEP(p_cep);

			  INSERT INTO TB_CLIENTE (
				 ID_CLIENTE, NOME, EMAIL, CEP,
				 LOGRADOURO, BAIRRO, CIDADE, UF, ATIVO
			  )
			  VALUES (
				 NULL,
				 UPPER(p_nome),
				 LOWER(p_email),
				 v_cep,
				 p_logradouro,
				 p_bairro,
				 p_cidade,
				 UPPER(p_uf),
				 p_ativo
			  )
			  RETURNING ID_CLIENTE INTO p_id_cliente;

		   EXCEPTION
			  WHEN DUP_VAL_ON_INDEX THEN
				 RAISE_APPLICATION_ERROR(c_erro_unique,
					'Já existe cliente com este email.');
			  WHEN OTHERS THEN
				 RAISE_APPLICATION_ERROR(c_erro_interno,
					'Erro interno. Contate o suporte.');
		   END;


		   -- =============================
		   -- UPDATE
		   -- =============================
		   PROCEDURE PRC_ATUALIZAR_CLIENTE(
			  p_id_cliente  IN  NUMBER,
			  p_nome        IN  VARCHAR2,
			  p_email       IN  VARCHAR2,
			  p_cep         IN  VARCHAR2,
			  p_logradouro  IN  VARCHAR2,
			  p_bairro      IN  VARCHAR2,
			  p_cidade      IN  VARCHAR2,
			  p_uf          IN  VARCHAR2,
			  p_ativo       IN  NUMBER
		   ) IS
			  v_cep VARCHAR2(8);
		   BEGIN

			  IF p_id_cliente IS NULL THEN
				 RAISE_APPLICATION_ERROR(c_erro_validacao,
					'ID é obrigatório.');
			  END IF;

			  PRC_VALIDAR_CLIENTE(p_id_cliente,p_nome,p_email,p_cep,p_uf,p_ativo);

			  v_cep := FN_NORMALIZAR_CEP(p_cep);

			  UPDATE TB_CLIENTE
				 SET NOME  = UPPER(p_nome),
					 EMAIL = LOWER(p_email),
					 CEP   = v_cep,
					 LOGRADOURO = p_logradouro,
					 BAIRRO     = p_bairro,
					 CIDADE     = p_cidade,
					 UF         = UPPER(p_uf),
					 ATIVO      = p_ativo
			   WHERE ID_CLIENTE = p_id_cliente;

			  IF SQL%ROWCOUNT = 0 THEN
				 RAISE_APPLICATION_ERROR(c_erro_notfound,
					'Cliente não encontrado.');
			  END IF;

		   EXCEPTION
			  WHEN DUP_VAL_ON_INDEX THEN
				 RAISE_APPLICATION_ERROR(c_erro_unique,
					'Já existe cliente com este email.');
			  WHEN OTHERS THEN
				 RAISE_APPLICATION_ERROR(c_erro_interno,
					'Erro interno. Contate o suporte.');
		   END;


		   -- =============================
		   -- DELETE
		   -- =============================
		   PROCEDURE PRC_DELETAR_CLIENTE(p_id NUMBER) IS
		   BEGIN
			  DELETE FROM TB_CLIENTE
			   WHERE ID_CLIENTE = p_id;

			  IF SQL%ROWCOUNT = 0 THEN
				 RAISE_APPLICATION_ERROR(c_erro_notfound,
					'Cliente não encontrado.');
			  END IF;
		   END;


		   -- =============================
		   -- LISTAR
		   -- =============================
		   PROCEDURE PRC_LISTAR_CLIENTES(
			  p_nome   IN  VARCHAR2,
			  p_email  IN  VARCHAR2,
			  p_rc     OUT SYS_REFCURSOR
		   ) IS
		   BEGIN
			  OPEN p_rc FOR
				 SELECT *
				   FROM TB_CLIENTE
				  WHERE (p_nome IS NULL OR UPPER(NOME) LIKE '%'||UPPER(p_nome)||'%')
					AND (p_email IS NULL OR LOWER(EMAIL) LIKE '%'||LOWER(p_email)||'%')
				  ORDER BY NOME;
		   END;

		END PKG_CLIENTE;
		/
