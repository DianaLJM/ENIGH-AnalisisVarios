** ENIGH + CONEVAL 2020 estimations

clear
set matsize 11000
set more off

gl datosenigh = "D:\diana_jimenez\Documents\DATOS\ENIGH\Pobreza"
gl bases="F:\2025\Datos\7-Julio\DGPPP\ENIGH2024\Gastos"

***************************************************************** Data obtention
local time=16
while `time' <= 24 {

********************************************************* I. Indexes of interest
******************************************** I.1 Overcrowding
use "$datosenigh/viviendas`time'.dta", clear
sort folioviv
save "$bases/viviendas`time'.dta", replace
use "$datosenigh/concentradohogar`time'.dta", clear
sort folioviv 
merge folioviv using "$bases/viviendas`time'.dta"
tab _merge
drop _merge

** Livingspace condition
* # of residents in a livingspace
rename tot_resid num_ind
* # of rooms in a livingspace
rename num_cuarto num_cua
* CONEVAL's overcrowding index
gen cv_hac=num_ind/num_cua

*Poverty indicator due to overcrowding
gen icv_hac=.
replace icv_hac=1 if cv_hac>2.5 & cv_hac!=.
replace icv_hac=0 if cv_hac<=2.5
label var icv_hac "Indicador de carencia por hacinamiento en la vivienda"
label value icv_hac caren
sort  folioviv foliohog
keep  folioviv foliohog icv_hac num_* cv_hac
save "$bases/touseoc`time'.dta", replace

* Merging bases to adequately get national overcrowding (only index)
use "$datosenigh/concentradohogar`time'.dta", clear
sort folioviv foliohog
merge 1:m folioviv foliohog using "$bases/touseoc`time'.dta", update
gen hogar = (folioviv + foliohog)

gen hogares = 1
gen hogares_carhac = (icv_hac == 1)
gen ingmon = ing_cor
gen gastomon = gasto_mon
drop _merge

gen anio = 2000 + `time'

save "$bases/touse.dta", replace

* Collapse national
gen indice = cv_hac if icv_hac == 1
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon num_ind num_cua indice [fweight=factor]
format gasto* ing* %12.0f
save "$bases/overcrowd_`time'.dta", replace
* Collapse by entity
use "$bases/touse.dta", clear
gen indice = cv_hac if icv_hac == 1
gen ent=real(substr(folioviv,1,2))
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon num_ind num_cua indice [fweight=factor], by(ent)
format gasto* ing* %12.0f
save "$bases/overcrowdent_`time'.dta", replace

* Merging bases to adequately get national overcrowding considering expenses obtained by DECILS
if `time' == 18 {
import excel "$datosenigh/D_R_2018.xlsx", sheet("Deciles_R") firstrow clear
}
else if `time' == 16 {
import excel "$datosenigh/D_R_2016.xlsx", sheet("Deciles_R_2016") firstrow clear
}
else if `time' == 20 {
import excel "$datosenigh/D_R_2020.xlsx", sheet("Deciles_R_2020") firstrow clear
}
else if `time' == 22 {
import excel "$datosenigh/D_R_2022.xlsx", sheet("Deciles_R_2022") firstrow clear
}
else if `time' == 24 {
import excel "$datosenigh/D_R_2024.xlsx", sheet("Deciles_R_2024") firstrow clear
}

tostring folioviv foliohog, replace
sort folioviv foliohog
rename DECIL deciles_tri
merge m:1 folioviv foliohog using "$bases/touseoc`time'.dta", update
keep if _merge == 3
gen hogar = (folioviv + foliohog)
keep if icv_hac == 1

gen hogares_carhac = (icv_hac == 1)
gen ingmon = ing_cor
gen gastomon = gasto_mon
gen anio = 2000 + `time'
drop _merge
gen indice = cv_hac if icv_hac == 1
save "$bases/touse.dta", replace

* Collapse per decil
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon num_ind num_cua indice [fweight=factor], by(deciles_tri)
format gasto* ing* %12.0f
save "$bases/overcrowddecil_`time'.dta", replace

