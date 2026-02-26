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

	### 🧠 Observações importantes (pensando já no Forms)
		✔ PK numérica com sequence → ideal para Data Block Wizard
		✔ EMAIL unique → valida automaticamente no banco
		✔ UF com CHECK → Forms já mostra erro automático
		✔ ATIVO 0/1 → perfeito para checkbox
		✔ DT_ATUALIZACAO via trigger → controle automático

	### Scripts create.sql (criação) e drop.sql (remoção):
	
			create.sql: 
			
![## Script](https://github.com/HelioHub/hapvida/blob/main/scripts/create.sql)
			
			drop.sql:
			
![## Script](https://github.com/HelioHub/hapvida/blob/main/scripts/drop.sql)

## US02 — Camada PL/SQL (Package de Negócio)			
		
			
	


