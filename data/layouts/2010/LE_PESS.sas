/****************************  MACRO PARA LEITURA DO ARQUIVO DE PESSOAS - CENSO 2010  ********************/

/*	PARÂMETRO DE ENTRADA

		ARQUIVO - caminho completo do arquivo texto de microdados do registro correspondente.

	SAÍDA

		Arquivo PESS no formato SAS

	OBSERVAÇÃO

		Layout gerado a partir da planilha oficial de layout dos microdados da amostra do Censo 2010.
		Os comentários abaixo reproduzem o conteúdo da coluna NOME da planilha, inclusive códigos,
		valores em branco/ignorados e referências a arquivos auxiliares quando informados pela fonte.

**********************************************************************************************************************/

%MACRO LE_PESS_2010(ARQUIVO);

FILENAME PESS "&ARQUIVO." LRECL=540 ;

DATA PESS;
INFILE PESS MISSOVER;
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
@54	V0502 $2.	/*	"RELAÇÃO DE PARENTESCO OU DE CONVIVÊNCIA COM A PESSOA RESPONSÁVEL PELO DOMICÍLIO:
					01- Pessoa responsável pelo domicílio
					02- Cônjuge ou companheiro(a) de sexo diferente
					03- Cônjuge ou companheiro(a) do mesmo sexo
					04- Filho(a) do responsável e do cônjuge
					05- Filho(a) somente do responsável
					06- Enteado(a)
					07- Genro ou nora
					08- Pai, mãe, padrasto ou madrasta
					09- Sogro(a)
					10- Neto(a)
					11- Bisneto(a)
					12- Irmão ou irmã
					13- Avô ou avó
					14- Outro parente
					15- Agregado(a)
					16- Convivente
					17- Pensionista
					18- Empregado(a) doméstico(a)
					19- Parente do(a) empregado(a)  doméstico(a)
					20- Individual em domicílio coletivo"	*/
@56	V0504 $2.	/*	ORDEM LÓGICA	*/
@58	V0601 $1.	/*	"SEXO:
					1- Masculino
					2- Feminino"	*/
@59	V6033 3.	/*	"VARIÁVEL AUXILIAR DA IDADE CALCULADA (ANOS E MESES):
					- 1 a 140
					-  900 a 911"	*/
@62	V6036 3.	/*	"VARIÁVEL AUXILIAR DA IDADE CALCULADA EM ANOS:
					- 0 a 140"	*/
@65	V6037 2.	/*	"VARIÁVEL AUXILIAR DA IDADE CALCULADA EM MESES (PARA AS PESSOAS MENORES DE 1 ANO):
					- 0 a 11"	*/
@67	V6040 $1.	/*	"FORMA DE DECLARAÇÃO DA IDADE:
					1- Data de nascimento
					2- Idade declarada"	*/
@68	V0606 $1.	/*	"COR OU RAÇA:
					1- Branca
					2- Preta
					3- Amarela
					4- Parda
					5- Indígena
					9- Ignorado"	*/
@69	V0613 $1.	/*	"REGISTRO DE NASCIMENTO:
					1- Do cartório
					2- Declaração de nascido vivo (DNV) do hospital ou da maternidade
					3- Registro administrativo de nascimento indígena (RANI)
					4- Não tem
					5- Não sabe
					9- Ignorado
					Branco"	*/
@70	V0614 $1.	/*	"DIFICULDADE PERMANENTE DE ENXERGAR:
					1- Sim, não consegue de modo algum
					2- Sim, grande dificuldade
					3- Sim, alguma dificuldade
					4- Não, nenhuma dificuldade
					9- Ignorado"	*/
@71	V0615 $1.	/*	"DIFICULDADE PERMANENTE DE OUVIR:
					1- Sim, não consegue de modo algum
					2- Sim, grande dificuldade
					3- Sim, alguma dificuldade
					4- Não, nenhuma dificuldade
					9- Ignorado"	*/
@72	V0616 $1.	/*	"DIFICULDADE PERMANENTE DE CAMINHAR OU SUBIR DEGRAUS:
					1- Sim, não consegue de modo algum
					2- Sim, grande dificuldade
					3- Sim, alguma dificuldade
					4- Não, nenhuma dificuldade
					9- Ignorado"	*/
@73	V0617 $1.	/*	"DEFICIÊNCIA MENTAL/INTELECTUAL PERMANENTE:
					1- Sim
					2- Não
					9- Ignorado"	*/
@74	V0618 $1.	/*	"NASCEU NESTE MUNICÍPIO:
					1- Sim e sempre morou
					2- Sim mas morou em outro município ou país estrangeiro
					3- Não"	*/
@75	V0619 $1.	/*	"NASCEU NESTA UNIDADE DA FEDERAÇÃO:
					1- Sim, e sempre morou
					2- Sim, mas morou em outra UF ou país estrangeiro
					3- Não
					Branco"	*/
@76	V0620 $1.	/*	"NACIONALIDADE:
					1- Brasileiro nato
					2- Naturalizado brasileiro
					3- Estrangeiro
					Branco"	*/
@77	V0621 $4.	/*	"ANO QUE FIXOU RESIDÊNCIA NO BRASIL:
					- Branco
					- 1869 a 2010"	*/
@81	V0622 $1.	/*	"UF OU PAÍS ESTRANGEIRO DE NASCIMENTO:
					1- UF
					2- País estrangeiro
					Branco"	*/
