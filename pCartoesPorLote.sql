USE SUPER
GO

ALTER PROCEDURE [dbo].[pCartoesPorLote](
     @CodLote			BIGINT
	,@Retorno			VARCHAR(255)= NULL	OUTPUT
) 
AS
	/*
		DECLARE @Ret varchar(255), @CodLote BIGINT
		EXEC pCartoesPorLote @CodLote = 7720, @Retorno = @Ret output
		SELECT @Ret
	*/

    SET NOCOUNT ON

    DECLARE @flgLoteUniversidades BIT = 0
    SELECT TOP 1 @flgLoteUniversidades = 1 
        FROM Lotes l (NOLOCK) 
        INNER JOIN Modalidades m (NOLOCK)
        ON m.codModalidade = l.codModalidade
        INNER JOIN Produtos p (NOLOCK)
        ON p.codProduto = l.codProduto
        AND p.Nome = 'UNIVERSIDADES'
        WHERE l.codLote = @CodLote

    DECLARE @flgEnderecoRollout BIT = 0
    SELECT TOP 1 @flgEnderecoRollout = 1 
        FROM Lotes l (NOLOCK) 
        INNER JOIN LotesCartoes lc
        ON lc.CodLote = l.CodLote
        INNER JOIN SolicitacoesCartoes sc
        ON sc.CartaoId = lc.CodCartao
        INNER JOIN ContaRolloutFopa crf
        ON crf.SolicitacaoCartaoId = sc.Id
        INNER JOIN SolicitacaoRolloutFopa srf
        ON srf.ID = crf.SolicitacaoRolloutId
        AND srf.UsarEnderecoPortador = 0
        WHERE l.codLote = @CodLote

	--LISTA TODAS AS MODALIDADES FOPA
	DECLARE @Modalidades TABLE (CodModalidade int)        
	INSERT INTO @Modalidades (CodModalidade)
	SELECT m.CodModalidade 
		FROM Produtos p
		INNER JOIN Modalidades m
		ON m.CodProduto = p.CodProduto
		WHERE p.Nome = 'FOPA'


	CREATE TABLE #TMP_CARTOES 
	(
	   CodCartao                        BIGINT			NOT NULL,
	   CodConta							INT				,
	   ContaCorrenteID                  INT				,
	   CodPessoa                        INT				,
	   NumeroCartao                     VARCHAR			(050),
	   CVC1                             VARCHAR			(050),
	   CVC2                             VARCHAR			(050),
	   CVCChip                          VARCHAR			(050),
	   PinBlock                         VARCHAR			(050),
	   SenhaCartao                      VARCHAR			(004),
	   NumeroMifare                     VARCHAR			(016),
	   NSU                              VARCHAR			(016),
	   DataValidade                     SMALLDATETIME,
	   Categoria                        VARCHAR			(032),
	   DescricaoFuncao                  VARCHAR			(050),
	   ParceiroCNPJ                     VARCHAR			(020),
	   ParceiroNome                     VARCHAR			(255)	unique(ParceiroNome, CodCartao),
	   CodModalidade                    INT,
	   CPF                              VARCHAR			(050),
	   NomePortador                     VARCHAR			(026),
	   TipoLogradouro                   VARCHAR			(050),
	   Logradouro                       VARCHAR			(124),
	   Numero                           VARCHAR			(064),
	   Complemento                      VARCHAR			(050),
	   Bairro                           VARCHAR			(080),
	   Cidade                           VARCHAR			(050),
	   UF                               VARCHAR			(050),
	   Cep                              VARCHAR			(009),
	   CriadoEm                         DATETIME,
	   ContaSalario                     INT, 
	   CartaoImportacao                 INT,
	   PessoaJuridicaEnderecoID         INT,
	   PessoaFisicaEnderecoID           INT                     UNIQUE(PessoaFisicaEnderecoID, CodCartao),
	   EnderecoDigitado                 BIT,
	   LogradouroDigitado               VARCHAR			(124),
	   BairroDigitado                   VARCHAR			(080),
	   CidadeDigitada                   VARCHAR			(050),
	   UFDigitado                       VARCHAR			(002),
	   CEPDigitado                      VARCHAR			(009),
	   ComplementoDigitado              VARCHAR			(050),
	   TipoEnderecoPessoa               CHAR            (001),
	   TipoPortador                     INT,
	   TipoIndividualizacaoID           INT,
	   AosCuidadosDe                    VARCHAR         (100),
	   TipoCartaoId                     INT,
	   UnidadeUniversidade              VARCHAR         (060)	UNIQUE(UnidadeUniversidade, NomePortador, ParceiroNome, CodCartao),
	   IdentificacaoPortador            VARCHAR         (042),
	   IdentificacaoCodigoBarra         VARCHAR         (200),
       CodBarrasCapaLote                VARCHAR         (031),
       NomeAgencia						VARCHAR         (045),
	   Matricula						VARCHAR         (016),
       NomeCurso                        VARCHAR         (080),
       PrimeiraEmissaoConta             CHAR            (001),
       NSUSolicitante                   VARCHAR         (010),
       SegundaLinha                     VARCHAR         (015),
       QuartaLinha                      VARCHAR         (050),
       Perfil                           INT,
       CartaoComFoto                    CHAR            (001),
       EnderecoEnvioId                  BIGINT,
	   Processado						BIT
	   PRIMARY KEY CLUSTERED (CodCartao)
   )


	OPEN SYMMETRIC KEY TripleDESChave
	DECRYPTION BY CERTIFICATE SuperCertificado;

	INSERT INTO #TMP_CARTOES
		(CodCartao, CodConta, ContaCorrenteID, CodPessoa, NumeroCartao, CVC1, CVC2, CVCChip, PinBlock, SenhaCartao, NumeroMifare, NSU, DataValidade, Categoria, DescricaoFuncao, ParceiroCNPJ, ParceiroNome, 
		CodModalidade, CPF, NomePortador, CriadoEm, ContaSalario, CartaoImportacao, PessoaJuridicaEnderecoID, PessoaFisicaEnderecoID, 
		EnderecoDigitado, LogradouroDigitado, BairroDigitado, CidadeDigitada, UFDigitado, CEPDigitado, ComplementoDigitado,
		TipoEnderecoPessoa, TipoPortador, TipoIndividualizacaoID, AosCuidadosDe, TipoCartaoId, UnidadeUniversidade, 
		IdentificacaoPortador, IdentificacaoCodigoBarra, CodBarrasCapaLote, NomeAgencia, Matricula, NomeCurso, 
        PrimeiraEmissaoConta, NSUSolicitante, SegundaLinha, QuartaLinha, Perfil, CartaoComFoto, EnderecoEnvioId, Processado)

	SELECT
		C.CodCartao          AS CodCartao,
		C.CodConta			 AS CodConta,
		CC.ID                AS ContaCorrenteID,
		pc.PessoaFisicaID    AS CodPessoa,
		CONVERT(VARCHAR, DECRYPTBYKEY(NumeroCartaoCript))	AS NumeroCartao,
		CONVERT(VARCHAR, DECRYPTBYKEY(CodSeguranca1Cript))	AS CVC1,
		CONVERT(VARCHAR, DECRYPTBYKEY(CodSeguranca2Cript))	AS CVC2,
		CONVERT(VARCHAR, DECRYPTBYKEY(CVCChip))	         AS CVCChip,				
		epb.PinBlock         AS PinBlock,
		'' AS SenhaCartao,
		--REPLICATE('0', 4 - LEN(dbo.fEmbossingDescriptografaSenha(sn.Senha))) + RTrim(dbo.fEmbossingDescriptografaSenha(sn.Senha)) AS SenhaCartao,
		C.NumeroMifare,
		NSU.NSU,
		C.DataValidade,
		C.Categoria,
		C.DescricaoFuncao,
		L.ParceiroCNPJ,
		PJ.RazaoSocial       AS ParceiroNome,
		C.CodModalidade,
		PF.CPF,
		CASE 
            WHEN coalesce(sm.PersonalizacaoNome,'') <> '' THEN sm.PersonalizacaoNome
            ELSE PC.NomePortador
        END                 AS NomePortador,
		CC.CriadoEm,
		CASE L.CodTipoLote WHEN 3 THEN 1 ELSE 0 END AS ContaSalario, 
		CASE L.CodTipoLote WHEN 2 THEN 1 ELSE 0 END AS CartaoImportacao,
		L.EnderecoID         AS PessoaJuridicaEnderecoID,
		C.PessoaFisicaEnderecoID,
		sm.EnderecoDigitado, 
		sm.LogradouroDigitado, 
		sm.BairroDigitado, 
		sm.CidadeDigitada, 
		sm.UFDigitado, 
		sm.CEPDigitado, 
		sm.ComplementoDigitado,
		CASE
			WHEN pc.PessoaFisicaID			IS NOT NULL THEN 'F'
			WHEN c.PessoaJuridicaEnderecoID	IS NOT NULL THEN 'J'
			ELSE NULL --Não deve cair nesta situação
		END                  AS TipoEnderecoPessoa,
        C.TipoPortador,
        C.TipoIndividualizacaoID,
        sm.AosCuidadosDe,
        isnull(C.TipoCartaoId,0) AS TipoCartaoId, -- Se não tiver a informação, considera como TARJA
        scp.UnidUniversidade  AS UnidadeUniversidade,
        scp.IdentificacaoPortador,
        scp.Identificacao     AS IdentificacaoCodigoBarra,
        sm.CodBarrasCapaLote,  
        sm.NomeAgencia,
        scp.Matricula,
        scp.NomeCurso,
        ' ' AS PrimeiraEmissaoConta,
        scp.NSUSolicitacao,
        scp.SegundaLinha,
        scp.QuartaLinha,
        scp.Perfil,
        scp.CartaoComFoto,
        c.EnderecoEnvioId,
		0
        
        FROM
	      dbo.Cartoes C WITH(NOLOCK)
	      INNER JOIN dbo.LotesCartoes LC WITH(NOLOCK)
		      ON LC.CodCartao = C.CodCartao
	      INNER JOIN dbo.Lotes L WITH(NOLOCK)
		      ON L.CodLote = LC.CodLote
	      LEFT JOIN dbo.PortadoresCartoes PC WITH(NOLOCK)	
		      ON C.CodCartao = PC.CartaoID
	      LEFT JOIN dbo.CartoesImpressao CI WITH(NOLOCK)
		      ON CI.CodCartao = C.CodCartao
	     LEFT JOIN dbo.PessoasFisicas PF	WITH(NOLOCK)
		      ON PF.ID = PC.PessoaFisicaID
	      LEFT JOIN dbo.ContasCorrentes CA WITH(NOLOCK)
		      ON CA.ID = C.CodConta
	      LEFT JOIN dbo.ContasCorrentes CC WITH(NOLOCK)
		      ON CC.ID = CA.ContaCorrenteID
	      LEFT JOIN dbo.CartoesNSU NSU WITH(NOLOCK)
		      ON C.CodCartao = NSu.CartaoID
	      LEFT JOIN dbo.PessoasJuridicasEnderecos PJE  WITH (NOLOCK)
		      ON PJE.ID = C.PessoaJuridicaEnderecoID
	      LEFT JOIN dbo.PessoasJuridicas PJ WITH(NOLOCK)
		      ON PJ.CNPJ = L.ParceiroCNPJ
		  LEFT JOIN dbo.SolicitacoesMassivasCartoes smc (NOLOCK)
		  ON smc.CartaoID = C.CodCartao
		  LEFT JOIN dbo.SolicitacoesMassivas sm (NOLOCK)
		  ON sm.ID = smc.SolicitacaoID
		  LEFT JOIN dbo.EmbossingPinBlockCartoes epb (NOLOCK)
		  ON epb.CodCartao = C.CodCartao
		  LEFT JOIN Senhas sn (NOLOCK)
		  ON sn.Id = CA.IdSenha
		  LEFT JOIN SolicitacoesCartoes sc (NOLOCK)
		  ON sc.CartaoId = lc.CodCartao
		  LEFT JOIN SolicitacoesCartoesParceiros scp (NOLOCK)
		  ON scp.SolicitacaoCartaoID = sc.ID
      WHERE
	      L.CodLote= @CodLote
		  AND (LC.Banido = 0 OR  (LC.Banido = 1 AND LC.InstanteLiberacao IS NOT NULL))

	CLOSE SYMMETRIC KEY TripleDESChave;  


	--RETORNA SENHA APENAS PARA CARTOES DO TIPO FOPA (EVITAR OVERHEAD)
	UPDATE t set t.Processado = 1
		FROM #TMP_CARTOES t
		WHERE t.CodModalidade NOT IN (SELECT CodModalidade 
									FROM @Modalidades m 
									WHERE m.CodModalidade = t.CodModalidade)

	WHILE EXISTS (SELECT TOP 1 1 FROM #TMP_CARTOES t where Processado = 0)
	begin

		declare @t			table (pin varchar(4))
		declare @CodCartao	BIGINT		= NULL, 
				@CodConta	INT			= NULL,
				@pin		VARCHAR(4)	= NULL

		select top 1 @CodCartao = CodCartao , @CodConta = CodConta 
			from #TMP_CARTOES t (nolock)
			where t.Processado = 0

		insert into @t (pin)
		exec pAutorizadorApuraId @CodConta

		select top 1 @pin = pin from @t

		update t set t.Processado = 1, t.SenhaCartao = @pin
		--select * 
			from #TMP_CARTOES t (nolock)
			where t.CodCartao = @CodCartao

		delete @t

	end




   IF (@flgLoteUniversidades = 1)
   BEGIN

    UPDATE t SET t.PrimeiraEmissaoConta =  
            CASE 
                WHEN EXISTS (SELECT TOP 1 1
                                FROM ContasCorrentes ccp1 (NOLOCK)
                                INNER JOIN ContasCorrentes cca1 (NOLOCK)
                                ON cca1.ContaCorrenteID = ccp1.ID
                                INNER JOIN Cartoes c1 (NOLOCK)
                                ON c1.CodConta = cca1.ID
                                AND c1.CriadoEm < c.CriadoEm
                                WHERE ccp1.ID = t.ContaCorrenteID) THEN 'N'
                ELSE 'S'
            END 
        FROM #TMP_CARTOES t 
        INNER JOIN Cartoes c (NOLOCK)
        ON c.CodCartao = t.CodCartao
        WHERE COALESCE(ContaCorrenteID, 0) > 0

	   UPDATE tm
		   SET tm.TipoLogradouro    = tl.TipoLogradouro,
			   tm.Logradouro		= ipu.Logradouro,
			   tm.Numero			= ipu.Numero,
			   tm.Complemento		= ipu.Complemento,
			   tm.Bairro			= ipu.Bairro,
			   tm.Cidade			= ipu.Cidade,
			   tm.UF				= ipu.UF,
			   tm.Cep				= ipu.CEP,
               tm.AosCuidadosDe     = ipu.AosCuidadosDe,
               tm.ParceiroCNPJ      = ipu.CNPJ,
               tm.ParceiroNome      = ipu.NomeUniversidade

		   FROM #TMP_CARTOES tm
         INNER JOIN SolicitacoesCartoes sc (NOLOCK)
            ON sc.CartaoID = tm.CodCartao
         INNER JOIN SolicitacoesCartoesParceiros scp (NOLOCK)
            ON sc.id = scp.SolicitacaoCartaoID
         INNER JOIN IntegracaoParceirosArquivosUniversidade ipu (NOLOCK)
            ON ipu.ID = scp.ArquivoIntegracaoID 
         LEFT JOIN dbo.TiposLogradouro tl WITH(NOLOCK)
            ON tl.ID = CONVERT(INT, ipu.TipoLogradouro)

   END --IF (@flgLoteUniversidades = 1)
   ELSE IF @flgEnderecoRollout = 1
   BEGIN

   	   UPDATE tm
		   SET tm.TipoLogradouro    = tl.TipoLogradouro,
			   tm.Logradouro		= erf.Logradouro,
			   tm.Numero			= erf.Numero,
			   tm.Complemento		= erf.Complemento,
			   tm.Bairro			= erf.Bairro,
			   tm.Cidade			= erf.Cidade,
			   tm.UF				= es.Sigla,
			   tm.Cep				= LEFT(RIGHT(('00000000' + CONVERT(VARCHAR, erf.NumeroCEP)),8),5) + '-' + RIGHT(RIGHT(('00000000' + CONVERT(VARCHAR, erf.NumeroCEP)),8),3)
		 FROM #TMP_CARTOES tm
         INNER JOIN SolicitacoesCartoes sc (NOLOCK)
            ON sc.CartaoID = tm.CodCartao
         INNER JOIN ContaRolloutFopa crf
            ON crf.SolicitacaoCartaoId = sc.Id
         INNER JOIN EnderecoRolloutFopa erf
            ON erf.ID = crf.EnderecoId
         LEFT JOIN dbo.TiposLogradouro tl WITH(NOLOCK)
            ON tl.ID = erf.TipoLogradouroId
         LEFT JOIN Estados es
            ON es.ID = erf.EstadoId


   END --IF @flgEnderecoRollout = 1
   ELSE
   BEGIN

	   UPDATE tm
		   SET tm.TipoLogradouro    = tl.TipoLogradouro,
			   tm.Logradouro        = eec.Logradouro,
			   tm.Numero            = eec.Numero,
			   tm.Complemento       = eec.Complemento,
			   tm.Bairro            = eec.Bairro,
			   tm.Cidade            = eec.Cidade,
			   tm.UF				= e.Sigla,
			   tm.Cep               = LEFT(RIGHT(('00000000' + CONVERT(VARCHAR, eec.NumeroCep)),8),5) + '-' + RIGHT(RIGHT(('00000000' + CONVERT(VARCHAR, eec.NumeroCep)),8),3)
		   FROM #TMP_CARTOES tm
		   INNER JOIN dbo.EnderecoEnvioCartoes eec WITH(NOLOCK)
			   ON eec.ID = tm.EnderecoEnvioId
		   LEFT JOIN dbo.TiposLogradouro tl WITH(NOLOCK)
			   ON tl.ID = eec.TipoLogradouroID
		   LEFT JOIN dbo.Estados e WITH(NOLOCK)
			   ON e.ID = eec.EstadoID
		   WHERE tm.EnderecoEnvioId IS NOT NULL


   	   --Tenta atualizar endereço para pessoa física baseado na coluna [Cartoes.PessoaFisicaEnderecoID]
	   UPDATE tm
		   SET tm.TipoLogradouro    = tl.TipoLogradouro,
			   tm.Logradouro        = pfe.Logradouro,
			   tm.Numero            = pfe.Numero,
			   tm.Complemento       = pfe.Complemento,
			   tm.Bairro            = pfe.Bairro,
			   tm.Cidade            = pfe.Cidade,
			   tm.UF				= e.Sigla,
			   tm.Cep               = pfe.Cep
		   FROM #TMP_CARTOES tm
		   INNER JOIN dbo.PessoasFisicasEnderecos pfe WITH(NOLOCK)
			   ON pfe.ID = tm.PessoaFisicaEnderecoID
		   LEFT JOIN dbo.TiposLogradouro tl WITH(NOLOCK)
			   ON tl.ID = pfe.TipoLogradouroID
		   LEFT JOIN dbo.Estados e WITH(NOLOCK)
			   ON E.ID = pfe.EstadoID
		   WHERE tm.EnderecoEnvioId IS NULL 
             AND tm.TipoEnderecoPessoa = 'F' 
             AND (tm.CodModalidade <> 58 OR tm.ContaSalario = 0)--NAO PODE SER FOPA OU CONTA SALÁRIO	

	   --Atualizar os demais pelo endereço mais recente 
	   UPDATE tm
		   SET tm.TipoLogradouro	= tl.TipoLogradouro,
			   tm.Logradouro		= pfe.Logradouro,
			   tm.Numero			= pfe.Numero,
			   tm.Complemento		= pfe.Complemento,
			   tm.Bairro			= pfe.Bairro,
			   tm.Cidade			= pfe.Cidade,
			   tm.UF				   = e.Sigla,
			   tm.Cep				= pfe.Cep
		   FROM #TMP_CARTOES tm
		   INNER JOIN dbo.PortadoresCartoes pc WITH(NOLOCK)
			   ON pc.CartaoID = tm.CodCartao
	      INNER JOIN 
	      (
		      SELECT PessoaFisicaID, Max(ID) as PFE_ID
		          FROM PESSOASFISICASENDERECOS p WITH(NOLOCK)
		          GROUP BY PessoaFisicaID
	      ) AS TMP 
		      ON TMP.PessoaFisicaID = pc.PessoaFisicaID
	      INNER JOIN dbo.PessoasFisicasEnderecos pfe WITH(NOLOCK)
		      ON TMP.PFE_ID = pfe.ID 
	      LEFT JOIN dbo.TiposLogradouro tl WITH(NOLOCK)
		      ON tl.ID = pfe.TipoLogradouroID
	      LEFT JOIN dbo.Estados e WITH(NOLOCK)
		      ON E.ID = pfe.EstadoID
		   WHERE tm.EnderecoEnvioId IS NULL
             AND tm.TipoEnderecoPessoa = 'F'	
		     AND tm.Logradouro IS NULL
		     AND (tm.CodModalidade <> 58 OR tm.ContaSalario = 0)--NAO PODE SER FOPA OU CONTA SALÁRIO	


	   --Atualiza endereço e parceiro para pessoa jurídica
	   UPDATE tm
		   SET tm.TipoLogradouro	= tl.TipoLogradouro,
			   tm.Logradouro		= pje.Logradouro,
			   tm.Numero			= pje.Numero,
			   tm.Complemento		= pje.Complemento,
			   tm.Bairro			= pje.Bairro,
			   tm.Cidade			= pje.Cidade,
			   tm.UF				= E.Sigla,
			   tm.Cep				= pje.Cep,
			   tm.ParceiroCNPJ = pj.CNPJ,
			   tm.ParceiroNome = pj.RazaoSocial
		   FROM #TMP_CARTOES tm
		   INNER JOIN dbo.PessoasJuridicasEnderecos pje WITH(NOLOCK)
			   ON pje.ID = tm.PessoaJuridicaEnderecoID
		   INNER JOIN dbo.PessoasJuridicas pj (NOLOCK)
			   ON pj.ID = pje.PessoaJuridicaID
		   LEFT JOIN dbo.TiposLogradouro tl (NOLOCK)
			   ON tl.ID = pje.TipoLogradouroID
		   LEFT JOIN dbo.Estados E WITH(NOLOCK)
			   ON E.ID = pje.EstadoID		
		   WHERE tm.EnderecoEnvioId IS NULL
             AND tm.TipoEnderecoPessoa = 'J' 
             OR (tm.TipoEnderecoPessoa = 'F' AND (tm.CodModalidade = 58 OR tm.ContaSalario = 1)) --CONSIDERA PESSOA FÍSICA COM FOPA  OU SE FOR CONTA SALÁRIO

   END --IF EXISTS
   


    DECLARE @cmd VARCHAR(MAX) = 'SELECT  tm.CodCartao
                                        ,tm.ContaCorrenteID
                                        ,tm.CodPessoa
                                        ,tm.NumeroCartao
                                        ,tm.CVC1 
                                        ,tm.CVC2 
                                        ,tm.CVCChip
                                        ,tm.PinBlock
                                        ,tm.SenhaCartao
                                        ,tm.NumeroMifare
                                        ,tm.NSU
                                        ,tm.DataValidade
                                        ,tm.Categoria 
                                        ,tm.DescricaoFuncao
                                        ,tm.ParceiroCNPJ
                                        ,tm.ParceiroNome
                                        ,tm.CodModalidade
                                        ,tm.CPF 
                                        ,dbo.RemoverAcentuacao(tm.NomePortador) as NomePortador
                                        ,isnull(tm.EnderecoDigitado,0) as EnderecoDigitado	
                                        ,tm.TipoLogradouro
                                        ,tm.Logradouro 
                                        ,tm.Numero 
                                        ,tm.Complemento 
                                        ,tm.Bairro 
                                        ,tm.Cidade 
                                        ,tm.UF 
                                        ,tm.Cep
                                        ,tm.LogradouroDigitado
                                        ,tm.BairroDigitado
                                        ,tm.CidadeDigitada
                                        ,tm.UFDigitado
                                        ,tm.CEPDigitado
                                        ,tm.ComplementoDigitado
                                        ,tm.CriadoEm 
                                        ,tm.ContaSalario 
                                        ,tm.CartaoImportacao
                                        ,tm.PessoaJuridicaEnderecoID
                                        ,tm.TipoPortador
                                        ,tm.TipoIndividualizacaoID
                                        ,tm.AosCuidadosDe
                                        ,tm.TipoCartaoId
                                        ,tm.IdentificacaoPortador
                                        ,tm.IdentificacaoCodigoBarra
                                        ,tm.UnidadeUniversidade
                                        ,tm.CodBarrasCapaLote 
                                        ,tm.NomeAgencia
                                        ,tm.Matricula
                                        ,tm.NomeCurso
                                        ,tm.NSUSolicitante
                                        ,tm.SegundaLinha
                                        ,tm.Perfil
               ,tm.CartaoComFoto
                                        ,tm.QuartaLinha
                                        ,tm.PrimeiraEmissaoConta
	                            FROM #TMP_CARTOES tm 
                                '
    
    IF @flgLoteUniversidades = 0 
    BEGIN
        SET @cmd = @cmd + 'ORDER BY  tm.NomePortador, tm.ParceiroNome, tm.CodBarrasCapaLote'
    END
    ELSE
    BEGIN
        SET @cmd = @cmd + 'ORDER BY  tm.Logradouro, tm.UnidadeUniversidade, tm.Perfil, tm.NomeCurso, tm.NomePortador'
    END

    EXEC (@cmd)



