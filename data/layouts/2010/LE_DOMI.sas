/****************************  MACRO PARA LEITURA DO ARQUIVO DE DOMICILIOS - CENSO 2010  ********************/

/*	PARÂMETRO DE ENTRADA

		ARQUIVO - caminho completo do arquivo texto de microdados do registro correspondente.

	SAÍDA

		Arquivo DOMI no formato SAS

	OBSERVAÇÃO

		Layout gerado a partir da planilha oficial de layout dos microdados da amostra do Censo 2010.
		Os comentários abaixo reproduzem o conteúdo da coluna NOME da planilha, inclusive códigos,
		valores em branco/ignorados e referências a arquivos auxiliares quando informados pela fonte.

**********************************************************************************************************************/

%MACRO LE_DOMI_2010(ARQUIVO);

FILENAME DOMI "&ARQUIVO." LRECL=172 ;

DATA DOMI;
INFILE DOMI MISSOVER;
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
@54	V4001 $2.	/*	"ESPÉCIE DE UNIDADE VISITADA:
					01- Domicílio particular permanente ocupado
					02- Domicílio particular permanente ocupado sem entrevista realizada
					05- Domicílio particular improvisado ocupado
					06- Domicílio coletivo com morador"	*/
@56	V4002 $2.	/*	"TIPO DE ESPÉCIE:
					11- Casa
					12- Casa de vila ou em condomínio
					13- Apartamento
					14- Habitação em: casa de cômodos, cortiço ou cabeça de porco
					15- Oca ou maloca
					51- Tenda ou barraca
					52- Dentro de estabelecimento
					53- Outro (vagão, trailer, gruta, etc)
					61- Asilo, orfanato e similares  com morador
					62- Hotel, pensão e similares com morador
					63- Alojamento de trabalhadores com morador
					64- Penitenciária, presídio ou casa de detenção com morador
					65- Outro com morador"	*/
@58	V0201 $1.	/*	"DOMICÍLIO, CONDIÇÃO DE OCUPAÇÃO:
					1- Próprio de algum morador - já pago
					2- Próprio de algum morador - ainda pagando
					3- Alugado
					4- Cedido por empregador
					5- Cedido de outra forma
					6- Outra condição
					Branco"	*/
@59	V2011 6.	/*	VALOR DO ALUGUEL (EM REAIS)	*/
@65	V2012 9.5	/*	ALUGUEL EM Nº DE SALÁRIOS MÍNIMOS	*/
@74	V0202 $1.	/*	"MATERIAL PREDOMINANTE, PAREDES EXTERNAS:
					1- Alvenaria com revestimento
					2- Alvenaria sem revestimento
					3- Madeira apropriada para construção (aparelhada)
					4- Taipa revestida
					5- Taipa não revestida
					6- Madeira aproveitada
					7- Palha
					8- Outro material
					9- Sem parede
					Branco"	*/
@75	V0203 2.	/*	"CÔMODOS, NÚMERO:
					- Branco
					- 1 a 30"	*/
@77	V6203 3.1	/*	DENSIDADE DE MORADOR/CÔMODO	*/
@80	V0204 2.	/*	"CÔMODOS COMO DORMITÓRIO, NÚMERO:
					- Branco
					- 1 a 15"	*/
@82	V6204 3.1	/*	DENSIDADE DE MORADOR / DORMITÓRIO	*/
@85	V0205 $1.	/*	"BANHEIROS DE USO EXCLUSIVO, NÚMERO:
					0- Zero banheiros
					1- Um banheiro
					2- Dois banheiros
					3- Três banheiros
					4- Quatro banheiros
					5- Cinco banheiros
					6- Seis banheiros
					7- Sete banheiros
					8- Oito banheiros
					9- Nove ou mais banheiros
					Branco"	*/
@86	V0206 $1.	/*	"SANITÁRIO OU BURACO PARA DEJEÇÕES, EXISTÊNCIA:
					1- Sim
					2- Não
					Branco"	*/