@82	V6222 $7.	/*	"UNIDADE DA FEDERAÇÃO DE NASCIMENTO – código:
					- A relação de códigos encontra-se no arquivo: “Migração_UFs_2010 V6222 V 6252 V6262 V6362 V6602.xls”"	*/
@89	V6224 $7.	/*	"QUAL É O PAÍS ESTRANGEIRO DE NASCIMENTO – código:
					- A relação de códigos encontra-se no arquivo: “Migração_Países_2010 V3061 V6224 V6256 V6266 V6366 V6606.xls”"	*/
@96	V0623 $3.	/*	"TEMPO DE MORADIA NA UF:
					- Branco
					- 0 a 140"	*/
@99	V0624 $3.	/*	"TEMPO DE MORADIA NO MUNICÍPIO:
					- Branco
					- 0 a 140"	*/
@102	V0625 $1.	/*	"UNIDADE DA FEDERAÇÃO E MUNICÍPIO OU PAÍS ESTRANGEIRO DE MORADIA ANTES DE MUDAR-SE PARA ESTE MUNICÍPIO:
					1- UF/Município
					2- País estrangeiro
					Branco"	*/
@103	V6252 $7.	/*	"UF DE RESIDÊNCIA ANTERIOR – código:
					- A relação de códigos encontra-se no arquivo: “Migração_UFs_2010 V6222 V6252 V6262 V6362 V6602.xls”"	*/
@110	V6254 $7.	/*	"MUNICÍPIO DE RESIDÊNCIA ANTERIOR – código:
					- A relação de códigos encontra-se no arquivo: “Migração_Município_2010 V6254 V6264 V6364 V6604.xls”"	*/
@117	V6256 $7.	/*	"PAÍS DE RESIDÊNCIA ANTERIOR – código:
					- A relação de códigos encontra-se no arquivo: “Migração_Países_2010 V3061 V6224 V6256 V6266 V6366 V6606.xls”"	*/
@124	V0626 $1.	/*	"RESIDÊNCIA EM 31 DE JULHO DE 2005:
					1- UF/Município
					2- País estrangeiro
					Branco"	*/
@125	V6262 $7.	/*	"UF DE RESIDÊNCIA EM 31 DE JULHO DE 2005 – código:
					- A relação de códigos encontra-se no arquivo: “Migração_UFs_2010 V6222 V6252 V6262 V6362 V6602.xls”"	*/
@132	V6264 $7.	/*	"MUNICÍPIO DE RESIDÊNCIA EM 31 DE JULHO DE 2005 – código:
					- A relação de códigos encontra-se no arquivo: “Migração_Município_2010 V6254 V6264 V6364 V6604.xls”"	*/
@139	V6266 $7.	/*	"PAÍS DE RESIDÊNCIA EM 31 DE JULHO DE 2005 – código:
					- A relação de códigos encontra-se no arquivo: “Migração_Países_2010 V3061 V6224 V6256 V6266 V6366 V6606.xls”"	*/
@146	V0627 $1.	/*	"SABE LER E ESCREVER:
					1- Sim
					2- Não
					Branco"	*/
@147	V0628 $1.	/*	"FREQUENTA ESCOLA OU CRECHE:
					1- Sim, pública
					2- Sim, particular
					3- Não, já frequentou
					4- Não, nunca frequentou"	*/
@148	V0629 $2.	/*	"CURSO QUE FREQUENTA:
					01- Creche
					02- Pré-escolar (maternal e jardim da infância)
					03- Classe de alfabetização - CA
					04- Alfabetização de jovens e adultos
					05- Regular do ensino fundamental
					06- Educação de jovens e adultos - EJA - ou supletivo do ensino fundamental
					07- Regular do ensino médio
					08- Educação de jovens e adultos - EJA - ou supletivo do ensino médio
					09- Superior de graduação
					10- Especialização de nível superior ( mínimo de 360 horas )
					11- Mestrado
					12- Doutorado
					Branco"	*/
@150	V0630 $2.	/*	"SÉRIE / ANO QUE FREQUENTA:
					01- Primeiro ano
					02- Primeira série / Segundo ano
					03- Segunda série / Terceiro ano
					04- Terceira série / Quarto ano
					05- Quarta série / Quinto ano
					06- Quinta série / Sexto ano
					07- Sexta série / Sétimo ano
					08- Sétima série / Oitavo ano
					09- Oitava série / Nono ano
					10- Não seriado
					Branco"	*/
@152	V0631 $1.	/*	"SÉRIE QUE FREQUENTA:
					1- Primeira série
					2- Segunda série
					3- Terceira série
					4- Quarta série
					5- Não seriado
					Branco"	*/
@153	V0632 $1.	/*	"CONCLUSÃO DE OUTRO CURSO SUPERIOR DE GRADUAÇÃO:
					1- Sim
					2- Não
					Branco"	*/
