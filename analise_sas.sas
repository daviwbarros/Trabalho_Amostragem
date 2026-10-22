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



/* Macro para gerar tabela com resultados de intenção de voto para cargo por categoria de varíavel explicativa*/
%macro tabela_pesquisa(dados, var_linha, var_coluna);
ods select none;
ods output Crosstabs = resultados;
proc surveyfreq data=&dados;
    tables &var_coluna * &var_linha / col cl;
run;

ods output ChiSq = resultado_chisq_freq;
proc freq data=&dados;
    tables &var_coluna * &var_linha / chisq;
run;

ods select all;
data dados_tabela;
    set resultados;
        ColVar = ColStdErr**2;
run;

proc tabulate data=dados_tabela format=6.2;
    class &var_linha F_&var_coluna;
    var Frequency ColPercent ColVar ColLowerCL ColUpperCL;
    
    table F_&var_coluna,
          &var_linha * (
              Frequency='N'*sum=''
              ColPercent='Prop (%)'*sum=''
              ColVar='Var'*sum='' 
              ColLowerCL='IC Inf'*sum='' 
              ColUpperCL='IC Sup'*sum=''
          );
run;

proc sort data=resultados out=resultados_ordenado;
    by &var_linha descending ColPercent;
run;

proc sgplot data=resultados_ordenado;
    vbar &var_linha / response=ColPercent
                      group=&var_coluna
                      groupdisplay=stack
                      grouporder=data
                      datalabel;
    yaxis label="Percentual(%)";
    keylegend / title="Candidato" location=outside position=bottom;
run;

proc sgplot data=dados_tabela;
    scatter x=&var_coluna y=ColPercent / group=&var_linha
                                           groupdisplay=cluster 
                                           clusterwidth=0.8
                                           yerrorlower=ColLowerCL 
                                           yerrorupper=ColUpperCL
                                           markerattrs=(symbol=circlefilled size=5);
                                           
    xaxis label="Candidato" discreteorder=data;
    yaxis label="Proporção Estimada (%)" grid;
    keylegend / location=outside position=bottom;
run;

proc report data=resultado_chisq_freq nowd headline headskip;
    column Statistic DF Value Prob;
    
    define Statistic / display "Estatística do Teste" 
                       style={cellwidth=45%};
                       
    define DF        / display "Graus de Liberdade (GL)" 
                       style={cellwidth=15% just=center};
                       
    define Value     / display "Estatística Calculada" 
                       format=8.4 
                       style={cellwidth=20% just=right};
                       
    define Prob      / display "P-valor" 
                       format=PVALUE6.4 
                       style={cellwidth=20% just=right};

    compute after;
        line "Nota: Nível de significância adotado de 5% (p < 0,05 indica associação estatisticamente significativa).";
    endcomp;
run;

proc delete data=dados_tabela resultados resultados_ordenado; 
run;
%mend;

/* Macro para padronizar tabela de intenção de voto para cargo por categoria de variável explicativa*/
%macro tabela_pesquisa_padronizada(dados, var_linha, var_coluna, out_ds);
ods output Crosstabs = resultados;
proc surveyfreq data=&dados;
    tables &var_linha * &var_coluna / row cl;
run;

data &out_ds (keep=Dominio Categoria F_&var_coluna Frequency RowPercent RowVar RowLowerCL RowUpperCL);
    set resultados;
    length Dominio $ 30 Categoria $ 50;
    Dominio = "&var_linha";
        
    Categoria = put(&var_linha, $string50.);
    if Categoria = '' then Categoria = cats(&var_linha);
        
    RowVar = RowStdErr**2;
run;

proc delete data=resultados; 
run;
%mend;

/* Macro para gerar tabela completa com intenção de para cargo por categoria de todas as variáveis explicativas */
%macro tabela_pesquisa_empilhada(var_coluna);

ods select none;
%tabela_pesquisa_padronizada(amostra_total, faixa_renda, &var_coluna, tab_renda)
%tabela_pesquisa_padronizada(amostra_total, sexo, &var_coluna, tab_sexo)
%tabela_pesquisa_padronizada(amostra_total, faixa_etaria, &var_coluna, tab_idade)
%tabela_pesquisa_padronizada(amostra_total, tipo_pesquisa, &var_coluna, tab_pesq)

ods select all;
data tabela_empilhada;
    set tab_sexo tab_idade tab_renda tab_pesq;
run;

proc tabulate data=tabela_empilhada format=6.2;
    class Dominio Categoria F_&var_coluna;
    var Frequency RowPercent RowVar RowLowerCL RowUpperCL;
    
    table Dominio * Categoria,
          F_&var_coluna * (
              Frequency='N'*sum=''
              RowPercent='Prop (%)'*sum=''
              RowVar='Var'*sum='' 
              RowLowerCL='IC Inf'*sum='' 
              RowUpperCL='IC Sup'*sum=''
          );
run;

proc delete data=tabela_empilhada tab_renda tab_sexo tab_idade tab_pesq;
run;

%mend;

/* Documento .pdf com os resultados*/ 
options orientation=landscape;
ods pdf file="~/Trabalho_Amostragem/Resultados/Relatorio_Eleitoral.pdf" style=Pearl pdftoc=1;

title "Intenção de Voto para Presidente";
ods output OneWay=resultados;
proc surveyfreq data=amostra_total order=freq;
tables cand_presidencia / var cl;
run;

proc sgplot data=resultados;
    vbar cand_presidencia / response=Percent 
                            datalabel 
                            fillattrs=(color=navy);
    xaxis label="Candidato";
    yaxis label="Percentual (%)" grid;
run;

proc delete data=resultados;
run;

title "Intenção de Voto para Presidente - Distribuição por Faixa Etária";
%tabela_pesquisa(amostra_total, faixa_etaria, cand_presidencia);

title "Intenção de Voto para Presidente - Distribuição por Sexo";
%tabela_pesquisa(amostra_total, sexo, cand_presidencia);

title "Intenção de Voto para Presidente - Distribuição por Renda";
%tabela_pesquisa(amostra_total, faixa_renda, cand_presidencia);

title "Intenção de Voto para Presedente - Distribuição por Tipo de Pesquisa";
%tabela_pesquisa(amostra_total, tipo_pesquisa, cand_presidencia);

title "Intenção de Voto para Presidente - Tabela Resumida";
%tabela_pesquisa_empilhada(cand_presidencia)

title "Intenção de Voto para Governador";
ods output OneWay=resultados;
proc surveyfreq data=amostra_total order=freq;
tables cand_governador / var cl;
run;

proc sgplot data=resultados;
    vbar cand_governador / response=Percent 
                            datalabel 
                            fillattrs=(color=navy);
    xaxis label="Candidato";
    yaxis label="Percentual (%)" grid;
run;

proc delete data=resultados;
run;

title "Intenção de Voto para Governador - Distribuição por Faixa Etária";
%tabela_pesquisa(amostra_total, faixa_etaria, cand_governador);

title "Intenção de Voto para Governador - Distribuição por Sexo";
%tabela_pesquisa(amostra_total, sexo, cand_governador);

title "Intenção de Voto para Governador - Distribuição por Renda";
%tabela_pesquisa(amostra_total, faixa_renda, cand_governador);

title "Intenção de Voto para Governador - Distribuição por Tipo de Pesquisa";
%tabela_pesquisa(amostra_total, tipo_pesquisa, cand_presidencia);

title "Intenção de Voto para Governador - Tabela Resumida";
%tabela_pesquisa_empilhada(cand_governador)

ods pdf close;