******************************************* I.2 Social Programs of current administration
use "$datosenigh/ingresos`time'.dta", clear
* Expenses variables (monthly construction)
replace ing_tri=ing_tri

gen progsmorena1_m = ing_tri if (clave == "P102" | clave == "P103" | clave == "P104" ///
								| clave == "P105" | clave == "P106" | clave == "P108")
gen progsmorena2_m = ing_tri if (clave == "P101" | clave == "P102" | clave == "P103" | clave == "P104" ///
								| clave == "P105" | clave == "P106" | clave == "P108")


gen progs_m = ing_tri if (clave == "P043" | clave == "P045" | clave == "P048" ///
							| clave == "P101" | clave == "P102" | clave == "P103" ///
							| clave == "P104" | clave == "P105" | clave == "P106" ///
							| clave == "P107" | clave == "P108")

collapse (sum) *_m, by(folioviv foliohog)
save "$bases/ing_fin`time'.dta", replace

* Merging bases to adequately get national households w/remitances (only index)
use "$datosenigh/concentradohogar`time'.dta", clear
sort folioviv foliohog
merge m:1 folioviv foliohog using "$bases/ing_fin`time'.dta", update
gen hogar = (folioviv + foliohog)

gen hogares = 1
gen hogares_pmor1 = (progsmorena1_m > 0 & !missing(progsmorena1_m))
gen hogares_pmor2 = (progsmorena2_m > 0 & !missing(progsmorena2_m))
gen hogares_progs = (progs_m > 0 & !missing(progs_m))
gen hogares_progscon = (bene_gob > 0 & !missing(bene_gob))
gen hogares_transf = ((jubilacion > 0 & !missing(jubilacion)) | (becas > 0 & !missing(becas)) | ///
					(donativos > 0 & !missing(donativos)) | (bene_gob > 0 & !missing(bene_gob)))
					
gen ingmon = ing_cor
gen gastomon = gasto_mon
drop _merge

gen anio = 2000 + `time'

save "$bases/touse.dta", replace

* Collapse national
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon *_m bene_gob transfer [fweight=factor]
format gasto* *_m bene* ing* %12.0f
order hogares_transf, last
save "$bases/progsoc_`time'.dta", replace
* Collapse by entity
use "$bases/touse.dta", clear
gen ent=real(substr(folioviv,1,2))
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon *_m bene_gob transfer [fweight=factor], by(ent)
format gasto* *_m bene* ing* %12.0f
order hogares_transf, last
save "$bases/progsocent_`time'.dta", replace

* Merging bases to adequately get househodls w/remitances considering expenses obtained by DECILS
if `time' == 18 {
import excel "$datosenigh/D_R_2018.xlsx", sheet("Deciles_R") firstrow clear
}
else if `time' == 16 {
import excel "$datosenigh/D_R_2016.xlsx", sheet("Deciles_R_2016") firstrow clear
}
else if `time' == 20 {
import excel "$datosenigh/D_R_2020.xlsx", sheet("Deciles_R_2020") firstrow clear
}
else if `time' == 22 {
import excel "$datosenigh/D_R_2022.xlsx", sheet("Deciles_R_2022") firstrow clear
}
else if `time' == 24 {
import excel "$datosenigh/D_R_2024.xlsx", sheet("Deciles_R_2024") firstrow clear
}

tostring folioviv foliohog, replace
sort folioviv foliohog
rename DECIL deciles_tri
merge m:1 folioviv foliohog using "$bases/ing_fin`time'.dta", update
keep if _merge == 3

gen hogar = (folioviv + foliohog)

gen hogares_pmor1 = (progsmorena1_m > 0 & !missing(progsmorena1_m))
gen hogares_pmor2 = (progsmorena2_m > 0 & !missing(progsmorena2_m))
gen hogares_progs = (progs_m > 0 & !missing(progs_m))
gen hogares_progscon = (bene_gob > 0 & !missing(bene_gob))
gen hogares_transf = ((jubilacion > 0 & !missing(jubilacion)) | (becas > 0 & !missing(becas)) | ///
					(donativos > 0 & !missing(donativos)) | (bene_gob > 0 & !missing(bene_gob)))
										