@154	V0633 $2.	/*	"CURSO MAIS ELEVADO QUE FREQUENTOU:
					01- Creche, pré-escolar (maternal e jardim de infância), classe de alfabetização - CA
					02- Alfabetização de jovens e adultos
					03- Antigo primário (elementar)
					04- Antigo ginásio (médio 1º ciclo)
					05- Ensino fundamental ou 1º grau (da 1ª a 3ª série/ do 1º ao 4º ano)
					06- Ensino fundamental ou 1º grau (4ª série/ 5º ano)
					07- Ensino fundamental ou 1º grau (da 5ª a 8ª série/ 6º ao 9º ano)
					08- Supletivo do ensino fundamental ou do 1º grau
					09- Antigo científico, clássico, etc.....(médio 2º ciclo)
					10- Regular ou supletivo do ensino médio ou do 2º grau
					11- Superior de graduação
					12- Especialização de nível superior ( mínimo de 360 horas )
					13- Mestrado
					14- Doutorado
					Branco"	*/
@156	V0634 $1.	/*	"CONCLUSÃO DESTE CURSO:
					1- Sim
					2- Não
					Branco"	*/
@157	V0635 $1.	/*	"ESPÉCIE DO CURSO MAIS ELEVADO CONCLUÍDO:
					1- Superior de graduação
					2- Mestrado
					3- Doutorado
					Branco"	*/
@158	V6400 $1.	/*	"NÍVEL DE INSTRUÇÃO:
					1- Sem instrução e fundamental incompleto
					2- Fundamental completo e médio incompleto
					3- Médio completo e superior incompleto
					4- Superior completo
					5- Não determinado"	*/
@159	V6352 $3.	/*	"CURSO SUPERIOR DE GRADUAÇÃO – código:
					- A relação de códigos encontra-se no arquivo: “Cursos Superiores_Estrutura 2010 V6352.xls”"	*/
@162	V6354 $3.	/*	"CURSO DE MESTRADO – código:
					- A relação de códigos encontra-se no arquivo: “Cursos Mestrado_Estrutura 2010 V6354.xls”"	*/
@165	V6356 $3.	/*	"CURSO DE DOUTORADO – código:
					- A relação de códigos encontra-se no arquivo: “Cursos Doutorado_Estrutura 2010 V6356.xls”"	*/
@168	V0636 $1.	/*	"MUNICÍPIO E UNIDADE DA FEDERAÇÃO OU PAÍS ESTRANGEIRO QUE FREQUENTAVA ESCOLA (OU CRECHE):
					1- Neste município
					2- Em outro município
					3- Em país estrangeiro
					Branco"	*/
@169	V6362 $7.	/*	"UF QUE FREQUENTAVA ESCOLA (OU CRECHE) – código:
					- A relação de códigos encontra-se no arquivo: “Migração_UFs_2010 V6222 V6252 V6262 V6362 V6602.xls”"	*/
@176	V6364 $7.	/*	"MUNICÍPIO QUE FREQUENTAVA ESCOLA (OU CRECHE) – código:
					- A relação de códigos encontra-se no arquivo: “Migração_Municípios_2010 V6254 V6264 V6364 V6604.xls”"	*/
@183	V6366 $7.	/*	"PAÍS ESTRANGEIRO QUE FREQUENTAVA ESCOLA (OU CRECHE) – código:
					- A relação de códigos encontra-se no arquivo: “Migração_Países_2010 V3061 V6224 V6256 V6266 V6366 V6606.xls”"	*/
@190	V0637 $1.	/*	"VIVE EM COMPANHIA DE CÔNJUGE OU COMPANHEIRO(A):
					1- Sim
					2- Não, mas viveu
					3- Não, nunca viveu
					Branco"	*/
@191	V0638 $2.	/*	"NÚMERO DE ORDEM DO CÔNJUGE OU COMPANHEIRO(A):
					- Branco
					- 1 a 98
					- 99 = ignorado"	*/
@193	V0639 $1.	/*	"NATUREZA DA UNIÃO:
					1- Casamento civil e religioso
					2- Só casamento civil
					3- Só casamento religioso
					4- União consensual
					Branco"	*/
@194	V0640 $1.	/*	"ESTADO CIVIL:
					1- Casado(a)
					2- Desquitado(a) ou separado(a) judicialmente
					3- Divorciado(a)
					4- Viúvo(a)
					5- Solteiro(a)
					Branco"	*/
@195	V0641 $1.	/*	"NA SEMANA DE 25 A 31/07/10, DURANTE PELO MENOS 1 HORA, TRABALHOU GANHANDO EM DINHEIRO, PRODUTOS, MERCADORIAS OU BENEFÍCIOS:
					1- Sim
					2- Não
					Branco"	*/
@196	V0642 $1.	/*	"NA SEMANA DE 25 A 31/07/10, TINHA TRABALHO REMUNERADO DO QUAL ESTAVA TEMPORARIAMENTE AFASTADO(A):
					1- Sim
					2- Não
					Branco"	*/
@197	V0643 $1.	/*	"NA SEMANA DE 25 A 31/07/10, DURANTE PELO MENOS 1 HORA, AJUDOU SEM QUALQUER PAGAMENTO NO TRABALHO REMUNERADO DE MORADOR DO DOMICÍLIO:
					1- Sim
					2- Não
					Branco"	*/
@198	V0644 $1.	/*	"NA SEMANA DE 25 A 31/07/10, DURANTE PELO MENOS 1 HORA, TRABALHOU NA PLANTAÇÃO, CRIAÇÃO DE ANIMAIS OU PESCA, SOMENTE PARA
					ALIMENTAÇÃO DOS MORADORES DO DOMICÍLIO (INCLUSIVE CAÇA E EXTRAÇÃO VEGETAL):
					1- Sim
					2- Não
					Branco"	*/
