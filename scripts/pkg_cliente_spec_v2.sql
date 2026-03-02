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