clear
cap clear
cap log close
scalar drop _all
set mem 1200m
set more off

*Program for expulsion of main results for poverty *****************************

gl datac="F:\2025\Datos\8-Agosto\ENIGH\Pobreza\CONEVAL"
gl datai="F:\2025\Datos\8-Agosto\ENIGH\Pobreza\INEGI"
gl dataenigh="/Volumes/DLJMDATOS/DATOS_brutos/ENIGH"
gl bases="/Volumes/TRABAJODLJM/2025/Datos/8-Agosto/ENIGH/Pobreza/2-Results/Simulaciones"
gl proces="/Volumes/TRABAJODLJM/2025/Datos/8-Agosto/ENIGH/Pobreza/3-Procesados/Simulaciones"

********************************************************
* 2024
********************************************************

* Simulation 1: asumme lag = 0 & poverty = 1 of people with health and social security lag ************
quietly {
use "$bases/pobreza_24.dta", clear
keep ic_* factor* ent* rururb ict* tamhog* plp* sexo pobreza*
label drop _all

******************* Make population with health and segsoc lag to be "satisfied"
rename ic_asalud icasalud 
rename ic_segsoc icsegsoc
gen ic_asalud = icasalud
replace ic_asalud = 0 if icasalud == 1 & icsegsoc == 1 & pobreza == 1
gen ic_segsoc = icsegsoc
replace ic_segsoc = 0 if icasalud == 1 & icsegsoc == 1 & pobreza == 1

drop pobreza*
******************************************************** Redefinition of poverty

****************************
*Índice de Privación Social
****************************

egen i_privacion=rsum(ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv ic_ali_nc)
replace i_privacion=. if ic_rezedu==. | ic_asalud==. | ic_segsoc==. | ///
						 ic_cv==. | ic_sbv==. | ic_ali_nc==.

label var i_privacion "Índice de Privación Social"


***************************
*Pobreza multidimensional
***************************

*Pobreza
gen pobreza=1 if plp==1 & (i_privacion>=1 & i_privacion!=.)
replace pobreza=0 if (plp==0 | i_privacion==0) & (plp!=. & i_privacion!=.)

label var pobreza "Pobreza"
label define pobreza 0 "No pobre" 1 "Pobre", add
label value pobreza pobreza

*Pobreza extrema
gen pobreza_e=1 if plp_e==1 & (i_privacion>=3 & i_privacion!=.)
replace pobreza_e=0 if (plp_e==0 | i_privacion<3) & (plp_e!=. & i_privacion!=.)

label var pobreza_e "Pobreza extrema"
label define pobreza_e 0 "No pobre extremo" 1 "Pobre extremo", add
label value pobreza_e pobreza_e

*Pobreza moderada
gen pobreza_m=1 if pobreza==1 & pobreza_e==0
replace pobreza_m=0 if pobreza==0 | (pobreza==1 & pobreza_e==1)

label var pobreza_m "Pobreza moderada"
label define pobreza_m 0 "No pobre moderado" 1 "Pobre moderado", add
label value pobreza_m pobreza_m


*******************************
*Población vulnerable
*******************************

*Vulnerables por carencias
gen vul_car=cond(plp==0 & (i_privacion>=1 & i_privacion!=.),1,0)
replace vul_car=. if pobreza==.
label var vul_car "Población vulnerable por carencias"
label define vul 0 "No vulnerable" 1 "Vulnerable", add
label value vul_car vul

*Vulnerables por ingresos
gen vul_ing=cond(plp==1 & i_privacion==0,1,0)
replace vul_ing=. if pobreza==.
label var vul_ing "Población vulnerable por ingresos"
label value vul_ing vul


****************************************************
*Población no pobre y no vulnerable
****************************************************

gen no_pobv=cond(plp==0 & i_privacion==0,1,0)
replace no_pobv=. if pobreza==.

label var no_pobv "Población no pobre y no vulnerable"
label define no_pobv 0 "Pobre o vulnerable" 1 "No pobre y no vulnerable", add
label value no_pobv no_pobv


***********************************
*Población con carencias sociales 
***********************************

gen carencias=cond(i_privacion>=1 & i_privacion!=.,1,0)
replace carencias=. if pobreza==.

label var carencias "Población con al menos una carencia social"
label define carencias 0 "Población sin carencias sociales" 1 "Población con al menos una carencia social", add
label value carencias carencias

gen carencias3=cond(i_privacion>=3 & i_privacion!=.,1,0)
replace carencias3=. if pobreza==.

label var carencias3 "Población con al menos tres carencias sociales"
label define carencias3 0 "Población con menos de tres carencias sociales" 1 "Población con al menos tres carencias sociales", add
label value carencias3 carencias3


************
*Cuadrantes
************

gen cuadrantes=.
replace cuadrantes=1 if plp==1 & (i_privacion>=1 & i_privacion!=.)
replace cuadrantes=2 if plp==0 & (i_privacion>=1 & i_privacion!=.)
replace cuadrantes=3 if plp==1 & i_privacion==0
replace cuadrantes=4 if plp==0 & i_privacion==0

label var cuadrantes "Cuadrantes de bienestar económico y derechos sociales"
label define cuadrantes 1 "Pobres" 2 "Vulnerables por carencias" 3 "Vulnerables por ingresos" 4 "No pobres y no vulnerables", add
label value cuadrantes cuadrantes


* Average number of lags per poverty condition
gen num_carp = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza == 1
gen num_carpm = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza_m == 1
gen num_carpe = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza_e == 1

******************************************************* Exportation of collapses
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=.
gen anio = 2024
save "$bases/sumpob24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=.
gen anio = 2024
save "$bases/meanpob24.dta", replace
restore

*********** Percentage & persons by poverty indicators by entity
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent)
gen anio = 2024
save "$bases/sument24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent)
gen anio = 2024
save "$bases/meanent24.dta", replace
restore