@199	V0645 $1.	/*	"QUANTOS TRABALHOS TINHA:
					1- Um
					2- Dois ou mais
					Branco"	*/
@200	V6461 $4.	/*	"OCUPAÇÃO – código:
					(pode ter valor branco)
					- A relação de códigos encontra-se no arquivo: “Ocupação COD_Estrutura 2010.xls”"	*/
@204	V6471 $5.	/*	"ATIVIDADE – código
					(pode ter valor branco)
					- A relação de códigos encontra-se no arquivo: “CNAEDOM2.0_Estrutura 2010.xls”"	*/
@209	V0648 $1.	/*	"NESSE TRABALHO ERA:
					1- Empregado com carteira de trabalho assinada
					2- Militar do exército, marinha, aeronáutica, policia militar ou corpo de bombeiros
					3- Empregado pelo regime jurídico dos funcionários públicos
					4- Empregado sem carteira de trabalho assinada
					5- Conta própria
					6- Empregador
					7- Não remunerado
					Branco"	*/
@210	V0649 $1.	/*	"QUANTAS PESSOAS EMPREGAVA NESSE TRABALHO:
					1- 1 a 5 pessoas
					2- 6 ou mais pessoas
					Branco"	*/
@211	V0650 $1.	/*	"ERA CONTRIBUINTE DE INSTITUTO DE PREVIDÊNCIA OFICIAL EM ALGUM TRABALHO QUE TINHA NA SEMANA DE 25 A 31 DE JULHO DE 2010:
					1- Sim, no trabalho principal
					2- Sim, em outro trabalho
					3- Não
					Branco"	*/
@212	V0651 $1.	/*	"NO TRABALHO PRINCIPAL, QUAL ERA O RENDIMENTO BRUTO (OU A RETIRADA) MENSAL QUE GANHAVA HABITUALMENTE EM JULHO DE 2010:
					0- Não tem
					1- Em dinheiro, produtos ou mercadorias
					2- Somente em benefícios
					Branco"	*/
@213	V6511 6.	/*	VALOR DO RENDIMENTO BRUTO (OU A RETIRADA) MENSAL NO TRABALHO PRINCIPAL: (pode ter valor branco)	*/
@219	V6513 6.	/*	RENDIMENTO NO TRABALHO PRINCIPAL: (pode ter valor branco)	*/
@225	V6514 6.2	/*	RENDIMENTO NO TRABALHO PRINCIPAL EM Nº DE SALÁRIOS MÍNIMOS:  (pode ter valor branco)	*/
@231	V0652 $1.	/*	"NOS DEMAIS TRABALHOS, QUAL ERA O RENDIMENTO BRUTO (OU A RETIRADA) MENSAL QUE GANHAVA HABITUALMENTE EM JULHO DE 2010:
					0- Não tem
					1- Em dinheiro, produtos ou mercadorias
					2- Somente em benefícios
					Branco"	*/
@232	V6521 6.	/*	VALOR DO RENDIMENTO BRUTO (OU A RETIRADA) MENSAL NOS DEMAIS TRABALHOS (EM REAIS)	*/
@238	V6524 9.5	/*	RENDIMENTO BRUTO NOS DEMAIS TRABALHOS EM Nº DE SALÁRIOS MÍNIMOS	*/
@247	V6525 7.	/*	RENDIMENTO EM TODOS OS TRABALHOS	*/
@254	V6526 9.5	/*	RENDIMENTO EM TODOS OS TRABALHOS EM Nº DE SALÁRIOS MÍNIMOS	*/
@263	V6527 7.	/*	RENDIMENTO MENSAL TOTAL EM JULHO DE 2010	*/
@270	V6528 9.5	/*	RENDIMENTO MENSAL TOTAL EM Nº DE SALÁRIOS MÍNIMOS EM JULHO DE 2010	*/
@279	V6529 7.	/*	RENDIMENTO DOMICILIAR (DOMICÍLIO PARTICULAR) EM JULHO DE 2010	*/
@286	V6530 10.5	/*	RENDIMENTO DOMICILIAR (DOMICÍLIO PARTICULAR) EM Nº DE SALÁRIOS MÍNIMOS EM JULHO DE 2010	*/
@296	V6531 8.2	/*	RENDIMENTO DOMICILIAR (DOMICÍLIO PARTICULAR) PER CAPITA EM JULHO DE 2010	*/
@304	V6532 9.5	/*	RENDIMENTO DOMICILIAR (DOMICÍLIO PARTICULAR) PER CAPITA EM Nº DE SALÁRIOS MÍNIMOS EM JULHO DE 2010	*/
@313	V0653 3.	/*	"NO TRABALHO PRINCIPAL, QUANTAS HORAS TRABALHAVA HABITUALMENTE POR SEMANA:
					- Branco
					- 1 a 140"	*/
@316	V0654 $1.	/*	"NO PERÍODO DE 02 A 31 DE JULHO DE 2010, TOMOU ALGUMA PROVIDÊNCIA, DE FATO, PARA CONSEGUIR  TRABALHO?
					1- Sim
					2- Não
					Branco"	*/
