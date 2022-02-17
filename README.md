# Global Fishing Watch Marine Manager: Tristan da Cunha

Global Fishing Watch Marine Manager is a dynamic technology portal designed to make actionable information on human activity and environmental data available to managers of marine protected areas. In this report we aimed to demonstrate the utility of the marine manager portal by applying Global Fishing Watch data to management use-cases for Tristan da Cunha.

## Instructions for Pew Data check:
This github repository includes all annotated code used to generate the tables and figures included in the report. The repository is organised as follows:

* analysis: annotated Rmarkdown notebooks which were used to create all R-generated figures and tables in the report.
* data: locally available sources of the data used in the report.
* geodata: shapefiles of Areas to be Avoided and Tristan da Cunha archipelago.
* queries: BigQuery queries, saved as .sql files, used to generate the data used in the report. 

The "analysis" folder includes one Rmarkdown notebook for the first three management use-cases:

1. Compliance with Tristan da Cunha’s Areas to be Avoided
2. The use of night-setting as a mitigation measure for Tristan albatross bycatch
3. Inter-annual trends in the distribution of tuna fisheries

The analysis for the fourth use-case, highlighting the utility of Marine manager as a tool for fisheries monitoring, control, and surveillance, was carried out predominantly using the Marine Manager portal. Each Rmarkdown notebook is saved as a usable notebook (.Rmd) or a pdf file (.pdf). Note that the pdf files include the output plots and tables, as they appear in the report. In each Rmarkdown notebook we used Google BiqQuery queries to pull data from Global Fishing Watch databases into R. These annotated queries are saved as .sql files and are loaded from the "queries" folder. As the data checker may not have access to Google BigQuery, we have also saved the results of these queries as .rds files in the "data_production/data" folder. The Rmarkdown notebooks include code to load these data files without the need to rerun the queries.