@87	V0207 $1.	/*	"ESGOTAMENTO SANITÁRIO, TIPO:
					1- Rede geral de esgoto ou pluvial
					2- Fossa séptica
					3- Fossa rudimentar
					4- Vala
					5- Rio, lago ou mar
					6- Outro
					Branco"	*/
@88	V0208 $2.	/*	"ABASTECIMENTO DE ÁGUA, FORMA:
					01- Rede geral de distribuição
					02- Poço ou nascente na propriedade
					03- Poço ou nascente fora da propriedade
					04- Carro-pipa
					05- Água da chuva armazenada em cisterna
					06- Água da chuva armazenada de outra forma
					07- Rios, açudes, lagos e igarapés
					08- Outra
					09- Poço ou nascente na aldeia
					10- Poço ou nascente fora da aldeia
					Branco"	*/
@90	V0209 $1.	/*	"ABASTECIMENTO DE ÁGUA, CANALIZAÇÃO:
					1- Sim, em pelo menos um cômodo
					2- Sim, só na propriedade ou terreno
					3- Não
					Branco"	*/
@91	V0210 $1.	/*	"LIXO, DESTINO:
					1- Coletado diretamente por serviço de limpeza
					2- Colocado em caçamba de serviço de limpeza
					3- Queimado (na propriedade)
					4- Enterrado (na propriedade)
					5- Jogado em terreno baldio ou logradouro
					6- Jogado em rio, lago ou mar
					7- Tem outro destino
					Branco"	*/
@92	V0211 $1.	/*	"ENERGIA ELÉTRICA, EXISTÊNCIA:
					1- Sim, de companhia distribuidora
					2- Sim, de outras fontes
					3- Não existe energia elétrica
					Branco"	*/
@93	V0212 $1.	/*	"EXISTÊNCIA DE MEDIDOR OU RELÓGIO, ENERGIA ELÉTRICA, COMPANHIA DISTRIBUIDORA:
					1- Sim, de uso exclusivo
					2- Sim, de uso comum
					3- Não tem medidor ou relógio
					Branco"	*/
@94	V0213 $1.	/*	"RÁDIO, EXISTÊNCIA:
					1- Sim
					2- Não
					Branco"	*/
@95	V0214 $1.	/*	"TELEVISÃO, EXISTÊNCIA:
					1- Sim
					2- Não
					Branco"	*/
@96	V0215 $1.	/*	"MÁQUINA DE LAVAR ROUPA, EXISTÊNCIA:
					1- Sim
					2- Não
					Branco"	*/
@97	V0216 $1.	/*	"GELADEIRA, EXISTÊNCIA:
					1- Sim
					2- Não
					Branco"	*/
@98	V0217 $1.	/*	"TELEFONE CELULAR, EXISTÊNCIA:
					1- Sim
					2- Não
					Branco"	*/
@99	V0218 $1.	/*	"TELEFONE FIXO, EXISTÊNCIA:
					1- Sim
					2- Não
					Branco"	*/
@100	V0219 $1.	/*	"MICROCOMPUTADOR, EXISTÊNCIA:
					1- Sim
					2- Não
					Branco"	*/
@101	V0220 $1.	/*	"MICROCOMPUTADOR COM ACESSO À INTERNET, EXISTÊNCIA:
					1- Sim
					2- Não
					Branco"	*/
@102	V0221 $1.	/*	"MOTOCICLETA PARA USO PARTICULAR, EXISTÊNCIA:
					1- Sim
					2- Não
					Branco"	*/
@103	V0222 $1.	/*	"AUTOMÓVEL PARA USO PARTICULAR, EXISTÊNCIA:
					1- Sim
					2- Não
					Branco"	*/
@104	V0301 $1.	/*	"ALGUMA PESSOA QUE MORAVA COM VOCÊ(S) ESTAVA MORANDO EM OUTRO PAÍS EM 31 DE JULHO DE 2010:
					1- Sim
					2- Não
					Branco"	*/
