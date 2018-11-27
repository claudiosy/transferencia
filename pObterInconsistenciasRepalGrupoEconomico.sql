
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


 

/*
Busca Lancamentos de grupo economico
exec pObterInconsistenciasRepalGrupoEconomico '2016-01-01', '2018-09-05'

Atualizações:
-Interaoperabilidade 19/09/2016
-Interaoperabilidade 17/05/2018 Fabio Santos Incluido relacionamento com as tabelas SituacaoRepalLancamentosIncoistentesGrupoEconomico e StatusSituacaoRepalLancamentosIncoistentesGrupoEconomico
*/

CREATE procedure pObterInconsistenciasRepalGrupoEconomico (
	@DataInicial date,
	@DataFinal	date
)
as
begin
	declare @statusInconsistenciagrupoEconomico int = 12

	set @DataFinal = cast(dateadd(day, 1, @DataFinal) as date)

	select
		 rcl.ID													as ID 
		,'GE'													as TipoArquivo 
		,convert(date, rcl.DataLancamento)						as DataLancamento 
		,dbo.fRemoveCaracteresNaoNumericos(rcl.NumeroDocumento) as NumeroDocumento
		,pj.RazaoSocial											as Nome 

		,rcl.ValorLancamento									as ValorLancamento 
		,'PJ'													as TipoPessoa 
		,cc2.Email												as Email 
		,''														as StatusConta 

--,cc.Email as EmailDaConta
,SRLIGE.CNPJCredito as CNPJCredito --pj2.CNPJ  as CNPJCredito
,SRLIGE.EmailContaCredito as EmailContaCredito --,cc3.Email as EmailContaCredito
,SRLIGE.AprovadorPor as AprovadoPor
,SRLIGE.AprovadorEm as AprovadorEm
,SRLIGE.LancamentoEfetuadoPor as LancamentoEfetuadoPor
		,''														as DescricaoStatusConta
		,0.0													as ValorTotalMes
		,dscc.ContaSantander									as ContaSantander
		,dscc.AgenciaSantander									as AgenciaSantander
,'C' as TipoRepal
,SRLIGE.Status as StatusSituacaoRepalLancamentos
,SRLIGE.LancamentoId as LancamentoIdEfetuado
,L.Status as StatusLancamentoEfetuado
--,L.Id as LancamentoIdEfetuado
,SRLIGE.LancamentoEfetuadoEm as LancamentoEfetuadoEm
--,L.DataLancto as LancamentoEfetuadoEm
, case when SSRLIGE.Descricao is not null then SSRLIGE.Descricao else 'Pendente Aprovacao' end as DescricaoStatusSituacaoRepal
,SRLIGE.Id as SituacaoRepalLancamentosIncoistentesGrupoEconomicoId

		from RepalConciliacaoLancamentos rcl (nolock)
		inner join RepalGrupoEconomico rge (nolock)				on convert(bigint,rge.CNPJGrupoEconomico) = convert(bigint,rcl.NumeroDocumento)
		inner join ContasCorrentesContasContabeis cccb (nolock) on cccb.ContaContabilId = rge.ContaContabilId
		inner join ContasCorrentes cc (nolock)					on cc.ID = cccb.ContaCorrenteId
		inner join PessoasJuridicasContasCorrentes pjcc (nolock) on pjcc.ContaCorrenteID = cc.ID
		inner join PessoasJuridicas pj (nolock)					on pj.ID = pjcc.PessoaJuridicaID
		inner join ContasCorrentes cc2 (nolock)					on cc2.ID = cccb.ContaContabilId
		left join DadosSantanderContaCorrente dscc (nolock)		on dscc.ContaCorrenteID = cc2.ID