@317	V0655 $1.	/*	"SE TIVESSE CONSEGUIDO TRABALHO, ESTARIA DISPONÍVEL PARA ASSUMI-LO NA SEMANA DE 25 A 31 DE JULHO DE 2010?
					1- Sim
					2- Não
					Branco"	*/
@318	V0656 $1.	/*	"EM JULHO DE 2010, TINHA RENDIMENTO MENSAL HABITUAL DE APOSENTADORIA OU PENSÃO DE INSTITUTO DE PREVIDÊNCIA OFICIAL (FEDERAL, ESTADUAL OU MUNICIPAL)?
					1- Sim
					0- Não
					9- Ignorado
					Branco"	*/
@319	V0657 $1.	/*	"EM JULHO DE 2010, TINHA RENDIMENTO MENSAL HABITUAL DE PROGRAMA SOCIAL BOLSA-FAMÍLIA OU PROGRAMA DE ERRADICAÇÃO DO TRABALHO INFANTIL (PETI):
					1- Sim
					0- Não
					9- Ignorado
					Branco"	*/
@320	V0658 $1.	/*	"EM JULHO 2010, TINHA RENDIMENTO MENSAL HABITUAL DE OUTROS PROGRAMAS SOCIAIS OU DE TRANSFERÊNCIAS:
					1- Sim
					0- Não
					9- Ignorado
					Branco"	*/
@321	V0659 $1.	/*	"EM JULHO DE 2010, TINHA RENDIMENTO MENSAL HABITUAL DE OUTRAS FONTES (JUROS DE POUPANÇA, APLICAÇÕES FINANCEIRAS, ALUGUEL, PENSÃO, APOSENTADORIA DE PREVIDÊNCIA PRIVADA, ETC)?
					1- Sim
					0- Não
					9- Ignorado
					Branco"	*/
@322	V6591 6.	/*	EM JULHO DE 2010 QUAL FOI O VALOR TOTAL DESTE(S) RENDIMENTO(S):	*/
@328	V0660 $1.	/*	"EM QUE MUNICÍPIO E UNIDADE DA FEDERAÇÃO OU PAÍS ESTRANGEIRO TRABALHA:
					1- No próprio domicílio
					2- Apenas neste município, mas não no próprio domicílio
					3- Em outro município
					4- Em país estrangeiro
					5- Em mais de um município ou país
					Branco"	*/
@329	V6602 $7.	/*	"EM QUE UNIDADE DA FEDERAÇÃO TRABALHAVA - código:
					- A relação de códigos encontra-se no arquivo: “Migração_UFs_2010 V6222 V6252 V6262 V6362 V6602.xls”"	*/
@336	V6604 $7.	/*	"EM QUE MUNICÍPIO TRABALHAVA - código:
					- A relação de códigos encontra-se no arquivo: “Migração_Municípios_2010 V6254 V6264 V6364 V6604.xls”"	*/
@343	V6606 $7.	/*	"EM QUE PAÍS ESTRANGEIRO TRABALHAVA - código:
					- A relação de códigos encontra-se no arquivo: “Migração_Países_2010 V3061 V6224 V6256 V6266 V6366 V6606.xls”"	*/
@350	V0661 $1.	/*	"RETORNA DO TRABALHO PARA CASA DIARIAMENTE:
					1- Sim
					2- Não
					Branco"	*/
@351	V0662 $1.	/*	"QUAL É O TEMPO HABITUAL GASTO DE DESLOCAMENTO DE SUA CASA ATÉ O TRABALHO:
					1- Até 05 minutos
					2- De 06 minutos até meia hora
					3- Mais de meia hora até uma hora
					4- Mais de uma hora até duas horas
					5- Mais de duas horas
					Branco"	*/
@352	V0663 $1.	/*	"QUANTOS FILHOS E FILHAS NASCIDOS VIVOS TEVE ATÉ 31 DE JULHO DE 2010:
					1- Teve filhos nascidos vivos
					2- Não teve nenhum filho nascido vivo
					Branco"	*/
@353	V6631 2.	/*	"QUANTOS FILHOS NASCIDOS VIVOS TEVE ATÉ 31 DE JULHO DE 2010:
					(branco; 0 a 31)"	*/
@355	V6632 2.	/*	"QUANTAS FILHAS NASCIDAS VIVAS TEVE ATÉ 31 DE JULHO DE 2010:
					(branco; 0 a 31)"	*/
@357	V6633 2.	/*	"TOTAL DE FILHOS NASCIDOS VIVOS QUE TEVE ATÉ 31 DE JULHO DE 2010:
					(branco; 0 a 31)"	*/
@359	V0664 $1.	/*	"DOS FILHOS E FILHAS QUE TEVE, QUANTOS ESTAVAM VIVOS EM 31 DE JULHO DE 2010:
					1- Filhos vivos
					2- Não sabe
					Branco"	*/
@360	V6641 2.	/*	"DOS FILHOS QUE TEVE, QUANTOS ESTAVAM VIVOS EM 31 DE JULHO DE 2010:
					- Branco
					- 0 a 31"	*/
@362	V6642 2.	/*	"DAS FILHAS QUE TEVE, QUANTAS ESTAVAM VIVAS EM 31 DE JULHO DE 2010:
					- Branco
					- 0 a 31"	*/
@364	V6643 2.	/*	"TOTAL DE FILHOS QUE TEVE, QUANTOS ESTAVAM VIVOS EM 31 DE JULHO DE 2010:
					- Branco
					- 0 a 31"	*/
