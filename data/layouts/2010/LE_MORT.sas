/****************************  MACRO PARA LEITURA DO ARQUIVO DE MORTALIDADE - CENSO 2010  ********************/

/*	PARÂMETRO DE ENTRADA

		ARQUIVO - caminho completo do arquivo texto de microdados do registro correspondente.

	SAÍDA

		Arquivo MORT no formato SAS

	OBSERVAÇÃO

		Layout gerado a partir da planilha oficial de layout dos microdados da amostra do Censo 2010.
		Os comentários abaixo reproduzem o conteúdo da coluna NOME da planilha, inclusive códigos,
		valores em branco/ignorados e referências a arquivos auxiliares quando informados pela fonte.

**********************************************************************************************************************/

%MACRO LE_MORT_2010(ARQUIVO);

FILENAME MORT "&ARQUIVO." LRECL=66 ;

DATA MORT;
INFILE MORT MISSOVER;
INPUT	
@1	V0001 $2.	/*	"UNIDADE DA FEDERAÇÃO:
					11- Rondônia
					12- Acre
					13- Amazonas
					14- Roraima
					15- Pará
					16- Amapá
					17- Tocantins
					21- Maranhão
					22- Piauí
					23- Ceará
					24- Rio Grande do Norte
					25- Paraíba
					26- Pernambuco
					27- Alagoas
					28- Sergipe
					29- Bahia
					31- Minas Gerais
					32- Espírito Santo
					33- Rio de Janeiro
					35- São Paulo
					41- Paraná
					42- Santa Catarina
					43- Rio Grande do Sul
					50- Mato Grosso do Sul
					51- Mato Grosso
					52- Goiás
					53- Distrito Federal"	*/
@3	V0002 $5.	/*	CÓDIGO DO MUNICÍPIO	*/
@8	V0011 $13.	/*	ÁREA DE PONDERAÇÃO	*/
@21	V0300 8.	/*	CONTROLE	*/
@29	V0010 16.13	/*	PESO AMOSTRAL	*/
@45	V1001 $1.	/*	"REGIÃO GEOGRÁFICA:
					1- Região norte (uf=11 a 17)
					2- Região nordeste (uf=21 a 29)
					3- Região sudeste (uf=31 a 33 e 35)
					4- Região sul (uf=41 a 43)
					5- Região centro-oeste (uf=50 a 53)"	*/
@46	V1002 $2.	/*	"CÓDIGO DA MESORREGIÃO:
					A relação de códigos encontra-se no arquivo:"	*/
@48	V1003 $3.	/*	"CÓDIGO DA MICRORREGIÃO:
					A relação de códigos encontra-se no arquivo:"	*/
@51	V1004 $2.	/*	"CÓDIGO DA REGIÃO METROPOLITANA:
					A relação de códigos encontra-se no arquivo:"	*/
@53	V1006 $1.	/*	"SITUAÇÃO DO DOMICÍLIO:
					1- Urbana
					2- Rural"	*/
@54	V0703 $2.	/*	"MÊS E ANO DE FALECIMENTO:
					01- Agosto de 2009
					02- Setembro de 2009
					03- Outubro de 2009
					04- Novembro de 2009
					05- Dezembro de 2009
					06- Janeiro de 2010
					07- Fevereiro de 2010
					08- Março de 2010
					09- Abril de 2010
					10- Maio de 2010
					11- Junho de 2010
					12- Julho de 2010
					99- Ignorado
					Branco"	*/
@56	V0704 $1.	/*	"SEXO DA PESSOA FALECIDA:
					1- Masculino
					2- Feminino
					9- Ignorado
					Branco"	*/
@57	V7051 3.	/*	"IDADE AO FALECER, EM ANOS:
					- Branco
					- 1 a 140
					- 999 = ignorado"	*/
@60	V7052 2.	/*	"IDADE AO FALECER, EM MESES:
					- Branco
					- 0 a 11
					- 99 = ignorado"	*/
@62	M0703 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0703:
					1- Sim
					2- Não"	*/
@63	M0704 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0704:
					1- Sim
					2- Não"	*/
@64	M7051 $1.	/*	"MARCA DE IMPUTAÇÃO NA V7051:
					1- Sim
					2- Não"	*/
@65	M7052 $1.	/*	"MARCA DE IMPUTAÇÃO NA V7052:
					1- Sim
					2- Não"	*/
@66	V1005 $1.	/*	"Situação do setor
					1 - Área urbanizada
					2 - Área não urbanizada
					3 - Área urbanizada isolada
					4 - Área rural de extensão urbana
					5 - Aglomerado rural (povoado)
					6 - Aglomerado rural (núcleo)
					7 - Aglomerado rural (outros)
					8 - Área rural exclusive aglomerado rural
					
					1- Masculino
					2- Feminino"	*/
;
RUN;

%MEND;

/* Exemplo de chamada:
   %LE_MORT_2010(C:\censo2010\arquivo_mort.txt)
*/