*********** Percentage & persons by poverty indicators by URBAN entity in screen

* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if rururb == 0 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/sumurb24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if rururb == 0 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanurb24.dta", replace
restore

*********** Percentage & persons by poverty indicators by RURAL entity in screen
* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if rururb == 1 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/sumrur24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if rururb == 1 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanrur24.dta", replace
restore

*********** Percentage & persons by poverty indicators by SEX entity
* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/sumsex24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/meansex24.dta", replace
restore

*********** Average income and income per capita per entity and sex by social lag
preserve

local varlist "rezedu asalud segsoc cv sbv ali_nc"
foreach x of local varlist {
gen ict_`x' = ict if ic_`x' == 1
replace ict_`x' = . if  ic_`x' != 1
gen ictpc_`x' = ictpc if ic_`x' == 1
replace ictpc_`x' = . if  ic_`x' != 1
}

collapse (mean) ict*  [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/meanic24.dta", replace
restore

*********** Average income and income per capita entity by social lag
preserve

local varlist "rezedu asalud segsoc cv sbv ali_nc"
foreach x of local varlist {
gen ict_`x' = ict if ic_`x' == 1
replace ict_`x' = . if  ic_`x' != 1
gen ictpc_`x' = ictpc if ic_`x' == 1
replace ictpc_`x' = . if  ic_`x' != 1
}

collapse (mean) ict*  [fweight=factor] if pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanict24.dta", replace
restore

}

* Appending and exportation to excel *******************************************
* National
use "$bases/meanpob24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sumpob24.dta"
replace tipo = "personas" if tipo == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Nacional1") firstrow(variables) sheetmodify

* States
use "$bases/meanent24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sument24.dta"
replace tipo = "personas" if tipo == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Entidades1") firstrow(variables) sheetmodify

* Urban/Rural
use "$bases/meanurb24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sumurb24.dta"
replace tipo = "personas" if tipo == ""
gen localidad = "urbana"
append using "$bases/meanrur24.dta"
replace tipo = "porcentaje" if tipo == ""
append using "$bases/sumrur24.dta"
replace tipo = "personas" if tipo == ""
replace localidad = "rural" if localidad == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Localidad1") firstrow(variables) sheetmodify

