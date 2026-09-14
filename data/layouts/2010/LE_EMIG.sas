/****************************  MACRO PARA LEITURA DO ARQUIVO DE EMIGRACAO INTERNACIONAL - CENSO 2010  ********************/

/*	PARÂMETRO DE ENTRADA

		ARQUIVO - caminho completo do arquivo texto de microdados do registro correspondente.

	SAÍDA

		Arquivo EMIG no formato SAS

	OBSERVAÇÃO

		Layout gerado a partir da planilha oficial de layout dos microdados da amostra do Censo 2010.
		Os comentários abaixo reproduzem o conteúdo da coluna NOME da planilha, inclusive códigos,
		valores em branco/ignorados e referências a arquivos auxiliares quando informados pela fonte.

**********************************************************************************************************************/

%MACRO LE_EMIG_2010(ARQUIVO);

FILENAME EMIG "&ARQUIVO." LRECL=74 ;

DATA EMIG;
INFILE EMIG MISSOVER;
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
@51	V1004 $2.	/*	"CÓDIGO DA  REGIÃO METROPOLITANA:
					A relação de códigos encontra-se no arquivo:"	*/
@53	V1006 $1.	/*	"SITUAÇÃO DO DOMICÍLIO:
					1- Urbana
					2- Rural"	*/
@54	V0303 $1.	/*	"SEXO DO EMIGRANTE:
					1- Masculino
					2- Feminino
					9- Ignorado
					Branco"	*/
@55	V0304 $4.	/*	"ANO DE NASCIMENTO DO EMIGRANTE:
					- Branco
					- 1869 a 2010
					- 9999 = ignorado"	*/
@59	V0305 $4.	/*	"ANO DA ÚLTIMA PARTIDA DO EMIGRANTE:
					- Branco
					- 1869 a 2010
					- 9999 = ignorado"	*/
@63	V3061 $7.	/*	"PAÍS DE RESIDÊNCIA EM 31 DE JULHO DE 2010 – CÓDIGO:
					- Branco
					- A relação de códigos encontra-se no arquivo: “Migração_Países_2010 V3061 V6224 V6256 V6266 V6366 V6606.xls”"	*/
@70	M0303 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0303:
					1- Sim
					2- Não"	*/
@71	M0304 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0304:
					1- Sim
					2- Não"	*/
@72	M0305 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0305:
					1- Sim
					2- Não"	*/
@73	M3061 $1.	/*	"MARCA DE IMPUTAÇÃO NA V3061:
					1- Sim
					2- Não"	*/
@74	V1005 $1.	/*	"Situação do setor
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
   %LE_EMIG_2010(C:\censo2010\arquivo_emig.txt)
*/
