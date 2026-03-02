CREATE OR REPLACE PACKAGE PKG_LOG AS
   PROCEDURE PRC_LOG_ERRO(
      p_origem   VARCHAR2,
      p_cod_erro NUMBER,
      p_msg      VARCHAR2
   );
END PKG_LOG;
/