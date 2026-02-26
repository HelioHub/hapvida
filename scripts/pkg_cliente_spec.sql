CREATE OR REPLACE PACKAGE PKG_CLIENTE AS

    -- =========================================
    -- FUNÇÕES UTILITÁRIAS
    -- =========================================

    FUNCTION FN_VALIDAR_EMAIL (
        p_email VARCHAR2
    ) RETURN NUMBER;

    FUNCTION FN_NORMALIZAR_CEP (
        p_cep VARCHAR2
    ) RETURN VARCHAR2;


    -- =========================================
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