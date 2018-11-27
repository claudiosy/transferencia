/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Histórico de Modificações
* Data                                  Autor                                               OS Descrição
* 23/05/2106            				Leandro Soto Fernandes							    Proc que obtem cargas de transferências REPAL por Id e intervalo de datas.
* 13/01/2017						    Fabio R Santos						            	Trac desenv 109 - Exbir motivos prevencao
* 13/02/2017						    Danilo Barreto Bezerra								Ajustando campo TipoPessoa para exiber corretamente, em alguns casos era exibido PJ para PF
* 05/03/2018						    Fabio R Santos						            	Filtro por CPF
* 16/03/2018						    Fabio R Santos						            	Dados de Origen Repal
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
--exec pObterInconsistenciasRepal @DataInicial = NULL, @DataFinal=NULL, @TipoConsulta= 1, @CPFCPNJ = '412.560.771-00' '092.894.677-03' '021.446.333-80' '74.400.052/0001-91' ---
-- exec pObterInconsistenciasRepal @DataInicial = '2017-12-01', @DataFinal= '2018-01-24', @TipoConsulta= 1, @CPFCPNJ = '092.894.677-03'  '021.446.333-80' ---  '021.446.333-80'
-- exec pObterInconsistenciasRepal '2017-05-01', '2018-05-24', 1
-- exec pObterInconsistenciasRepal '2016-12-01', '2017-01-23', 2
 
CREATE PROCEDURE [dbo].[pObterInconsistenciasRepal]
(
	@DataInicial DATETIME --= '2016-12-01'
	, @DataFinal DATETIME --= '2017-01-23'
	, @TipoConsulta INT --1 = risco / 2 = BackOffice
	, @SomenteLeitura SYSNAME = 'AORO'
	, @Retorno TINYINT = 0
	, @Servidor SYSNAME = NULL OUTPUT
	, @CPFCPNJ varchar(20) = NULL
)
as
 set nocount on

declare
 @sv_error int = 0
 ,@nm_stpr sysname
 ,@CodigoProcesso bigint = 111

 select
 @Servidor = @@servername
 
 if (@SomenteLeitura is not null)
 begin
 exec Super.dbo.ptestlinkedserver
 @Nome = @SomenteLeitura output
 ,@sv_error = @sv_error output
 ,@CodigoProcesso = @CodigoProcesso

 update
 Super.dbo.Processos
 set
 Servidor = @Servidor
 ,ErroLinkedServer = @sv_error
 ,DataExecucaoAO = getdate()
 where
 CodigoProcesso = @CodigoProcesso

 if (@sv_error = 0)
 begin
 select
 @nm_stpr = @SomenteLeitura + '.' + db_name() + '.dbo.' + object_name(@@procid)

 begin try
 exec @nm_stpr
 @DataInicial = @DataInicial
 ,@DataFinal = @DataFinal
 ,@TipoConsulta = @TipoConsulta
 ,@SomenteLeitura = null
 ,@Retorno = 1
 ,@Servidor = @Servidor output
  ,@CPFCPNJ   = @CPFCPNJ
 end try
 begin catch
 select
 @sv_error = error_number()
 end catch

 update
 Super.dbo.Processos
 set
 Servidor = @Servidor
 ,Comando = @nm_stpr
 ,DataExecucaoAO = getdate()
 ,ErroLinkedServer = @sv_error
 where
 CodigoProcesso = @CodigoProcesso

 if (@sv_error = 0)
 begin
 return
 end --if (@sv_error = 0)
 end --if (@sv_error = 0)
 end --if (@SomenteLeitura is not null)
 

declare 
	 @statusInconsistenciagrupoEconomico int = 12
	 ,@DataBaseInicial datetime
	 ,@DataBaseFinal datetime
	 ,@mesAtual int
	 ,@anoAtual int

create table #DocumentosParaConsulta
 (
	CpfCnpj bigint null unique(CpfCnpj, nr_regt)
	,TipoArquivo varchar(1) null
	,AgenciaSantander varchar(4) null unique(AgenciaSantander, nr_regt)
	,ContaSantander varchar(12) null unique(ContaSantander, nr_regt)
	,Id int null
	,DataLancamento datetime null
	,ValorLancamento decimal(16,2) null
	,StatusContaId int null unique(StatusContaId, nr_regt)
	,Descricao varchar(150) null
	,Motivo varchar(250) null
,Origem  varchar(50) null
--,ArquivosRepalId int 
	,nr_regt bigint identity(1,1)
	,primary key clustered (nr_regt)
 )
 
