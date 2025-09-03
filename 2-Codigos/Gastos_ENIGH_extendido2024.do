** ENIGH main EXPENDITURES 2024 estimations

clear
set matsize 11000
set more off

gl datosenigh = "D:\diana_jimenez\Documents\DATOS\ENIGH\Pobreza"
gl bases="F:\2025\Datos\8-Agosto\ENIGH\Gastos"

****************************** I. Specific expenses per household per decil 
****************************** (monetary quaterly estimation non deflacted) Rdata
local time=18
while `time' <= 22 {

use "$datosenigh/gastoshogar`time'.dta", clear
gen base=1
append using "$datosenigh/gastospersona`time'.dta"
recode base (.=2)

compress

replace frecuencia=frec_rem if base==2

label var base "Origen del monto"
label define base 1 "Monto del hogar", modify
label define base 2 "Monto de personas", modify
label value base base

* Expenses variables (monthly construction)
replace gasto_tri=gasto_tri

* Drop expenses from self-consumption & expense imputation from rent
drop if tipo_gasto=="G3" | tipo_gasto=="G7" 

************************************* Separate specific expenses disaggregated
local varlist "A215	A216 A217 A218 A219 A220 A221 A222 F007 F008 F009 G011 M001 B006 B007 M004 M006 B002 B004 B005 A095 A019 A004 A001 A042 A025 A031 A034 A057 A058 A059 A112 A115 A116 A117 A118 A137 A093 A124 A075 A080 A154 A158 A160 A102 A015 A009 A173 A070 A130 A068 D001 D014 R008 R010 R011 F002 F003 R007 L007 L008 A239 A240 A241 A223 A224 A225 A226 A227 A228 A229 A230 A231 A232 A233 A234 A235 A236 A237 A238 E027 E030 E031 E032 E033 E034 E022 E023 E024 E025 E026 A243 A244 A245 A246 A247 M007 M008 M009 M012 M013 M014 M015 M016 M017 M018 G101 Q001 G009 G010 G012 G013 G014 G015 G016 R001 R003 J044 J045 J046 J047 J048 J049 J050 J051 J052 J053 J054 J055 J056 J057 J058 J059 J060 J061 J062 J063 J064 J065 J066 J067 J068 J069"
foreach x of local varlist {
gen `x'_m=gasto_tri if clave == "`x'"
}

collapse (sum) *_m, by(folioviv foliohog)
save "$bases/gasto_fin`time'.dta", replace

* Merging bases to adequately get expenses per income decil FOLLOWING R-ENIGH methodology
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
merge m:1 folioviv foliohog using "$bases/gasto_fin`time'.dta", keepusing(*_m)
keep if _merge == 3
drop _merge
merge m:1 folioviv foliohog using "$datosenigh/concentradohogar`time'.dta", keepusing(ali_dentro)
keep if _merge == 3
gen hogar = (folioviv + foliohog)

gen hogares = 1
gen ingmon = ing_cor
gen gastomon = gasto_mon
gen anio = 2000 + `time'
drop _merge
save "$bases/touse.dta", replace

* Collapse per decil
collapse (first) anio (sum) hogares (mean) *_m gastomon* ingmon ali_dentro [fweight=factor], by(deciles_tri)
format gasto* *_m ing* %12.0f
save "$bases/gasto_decil`time'.dta", replace
* Collapse acum per decil
use "$bases/touse.dta", clear
collapse (first) anio (sum) hogares (sum) *_m gastomon* ingmon ali_dentro [fweight=factor], by(deciles_tri)
format gasto* *_m ing* %12.0f
save "$bases/gastoacum_decil`time'.dta", replace

* Merging bases to adequately get national average expenses
use "$datosenigh/concentradohogar`time'.dta", clear
sort folioviv foliohog
merge 1:m folioviv foliohog using "$bases/gasto_fin`time'.dta", keepusing(*_m)
gen hogar = (folioviv + foliohog)

gen hogares = 1
gen ingmon = ing_cor
gen gastomon = gasto_mon
drop _merge