* Income & states
use "$bases/meanict24.dta", clear
gen sexo = "General"
append using "$bases/meanic24.dta"
export excel "$proces/PobAlterna2024.xlsx", sheet("IngEntSex1") firstrow(variables) sheetmodify

* Simulation 2: asumme lag = 0 & povertyext = 1 of people with health and social security lag ************
quietly {
use "$bases/pobreza_24.dta", clear
keep ic_* factor* ent* rururb ict* tamhog* plp* sexo pobreza*
label drop _all

******************* Make population with health and segsoc lag to be "satisfied"
rename ic_asalud icasalud 
rename ic_segsoc icsegsoc
gen ic_asalud = icasalud
replace ic_asalud = 0 if icasalud == 1 & icsegsoc == 1 & pobreza_e == 1
gen ic_segsoc = icsegsoc
replace ic_segsoc = 0 if icasalud == 1 & icsegsoc == 1 & pobreza_e == 1

drop pobreza*

******************************************************** Redefinition of poverty

****************************
*Índice de Privación Social
****************************

egen i_privacion=rsum(ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv ic_ali_nc)
replace i_privacion=. if ic_rezedu==. | ic_asalud==. | ic_segsoc==. | ///
						 ic_cv==. | ic_sbv==. | ic_ali_nc==.

label var i_privacion "Índice de Privación Social"


***************************
*Pobreza multidimensional
***************************

*Pobreza
gen pobreza=1 if plp==1 & (i_privacion>=1 & i_privacion!=.)
replace pobreza=0 if (plp==0 | i_privacion==0) & (plp!=. & i_privacion!=.)

label var pobreza "Pobreza"
label define pobreza 0 "No pobre" 1 "Pobre", add
label value pobreza pobreza

*Pobreza extrema
gen pobreza_e=1 if plp_e==1 & (i_privacion>=3 & i_privacion!=.)
replace pobreza_e=0 if (plp_e==0 | i_privacion<3) & (plp_e!=. & i_privacion!=.)

label var pobreza_e "Pobreza extrema"
label define pobreza_e 0 "No pobre extremo" 1 "Pobre extremo", add
label value pobreza_e pobreza_e

*Pobreza moderada
gen pobreza_m=1 if pobreza==1 & pobreza_e==0
replace pobreza_m=0 if pobreza==0 | (pobreza==1 & pobreza_e==1)

label var pobreza_m "Pobreza moderada"
label define pobreza_m 0 "No pobre moderado" 1 "Pobre moderado", add
label value pobreza_m pobreza_m


*******************************
*Población vulnerable
*******************************

*Vulnerables por carencias
gen vul_car=cond(plp==0 & (i_privacion>=1 & i_privacion!=.),1,0)
replace vul_car=. if pobreza==.
label var vul_car "Población vulnerable por carencias"
label define vul 0 "No vulnerable" 1 "Vulnerable", add
label value vul_car vul

*Vulnerables por ingresos
gen vul_ing=cond(plp==1 & i_privacion==0,1,0)
replace vul_ing=. if pobreza==.
label var vul_ing "Población vulnerable por ingresos"
label value vul_ing vul


****************************************************
*Población no pobre y no vulnerable
****************************************************

gen no_pobv=cond(plp==0 & i_privacion==0,1,0)
replace no_pobv=. if pobreza==.

label var no_pobv "Población no pobre y no vulnerable"
label define no_pobv 0 "Pobre o vulnerable" 1 "No pobre y no vulnerable", add
label value no_pobv no_pobv


***********************************
*Población con carencias sociales 
***********************************

gen carencias=cond(i_privacion>=1 & i_privacion!=.,1,0)
replace carencias=. if pobreza==.

label var carencias "Población con al menos una carencia social"
label define carencias 0 "Población sin carencias sociales" 1 "Población con al menos una carencia social", add
label value carencias carencias

gen carencias3=cond(i_privacion>=3 & i_privacion!=.,1,0)
replace carencias3=. if pobreza==.

label var carencias3 "Población con al menos tres carencias sociales"
label define carencias3 0 "Población con menos de tres carencias sociales" 1 "Población con al menos tres carencias sociales", add
label value carencias3 carencias3


************
*Cuadrantes
************

gen cuadrantes=.
replace cuadrantes=1 if plp==1 & (i_privacion>=1 & i_privacion!=.)
replace cuadrantes=2 if plp==0 & (i_privacion>=1 & i_privacion!=.)
replace cuadrantes=3 if plp==1 & i_privacion==0
replace cuadrantes=4 if plp==0 & i_privacion==0

label var cuadrantes "Cuadrantes de bienestar económico y derechos sociales"
label define cuadrantes 1 "Pobres" 2 "Vulnerables por carencias" 3 "Vulnerables por ingresos" 4 "No pobres y no vulnerables", add
label value cuadrantes cuadrantes


* Average number of lags per poverty condition
gen num_carp = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza == 1
gen num_carpm = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza_m == 1
gen num_carpe = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza_e == 1

******************************************************* Exportation of collapses
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=.
gen anio = 2024
save "$bases/sumpob24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=.
gen anio = 2024
save "$bases/meanpob24.dta", replace
restore

*********** Percentage & persons by poverty indicators by entity
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent)
gen anio = 2024
save "$bases/sument24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent)
gen anio = 2024
save "$bases/meanent24.dta", replace
restore