@366	V0665 $1.	/*	"QUAL É O SEXO DO ÚLTIMO FILHO TIDO NASCIDO VIVO ATÉ 31 DE JULHO DE 2010:
					1- Masculino
					2- Feminino
					Branco"	*/
@367	V6660 3.	/*	"IDADE DO ÚLTIMO FILHO TIDO NASCIDO VIVO ATÉ 31 DE JULHO DE 2010:
					- Branco
					- 0 a 130"	*/
@370	V6664 $1.	/*	"EXISTÊNCIA DE FILHO TIDO NASCIDO VIVO NO PERÍODO DE REFERÊNCIA DE 12 MESES ANTERIORES A 31/07/2010:
					1- Sim
					0- Não
					Branco"	*/
@371	V0667 $1.	/*	"ESTE(A) FILHO(A) ESTAVA VIVO(A) EM 31 DE JULHO DE 2010:
					1- Sim
					2- Não
					9- Não sabe
					Branco"	*/
@372	V0668 $1.	/*	"QUAL FOI O MÊS E O ANO QUE ESTE(A) FILHO(A) FALECEU:
					1- Sabe o mês e ano ou somente o ano
					2- Não sabe
					Branco"	*/
@373	V6681 $2.	/*	"QUAL FOI O MÊS QUE ESTE(A) FILHO(A) FALECEU:
					- Branco
					- 1 a 12
					- 99 = ignorado"	*/
@375	V6682 $4.	/*	"QUAL FOI O ANO QUE ESTE(A) FILHO(A) FALECEU:
					- Branco
					-  1879 a 2010
					- 9999 = ignorado"	*/
@379	V0669 $1.	/*	"QUANTOS FILHOS E FILHAS NASCIDOS MORTOS TEVE ATÉ 31 DE JULHO DE 2010:
					1- Teve filho nascido morto
					2- Não teve filho nascido morto
					3- Não sabe
					Branco"	*/
@380	V6691 2.	/*	"QUANTOS FILHOS NASCIDOS MORTOS TEVE ATÉ 31 DE JULHO DE 2010
					- Branco
					- 0 a 31"	*/
@382	V6692 2.	/*	"QUANTOS FILHAS NASCIDAS MORTAS TEVE ATÉ 31 DE JULHO DE 2010
					- Branco
					- 0 a 31"	*/
@384	V6693 2.	/*	"QUANTOS FILHOS E FILHAS NASCIDOS MORTOS TEVE ATÉ 31 DE JULHO DE 2010
					- Branco
					- 0 a 31"	*/
@386	V6800 2.	/*	"TOTAL DE FILHOS TIDOS NASCIDOS VIVOS E NASCIDOS MORTOS:
					- Branco
					- 0 a 31"	*/
@388	V0670 $1.	/*	"ASSINALE QUEM PRESTOU AS INFORMAÇÕES DESTA PESSOA
					1- A própria pessoa
					2- Outro morador
					3- Não morador
					9- Ignorado"	*/
@389	V0671 $2.	/*	NÚMERO DE ORDEM DO INFORMANTE (OUTRO MORADOR)	*/
@391	V6900 $1.	/*	"CONDIÇÃO DE ATIVIDADE NA SEMANA DE REFERÊNCIA
					1- Economicamente ativas
					2- Não economicamente ativas
					Branco"	*/
@392	V6910 $1.	/*	"CONDIÇÃO DE OCUPAÇÃO NA SEMANA DE REFERÊNCIA
					1- Ocupadas
					2- Desocupadas
					Branco"	*/
@393	V6920 $1.	/*	"SITUAÇÃO DE OCUPAÇÃO NA SEMANA DE REFERÊNCIA
					1- Ocupadas
					2- Não ocupadas
					Branco"	*/
@394	V6930 $1.	/*	"POSIÇÃO NA OCUPAÇÃO E CATEGORIA DO EMPREGO NO TRABALHO PRINCIPAL
					1- Empregados com carteira de trabalho assinada
					2- Militares e funcionários públicos estatutários
					3- Empregados sem carteira de trabalho assinada
					4- Conta própria
					5- Empregadores
					6- Não remunerados
					7- Trabalhadores na produção para o próprio consumo
					Branco"	*/
@395	V6940 $1.	/*	"SUBGRUPO E CATEGORIA DO EMPREGO NO TRABALHO PRINCIPAL
					1- Trabalhadores domésticos com carteira de trabalho assinada
					2- Trabalhadores domésticos sem carteira de trabalho assinada
					3- Demais empregados com carteira de trabalho assinada
					4- Militares e funcionários públicos estatutários
					5- Demais empregados sem carteira de trabalho assinada
					Branco"	*/
@396	V6121 $3.	/*	Qual é a sua religião ou culto? -  código   (banco de códigos; 999 = ignorado)	*/
@399	V0604 $1.	/*	"TEM MÃE VIVA?
					1- 	Sim e mora neste domicílio
					2- 	Sim e mora em outro domicílio
					3- 	Não
					4- 	Não sabe
					9- 	Ignorado"	*/