create table #lancamentosRepal
 (
	 ID bigint null
	 ,TipoArquivo varchar(1) null unique(TipoArquivo, nr_regt)
	 ,DataLancamento datetime null
	 ,NumeroDocumento varchar(118) null
	 ,Nome varchar(200) null
	 ,TipoPessoa varchar(4) null
	 ,Email varchar(255) null
	 ,StatusConta varchar(1) null
	 ,DescricaoStatusConta varchar(255) null
	 ,ValorLancamento decimal(16,2) null
	 ,ValorTotalMes decimal(16,2) null
	 ,NumeroDocumentoArquivo varchar(18) null unique(NumeroDocumentoArquivo, nr_regt)
	 ,AgenciaSantander varchar(4) null
	 ,ContaSantander varchar(12) null
	,Descricao varchar(150) null
	,Motivo varchar(250) null
,Origem  varchar(50) null
--,ArquivosRepalId int 
	 ,CpfCnpj bigint null unique(CpfCnpj, nr_regt)
	 ,Tipo tinyint not null default(0) unique(Tipo, nr_regt)
	 ,nr_regt bigint identity(1,1)
	 ,primary key clustered (nr_regt)
 )
  
create table #statusInconsistenciasConciliacaoLancamentos
(
	ID int null
	,Descricao varchar(500)
	,Tipo varchar(500)
)

create table #statusInconsistenciasIntradayLancamentos
(
	ID int null
	,Descricao varchar(500)
	,Tipo varchar(500)
)

	 if @TipoConsulta = 2 --BackOffice
	 begin

			insert #statusInconsistenciasConciliacaoLancamentos
			select ID, Descricao, Tipo  from StatusRepalConciliacaoLancamentos (nolock) where Tipo like '%AnaliseBackOffice%'

			insert #statusInconsistenciasIntradayLancamentos
			select ID, Descricao, Tipo from StatusRepalIntradayLancamentos (nolock) where Tipo like '%AnaliseBackOffice%'
	
	 end
	 else
	 begin

			insert #statusInconsistenciasConciliacaoLancamentos
			select ID, Descricao, Tipo from StatusRepalConciliacaoLancamentos (nolock) where Tipo like '%AnaliseRisco%'

			insert #statusInconsistenciasIntradayLancamentos
			select ID, Descricao, Tipo from StatusRepalIntradayLancamentos (nolock) where Tipo like '%AnaliseRisco%'

	 end

 insert #DocumentosParaConsulta 
 (
		CpfCnpj
		,TipoArquivo
		,AgenciaSantander
		,ContaSantander
		,Id
		,DataLancamento
		,ValorLancamento
		,StatusContaId
		,Descricao
		,Motivo
,Origem
--,ArquivosRepalId
 )
 select
		 CAST(ril.NumeroDocumento as bigint) as CpfCnpj
		 ,'I' as TipoArquivo
		 ,ril.AgenciaSantander as AgenciaSantander
		 ,ril.ContaSantander as ContaSantander
		 ,ril.ID as Id
		 ,ril.DataLancamento as DataLancamento
		 ,ril.ValorLancamento as ValorLancamento
		 ,ril.StatusContaId as StatusContaId
		,thr_.Descricao
		,SRIL.Descricao as Motivo
,ARID.ComplementoLancamento as Origem
--,ril.ArquivosRepalIntraday240v9DetalheId ArquivosRepalId
 		from RepalIntradayLancamentos ril (nolock)
			left join TiposHistoricosRepal (nolock) thr_ on thr_.CodigoHistorico = ril.CodigoHistorico	
			left join StatusRepalIntradayLancamentos (nolock) SRIL on SRIL.ID = ril.StatusId	