*********** Percentage & persons by poverty indicators by URBAN entity in screen

* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if rururb == 0 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/sumurb24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if rururb == 0 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanurb24.dta", replace
restore

*********** Percentage & persons by poverty indicators by RURAL entity in screen
* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if rururb == 1 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/sumrur24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if rururb == 1 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanrur24.dta", replace
restore

*********** Percentage & persons by poverty indicators by SEX entity
* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/sumsex24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/meansex24.dta", replace
restore

*********** Average income and income per capita per entity and sex by social lag
preserve

local varlist "rezedu asalud segsoc cv sbv ali_nc"
foreach x of local varlist {
gen ict_`x' = ict if ic_`x' == 1
replace ict_`x' = . if  ic_`x' != 1
gen ictpc_`x' = ictpc if ic_`x' == 1
replace ictpc_`x' = . if  ic_`x' != 1
}

collapse (mean) ict*  [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/meanic24.dta", replace
restore

*********** Average income and income per capita entity by social lag
preserve

local varlist "rezedu asalud segsoc cv sbv ali_nc"
foreach x of local varlist {
gen ict_`x' = ict if ic_`x' == 1
replace ict_`x' = . if  ic_`x' != 1
gen ictpc_`x' = ictpc if ic_`x' == 1
replace ictpc_`x' = . if  ic_`x' != 1
}

collapse (mean) ict*  [fweight=factor] if pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanict24.dta", replace
restore

}

* Appending and exportation to excel *******************************************
* National
use "$bases/meanpob24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sumpob24.dta"
replace tipo = "personas" if tipo == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Nacional2") firstrow(variables) sheetmodify

* States
use "$bases/meanent24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sument24.dta"
replace tipo = "personas" if tipo == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Entidades2") firstrow(variables) sheetmodify

* Urban/Rural
use "$bases/meanurb24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sumurb24.dta"
replace tipo = "personas" if tipo == ""
gen localidad = "urbana"
append using "$bases/meanrur24.dta"
replace tipo = "porcentaje" if tipo == ""
append using "$bases/sumrur24.dta"
replace tipo = "personas" if tipo == ""
replace localidad = "rural" if localidad == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Localidad2") firstrow(variables) sheetmodify

* Income & states
use "$bases/meanict24.dta", clear
gen sexo = "General"
append using "$bases/meanic24.dta"
export excel "$proces/PobAlterna2024.xlsx", sheet("IngEntSex2") firstrow(variables) sheetmodify