@400	V0605 $2.	/*	Número de ordem da mãe da pessoa   (branco; 1 a 98; 99 = ignorado)	*/
@402	V5020 $2.	/*	"NÚMERO DA FAMÍLIA
					01 - Famílias únicas ou conviventes principais: Corresponde à família dos responsáveis pela unidade doméstica.
					02 – Família convivente – segunda
					03 – Família convivente – terceira
					04 – Família convivente – quarta
					05 – Família convivente – quinta
					06 – Família convivente – sexta
					07 – Família convivente – sétima
					08 – Família convivente – oitava
					09 – Família convivente – nona
					Branco – para pessoas residentes em domicílios coletivos e/ou em unidades domésticas localizadas em terras indígenas, onde não se fez a identificação de famílias."	*/
@404	V5060 2.	/*	Número de Pessoas na Família	*/
@406	V5070 8.2	/*	Rendimento familiar per capita em julho de 2010 (0 a 999999,99)	*/
@414	V5080 9.5	/*	Rendimento familiar per capita em nº de salários mínimos em julho de 2010 (0 a 9999,99999)	*/
@423	V6462 $4.	/*	Qual era a ocupação que exercia no trabalho que tinha? - código 2000  (branco; banco de códigos de 2000)	*/
@427	V6472 $5.	/*	Qual era a atividade principal do empreendimento em que tinha esse trabalho? - código 2000  (branco; banco de códigos de 2000)	*/
@432	V5110 $1.	/*	"CONDIÇÃO DE CONTRIBUIÇÃO PARA INSTITUTO DE PREVIDÊNCIA OFICIAL NO TRABALHO PRINCIPAL
					Contribuintes
					Não contribuintes
					Branco"	*/
@433	V5120 $1.	/*	"CONDIÇÃO DE CONTRIBUIÇÃO PARA INSTITUTO DE PREVIDÊNCIA OFICIAL EM QUALQUER TRABALHO
					Contribuintes
					Não contribuintes
					Branco"	*/
@434	V5030 $1.	/*	"TIPO DE UNIDADE DOMÉSTICA
					1 - Unipessoal
					2 - Duas pessoas ou mais sem parentesco
					3 - Duas pessoas ou mais com parentesco
					Branco"	*/
@435	V5040 $1.	/*	"INDICADORA DE FAMÍLIA
					1 - Arranjo familiar
					0 - Arranjo não familiar
					Branco"	*/
@436	V5090 $1.	/*	"TIPO DE COMPOSIÇÃO FAMILIAR DAS FAMÍLIAS ÚNICAS E CONVIVENTES PRINCIPAIS
					1 - Casal sem filho(s)
					2 - Casal sem filho(s) e com parente(s)
					3 - Casal com filho(s)
					4 - Casal com filho(s) e com parente(s)
					5 - Mulher sem cônjuge com filho(s)
					6 - Mulher sem cônjuge com filho(s) e com parente(s)
					7 - Homem sem cônjuge com filho(s)
					8 - Homem sem cônjuge com filho(s) e com parente(s)
					9 - Outro
					Branco"	*/
@437	V5100 $1.	/*	"TIPO DE COMPOSIÇÃO FAMILIAR DAS FAMÍLIAS CONVIVENTES SECUNDÁRIAS
					1 - Casal sem filho(s)
					2 - Casal com filho(s)
					3 - Mulher sem cônjuge com filho(s)
					Branco"	*/
@438	V5130 $2.	/*	ORDEM LÓGICA NA FAMÍLIA	*/
@440	M0502 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0502
					1- Sim
					2- Não"	*/
@441	M0601 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0601
					1- Sim
					2- Não"	*/
@442	M6033 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6033
					1- Sim
					2- Não"	*/
@443	M0606 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0606
					1- Sim
					2- Não"	*/
@444	M0613 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0613
					1- Sim
					2- Não"	*/
@445	M0614 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0614
					1- Sim
					2- Não"	*/
@446	M0615 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0615
					1- Sim
					2- Não"	*/
@447	M0616 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0616
					1- Sim
					2- Não"	*/
@448	M0617 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0617
					1- Sim
					2- Não"	*/
@449	M0618 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0618
					1- Sim
					2- Não"	*/
@450	M0619 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0619
					1- Sim
					2- Não"	*/
@451	M0620 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0620
					1- Sim
					2- Não"	*/
@452	M0621 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0621
					1- Sim
					2- Não"	*/
@453	M0622 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0622
					1- Sim
					2- Não"	*/
@454	M6222 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6222
					1- Sim
					2- Não"	*/
@455	M6224 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6224
					1- Sim
					 2- Não"	*/
@456	M0623 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0623
					1- Sim
					2- Não"	*/
@457	M0624 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0624
					1- Sim
					2- Não"	*/
@458	M0625 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0625
					1- Sim
					2- Não"	*/
@459	M6252 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6252
					1- Sim
					2- Não"	*/
@460	M6254 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6254
					1- Sim
					 2- Não"	*/
@461	M6256 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6256
					1- Sim
					2- Não"	*/
@462	M0626 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0626
					1- Sim
					2- Não"	*/
@463	M6262 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6262
					1- Sim
					2- Não"	*/
@464	M6264 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6264
					1- Sim
					2- Não"	*/
@465	M6266 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6266
					1- Sim
					2- Não"	*/
@466	M0627 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0627
					1- Sim
					2- Não"	*/
@467	M0628 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0628
					1- Sim
					2- Não"	*/