gen anio = 2000 + `time'

save "$bases/touse.dta", replace

* Collapse national
collapse (first) anio (sum) hogares (mean) *_m gastomon* ingmon ali_dentro [fweight=factor]
format gasto* *_m ing* %12.0f
save "$bases/gasto_`time'.dta", replace
* Collapse national
use "$bases/touse.dta", clear
collapse (first) anio (sum) hogares (sum) *_m gastomon* ingmon ali_dentro [fweight=factor]
format gasto* *_m ing* %12.0f
save "$bases/gastoac_`time'.dta", replace

*erase "$bases/touse.dta"
local time = `time' + 2
}

****************************** I. Specific expenses per household per decil ONLY 2024
****************************** (monetary quaterly estimation non deflacted) Rdata
local time=24
while `time' <= 24 {

use "$datosenigh/gastoshogar`time'.dta", clear
gen base=1
append using "$datosenigh/gastospersona`time'.dta"
recode base (.=2)

compress

replace frecuencia=frec_rem if base==2

label var base "Origen del monto"
label define base 1 "Monto del hogar", modify
label define base 2 "Monto de personas", modify
label value base base

* Expenses variables (monthly construction)
replace gasto_tri=gasto_tri

* Drop expenses from self-consumption & expense imputation from rent
drop if tipo_gasto=="G3" | tipo_gasto=="G7" 

************************************* Separate specific expenses
** Short-term expenses NOT FOOD
* Non alcoholic drinks
local varlist "012501	012902	012502	181162	012901	181170	012100	012905	012601	012602	012603	012604	012903	012904	012400	011862	012907 072221 072222 072230 072210 073211 073212 073290 181211 073222 073213 074911 074912 091242 072440 073215 073221 011512 011111 011131 011112 011228 011221 181117 011224 181124 181125 01122F 011743 011723 011724 011725 011726 011761 011481 011727 011411 011420 011412 011621 011633 011622 011751 011134 011150 011810 011323 011748 011322 131208 13120L 13120M 083301 083401 083403 083405 083404 081200 083201 083202 081311 081312 081313 081321 023010 023020 023090 021101	021301	021302	021303	181146	181151	181147	181148	181154	021102	181149	021220	021103	021211	021213	181150	021104	021212	021901	021902	021105 096101 094630 094700 094622 094624 094625 083923 094312 094613 094615 094616 096104 096105 096201 096903 096202 097191 097192 097193 097194 097210 097220 081502 081503 095201 095202 095204 095205 095206 083921 083922 097301 097302 097401 097402 097403 097404 097405 097406 097407 111111 111112 111113 111114 111115 111116 071110 071120 071200 072110 072122 072121 072133 072131 072132 072301 072305 072304 072308 072307 072309 041103 041211 173511 061118 061119 06111A 06111B 06111C 06111D 06111E 06111G 06111H 06111I 061111 061112 061113 061114 061115 061116 061117 06111K 06111L 06111F 06111J 061211 061212 061221 061222 061223 061230 061120 061311 061312 061320 061332 061333 061331 061334 061335 061336 061337 061338 061401 061402 045222 045300 045410 045420 045430 045490 045502 05619A 045100 045210 045221"
foreach x of local varlist {
gen g`x'_m=gasto_tri if clave == "`x'"
}
			
collapse (sum) *_m, by(folioviv foliohog)
save "$bases/gasto_fin`time'.dta", replace

* Merging bases to adequately get expenses per income decil FOLLOWING R-ENIGH methodology
import excel "$datosenigh/D_R_2024.xlsx", sheet("Deciles_R_2024") firstrow clear

tostring folioviv foliohog, replace
sort folioviv foliohog
rename DECIL deciles_tri
merge m:1 folioviv foliohog using "$bases/gasto_fin`time'.dta", keepusing(*_m)
keep if _merge == 3
drop _merge
merge m:1 folioviv foliohog using "$datosenigh/concentradohogar`time'.dta", keepusing(ali_dentro)
keep if _merge == 3
gen hogar = (folioviv + foliohog)

gen hogares = 1
gen ingmon = ing_cor
gen gastomon = gasto_mon
gen anio = 2000 + `time'
drop _merge
save "$bases/touse.dta", replace

* Collapse per decil
collapse (first) anio (sum) hogares (mean) *_m gastomon* ingmon ali_dentro [fweight=factor], by(deciles_tri)
format gasto* *_m ing* %12.0f
save "$bases/gasto_decil`time'.dta", replace
* Collapse acum per decil
use "$bases/touse.dta", clear
collapse (first) anio (sum) hogares (sum) *_m gastomon* ingmon ali_dentro [fweight=factor], by(deciles_tri)
format gasto* *_m ing* %12.0f
save "$bases/gastoacum_decil`time'.dta", replace