* Simulation 3: asumme lag = 0 & poverty rural of people with health and social security lag ************
quietly {
use "$bases/pobreza_24.dta", clear
keep ic_* factor* ent* rururb ict* tamhog* plp* sexo pobreza*
label drop _all

******************* Make population with health and segsoc lag to be "satisfied"
rename ic_asalud icasalud 
rename ic_segsoc icsegsoc
gen ic_asalud = icasalud
replace ic_asalud = 0 if icasalud == 1 & icsegsoc == 1 & pobreza == 1 & rururb == 1 
gen ic_segsoc = icsegsoc
replace ic_segsoc = 0 if icasalud == 1 & icsegsoc == 1 & pobreza == 1 & rururb == 1 

drop pobreza*
******************************************************** Redefinition of poverty

****************************
*Índice de Privación Social
****************************

egen i_privacion=rsum(ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv ic_ali_nc)
replace i_privacion=. if ic_rezedu==. | ic_asalud==. | ic_segsoc==. | ///
						 ic_cv==. | ic_sbv==. | ic_ali_nc==.

label var i_privacion "Índice de Privación Social"


***************************
*Pobreza multidimensional
***************************

*Pobreza
gen pobreza=1 if plp==1 & (i_privacion>=1 & i_privacion!=.)
replace pobreza=0 if (plp==0 | i_privacion==0) & (plp!=. & i_privacion!=.)

label var pobreza "Pobreza"
label define pobreza 0 "No pobre" 1 "Pobre", add
label value pobreza pobreza

*Pobreza extrema
gen pobreza_e=1 if plp_e==1 & (i_privacion>=3 & i_privacion!=.)
replace pobreza_e=0 if (plp_e==0 | i_privacion<3) & (plp_e!=. & i_privacion!=.)

label var pobreza_e "Pobreza extrema"
label define pobreza_e 0 "No pobre extremo" 1 "Pobre extremo", add
label value pobreza_e pobreza_e

*Pobreza moderada
gen pobreza_m=1 if pobreza==1 & pobreza_e==0
replace pobreza_m=0 if pobreza==0 | (pobreza==1 & pobreza_e==1)

label var pobreza_m "Pobreza moderada"
label define pobreza_m 0 "No pobre moderado" 1 "Pobre moderado", add
label value pobreza_m pobreza_m


*******************************
*Población vulnerable
*******************************

*Vulnerables por carencias
gen vul_car=cond(plp==0 & (i_privacion>=1 & i_privacion!=.),1,0)
replace vul_car=. if pobreza==.
label var vul_car "Población vulnerable por carencias"
label define vul 0 "No vulnerable" 1 "Vulnerable", add
label value vul_car vul

*Vulnerables por ingresos
gen vul_ing=cond(plp==1 & i_privacion==0,1,0)
replace vul_ing=. if pobreza==.
label var vul_ing "Población vulnerable por ingresos"
label value vul_ing vul


****************************************************
*Población no pobre y no vulnerable
****************************************************

gen no_pobv=cond(plp==0 & i_privacion==0,1,0)
replace no_pobv=. if pobreza==.

label var no_pobv "Población no pobre y no vulnerable"
label define no_pobv 0 "Pobre o vulnerable" 1 "No pobre y no vulnerable", add
label value no_pobv no_pobv


***********************************
*Población con carencias sociales 
***********************************

gen carencias=cond(i_privacion>=1 & i_privacion!=.,1,0)
replace carencias=. if pobreza==.

label var carencias "Población con al menos una carencia social"
label define carencias 0 "Población sin carencias sociales" 1 "Población con al menos una carencia social", add
label value carencias carencias

gen carencias3=cond(i_privacion>=3 & i_privacion!=.,1,0)
replace carencias3=. if pobreza==.

label var carencias3 "Población con al menos tres carencias sociales"
label define carencias3 0 "Población con menos de tres carencias sociales" 1 "Población con al menos tres carencias sociales", add
label value carencias3 carencias3


************
*Cuadrantes
************

gen cuadrantes=.
replace cuadrantes=1 if plp==1 & (i_privacion>=1 & i_privacion!=.)
replace cuadrantes=2 if plp==0 & (i_privacion>=1 & i_privacion!=.)
replace cuadrantes=3 if plp==1 & i_privacion==0
replace cuadrantes=4 if plp==0 & i_privacion==0

label var cuadrantes "Cuadrantes de bienestar económico y derechos sociales"
label define cuadrantes 1 "Pobres" 2 "Vulnerables por carencias" 3 "Vulnerables por ingresos" 4 "No pobres y no vulnerables", add
label value cuadrantes cuadrantes


* Average number of lags per poverty condition
gen num_carp = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza == 1
gen num_carpm = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza_m == 1
gen num_carpe = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza_e == 1

******************************************************* Exportation of collapses
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=.
gen anio = 2024
save "$bases/sumpob24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=.
gen anio = 2024
save "$bases/meanpob24.dta", replace
restore

*********** Percentage & persons by poverty indicators by entity
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent)
gen anio = 2024
save "$bases/sument24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent)
gen anio = 2024
save "$bases/meanent24.dta", replace
restore