LEFT JOIN ArquivosRepalIntraday240v9Detalhe (nolock) ARID ON ARID.ID = ril.ArquivosRepalIntraday240v9DetalheId
		 where
			ril.StatusId in (select Id from #statusInconsistenciasIntradayLancamentos)
			and  (@DataInicial is null or ril.DataLancamento >= @DataInicial)
	  		and  (@DataFinal is null or  ril.DataLancamento < @DataFinal)
			and ril.LancamentoId is not null

 union all

 select
	CAST(rcl.NumeroDocumento as bigint) as CpfCnpj
	,'C' as TipoArquivo
	,rcl.AgenciaSantander as AgenciaSantander
	,rcl.ContaSantander as ContaSantander
	,rcl.ID as Id
	,rcl.DataLancamento as DataLancamento
	,rcl.ValorLancamento as ValorLancamento
	,rcl.StatusContaId as StatusContaId
	,thr.Descricao
	,SRCL.Descricao as Motivo
 ,ARCD.ComplementoLancamento as Origem
 --,rcl.ArquivosRepalConciliacaoDetalheId ArquivosRepalId
  from
	 dbo.RepalConciliacaoLancamentos rcl (nolock)
		left join TiposHistoricosRepal (nolock) thr on thr.CodigoHistorico = rcl.CodigoHistorico	
		left join StatusRepalConciliacaoLancamentos (nolock) SRCL on SRCL.ID = rcl.StatusId
 LEFT JOIN ArquivosRepalConciliacaoDetalhe (nolock) ARCD ON ARCD.ID = rcl.ArquivosRepalConciliacaoDetalheId
	 where
	rcl.StatusId in (select Id from #statusInconsistenciasConciliacaoLancamentos)
	 and (@DataInicial is null or rcl.DataLancamento >= @DataInicial)
	 and (@DataFinal is null or rcl.DataLancamento < @DataFinal)
	 and rcl.LancamentoId is not null

 
 insert #lancamentosRepal
 (
	 ID
	 ,TipoArquivo
	 ,DataLancamento
	 ,NumeroDocumento
	 ,Nome
	 ,TipoPessoa
	 ,Email
	 ,StatusConta
	 ,DescricaoStatusConta
	 ,ValorLancamento
	 ,ValorTotalMes
	 ,NumeroDocumentoArquivo
	 ,AgenciaSantander
	 ,ContaSantander
	,dpc.Descricao
	,dpc.Motivo
	 ,CpfCnpj
,Origem  
--,ArquivosRepalId
 )
 select
		 dpc.Id 
		 ,dpc.TipoArquivo as TipoArquivo 
		 ,dpc.DataLancamento as DataLancamento
		 ,pj.CNPJ as NumeroDocumento
		 ,pj.RazaoSocial as Nome
		 ,'PJ' as TipoPessoa
		 ,cc.Email as Email
		 ,s.CodigoStatus as StatusConta
		 ,s.Status as DescricaoStatusConta
		 ,dpc.ValorLancamento as ValorLancamento
		 ,0 as ValorTotalMes
		 ,dpc.CpfCnpj as NumeroDocumentoArquivo
		 ,null as AgenciaSantander
		 ,null as ContaSantander
		,dpc.Descricao
		,dpc.Motivo
		,dpc.CpfCnpj
,dpc.Origem
--,dpc.ArquivosRepalId
 from
	 #DocumentosParaConsulta dpc 
	 inner join dbo.PessoasJuridicas pj (nolock) on (pj.NumeroCNPJ = dpc.CpfCnpj)
	 inner join dbo.PessoasJuridicasContasCorrentes pjcc (nolock) on (pjcc.PessoaJuridicaID = pj.ID)
	 inner join dbo.ContasCorrentes cc (nolock) on (cc.ID = pjcc.ContaCorrenteId)
	 inner join  dbo.Status s (nolock) on (dpc.StatusContaId = s.ID)
  where
	 dpc.AgenciaSantander is null
	 and dpc.ContaSantander is null
and (@CPFCPNJ is null or  pj.CNPJ = @CPFCPNJ)

 insert #lancamentosRepal
 (
	 ID
	 ,TipoArquivo
	 ,DataLancamento
	 ,NumeroDocumento
	 ,Nome
	 ,TipoPessoa
	 ,Email
	 ,StatusConta
	 ,DescricaoStatusConta
	 ,ValorLancamento
	 ,ValorTotalMes
	 ,NumeroDocumentoArquivo
	 ,AgenciaSantander
	 ,ContaSantander
	,dpc.Descricao
	,dpc.Motivo
	 ,CpfCnpj
,Origem
--,ArquivosRepalId
 )
 select
	 dpc.Id 
	 ,dpc.TipoArquivo as TipoArquivo 
	 ,dpc.DataLancamento as DataLancamento
	 ,pf.CPF as NumeroDocumento
	 ,pf.Nome as Nome
	 ,(select  case when count(ContaCorrenteID) = 0  then'PF'  else 'FOPA' end   from Favorecidos (nolock) where ContaCorrenteFavorecidoID =pfcc.ContaCorrenteId)  as TipoPessoa
	 ,cc.Email as Email
	 ,s.CodigoStatus as StatusConta
	 ,s.Status as DescricaoStatusConta
	 ,dpc.ValorLancamento as ValorLancamento
	 ,0 as ValorTotalMes
	 ,dpc.CpfCnpj as NumeroDocumentoArquivo
	 ,null as AgenciaSantander
	 ,null as ContaSantander
	,dpc.Descricao
	,dpc.Motivo
	,dpc.CpfCnpj
,dpc.Origem
--,dpc.ArquivosRepalId
 from
	 #DocumentosParaConsulta dpc inner join dbo.PessoasFisicas pf (nolock) on (pf.NumeroCPF = dpc.CpfCnpj)
	 inner join dbo.PessoasFisicasContasCorrentes pfcc (nolock) on (pfcc.PessoaFisicaID = pf.ID)
	 inner join dbo.ContasCorrentes cc (nolock) on (cc.ID = pfcc.ContaCorrenteId)
	 inner join dbo.Status s (nolock) on (dpc.StatusContaId = s.ID)
 where
	dpc.AgenciaSantander is null
	and dpc.ContaSantander is null
and (@CPFCPNJ is null or  pf.CPF = @CPFCPNJ)
	and not exists (
					select
						nr_regt
					 from
						#lancamentosRepal ttmp
					 where
						ttmp.CpfCnpj = dpc.CpfCnpj
						and ttmp.Tipo = 0
					)

 insert #lancamentosRepal
 (
	 ID
	 ,TipoArquivo
	 ,DataLancamento
	 ,NumeroDocumento
	 ,Nome
	 ,TipoPessoa
	 ,Email
	 ,StatusConta
	 ,DescricaoStatusConta
	 ,ValorLancamento
	 ,ValorTotalMes
	 ,NumeroDocumentoArquivo
	 ,AgenciaSantander
	 ,ContaSantander
	,Descricao
	,dpc.Motivo
	 ,CpfCnpj
	 ,Tipo
,Origem
--,ArquivosRepalId
 )
 select
	 dpc.Id 
	 ,dpc.TipoArquivo as TipoArquivo 
	 ,dpc.DataLancamento as DataLancamento
	 ,pj.CNPJ as NumeroDocumento
	 ,pj.RazaoSocial as Nome
	 ,'PJ' as TipoPessoa
	 ,cc.Email as Email
	 ,s.CodigoStatus as StatusConta
	 ,s.Status as DescricaoStatusConta
	 ,dpc.ValorLancamento as ValorLancamento
	 ,0 as ValorTotalMes
	 ,dpc.CpfCnpj as NumeroDocumentoArquivo
	 ,dpc.AgenciaSantander as AgenciaSantander
	 ,dpc.ContaSantander as ContaSantander
	,dpc.Descricao
	,dpc.Motivo
	 ,dpc.CpfCnpj
	 ,1 as Tipo
,dpc.Origem
--,dpc.ArquivosRepalId
 from
 #DocumentosParaConsulta dpc 
 inner join
 dbo.DadosSantanderContaCorrente dscc (nolock)
 on
 (
 dscc.AgenciaSantander = dpc.AgenciaSantander
 and dscc.ContaSantander = dpc.ContaSantander
 )
 inner join
 dbo.PessoasJuridicasContasCorrentes pjcc (nolock)
 on
 (
 pjcc.ContaCorrenteID = dscc.ContaCorrenteID
 )
 inner join
 dbo.PessoasJuridicas pj (nolock)
 on
 (
 pj.ID = pjcc.PessoaJuridicaId
 )
 inner join
 dbo.ContasCorrentes cc (nolock)
 on
 (
 cc.ID = dscc.ContaCorrenteID
 )
 inner join
 dbo.Status s (nolock)
 on
 (
 dpc.StatusContaId = s.ID
 )
 where
 dpc.AgenciaSantander is not null
 and dpc.ContaSantander is not null
 and (@CPFCPNJ is null or  pj.CNPJ = @CPFCPNJ)

 insert #lancamentosRepal
 (
	 ID
	 ,TipoArquivo
	 ,DataLancamento
	 ,NumeroDocumento
	 ,Nome
	 ,TipoPessoa
	 ,Email
	 ,StatusConta
	 ,DescricaoStatusConta
	 ,ValorLancamento
	 ,ValorTotalMes
	 ,NumeroDocumentoArquivo
	 ,AgenciaSantander
	 ,ContaSantander
	,Descricao
	,dpc.Motivo
	 ,CpfCnpj
	 ,Tipo
,Origem
--,ArquivosRepalId
 )
 select
	 dpc.Id 
	 ,dpc.TipoArquivo as TipoArquivo 
	 ,dpc.DataLancamento as DataLancamento
	 ,pf.CPF as NumeroDocumento
	 ,pf.Nome
	 ,'PF' as TipoPessoa
	 ,cc.Email as Email
	 ,s.CodigoStatus as StatusConta
	 ,s.Status as DescricaoStatusConta
	 ,dpc.ValorLancamento as ValorLancamento
	 ,0 as ValorTotalMes
	 ,dpc.CpfCnpj as NumeroDocumentoArquivo
	 ,dpc.AgenciaSantander as AgenciaSantander
	 ,dpc.ContaSantander as ContaSantander
	,dpc.Descricao
	,dpc.Motivo
	 ,dpc.CpfCnpj
	 ,1 as Tipo
,dpc.Origem
--,dpc.ArquivosRepalId
 from
 #DocumentosParaConsulta dpc 
 inner join
 dbo.DadosSantanderContaCorrente dscc (nolock)
 on
 (
 dscc.AgenciaSantander = dpc.AgenciaSantander
 and dscc.ContaSantander = dpc.ContaSantander
 )
 inner join
 dbo.PessoasFisicasContasCorrentes pfcc (nolock)
 on
 (
 pfcc.ContaCorrenteID = dscc.ContaCorrenteID
 )
 inner join
 dbo.PessoasFisicas pf (nolock)
 on
 (
 pf.ID = pfcc.PessoaFisicaId
 )
 inner join
 dbo.ContasCorrentes cc (nolock)
 on
 (
 cc.ID = dscc.ContaCorrenteID
 )
 inner join
 dbo.Status s (nolock)
 on
 (
 dpc.StatusContaId = s.ID
 )
 where
 dpc.AgenciaSantander is not null
 and dpc.ContaSantander is not null
 and (@CPFCPNJ is null or  pf.CPF = @CPFCPNJ)
 and not exists
 (
 select
 nr_regt
 from
 #lancamentosRepal ttmp
 where
 ttmp.CpfCnpj = dpc.CpfCnpj
 and ttmp.Tipo = 1
 )

 select
 @mesAtual = MONTH(getdate())
 ,@anoAtual = YEAR(getdate())

 select
 @DataBaseInicial = convert(varchar, @anoAtual)
 + '-'
 + convert(varchar, @mesAtual)
 + '-01'

 select
 @DataBaseFinal = dateadd(mm, 1, @DataBaseInicial)

 select distinct
 ID 
 ,TipoArquivo 
 ,DataLancamento 
 ,dbo.fRemoveCaracteresNaoNumericos(NumeroDocumento) as NumeroDocumento
 ,Nome 
 ,TipoPessoa 
 ,Email 
 ,StatusConta 
 ,DescricaoStatusConta
 ,ValorLancamento 
 ,AgenciaSantander
 ,ContaSantander
 ,ValorTotalMes = (
				 select 
				 sum(isnull(ril.ValorLancamento, 0)) + sum(isnull(rcl.ValorLancamento,0)) 
				 from 
				 #lancamentosRepal t2 
				 left join
				 dbo.RepalIntradayLancamentos ril (nolock) 
				 on 
				 (
				 t2.TipoArquivo = 'I'
				 and ril.NumeroDocumento = t2.NumeroDocumentoArquivo
				 and ril.DataLancamento >= @DataBaseInicial
				 and ril.DataLancamento < @DataBaseFinal
				 )
				 left join
				 dbo.RepalConciliacaoLancamentos rcl (nolock) 
				 on 
				 (
				 t2.TipoArquivo = 'C'
				 and rcl.NumeroDocumento = NumeroDocumentoArquivo
				 and rcl.DataLancamento >= @DataBaseInicial
				 and rcl.DataLancamento < @DataBaseFinal
				 )
				 where 
				 t1.NumeroDocumentoArquivo = t2.NumeroDocumentoArquivo
				 )
	,Descricao as Modalidade
	,Motivo
	,Origem
--	,ArquivosRepalId
 from 
 #lancamentosRepal t1
 order by t1.DataLancamento desc

  --select top 1000 *  from ArquivosRepalIntraday240v9
  -- select top 1000 *  from ArquivosRepalIntraday240v9Detalhe order by 1 DESC
   -- select top 1000 ArquivosRepalIntraday240v9DetalheId, *      	from RepalIntradayLancamentos order by 1 DESC