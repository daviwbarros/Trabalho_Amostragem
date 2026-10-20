proc import datafile='~/Trabalho_Amostragem/amostras/amostras_xlsx/Pesquisa_Eleitoral_Amostra_1.xlsx'
dbms=xlsx out=amostra1_raw replace;
run;

proc import datafile='~/Trabalho_Amostragem/amostras/amostras_xlsx/Pesquisa_Eleitoral_Amostra_1.xlsx'
dbms=xlsx out=amostra2_raw replace;
run;

proc import datafile='~/Trabalho_Amostragem/amostras/amostras_xlsx/Pesquisa_Eleitoral_Amostra_3.xlsx'
dbms=xlsx out=amostra3_raw replace;
run;

proc import datafile='~/Trabalho_Amostragem/amostras/amostras_xlsx/Pesquisa_Eleitoral_Amostra_4.xlsx'
dbms=xlsx out=amostra4_raw replace;
run;

%macro padronizar_nome(dados_entrada, dados_saida, tipo_pesq);
	data &dados_saida (rename = (
		'Faixa de Renda Familiar'n   = faixa_renda
		'Faixa etária'n              = faixa_etaria
		'Candidato a presidência'n   = cand_presidencia
		'Candidato à Governador DF'n = cand_governador
		));
	set &dados_entrada;	
	length tipo_pesquisa $ 20;
	tipo_pesquisa = &tipo_pesq;
	run;
%mend;

%padronizar_nome(amostra1_raw, amostra1, 'Estimulada')
%padronizar_nome(amostra2_raw, amostra2, 'Estimulada')
%padronizar_nome(amostra3_raw, amostra3, 'Não Estimulada')
%padronizar_nome(amostra4_raw, amostra4, 'Não Estimulada')

data amostra_total;
	set amostra1 amostra2 amostra3 amostra4;
run;

proc surveyfreq data=amostra_total order=freq;
tables cand_presidencia / var cl;
run;

%macro tabela_pesquisa(dados, var_linha, var_coluna);
ods output Crosstabs = resultados;
proc surveyfreq data=&dados;
    tables &var_coluna * &var_linha / col cl;
run;

data dados_tabela;
    set resultados;
        ColVar = ColStdErr**2;
run;

proc tabulate data=dados_tabela format=6.2;
    class &var_linha &var_coluna;
    var ColPercent ColVar ColLowerCL ColUpperCL;
    
    table &var_coluna,
          &var_linha * (
              ColPercent='Prop (%)'*sum='' 
              ColVar='Var'*sum='' 
              ColLowerCL='IC Inf'*sum='' 
              ColUpperCL='IC Sup'*sum=''
          );
run;
proc delete data=dados_tabela resultados; 
run;
%mend;

%tabela_pesquisa(amostra_total, sexo, cand_presidencia)
%tabela_pesquisa(amostra_total, faixa_renda, cand_presidencia)
%tabela_pesquisa(amostra_total, faixa_etaria, cand_presidencia)

%tabela_pesquisa(amostra_total, sexo, cand_governador)
%tabela_pesquisa(amostra_total, faixa_renda, cand_governador)
%tabela_pesquisa(amostra_total, faixa_etaria, cand_governador)


proc surveymeans data=amostra_total var clm;
var cand_presidencia;
domain sexo;
run;


options orientation=landscape;
/* 1. Define o local e o nome do arquivo PDF que será gerado */
/* O uso de ~/ garante compatibilidade entre os membros da equipe no SAS Studio */
ods pdf file="~/Trabalho_Amostragem/Resultados/Relatorio_Eleitoral.pdf" style=Pearl pdftoc=1;

title "Intenção de Voto para Presidente - Distribuição por Faixa Etária";
%tabela_pesquisa(amostra_total, faixa_etaria, cand_presidencia);

title "Intenção de Voto para Presidente - Distribuição por Sexo";
%tabela_pesquisa(amostra_total, sexo, cand_presidencia);

title "Intenção de Voto para Presidente - Distribuição por Renda";
%tabela_pesquisa(amostra_total, faixa_renda, cand_presidencia);

ods pdf close;