*********** Percentage & persons by poverty indicators by URBAN entity in screen

* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if rururb == 0 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/sumurb24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if rururb == 0 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanurb24.dta", replace
restore

*********** Percentage & persons by poverty indicators by RURAL entity in screen
* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if rururb == 1 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/sumrur24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if rururb == 1 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanrur24.dta", replace
restore

*********** Percentage & persons by poverty indicators by SEX entity
* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/sumsex24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/meansex24.dta", replace
restore

*********** Average income and income per capita per entity and sex by social lag
preserve

local varlist "rezedu asalud segsoc cv sbv ali_nc"
foreach x of local varlist {
gen ict_`x' = ict if ic_`x' == 1
replace ict_`x' = . if  ic_`x' != 1
gen ictpc_`x' = ictpc if ic_`x' == 1
replace ictpc_`x' = . if  ic_`x' != 1
}

collapse (mean) ict*  [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/meanic24.dta", replace
restore

*********** Average income and income per capita entity by social lag
preserve

local varlist "rezedu asalud segsoc cv sbv ali_nc"
foreach x of local varlist {
gen ict_`x' = ict if ic_`x' == 1
replace ict_`x' = . if  ic_`x' != 1
gen ictpc_`x' = ictpc if ic_`x' == 1
replace ictpc_`x' = . if  ic_`x' != 1
}

collapse (mean) ict*  [fweight=factor] if pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanict24.dta", replace
restore

}

* Appending and exportation to excel *******************************************
* National
use "$bases/meanpob24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sumpob24.dta"
replace tipo = "personas" if tipo == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Nacional3") firstrow(variables) sheetmodify

* States
use "$bases/meanent24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sument24.dta"
replace tipo = "personas" if tipo == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Entidades3") firstrow(variables) sheetmodify

* Urban/Rural
use "$bases/meanurb24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sumurb24.dta"
replace tipo = "personas" if tipo == ""
gen localidad = "urbana"
append using "$bases/meanrur24.dta"
replace tipo = "porcentaje" if tipo == ""
append using "$bases/sumrur24.dta"
replace tipo = "personas" if tipo == ""
replace localidad = "rural" if localidad == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Localidad3") firstrow(variables) sheetmodify

* Income & states
use "$bases/meanict24.dta", clear
gen sexo = "General"
append using "$bases/meanic24.dta"
export excel "$proces/PobAlterna2024.xlsx", sheet("IngEntSex3") firstrow(variables) sheetmodify

