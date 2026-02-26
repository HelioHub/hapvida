# Projeto Teste Técnico HAPVIDA - Hélio Marques

CRUD de Clientes utilizando ORACLE FORM e PL/SQL.

## Motagem do Ambiente de Desenvolvimento (Download efetuado direto no Portal da ORACLE)

	• Instalação do Banco de dados ORACLE 21c XE:
![## Banco](https://github.com/HelioHub/hapvida/blob/main/images/Banco21cXE.PNG)
	• Instalação do ORACLE Forms 12.2.1.19.0:
![## Banco](https://github.com/HelioHub/hapvida/blob/main/images/OracleForms.PNG)
	• Instalação do Form Builder Configuration (Conexão Form com o Banco de dados):
![## Banco](https://github.com/HelioHub/hapvida/blob/main/images/FormBuilderConfig.PNG)
	• Configuração TNSNAMES.ORA do Builder:
		XE21C =
		  (DESCRIPTION =
			(ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
			(CONNECT_DATA =
			  (SERVICE_NAME = XEPDB1)
			)
		  )
	• Instalçao e Configuração do SQL Developer:
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

	...