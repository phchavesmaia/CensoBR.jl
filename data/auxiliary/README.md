# Auxiliary dictionary data

These text files are source extracts from IBGE documentation archives. They keep layout generation independent of legacy `.doc` readers and Java tooling.

## Religion

`V4090_religion_2000.txt` is the LibreOffice text conversion of the 2000 IBGE file `Arquivos Auxiliares/Estrutura de Religiao - V4090.doc`. Its 143 three-digit codes populate 2000 `V4090`.

`V4090_religion_2000_censobr.tsv` records 41 labels from the `religiao_V4090` sheet of the published `censobr` 2000 microdata dictionary workbook ([source release](https://github.com/ipea/censobr_prep_data/releases/download/censo_docs/2000_dictionary_microdata.xlsx)). The IBGE document has the same 143-code set, but uses broad “Outras” labels for these codes and combines code 112 differently. The generated 2000 `V4090` dictionary uses the more specific `censobr` labels for those 41 entries.

`V6121_religion_2010.txt` is the LibreOffice text conversion of the 2010 IBGE file `Anexos Auxiliares/Religião 2010.doc`. Its 201 distinct numeric codes populate 2010 `V6121`; these code/label pairs match the `religiao` sheet of the published [2010 `censobr` dictionary workbook](https://github.com/ipea/censobr_prep_data/releases/download/censo_docs/2010_dictionary_microdata.xlsx). The source includes two-digit hierarchy headings as well as response codes; codes are normalized numerically, with the three-digit leaf label retained when it duplicates a two-digit heading (code `0`).

## Metropolitan regions

`V1004_metropolitan_2000.txt` is the LibreOffice text conversion of `Documentacao/DocumentacaoFam.doc` in the 2000 archive. Its family-record table supplies codes 01–28 and a `Branco — Não aplicável` note for 2000 `family.V1004`; `Branco` is not a raw category code.

The 2000 household and person records use codes 00–28 from `V1004_metropolitan_2000_household_person.txt`, extracted from the V1004 section of `Documentacao/Documentação.doc`; that document labels code 00 “Sem Área de Ponderação”, matching the `censobr` workbook. The separate IBGE auxiliary file `Arquivos Auxiliares/V1004.txt` instead calls code 00 “Sem Área Metropolitana” and adds `Branco`; those entries are absent from the `censobr` household/person dictionary. The generator follows the main documentation list for these records. Family records use the distinct `DocumentacaoFam.doc` list, which contains codes 01–28 and `Branco`.

`V1004_metropolitan_2010.txt` contains the first V1004 code list from the 2010 IBGE file `Layout/Descrição das variáveis - Microdados da amostra do Censo Demográfico 2010.doc`. It supplies codes 00–42 for 2010 layouts. The document names V1004 in the other record sections without repeating its code/label list.

## Comparing with the 2000 `censobr` workbook

The workbook is not a one-to-one schema for the raw fixed-width SAS layouts: its DOMI, PESS, and FAMI sheets contain 58, 110, and 26 unique variable names, while the raw layouts contain 80, 183, and 26 fields. The extra 23 household and 73 person layout fields are `M` imputation indicators. PESS also lists `V0103`, `V0435`, and `V4752`, which are absent from the raw SAS layout; the raw layout instead contains `V4230`, `V4355`, and `V4572`. The workbook repeats `V0430`, and one row describes prior residence, which the raw SAS layout names `V4230`. These differences prevent direct field-for-field equality and make the raw SAS files the appropriate source for record positions.

The auxiliary 2000 `V1004` category maps match the workbook for household, person, and family after treating family `Branco` as a note; the 143-entry `V4090` map matches exactly after applying the 41 workbook labels. The SAS layouts also list `Branco` applicability notes that the workbook omits for some variables, and these notes are not category codes present in the raw fixed-width records.

The 2010 `V6461` occupation dictionary is read from `Anexos Auxiliares/Ocupação COD 2010.xls`. That workbook includes hierarchical headings in addition to four-character occupation codes. The generator pads short hierarchy codes to the field width while resolving collisions in favor of the shortest source code, and omits the two military headings `0110` and `0210`; the resulting 603 codes and labels match the published `censobr` dictionary.

## Refreshing the extracts

The `.doc` source files can be converted with LibreOffice. For example:

```sh
libreoffice --headless --convert-to 'txt:Text' --outdir /tmp \
  '/path/to/Religião 2010.doc'
```

Copy or extract the relevant source text into the correspondingly named file above, then regenerate layouts with the scripts in `dev/`. Layout generation fails if the expected distinct code set is incomplete. The 2000 religion override table is derived from the `religiao_V4090` sheet in the published `censobr` dictionary workbook; LibreOffice is needed only when refreshing the IBGE source extracts.