* Simulation 4: asumme lag = 0 & povertyext = 1 & rural of people with health and social security lag ************
quietly {
use "$bases/pobreza_24.dta", clear
keep ic_* factor* ent* rururb ict* tamhog* plp* sexo pobreza*
label drop _all

******************* Make population with health and segsoc lag to be "satisfied"
rename ic_asalud icasalud 
rename ic_segsoc icsegsoc
gen ic_asalud = icasalud
replace ic_asalud = 0 if icasalud == 1 & icsegsoc == 1 & pobreza_e == 1 & rururb == 1 
gen ic_segsoc = icsegsoc
replace ic_segsoc = 0 if icasalud == 1 & icsegsoc == 1 & pobreza_e == 1 & rururb == 1 

drop pobreza*

******************************************************** Redefinition of poverty

****************************
*Índice de Privación Social
****************************

egen i_privacion=rsum(ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv ic_ali_nc)
replace i_privacion=. if ic_rezedu==. | ic_asalud==. | ic_segsoc==. | ///
						 ic_cv==. | ic_sbv==. | ic_ali_nc==.

label var i_privacion "Índice de Privación Social"


***************************
*Pobreza multidimensional
***************************

*Pobreza
gen pobreza=1 if plp==1 & (i_privacion>=1 & i_privacion!=.)
replace pobreza=0 if (plp==0 | i_privacion==0) & (plp!=. & i_privacion!=.)

label var pobreza "Pobreza"
label define pobreza 0 "No pobre" 1 "Pobre", add
label value pobreza pobreza

*Pobreza extrema
gen pobreza_e=1 if plp_e==1 & (i_privacion>=3 & i_privacion!=.)
replace pobreza_e=0 if (plp_e==0 | i_privacion<3) & (plp_e!=. & i_privacion!=.)

label var pobreza_e "Pobreza extrema"
label define pobreza_e 0 "No pobre extremo" 1 "Pobre extremo", add
label value pobreza_e pobreza_e

*Pobreza moderada
gen pobreza_m=1 if pobreza==1 & pobreza_e==0
replace pobreza_m=0 if pobreza==0 | (pobreza==1 & pobreza_e==1)

label var pobreza_m "Pobreza moderada"
label define pobreza_m 0 "No pobre moderado" 1 "Pobre moderado", add
label value pobreza_m pobreza_m


*******************************
*Población vulnerable
*******************************

*Vulnerables por carencias
gen vul_car=cond(plp==0 & (i_privacion>=1 & i_privacion!=.),1,0)
replace vul_car=. if pobreza==.
label var vul_car "Población vulnerable por carencias"
label define vul 0 "No vulnerable" 1 "Vulnerable", add
label value vul_car vul

*Vulnerables por ingresos
gen vul_ing=cond(plp==1 & i_privacion==0,1,0)
replace vul_ing=. if pobreza==.
label var vul_ing "Población vulnerable por ingresos"
label value vul_ing vul


****************************************************
*Población no pobre y no vulnerable
****************************************************

gen no_pobv=cond(plp==0 & i_privacion==0,1,0)
replace no_pobv=. if pobreza==.

label var no_pobv "Población no pobre y no vulnerable"
label define no_pobv 0 "Pobre o vulnerable" 1 "No pobre y no vulnerable", add
label value no_pobv no_pobv


***********************************
*Población con carencias sociales 
***********************************

gen carencias=cond(i_privacion>=1 & i_privacion!=.,1,0)
replace carencias=. if pobreza==.

label var carencias "Población con al menos una carencia social"
label define carencias 0 "Población sin carencias sociales" 1 "Población con al menos una carencia social", add
label value carencias carencias

gen carencias3=cond(i_privacion>=3 & i_privacion!=.,1,0)
replace carencias3=. if pobreza==.

label var carencias3 "Población con al menos tres carencias sociales"
label define carencias3 0 "Población con menos de tres carencias sociales" 1 "Población con al menos tres carencias sociales", add
label value carencias3 carencias3


************
*Cuadrantes
************

gen cuadrantes=.
replace cuadrantes=1 if plp==1 & (i_privacion>=1 & i_privacion!=.)
replace cuadrantes=2 if plp==0 & (i_privacion>=1 & i_privacion!=.)
replace cuadrantes=3 if plp==1 & i_privacion==0
replace cuadrantes=4 if plp==0 & i_privacion==0

label var cuadrantes "Cuadrantes de bienestar económico y derechos sociales"
label define cuadrantes 1 "Pobres" 2 "Vulnerables por carencias" 3 "Vulnerables por ingresos" 4 "No pobres y no vulnerables", add
label value cuadrantes cuadrantes


* Average number of lags per poverty condition
gen num_carp = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza == 1
gen num_carpm = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza_m == 1
gen num_carpe = ic_rezedu + ic_asalud + ic_segsoc + ic_cv + ic_sbv + ic_ali_nc if pobreza_e == 1

******************************************************* Exportation of collapses
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=.
gen anio = 2024
save "$bases/sumpob24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=.
gen anio = 2024
save "$bases/meanpob24.dta", replace
restore

*********** Percentage & persons by poverty indicators by entity
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent)
gen anio = 2024
save "$bases/sument24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent)
gen anio = 2024
save "$bases/meanent24.dta", replace
restore

