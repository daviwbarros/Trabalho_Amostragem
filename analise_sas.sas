proc import datafile='/home/u64571875/Trabalho_Amostragem/amostras/amostras_xlsx/Pesquisa_Eleitoral_Amostra_1.xlsx'
dbms=xlsx out=amostra1_raw replace;
run;

proc import datafile='/home/u64571875/Trabalho_Amostragem/amostras/amostras_xlsx/Pesquisa_Eleitoral_Amostra_1.xlsx'
dbms=xlsx out=amostra2_raw replace;
run;

proc import datafile='/home/u64571875/Trabalho_Amostragem/amostras/amostras_xlsx/Pesquisa_Eleitoral_Amostra_3.xlsx'
dbms=xlsx out=amostra3_raw replace;
run;

proc import datafile='/home/u64571875/Trabalho_Amostragem/amostras/amostras_xlsx/Pesquisa_Eleitoral_Amostra_4.xlsx'
dbms=xlsx out=amostra4_raw replace;
run;

%macro padronizar_nome(dados_entrada, dados_saida);
	data &dados_saida (rename = (
		'Faixa de Renda Familiar'n   = faixa_renda
		'Faixa etária'n              = faixa_etária
		'Candidato a presidência'n   = cand_presidencia
		'Candidato à Governador DF'n = cand_governador
		));
	set &dados_entrada;	
	run;
%mend;

%padronizar_nome(amostra1_raw, amostra1)
%padronizar_nome(amostra2_raw, amostra2)
%padronizar_nome(amostra3_raw, amostra3)
%padronizar_nome(amostra4_raw, amostra4)

data amostra_estimulada;
	set amostra1 amostra2;
run;

data amostra_nao_estimulada;
	set amostra3 amostra4;
run;

data amostra_total;
	set amostra_estimulada amostra_nao_estimulada;
run;

proc freq data = amostra_total;
tables cand_presidencia;
run;