left join SituacaoRepalLancamentosIncoistentesGrupoEconomico SRLIGE (nolock) on SRLIGE.RepalLancamentoID = rcl.ID and SRLIGE.TipoRepal = 'C'
left join StatusSituacaoRepalLancamentosIncoistentesGrupoEconomico SSRLIGE (nolock) on SSRLIGE.Id = SRLIGE.Status
left JOIN Lancamentos L (nolock) on L.ID = SRLIGE.LancamentoId
--left join Lancamentos L (nolock) on L.Id = SRLIGE.LancamentoId
	where
			rcl.StatusId = @statusInconsistenciagrupoEconomico
		and rcl.DataLancamento >= @DataInicial
		and rcl.DataLancamento < @DataFinal
		and rcl.LancamentoId is not null
	
	union all

	select
		ril.ID													as ID 
		,'GE'													as TipoArquivo 
		,convert(date, ril.DataLancamento)						as DataLancamento 
		,dbo.fRemoveCaracteresNaoNumericos(ril.NumeroDocumento) as NumeroDocumento
		,pj.RazaoSocial											as Nome 

		,ril.ValorLancamento									as ValorLancamento 
		,'PJ'													as TipoPessoa 
		,cc2.Email												as Email --email de debto	
		,''														as StatusConta -- Pendente/Aprovado

--,cc.Email as EmailDaConta
,SRLIGE_.CNPJCredito as CNPJCredito --pj2.CNPJ  as CNPJCredito
,SRLIGE_.EmailContaCredito as EmailContaCredito --,cc3.Email as EmailContaCredito
,SRLIGE_.AprovadorPor as AprovadoPor
,SRLIGE_.AprovadorEm as AprovadorEm
,SRLIGE_.LancamentoEfetuadoPor as LancamentoEfetuadoPor
		,''														as DescricaoStatusConta
		,0.0													as ValorTotalMes
		,dscc.ContaSantander									as ContaSantander
		,dscc.AgenciaSantander									as AgenciaSantander
,'I'													as TipoRepal
,SRLIGE_.Status as StatusSituacaoRepalLancamentos
,SRLIGE_.LancamentoId as LancamentoIdEfetuado
,L_.Status as StatusLancamentoEfetuado
--,L_.Id as LancamentoIdEfetuado
,SRLIGE_.LancamentoEfetuadoEm as LancamentoEfetuadoEm
--,L_.DataLancto as LancamentoEfetuadoEm
, case when SSRLIGE_.Descricao is not null then SSRLIGE_.Descricao else 'Pendente Aprovacao' end as DescricaoStatusSituacaoRepal
,SRLIGE_.Id as SituacaoRepalLancamentosIncoistentesGrupoEconomicoId
 
		from RepalIntradayLancamentos ril (nolock)
		inner join RepalGrupoEconomico rge (nolock)				on convert(bigint,rge.CNPJGrupoEconomico) = convert(bigint,ril.NumeroDocumento)
		inner join ContasCorrentesContasContabeis cccb (nolock) on cccb.ContaContabilId = rge.ContaContabilId
		inner join ContasCorrentes cc (nolock)					on cc.ID = cccb.ContaCorrenteId
		inner join PessoasJuridicasContasCorrentes pjcc (nolock) on pjcc.ContaCorrenteID = cc.ID
		inner join PessoasJuridicas pj (nolock)					on pj.ID = pjcc.PessoaJuridicaID
		inner join ContasCorrentes cc2 (nolock)					on cc2.ID = cccb.ContaContabilId		
		left join DadosSantanderContaCorrente dscc (nolock)		on dscc.ContaCorrenteID = cc2.ID
left join SituacaoRepalLancamentosIncoistentesGrupoEconomico SRLIGE_ (nolock) on SRLIGE_.RepalLancamentoID = ril.ID and SRLIGE_.TipoRepal = 'I'
left join StatusSituacaoRepalLancamentosIncoistentesGrupoEconomico SSRLIGE_ (nolock) on SSRLIGE_.Id = SRLIGE_.Status
left JOIN Lancamentos L_ (nolock) on L_.ID = SRLIGE_.LancamentoId
--left join Lancamentos L_ (nolock) on L_.Id = SRLIGE_.LancamentoId

	where
			ril.StatusId = @statusInconsistenciagrupoEconomico
		and ril.DataLancamento >= @DataInicial
		and ril.DataLancamento < @DataFinal
		and ril.LancamentoId is not null
	order by 1 desc
end
 