@105	V0401 2.	/*	QUANTAS PESSOAS MORAVAM NESTE DOMICÍLIO EM 31 DE JULHO DE 2010	*/
@107	V0402 $1.	/*	"A RESPONSABILIDADE PELO DOMICÍLIO É DE:
					1- Apenas um morador
					2- Mais de um morador
					9- Ignorado
					Branco"	*/
@108	V0701 $1.	/*	"DE AGOSTO DE 2009 A JULHO DE 2010, FALECEU ALGUMA PESSOA QUE MORAVA COM VOCÊ(S) (INCLUSIVE CRIANÇAS RECÉM-NASCIDAS E IDOSOS):
					1- Sim
					2- Não
					Branco"	*/
@109	V6529 7.	/*	RENDIMENTO MENSAL DOMICILIAR EM JULHO DE 2010	*/
@116	V6530 10.5	/*	RENDIMENTO DOMICILIAR, SALÁRIOS MÍNIMOS, EM JULHO DE 2010	*/
@126	V6531 8.2	/*	RENDIMENTO DOMICILIAR PER CAPITA EM JULHO DE 2010	*/
@134	V6532 9.5	/*	RENDIMENTO DOMICILIAR PER CAPITA, EM Nº DE SALÁRIOS MÍNIMOS, EM JULHO DE 2010	*/
@143	V6600 $1.	/*	"Espécie da Unidade Doméstica
					1- Unipessoal
					2- Nuclear
					3- Estendida
					4- Composta
					Branco (Domicílio Coletivo)"	*/
@144	V6210 $1.	/*	"ADEQUAÇÃO DA MORADIA
					1- 	Adequada
					2- 	Semi-adequada
					3- 	Inadequada
					Branco"	*/
@145	M0201 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0201:
					1- Sim
					2- Não"	*/
@146	M2011 $1.	/*	"MARCA DE IMPUTAÇÃO NA V2011:
					1- Sim
					2- Não"	*/
@147	M0202 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0202:
					1- Sim
					2- Não"	*/
@148	M0203 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0203:
					1- Sim
					2- Não"	*/
@149	M0204 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0204:
					1- Sim
					2- Não"	*/
@150	M0205 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0205:
					1- Sim
					2- Não"	*/
@151	M0206 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0206:
					1- Sim
					2- Não"	*/
@152	M0207 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0207:
					1- Sim
					2- Não"	*/
@153	M0208 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0208:
					1- Sim
					2- Não"	*/
@154	M0209 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0209:
					1- Sim
					2- Não"	*/
@155	M0210 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0210:
					1- Sim
					2- Não"	*/
@156	M0211 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0211:
					1- Sim
					 2- Não"	*/
@157	M0212 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0212:
					1- Sim
					2- Não"	*/
@158	M0213 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0213:
					1- Sim
					2- Não"	*/
@159	M0214 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0214:
					1- Sim
					2- Não"	*/
@160	M0215 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0215:
					1- Sim
					2- Não"	*/
@161	M0216 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0216:
					1- Sim
					2- Não"	*/
@162	M0217 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0217:
					1- Sim
					2- Não"	*/
@163	M0218 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0218:
					1- Sim
					2- Não"	*/
@164	M0219 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0219:
					1- Sim
					2- Não"	*/
@165	M0220 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0220:
					1- Sim
					 2- Não"	*/
@166	M0221 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0221:
					1- Sim
					2- Não"	*/
@167	M0222 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0222:
					1- Sim
					2- Não"	*/
@168	M0301 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0301:
					1- Sim
					2- Não"	*/
@169	M0401 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0401:
					1- Sim
					2- Não"	*/
@170	M0402 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0402:
					1- Sim
					2- Não"	*/
@171	M0701 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0701:
					1- Sim
					2- Não"	*/
@172	V1005 $1.	/*	"Situação do setor
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
   %LE_DOMI_2010(C:\censo2010\arquivo_domi.txt)
*/