@468	M0629 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0629
					1- Sim
					2- Não"	*/
@469	M0630 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0630
					1- Sim
					2- Não"	*/
@470	M0631 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0631
					1- Sim
					2- Não"	*/
@471	M0632 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0632
					1- Sim
					2- Não"	*/
@472	M0633 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0633
					1- Sim
					2- Não"	*/
@473	M0634 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0634
					1- Sim
					2- Não"	*/
@474	M0635 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0635
					1- Sim
					2- Não"	*/
@475	M6352 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6352
					1- Sim
					2- Não"	*/
@476	M6354 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6354
					1- Sim
					2- Não"	*/
@477	M6356 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6356
					1- Sim
					2- Não"	*/
@478	M0636 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0636
					1- Sim
					2- Não"	*/
@479	M6362 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6362
					1- Sim
					2- Não"	*/
@480	M6364 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6364
					1- Sim
					2- Não"	*/
@481	M6366 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6366
					1- Sim
					2- Não"	*/
@482	M0637 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0637
					1- Sim
					2- Não"	*/
@483	M0638 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0638
					1- Sim
					2- Não"	*/
@484	M0639 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0639
					1- Sim
					2- Não"	*/
@485	M0640 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0640
					1- Sim
					2- Não"	*/
@486	M0641 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0641
					1- Sim
					2- Não"	*/
@487	M0642 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0642
					1- Sim
					2- Não"	*/
@488	M0643 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0643
					1- Sim
					2- Não"	*/
@489	M0644 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0644
					1- Sim
					2- Não"	*/
@490	M0645 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0645
					1- Sim
					2- Não"	*/
@491	M6461 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6461
					1- Sim
					2- Não"	*/
@492	M6471 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6471
					1- Sim
					2- Não"	*/
@493	M0648 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0648
					1- Sim
					2- Não"	*/
@494	M0649 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0649
					1- Sim
					2- Não"	*/
@495	M0650 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0650
					1- Sim
					2- Não"	*/
@496	M0651 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0651
					1- Sim
					2- Não"	*/
@497	M6511 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6511
					1- Sim
					2- Não"	*/
@498	M0652 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0652
					1- Sim
					2- Não"	*/
@499	M6521 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6521
					1- Sim
					2- Não"	*/
@500	M0653 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0653
					1- Sim
					2- Não"	*/
@501	M0654 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0654
					1- Sim
					2- Não"	*/
@502	M0655 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0655
					1- Sim
					2- Não"	*/
@503	M0656 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0656
					1- Sim
					2- Não"	*/
@504	M0657 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0657
					1- Sim
					2- Não"	*/
@505	M0658 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0658
					1- Sim
					2- Não"	*/
@506	M0659 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0659
					1- Sim
					2- Não"	*/
@507	M6591 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6591
					1- Sim
					2- Não"	*/
@508	M0660 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0660
					1- Sim
					2- Não"	*/
@509	M6602 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6602
					1- Sim
					2- Não"	*/
@510	M6604 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6604
					1- Sim
					2- Não"	*/
@511	M6606 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6606
					1- Sim
					2- Não"	*/
@512	M0661 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0661
					1- Sim
					 2- Não"	*/
@513	M0662 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0662
					1- Sim
					2- Não"	*/
@514	M0663 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0663
					1- Sim
					2- Não"	*/
@515	M6631 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6631
					1- Sim
					2- Não"	*/
@516	M6632 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6632
					1- Sim
					2- Não"	*/
@517	M6633 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6633
					1- Sim
					2- Não"	*/
@518	M0664 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0664
					1- Sim
					2- Não"	*/
@519	M6641 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6641
					1- Sim
					2- Não"	*/
@520	M6642 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6642
					1- Sim
					2- Não"	*/
@521	M6643 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6643
					1- Sim
					2- Não"	*/
@522	M0665 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0665
					1- Sim
					2- Não"	*/
@523	M6660 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6660
					1- Sim
					2- Não"	*/
@524	M0667 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0667
					1- Sim
					2- Não"	*/
@525	M0668 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0668
					1- Sim
					2- Não"	*/
@526	M6681 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6681
					1- Sim
					2- Não"	*/
@527	M6682 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6682
					1- Sim
					2- Não"	*/
@528	M0669 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0669
					1- Sim
					2- Não"	*/
@529	M6691 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6691
					1- Sim
					2- Não"	*/
@530	M6692 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6692
					1- Sim
					2- Não"	*/
@531	M6693 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6693
					1- Sim
					2- Não"	*/
@532	M0670 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0670
					1- Sim
					2- Não"	*/
@533	M0671 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0671
					1- Sim
					2- Não"	*/
@534	M6800 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6800
					1- Sim
					2- Não"	*/
@535	M6121 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6121
					1- Sim
					2- Não"	*/
@536	M0604 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0604
					1- Sim
					2- Não"	*/
@537	M0605 $1.	/*	"MARCA DE IMPUTAÇÃO NA V0605
					1- Sim
					2- Não"	*/
@538	M6462 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6462
					1- Sim
					2- Não"	*/
@539	M6472 $1.	/*	"MARCA DE IMPUTAÇÃO NA V6472
					1- Sim
					2- Não"	*/
@540	V1005 $1.	/*	"Situação do setor
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
   %LE_PESS_2010(C:\censo2010\arquivo_pess.txt)
*/
