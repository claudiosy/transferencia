/*------------------------------------------------------------------------------------------------------------------------------------------
* Nome do Arquivo: pContasPessoa
* Data de Criação: 09/10/2018
* Autor: Claudio Shiniti Yamamoto
* Projeto: Operações
* Grant: GRANT EXECUTE ON pContasPessoa TO public;
* Chamada: Exec pContasPessoa
* Descrição: Esta procedure busca dados de pessoas físicas e jurídicas para serem exibidas na ABA (Dados)
	do sistema de Operações. Terão várias opções de filtros, pois está substituindo a View (vwContasPessoa),
	com o intuito de otimizar e eliminar o grande retorno de dados causados pela view e eliminar as
	queries ofensoras que o Entity provoca com a leitura dela.
* Histórico de Modificações
* Data			Autor				OS Descrição
------------------------------------------------------------------------------------------------------------------------------------------*/  
/* INICIO DAS INSTRUÇÕES SQL */

ALTER PROCEDURE pContasPessoa
(
	@TipoPessoa varchar(2) = null,
	@Documento bigint = null,	--
	@Nome varchar(200) = null,	--
	@Email varchar(255) = null,	--
	@Agencia varchar(4) = null,
	@Conta varchar(20) = null,
	@Telefone bigint = null,	--
	@DataInicialAbertura datetime = null,
	@DataFinalAbertura datetime = null,
	@DataInicialPrimeiraCarga datetime = null,
	@DataFinalPrimeiraCarga datetime = null,
	@Estado varchar(2) = null,
	@Cidade varchar(50) = null,
	@StatusDocumento varchar(1) = null,
	@Validacao varchar(30) = null,
	@StatusConta char(1) = null,
	@Canal varchar(30) = null,
	@StatusContaId int = null,
	@PEP bit = null,
	@Santander bit = null,
	@Fatca bit = null
)
AS
	SET NOCOUNT ON;

declare
	 @sv_rowcount int