gen ingmon = ing_cor
gen gastomon = gasto_mon
gen anio = 2000 + `time'
drop _merge
save "$bases/touse.dta", replace

* Collapse per decil
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon *_m bene_gob transfer [fweight=factor], by(deciles_tri)
format gasto* *_m bene* ing* %12.0f
order hogares_transf, last
save "$bases/progsocdecil_`time'.dta", replace

******************************************* I.3 Sex of head of households
use "$datosenigh/concentradohogar`time'.dta", clear
sort folioviv foliohog
gen hogar = (folioviv + foliohog)

gen hogares = 1

gen ingmon = ing_cor
gen gastomon = gasto_mon

gen anio = 2000 + `time'

save "$bases/touse.dta", replace

* Collapse national
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon edad_jefe tot_integ menores p65mas [fweight=factor], by(sexo_jefe)
format gasto* ing* %12.0f
save "$bases/sexjef_`time'.dta", replace
* Collapse national
use "$bases/touse.dta", clear
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon edad_jefe tot_integ menores p65mas [fweight=factor]
format gasto* ing* %12.0f
save "$bases/sexjefgral_`time'.dta", replace
* Collapse by entity
use "$bases/touse.dta", clear
gen ent=real(substr(folioviv,1,2))
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon edad_jefe tot_integ menores p65mas [fweight=factor], by(ent sexo_jefe)
format gasto* ing* %12.0f
save "$bases/sexjefent_`time'.dta", replace
* Collapse by entity
use "$bases/touse.dta", clear
gen ent=real(substr(folioviv,1,2))
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon edad_jefe tot_integ menores p65mas [fweight=factor], by(ent)
format gasto* ing* %12.0f
save "$bases/sexjefgralent_`time'.dta", replace

* Merging bases to adequately get househodls w/remitances considering expenses obtained by DECILS
if `time' == 18 {
import excel "$datosenigh/D_R_2018.xlsx", sheet("Deciles_R") firstrow clear
}
else if `time' == 16 {
import excel "$datosenigh/D_R_2016.xlsx", sheet("Deciles_R_2016") firstrow clear
}
else if `time' == 20 {
import excel "$datosenigh/D_R_2020.xlsx", sheet("Deciles_R_2020") firstrow clear
}
else if `time' == 22 {
import excel "$datosenigh/D_R_2022.xlsx", sheet("Deciles_R_2022") firstrow clear
}
else if `time' == 24 {
import excel "$datosenigh/D_R_2024.xlsx", sheet("Deciles_R_2024") firstrow clear
}

tostring folioviv foliohog, replace
sort folioviv foliohog
rename DECIL deciles_tri

merge m:1 folioviv foliohog using "$datosenigh/concentradohogar`time'.dta", ///
keepusing(sexo_jefe edad_jefe tot_integ menores p65mas)
keep if _merge == 3

gen hogar = (folioviv + foliohog)
drop _merge
gen hogares = 1

gen ingmon = ing_cor
gen gastomon = gasto_mon
gen anio = 2000 + `time'

save "$bases/touse.dta", replace

* Collapse per decil
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon  edad_jefe tot_integ menores p65mas [fweight=factor], by(deciles_tri sexo_jefe)
format gasto* ing* %12.0f
save "$bases/sexjefdecil_`time'.dta", replace

* Collapse per decil
use "$bases/touse.dta", clear
collapse (first) anio (sum) hogares* (mean) gastomon* ingmon  edad_jefe tot_integ menores p65mas [fweight=factor], by(deciles_tri)
format gasto* ing* %12.0f
save "$bases/sexjefgraldecil_`time'.dta", replace

erase "$bases/touse.dta"