*********** Percentage & persons by poverty indicators by URBAN entity in screen

* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if rururb == 0 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/sumurb24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if rururb == 0 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanurb24.dta", replace
restore

*********** Percentage & persons by poverty indicators by RURAL entity in screen
* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if rururb == 1 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/sumrur24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if rururb == 1 & pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanrur24.dta", replace
restore

*********** Percentage & persons by poverty indicators by SEX entity
* Percentage & persons by poverty indicators by entity to excel
preserve
collapse (sum) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp (mean) num_car* [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/sumsex24.dta", replace
restore

preserve
collapse (mean) pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv carencias carencias3 ic_rezedu ic_asalud ///
ic_segsoc ic_cv ic_sbv ic_ali_nc plp_e plp [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/meansex24.dta", replace
restore

*********** Average income and income per capita per entity and sex by social lag
preserve

local varlist "rezedu asalud segsoc cv sbv ali_nc"
foreach x of local varlist {
gen ict_`x' = ict if ic_`x' == 1
replace ict_`x' = . if  ic_`x' != 1
gen ictpc_`x' = ictpc if ic_`x' == 1
replace ictpc_`x' = . if  ic_`x' != 1
}

collapse (mean) ict*  [fweight=factor] if pobreza!=., by(ent sexo)

gen anio = 2024
save "$bases/meanic24.dta", replace
restore

*********** Average income and income per capita entity by social lag
preserve

local varlist "rezedu asalud segsoc cv sbv ali_nc"
foreach x of local varlist {
gen ict_`x' = ict if ic_`x' == 1
replace ict_`x' = . if  ic_`x' != 1
gen ictpc_`x' = ictpc if ic_`x' == 1
replace ictpc_`x' = . if  ic_`x' != 1
}

collapse (mean) ict*  [fweight=factor] if pobreza!=., by(ent)

gen anio = 2024
save "$bases/meanict24.dta", replace
restore

}

* Appending and exportation to excel *******************************************
* National
use "$bases/meanpob24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sumpob24.dta"
replace tipo = "personas" if tipo == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Nacional4") firstrow(variables) sheetmodify

* States
use "$bases/meanent24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sument24.dta"
replace tipo = "personas" if tipo == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Entidades4") firstrow(variables) sheetmodify

* Urban/Rural
use "$bases/meanurb24.dta", clear
gen tipo = "porcentaje"
append using "$bases/sumurb24.dta"
replace tipo = "personas" if tipo == ""
gen localidad = "urbana"
append using "$bases/meanrur24.dta"
replace tipo = "porcentaje" if tipo == ""
append using "$bases/sumrur24.dta"
replace tipo = "personas" if tipo == ""
replace localidad = "rural" if localidad == ""
export excel "$proces/PobAlterna2024.xlsx", sheet("Localidad4") firstrow(variables) sheetmodify

* Income & states
use "$bases/meanict24.dta", clear
gen sexo = "General"
append using "$bases/meanic24.dta"
export excel "$proces/PobAlterna2024.xlsx", sheet("IngEntSex4") firstrow(variables) sheetmodify


/* For comments/doubts please contact
Diana L. Jimenez M.
diana_jimenez@hacienda.gob.mx
