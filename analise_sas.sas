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
    tables &var_linha * &var_coluna / row cl;
run;

data dados_tabela;
    set resultados;
        RowVar = RowStdErr**2;
run;

proc tabulate data=dados_tabela format=6.2;
    class &var_linha &var_coluna;
    var RowPercent RowVar RowLowerCL RowUpperCL;
    
    table &var_linha,
          &var_coluna * (
              RowPercent='Prop (%)'*sum='' 
              RowVar='Var'*sum='' 
              RowLowerCL='IC Inf'*sum='' 
              RowUpperCL='IC Sup'*sum=''
          );
run;
proc delete data=dados_tabela resultados; 
run;
%mend;

%tabela_pesquisa(amostra_total, sexo, cand_presidencia)
%tabela_pesquisa(amostra_total, faixa_renda, cand_presidencia)


proc surveymeans data=amostra_total var clm;
var cand_presidencia;
domain sexo;
run;

proc surveyfreq data=amostra_total;
tables faixa_renda * cand_presidencia / row cl;
run;

ods output Crosstabs = resultados_fe;
proc surveyfreq data=amostra_total;
    tables faixa_etaria * cand_presidencia / row cl;
run;

data dados_tabela_fe;
    set resultados_fe;
        RowVar = RowStdErr**2;
run;

proc tabulate data=dados_tabela_fe format=6.2;
    class faixa_etaria cand_presidencia;
    var RowPercent RowVar RowLowerCL RowUpperCL;
    
    table faixa_etaria,
          cand_presidencia * (
              RowPercent='Prop (%)'*sum='' 
              RowVar='Var'*sum='' 
              RowLowerCL='IC Inf'*sum='' 
              RowUpperCL='IC Sup'*sum=''
          );
run;

ods output Crosstabs = resultados_fr;
proc surveyfreq data=amostra_total;
    tables faixa_etaria * cand_presidencia / row cl;
run;

data dados_tabela_fr;
    set resultados_fe;
        RowVar = RowStdErr**2;
run;

proc tabulate data=dados_tabela_fe format=6.2;
    class faixa_etaria cand_presidencia;
    var RowPercent RowVar RowLowerCL RowUpperCL;
    
    table faixa_etaria,
          cand_presidencia * (
              RowPercent='Prop (%)'*sum='' 
              RowVar='Var'*sum='' 
              RowLowerCL='IC Inf'*sum='' 
              RowUpperCL='IC Sup'*sum=''
          );
run;

