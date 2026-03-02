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