* Merging bases to adequately get national average expenses
use "$datosenigh/concentradohogar`time'.dta", clear
sort folioviv foliohog
merge 1:m folioviv foliohog using "$bases/gasto_fin`time'.dta", keepusing(*_m)
gen hogar = (folioviv + foliohog)

gen hogares = 1
gen ingmon = ing_cor
gen gastomon = gasto_mon
drop _merge

gen anio = 2000 + `time'

save "$bases/touse.dta", replace

* Collapse national
collapse (first) anio (sum) hogares (mean) *_m gastomon* ingmon ali_dentro [fweight=factor]
format gasto* *_m ing* %12.0f
save "$bases/gasto_`time'.dta", replace
* Collapse national
use "$bases/touse.dta", clear
collapse (first) anio (sum) hogares (sum) *_m gastomon* ingmon ali_dentro [fweight=factor]
format gasto* *_m ing* %12.0f
save "$bases/gastoac_`time'.dta", replace

*erase "$bases/touse.dta"
local time = `time' + 2
}


** Deciles R export
use "$bases/gasto_decil16.dta", clear
local time=18
while `time' <= 22 {
append using "$bases/gasto_decil`time'.dta"
destring deciles*, replace
sort anio deciles*
local time = `time' + 2
}
export excel "$bases/Gastos-ENIGH-24Extendido.xlsx", sheet(Deciles_mean) firstrow(variables) sheetmodify
use "$bases/gasto_decil24.dta", clear
destring deciles*, replace
sort anio deciles*
export excel "$bases/Gastos-ENIGH-24Extendido.xlsx", sheet(Deciles_mean24) firstrow(variables) sheetmodify

** Nationalusual export
use "$bases/gasto_16.dta", clear
local time=18
while `time' <= 22 {
append using "$bases/gasto_`time'.dta"
sort anio
local time = `time' + 2
}
export excel "$bases/Gastos-ENIGH-24Extendido.xlsx", sheet(Nal_mean) firstrow(variables) sheetmodify
use "$bases/gasto_24.dta", clear
export excel "$bases/Gastos-ENIGH-24Extendido.xlsx", sheet(Nal_mean24) firstrow(variables) sheetmodify

** Deciles R export
use "$bases/gastoacum_decil16.dta", clear
local time=18
while `time' <= 22 {
append using "$bases/gastoacum_decil`time'.dta"
destring deciles*, replace
sort anio
local time = `time' + 2
}
export excel "$bases/Gastos-ENIGH-24Extendido.xlsx", sheet(Deciles_acum) firstrow(variables) sheetmodify
use "$bases/gastoacum_decil24.dta", clear
destring deciles*, replace
sort anio
export excel "$bases/Gastos-ENIGH-24Extendido.xlsx", sheet(Deciles_acum24) firstrow(variables) sheetmodify

** Nationalusual export
use "$bases/gastoac_16.dta", clear
local time=18
while `time' <= 22 {
append using "$bases/gastoac_`time'.dta"
sort anio
local time = `time' + 2
}
export excel "$bases/Gastos-ENIGH-24Extendido.xlsx", sheet(Nal_acum) firstrow(variables) sheetmodify
use "$bases/gastoac_24.dta", clear
export excel "$bases/Gastos-ENIGH-24Extendido.xlsx", sheet(Nal_acum24) firstrow(variables) sheetmodify


local time=16
while `time' <= 24 {
erase  "$bases/gasto_`time'.dta"
erase  "$bases/gastoac_`time'.dta"
erase  "$bases/gastoacum_decil`time'.dta"
erase  "$bases/gasto_decil`time'.dta"
erase  "$bases/gasto_fin`time'.dta"
local time = `time' + 2
}
erase  "$bases/touse.dta"


/*
To comments on the present do file please contact the editor:
   Diana L. Jimenez M. dianaljm@infinitum.com.mx
