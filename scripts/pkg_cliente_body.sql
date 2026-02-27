CONN DEVAPP/dev123@XEDEV;

CREATE OR REPLACE PACKAGE BODY PKG_CLIENTE AS

    -- =========================================
    -- CONSTANTES DE ERRO
    -- =========================================
    c_erro_nome_obrigatorio   CONSTANT NUMBER := -20001;
    c_erro_email_invalido     CONSTANT NUMBER := -20002;
    c_erro_cep_invalido       CONSTANT NUMBER := -20003;
    c_erro_uf_invalida        CONSTANT NUMBER := -20004;
    c_erro_cliente_nao_existe CONSTANT NUMBER := -20005;


    -- =========================================
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


    -- =========================================
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


    -- =========================================
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


    -- =========================================
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


    -- =========================================
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


    -- =========================================
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


    -- =========================================
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