local time = `time' + 2
}

*************************************************************** Data exportation
** Overcrowding
quietly {
use "$bases/overcrowd_16.dta", clear
local time=18
while `time' <= 24 {
append using "$bases/overcrowd_`time'.dta"
local time = `time' + 2
}
sort anio
export excel "$bases/Indices-ENIGH-24.xlsx", sheet(Hacina) firstrow(variables) sheetmodify
** Overcrowding entity
use "$bases/overcrowdent_16.dta", clear
local time=18
while `time' <= 24 {
append using "$bases/overcrowdent_`time'.dta"
local time = `time' + 2
}
sort anio ent
export excel "$bases/Indices-ENIGH-24.xlsx", sheet(HacinaEnt) firstrow(variables) sheetmodify
** Overcrowding by deciles
use "$bases/overcrowddecil_16.dta", clear
local time=18
while `time' <= 24 {
append using "$bases/overcrowddecil_`time'.dta"
local time = `time' + 2
}
destring deciles*, replace
sort anio deciles*
export excel "$bases/Indices-ENIGH-24.xlsx", sheet(HacinaDecil) firstrow(variables) sheetmodify
}

** Social programs
quietly{
use "$bases/progsoc_16.dta", clear
local time=18
while `time' <= 24 {
append using "$bases/progsoc_`time'.dta"
local time = `time' + 2
}
sort anio
export excel "$bases/Indices-ENIGH-24.xlsx", sheet(ProgSoc) firstrow(variables) sheetmodify
** Social programs entity
use "$bases/progsocent_16.dta", clear
local time=18
while `time' <= 24 {
append using "$bases/progsocent_`time'.dta"
local time = `time' + 2
}
sort anio ent
export excel "$bases/Indices-ENIGH-24.xlsx", sheet(ProgSocEnt) firstrow(variables) sheetmodify
** Social programs by deciles
use "$bases/progsocdecil_16.dta", clear
local time=18
while `time' <= 24 {
append using "$bases/progsocdecil_`time'.dta"
local time = `time' + 2
}
destring deciles*, replace
sort anio deciles*
export excel "$bases/Indices-ENIGH-24.xlsx", sheet(ProgSocDecil) firstrow(variables) sheetmodify
}

** Sex head of household
quietly {
use "$bases/sexjefgral_16.dta", clear
local time=18
while `time' <= 24 {
append using "$bases/sexjefgral_`time'.dta"
local time = `time' + 2
}
gen sexo_jefe = "0"
local time=16
while `time' <= 24 {
append using "$bases/sexjef_`time'.dta"
local time = `time' + 2
}
sort anio
export excel "$bases/Indices-ENIGH-24.xlsx", sheet(SexJefatura) firstrow(variables) sheetmodify
** Sex head of household entity
use "$bases/sexjefgralent_16.dta", clear
local time=18
while `time' <= 24 {
append using "$bases/sexjefgralent_`time'.dta"
local time = `time' + 2
}
gen sexo_jefe = "0"
local time=16
while `time' <= 24 {
append using "$bases/sexjefent_`time'.dta"
local time = `time' + 2
}
sort anio ent
export excel "$bases/Indices-ENIGH-24.xlsx", sheet(SexJefaturaEnt) firstrow(variables) sheetmodify
** Sex head of household by deciles
use "$bases/sexjefgraldecil_16.dta", clear
local time=18
while `time' <= 24 {
append using "$bases/sexjefgraldecil_`time'.dta"
local time = `time' + 2
}
gen sexo_jefe = "0"
local time=16
while `time' <= 24 {
append using "$bases/sexjefdecil_`time'.dta"
local time = `time' + 2
}
destring deciles*, replace
sort anio deciles*
export excel "$bases/Indices-ENIGH-24.xlsx", sheet(SexJefaturaDecil) firstrow(variables) sheetmodify
}


**************************************************** Unnecesary data elimination
local varlist "sexjef sexjefgral progsoc overcrowd"
foreach x of local varlist {
	local time=16
	while `time' <= 24 {
	erase  "$bases/`x'_`time'.dta"
	erase  "$bases/`x'ent_`time'.dta"
	erase  "$bases/`x'decil_`time'.dta"
	local time = `time' + 2
	}
}

local time=16
while `time' <= 24 {
	erase  "$bases/viviendas`time'.dta"
	erase  "$bases/ing_fin`time'.dta"
local time = `time' + 2
}


/*
To comments on the present do file please contact the editor:
   Diana L. Jimenez M. dianaljm@infinitum.com.mx