create table #resu
	(
	 [ID] [int] NOT NULL
	,[Canal] [varchar](30) NULL
	,[Nome] [varchar](200) NULL
	,[Documento] [varchar](50) NULL
	,[Cidade] [varchar](50) NULL
	,[UF] [varchar](50) NULL
	,[Coaf] [bit] NOT NULL
	,[PEP] [bit] NOT NULL
	,[Fatca] [bit] NOT NULL
	,[Santander] [bit] NOT NULL
	,[Email] [varchar](255) NOT NULL
	,[DataCarga] [datetime] NULL
	,[Validacao] [varchar](30) NULL
	,[StatusConta] [char](1) NULL
	,[StatusContaDetalhe] [varchar](60) NULL
	,[StatusContaID] [int] NULL
	,[Monitoria] [varchar](3) NOT NULL
	,[Dominio] [varchar](150) NULL
	,[Telefone] [int] NULL
	,[CriadoEm] [datetime] NOT NULL	unique(CriadoEm, nr_regt)
	,[valor] [money] NOT NULL
	,[valorcontrole] [money] NOT NULL
	,[AlteradoEm] [datetime] NOT NULL
	,[AlteradoPor] [varchar](255) NOT NULL
	,[TipoPessoa] [int] NOT NULL
	,[ValorPrimeiraCargaLancamento] [money] NULL
	,[DataLancamento] [datetime] NULL
	,[DescricaoLancamento] [varchar](50) NULL
	,[LancamentoID] [int] NULL
	,[HistoricoLancamento] [varchar](max) NULL
	,[DescricaoStatusLancamento] [varchar](50) NULL
	,[CoafData] [datetime] NULL
	,[CoafOpereracao] [int] NULL
	,[CoafDescricao] [nvarchar](50) NULL
	,[Agencia] [varchar](4) NULL	unique(Agencia, Conta, nr_regt)
	,[Conta] [varchar](20) NULL
	,nr_regt	bigint	identity(1,1)
	,primary key clustered (nr_regt)
	)

	select @sv_rowcount = 0

	if (@Documento is not null)
	begin
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				[ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pf.NumeroCPF = @Documento

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end -- if (@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@sv_rowcount = 0 and (@TipoPessoa is null or @TipoPessoa = 'PJ'))
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pj.NumeroCNPJ = @Documento

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@sv_rowcount = 0 and (@TipoPessoa is null or @TipoPessoa = 'PJ'))
	end --if (@Documento is not null)

	if (@Nome is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				Nome not like '%' + @Nome + '%'

			goto filtro_email
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pf.Nome like '%' + @Nome + '%'

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pj.RazaoSocial like '%' + @Nome + '%'

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@Nome is not null)

	filtro_email:

	if (@Email is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				Email not like '%' + @Email + '%'

			goto filtro_telefone
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.Email like '%' + @Email + '%'

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end -- if (@TipoPessoa is null or @TipoPessoa = 'PF')
			
		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.Email like '%' + @Email + '%'

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@Email is not null)

	filtro_telefone:

	if (@Telefone is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			if (@TipoPessoa is null or @TipoPessoa = 'PF')
			begin
				delete
					#resu
				where
					ID IN (Select pfcc.ContaCorrenteID From PessoasFisicasTelefones pft (nolock) inner join PessoasFisicasContasCorrentes pfcc (nolock) on pft.PessoaFisicaID = pfcc.PessoaFisicaID Where NumeroTelefone <> @Telefone)
			end

			if (@TipoPessoa is null or @TipoPessoa = 'PJ')
			begin
				delete
					#resu
				where
					ID IN (Select pjcc.ContaCorrenteID From PessoasJuridicasTelefones pjt (nolock) inner join PessoasJuridicasContasCorrentes pjcc (nolock) on pjt.PessoaJuridicaID = pjcc.PessoaJuridicaID Where NumeroTelefone <> @Telefone)
			end

			goto filtro_agencia
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pf.ID IN (Select PessoaFisicaID From PessoasFisicasTelefones (nolock) Where NumeroTelefone = @Telefone)

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pj.ID IN (Select PessoaJuridicaID From PessoasJuridicasTelefones (nolock) Where NumeroTelefone = @Telefone)

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@Telefone is not null)

	filtro_agencia:

	if (@Agencia is not null and @Conta is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				Agencia <> @Agencia
				AND Conta <> @Conta

			goto filtro_data
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE dscc.AgenciaSantander = @Agencia
				AND dscc.ContaSantander = @Conta

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE dscc.AgenciaSantander = @Agencia AND dscc.ContaSantander = @Conta

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@Agencia is not null and @Conta is not null)

	filtro_data:

	if (@DataInicialAbertura is not null and @DataFinalAbertura is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				CriadoEm not Between @DataInicialAbertura AND @DataFinalAbertura

			goto filtro_datacarga
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.CriadoEm >= @DataInicialAbertura AND cc.CriadoEm < @DataFinalAbertura

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.CriadoEm >= @DataInicialAbertura AND cc.CriadoEm < @DataFinalAbertura

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@DataInicialAbertura is not null and @DataFinalAbertura is not null)

	filtro_datacarga:

	if (@DataInicialPrimeiraCarga is not null and @DataFinalPrimeiraCarga is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				DataCarga not Between @DataInicialPrimeiraCarga AND @DataFinalPrimeiraCarga

			goto filtro_estado
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.DataPrimeiraCarga >= @DataInicialPrimeiraCarga AND cc.DataPrimeiraCarga < @DataFinalPrimeiraCarga

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.DataPrimeiraCarga >= @DataInicialPrimeiraCarga AND cc.DataPrimeiraCarga < @DataFinalPrimeiraCarga

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@DataInicialPrimeiraCarga is not null and @DataFinalPrimeiraCarga is not null)

	filtro_estado:

	if (@Estado is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			if (@TipoPessoa is null or @TipoPessoa = 'PF')
			begin
				delete
					#resu
				where
					ID IN (Select pfcc.ContaCorrenteID From PessoasFisicasEnderecos pfe (nolock) Inner Join Estados e (nolock) ON pfe.EstadoID = e.ID inner join PessoasFisicasContasCorrentes pfcc on pfe.PessoaFisicaID = pfcc.PessoaFisicaID Where e.Sigla <> @Estado)
			end --if (@TipoPessoa is null or @TipoPessoa = 'PF')

			if (@TipoPessoa is null or @TipoPessoa = 'PJ')
			begin
				delete
					#resu
				where
					ID IN (Select pjcc.ContaCorrenteID From PessoasJuridicasEnderecos pje (nolock) Inner Join Estados e (nolock) ON pje.EstadoID = e.ID inner join PessoasJuridicasContasCorrentes pjcc on pje.PessoaJuridicaID = pjcc.PessoaJuridicaID Where e.Sigla <> @Estado)
			end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')

			goto filtro_cidade
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pf.ID IN (Select PessoaFisicaID From PessoasFisicasEnderecos pfe (nolock) Inner Join Estados e (nolock) ON pfe.EstadoID = e.ID Where e.Sigla = @Estado)

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pj.ID IN (Select PessoaJuridicaID From PessoasJuridicasEnderecos pfe (nolock) Inner Join Estados e (nolock) ON pfe.EstadoID = e.ID Where e.Sigla = @Estado)

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@Estado is not null)

	filtro_cidade:

	if (@Cidade is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			if (@TipoPessoa is null or @TipoPessoa = 'PF')
			begin
				delete
					#resu
				where
					ID IN (Select pfcc.ContaCorrenteID From PessoasFisicasEnderecos pfe (nolock) inner join PessoasFisicasContasCorrentes pfcc (nolock) on pfe.PessoaFisicaID = pfcc.PessoaFisicaID Where Cidade not like '%' + @Cidade + '%')
			end --if (@TipoPessoa is null or @TipoPessoa = 'PF')

			if (@TipoPessoa is null or @TipoPessoa = 'PJ')
			begin
				delete
					#resu
				where
					ID IN (Select pjcc.ContaCorrenteID From PessoasJuridicasEnderecos pje (nolock) inner join PessoasJuridicasContasCorrentes pjcc (nolock) on pje.PessoaJuridicaID = pjcc.PessoaJuridicaID Where Cidade not like '%' + @Cidade + '%')
			end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')

			goto filtro_statusdocumento
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pf.ID IN (Select PessoaFisicaID From PessoasFisicasEnderecos (nolock) Where Cidade like '%' + @Cidade + '%')

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pj.ID IN (Select PessoaJuridicaID From PessoasJuridicasEnderecos (nolock) Where Cidade like '%' + @Cidade + '%')

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@Cidade is not null)

	filtro_statusdocumento:

	if (@StatusDocumento is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			if (@StatusDocumento = '0')
			begin
				delete
					#resu
				where
					Monitoria <> 'Não'
			end else
			begin
				delete
					#resu
				where
					Monitoria <> 'Sim'
			end

			goto filtro_validacao
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.StatusDocumento = @StatusDocumento

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.StatusDocumento = @StatusDocumento

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@StatusDocumento is not null)

	filtro_validacao:

	if (@Validacao is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				Validacao <> @Validacao

			goto filtro_statusconta
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.StatusCadastroID = (Select ID From StatusCadastro (nolock) Where Status = @Validacao)

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.StatusCadastroID = (Select ID From StatusCadastro (nolock) Where Status = @Validacao)

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@Validacao is not null)

	filtro_statusconta:

	if (@StatusConta is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				StatusConta <> @StatusConta

			goto filtro_canal
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.Status = @StatusConta

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.Status = @StatusConta

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@StatusConta is not null)

	filtro_canal:

	if (@Canal is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				canal <> @Canal

			goto filtro_statuscontaid
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.Canal = @Canal

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.Canal = @Canal

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@Canal is not null)

	filtro_statuscontaid:

	if (@StatusContaId is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				StatusContaID <> @StatusContaId

			goto filtro_pep
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.StatusContaID = @StatusContaId

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE cc.StatusContaID = @StatusContaId

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@StatusContaId is not null)

	filtro_pep:

	if (@PEP is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				PEP <> @PEP

			goto filtro_santander
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pf.PEP = @PEP

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pj.PEP = @PEP

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@PEP is not null)

	filtro_santander:

	if (@Santander is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				Santander <> @Santander

			goto filtro_fatca
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pf.Santander = @Santander

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				inner JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
	end --if (@Santander is not null)

	filtro_fatca:

	if (@Fatca is not null)
	begin
		if (@sv_rowcount <> 0)
		begin
			delete
				#resu
			where
				Fatca <> @Fatca

			goto fim
		end --if (@sv_rowcount <> 0)
		
		if (@TipoPessoa is null or @TipoPessoa = 'PF')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pfcc.ContaCorrenteID as ID,
				cc.Canal,
				pf.Nome,
				pf.CPF as Documento,
				pfe.Cidade,
				e.Sigla as UF,
				ISNULL(pf.Coaf, 0) AS Coaf,
				ISNULL(pf.PEP, 0) AS PEP,
				ISNULL(pf.Fatca, 0) AS Fatca,
				ISNULL(pf.Santander, 0) AS Santander,
				cc.Email,
				cc.DataPrimeiraCarga AS DataCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				1 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pf.CoafData,
				pf.CoafOpereracaoId AS CoafOpereracao,
				CO.Descricao AS CoafDescricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasFisicas pf WITH (nolock) INNER JOIN PessoasFisicasContasCorrentes pfcc WITH (nolock) ON
					pf.ID = pfcc.PessoaFisicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pfcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasFisicasEnderecos pfe WITH (nolock) ON
					pf.ID = pfe.PessoaFisicaID
					and pfe.ID IN (Select MIN(ID) From PessoasFisicasEnderecos WITH (nolock)
						Group by PessoaFisicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pfe.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pf.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID
			WHERE pf.Fatca = @Fatca

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --(@TipoPessoa is null or @TipoPessoa = 'PF')

/*
Denilton - PJ não tem a coluna Fatca.
		if (@TipoPessoa is null or @TipoPessoa = 'PJ')
		begin
			insert #resu
				(
				 [ID]
				,[Canal]
				,[Nome]
				,[Documento]
				,[Cidade]
				,[UF]
				,[Coaf]
				,[PEP]
				,[Fatca]
				,[Santander]
				,[Email]
				,[DataCarga]
				,[Validacao]
				,[StatusConta]
				,[StatusContaDetalhe]
				,[StatusContaID]
				,[Monitoria]
				,[Dominio]
				,[Telefone]
				,[CriadoEm]
				,[valor]
				,[valorcontrole]
				,[AlteradoEm]
				,[AlteradoPor]
				,[TipoPessoa]
				,[ValorPrimeiraCargaLancamento]
				,[DataLancamento]
				,[DescricaoLancamento]
				,[LancamentoID]
				,[HistoricoLancamento]
				,[DescricaoStatusLancamento]
				,[CoafData]
				,[CoafOpereracao]
				,[CoafDescricao]
				,[Agencia]
				,[Conta]
				)
			Select pjcc.ContaCorrenteID,
				cc.Canal,
				pj.RazaoSocial,
				pj.CNPJ,
				pje.Cidade,
				e.Sigla as UF,
				ISNULL(pj.Coaf, 0) AS Coaf,
				ISNULL(pj.PEP, 0) AS PEP,
				0,
				0,
				cc.Email,
				cc.DataPrimeiraCarga,
				sc.Status AS Validacao,
				st.CodigoStatus AS StatusConta,
				st.Descricao AS StatusContaDetalhe,
				cc.StatusContaID,
				CASE cc.StatusDocumento WHEN '0' THEN 'Não' WHEN '1' THEN 'Sim' ELSE 'Não' END AS Monitoria,
				parc.Dominio,
				null AS Telefone,
				cc.CriadoEm,
				ISNULL(td_Lancamentos.valLanc1, 0.0) AS valor,
				ISNULL(td_Lancamentos2.valLanc2, 0.0) AS valorcontrole,
				ISNULL(cc.AlteradoEm, cc.CriadoEm) AS AlteradoEm,
				ISNULL(cc.AlteradoPor, cc.CriacaoPor) AS AlteradoPor,
				2 AS TipoPessoa,
				L.Valor AS ValorPrimeiraCargaLancamento,
				L.CriadoEm AS DataLancamento,
				TP.Descricao AS DescricaoLancamento,
				L.ID AS LancamentoID,
				L.Historico AS HistoricoLancamento,
				LS.Descricao AS DescricaoStatusLancamento,
				pj.CoafData,
				pj.CoafOpereracaoId,
				CO.Descricao,
				dscc.AgenciaSantander AS Agencia,
				dscc.ContaSantander AS Conta
			From PessoasJuridicas pj WITH (nolock) INNER JOIN PessoasJuridicasContasCorrentes pjcc WITH (nolock) on
					pj.ID = pjcc.PessoaJuridicaID
				INNER JOIN ContasCorrentes cc WITH (nolock) ON
					pjcc.ContaCorrenteID = cc.ID
				LEFT JOIN PessoasJuridicasEnderecos pje WITH (nolock) ON
					pj.ID = pje.PessoaJuridicaID
					and pje.ID IN (Select MIN(ID) From PessoasJuridicasEnderecos WITH (nolock)
						Group by PessoaJuridicaID
					)
				LEFT JOIN Estados e WITH (nolock) ON
					pje.EstadoID = e.ID
				LEFT JOIN StatusCadastro sc WITH (nolock) ON
					cc.StatusCadastroID = sc.ID
				LEFT JOIN Status st WITH (nolock) ON
					cc.StatusContaID = st.ID
				LEFT JOIN Parceiros parc WITH (nolock) ON
					cc.Canal = parc.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc1
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					GROUP BY cc.ID
				) td_Lancamentos ON
					cc.ID = td_Lancamentos.ID
				LEFT JOIN (
					Select cc.ID, SUM(Valor) AS valLanc2
					From ContasCorrentes cc WITH (nolock) INNER JOIN Lancamentos l WITH (nolock) ON
						cc.ID = l.ContaCorrenteID
					Where l.MoedaId = 1 AND l.Status <> 'C' AND cc.TipoConta = 'P'
					and l.ContaCorrenteID in (
						SELECT ID
						FROM dbo.ContasCorrentes WITH (nolock)
						WHERE (ContaCorrenteID = cc.ID)
					)
					GROUP BY cc.ID
				) td_Lancamentos2 ON
					cc.ID = td_Lancamentos2.ID
				LEFT OUTER JOIN Lancamentos AS L WITH (nolock) ON
					L.ID =
						(SELECT MIN(ID) AS Expr1
							FROM Lancamentos WITH (nolock)
							WHERE (ContaCorrenteID = cc.ID) AND (cc.DataPrimeiraCarga = CriadoEm))
				LEFT OUTER JOIN TiposLancamento AS TP WITH (nolock) ON
					L.TipoLancamentoID = TP.ID
				LEFT OUTER JOIN LancamentoStatus AS LS WITH (nolock) ON
					L.Status = LS.IdStatusLancamento
				LEFT OUTER JOIN	CoafOperacao AS CO WITH (nolock) ON
					CO.Id = pj.CoafOpereracaoId
				LEFT JOIN DadosSantanderContaCorrente AS dscc WITH (nolock) ON
					cc.ID = dscc.ContaCorrenteID

			select
				 @sv_rowcount	= count(nr_regt) from #resu
		end --if (@TipoPessoa is null or @TipoPessoa = 'PJ')
*/
	end --if (@Fatca is not null)

	fim:

	select
		*
	from
		#resu
go
