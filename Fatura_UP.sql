select emp_cnpj as CNPJ_Revenda,
   emp_razaosocial as Revenda,
   emp_nomefantasia As NomeFantasia,
   pdt_cod_produto as Produto,
   count(ded_codigo) as Qtde,
   sum(ded_valor_mensal * ded_parcela) / count(ded_codigo) as ValorUnitario
from tb_pedidos_ded inner join tb_empresas on
   ded_empcodigo = emp_codigo
   inner join tb_produtos on
   ded_pdtcodigo = pdt_codigo
where ded_stacodigo > 2 and ded_tipcodigo = 4
group by
   emp_cnpj,
   emp_razaosocial,
   emp_nomefantasia,
   pdt_cod_produto
