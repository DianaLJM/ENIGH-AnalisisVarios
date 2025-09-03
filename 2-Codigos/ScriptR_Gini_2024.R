# DO FILE. CUADRO 2.1 TABULADOS B?SICOS
## Limpia la pantalla de tablas o basura de un ejercicio anterior
rm(list = ls())
## Carga librerías
library(foreign)
library(doBy)
library(reldist)
## Cuadro de sección 2 tabulados básicos ENIGH 2024
## Establece el directorio donde se encuentra la base de datos
setwd("D:/diana_jimenez/Documents/DATOS/ENIGH/Pobreza")

## Abre la tabla concentradohogar
Conc<- read.dbf("concentradohogar24.dbf",as.is = T)
## Selecciona las variables de interés
Conc <- Conc [ c("folioviv", "foliohog", "ing_cor", "ingtrab", "trabajo", "negocio",
                  "otros_trab", "rentas", "utilidad", "arrenda", "transfer", "jubilacion",
                  "becas", "donativos", "remesas", "bene_gob", "transf_hog", "trans_inst",
                  "estim_alqu", "otros_ing", "factor", "upm", "est_dis")]
## Se define la columna de los deciles
Numdec<-c("Total", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X")
## Hogares
## Se crea una bandera para numerar los hogares
Conc$Nhog <- 1
## Deciles de hogares
## Deja activa la tabla Conc
attach(Conc)

## Ordena Conc de acuerdo a ing_cor, folioviv, foliohog
Conc<- orderBy (~+ing_cor+folioviv+foliohog, data=Conc)
## Suma todos los factores y guarda el valor en el vector tot_hogares
tot_hogares <- sum(factor)
## Se divide la suma de factores entre diez para sacar el tamaño del decil
## (se debe de truncar el resultado quitando los decimales)
tam_dec<-trunc(tot_hogares/10)
## Muestra la suma del factor en variable hogar
Conc$tam_dec=tam_dec
## Creación de deciles de hogares
## Se renombra la tabla concentrado a BD1
BD1 <- Conc
## Dentro de la tabla BD1 se crea la variable MAXT y se le asignan los
## valores que tiene el ing_cor.
BD1$MAXT <- BD1$ing_cor
## Se ordena de menor a mayor según la variable MAXT
BD1 <- BD1[with(BD1, order(rank(MAXT))),]
## Se aplica la función cumsum, suma acumulada a la variable factor
BD1$ACUMULA <- cumsum(BD1$factor)
## Entra a un ciclo donde genera los deciles 1 a 10
for(i in 1:9)
{
  a1<-BD1[dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1,]$factor
  BD1<-rbind(BD1[1:(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1),],
             BD1[(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1):dim(BD1[1])[1],])
  b1<-tam_dec*i-BD1[dim(BD1[BD1$ACUMULA<tam_dec*i,])[1],]$ACUMULA
  BD1[(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1),]$factor<-b1
  BD1[(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+2),]$factor<-(a1-b1)
}
BD1$ACUMULA2<-cumsum(BD1$factor)
BD1$DECIL <- 0
BD1[(BD1$ACUMULA2<=tam_dec),]$DECIL <- 1
for(i in 1:9)
{
  BD1[((BD1$ACUMULA2>tam_dec*i)&(BD1$ACUMULA2<=tam_dec*(i+1))),]$DECIL <- (i+1)
}
#BD1[BD1$DECIL%in%"0",]$DECIL <- 10

## Total de hogares
x <- tapply(BD1$factor,BD1$Nhog,sum)

## Deciles
y <- tapply(BD1$factor,BD1$DECIL,sum)
## Se calcula el promedio de ingreso para el total y para cada uno de los deciles
ing_cormed_t <- tapply(BD1$factor*BD1$ing_cor,BD1$Nhog,sum)/x
ing_cormed_d <- tapply(BD1$factor*BD1$ing_cor,BD1$DECIL,sum)/y
## Cuadros
## Guarda los resultados en un data frame
prom_rub <- data.frame (c(ing_cormed_t,ing_cormed_d))
## Agrega el nombre a las filas
row.names(prom_rub) <- Numdec
## Cálculo del coeficiente de GINI
deciles_hog_ingcor <- data.frame(hogaresxdecil=c(x,x,x,x,x,x,x,x,x,x),
                                 ingreso=c(ing_cormed_d[1],ing_cormed_d[2],
                                           ing_cormed_d[3],ing_cormed_d[4],
                                           ing_cormed_d[5],ing_cormed_d[6],
                                           ing_cormed_d[7],ing_cormed_d[8],
                                           ing_cormed_d[9],ing_cormed_d[10]))
## Se efectúa la función GINI y se guarda en el vector
a<-gini(deciles_hog_ingcor$ingreso,weights=deciles_hog_ingcor$hogares)
## Se renombran las variables (columnas)
names(prom_rub) <- c("INGRESO CORRIENTE")
names(a) <- "GINI"
## Muestra el resultado en pantalla
round(prom_rub)
round(a,3)

##### Alternativa sin beneficios de gob ####
## Abre la tabla concentradohogar
Conc<- read.dbf("concentradohogar24.dbf",as.is = T)
## Selecciona las variables de interés
Conc <- Conc [ c("folioviv", "foliohog", "ing_cor", "ingtrab", "trabajo", "negocio",
                 "otros_trab", "rentas", "utilidad", "arrenda", "transfer", "jubilacion",
                 "becas", "donativos", "remesas", "bene_gob", "transf_hog", "trans_inst",
                 "estim_alqu", "otros_ing", "factor", "upm", "est_dis")]
## Se define la columna de los deciles
Numdec<-c("Total", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X")
## Hogares
## Se crea una bandera para numerar los hogares
Conc$Nhog <- 1
## Deciles de hogares
## Deja activa la tabla Conc
attach(Conc)

# Alternativa
Conc$ing_alt<- Conc$ing_cor - Conc$bene_gob

## Ordena Conc de acuerdo a ing_cor, folioviv, foliohog
Conc<- orderBy (~+ing_alt+folioviv+foliohog, data=Conc)
## Suma todos los factores y guarda el valor en el vector tot_hogares
tot_hogares <- sum(factor)
## Se divide la suma de factores entre diez para sacar el tamaño del decil
## (se debe de truncar el resultado quitando los decimales)
tam_dec<-trunc(tot_hogares/10)
## Muestra la suma del factor en variable hogar
Conc$tam_dec=tam_dec
## Creación de deciles de hogares
## Se renombra la tabla concentrado a BD1
BD1 <- Conc
## Dentro de la tabla BD1 se crea la variable MAXT y se le asignan los
## valores que tiene el ing_cor.
BD1$MAXT <- BD1$ing_alt
## Se ordena de menor a mayor según la variable MAXT
BD1 <- BD1[with(BD1, order(rank(MAXT))),]
## Se aplica la función cumsum, suma acumulada a la variable factor
BD1$ACUMULA <- cumsum(BD1$factor)
## Entra a un ciclo donde genera los deciles 1 a 10
for(i in 1:9)
{
  a1<-BD1[dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1,]$factor
  BD1<-rbind(BD1[1:(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1),],
             BD1[(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1):dim(BD1[1])[1],])
  b1<-tam_dec*i-BD1[dim(BD1[BD1$ACUMULA<tam_dec*i,])[1],]$ACUMULA
  BD1[(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1),]$factor<-b1
  BD1[(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+2),]$factor<-(a1-b1)
}
BD1$ACUMULA2<-cumsum(BD1$factor)
BD1$DECIL <- 0
BD1[(BD1$ACUMULA2<=tam_dec),]$DECIL <- 1
for(i in 1:9)
{
  BD1[((BD1$ACUMULA2>tam_dec*i)&(BD1$ACUMULA2<=tam_dec*(i+1))),]$DECIL <- (i+1)
}
#BD1[BD1$DECIL%in%"0",]$DECIL <- 10

## Total de hogares
x <- tapply(BD1$factor,BD1$Nhog,sum)

## Deciles
y <- tapply(BD1$factor,BD1$DECIL,sum)
## Se calcula el promedio de ingreso para el total y para cada uno de los deciles
ing_cormed_t <- tapply(BD1$factor*BD1$ing_alt,BD1$Nhog,sum)/x
ing_cormed_d <- tapply(BD1$factor*BD1$ing_alt,BD1$DECIL,sum)/y
## Cuadros
## Guarda los resultados en un data frame
prom_rub <- data.frame (c(ing_cormed_t,ing_cormed_d))
## Agrega el nombre a las filas
row.names(prom_rub) <- Numdec
## Cálculo del coeficiente de GINI
deciles_hog_ingcor <- data.frame(hogaresxdecil=c(x,x,x,x,x,x,x,x,x,x),
                                 ingreso=c(ing_cormed_d[1],ing_cormed_d[2],
                                           ing_cormed_d[3],ing_cormed_d[4],
                                           ing_cormed_d[5],ing_cormed_d[6],
                                           ing_cormed_d[7],ing_cormed_d[8],
                                           ing_cormed_d[9],ing_cormed_d[10]))
## Se efectúa la función GINI y se guarda en el vector
a<-gini(deciles_hog_ingcor$ingreso,weights=deciles_hog_ingcor$hogares)
## Se renombran las variables (columnas)
names(prom_rub) <- c("INGRESO CORRIENTE")
names(a) <- "GINI"
## Muestra el resultado en pantalla
round(prom_rub)
round(a,3)

##### Alternativa sin transferencias a hogares ####
## Abre la tabla concentradohogar
Conc<- read.dbf("concentradohogar24.dbf",as.is = T)
## Selecciona las variables de interés
Conc <- Conc [ c("folioviv", "foliohog", "ing_cor", "ingtrab", "trabajo", "negocio",
                 "otros_trab", "rentas", "utilidad", "arrenda", "transfer", "jubilacion",
                 "becas", "donativos", "remesas", "bene_gob", "transf_hog", "trans_inst",
                 "estim_alqu", "otros_ing", "factor", "upm", "est_dis")]
## Se define la columna de los deciles
Numdec<-c("Total", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X")
## Hogares
## Se crea una bandera para numerar los hogares
Conc$Nhog <- 1
## Deciles de hogares
## Deja activa la tabla Conc
attach(Conc)

# Alternativa
Conc$ing_alt<- Conc$ing_cor - Conc$transfer

## Ordena Conc de acuerdo a ing_cor, folioviv, foliohog
Conc<- orderBy (~+ing_alt+folioviv+foliohog, data=Conc)
## Suma todos los factores y guarda el valor en el vector tot_hogares
tot_hogares <- sum(factor)
## Se divide la suma de factores entre diez para sacar el tamaño del decil
## (se debe de truncar el resultado quitando los decimales)
tam_dec<-trunc(tot_hogares/10)
## Muestra la suma del factor en variable hogar
Conc$tam_dec=tam_dec
## Creación de deciles de hogares
## Se renombra la tabla concentrado a BD1
BD1 <- Conc
## Dentro de la tabla BD1 se crea la variable MAXT y se le asignan los
## valores que tiene el ing_cor.
BD1$MAXT <- BD1$ing_alt
## Se ordena de menor a mayor según la variable MAXT
BD1 <- BD1[with(BD1, order(rank(MAXT))),]
## Se aplica la función cumsum, suma acumulada a la variable factor
BD1$ACUMULA <- cumsum(BD1$factor)
## Entra a un ciclo donde genera los deciles 1 a 10
for(i in 1:9)
{
  a1<-BD1[dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1,]$factor
  BD1<-rbind(BD1[1:(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1),],
             BD1[(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1):dim(BD1[1])[1],])
  b1<-tam_dec*i-BD1[dim(BD1[BD1$ACUMULA<tam_dec*i,])[1],]$ACUMULA
  BD1[(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+1),]$factor<-b1
  BD1[(dim(BD1[BD1$ACUMULA<tam_dec*i,])[1]+2),]$factor<-(a1-b1)
}
BD1$ACUMULA2<-cumsum(BD1$factor)
BD1$DECIL <- 0
BD1[(BD1$ACUMULA2<=tam_dec),]$DECIL <- 1
for(i in 1:9)
{
  BD1[((BD1$ACUMULA2>tam_dec*i)&(BD1$ACUMULA2<=tam_dec*(i+1))),]$DECIL <- (i+1)
}
#BD1[BD1$DECIL%in%"0",]$DECIL <- 10

## Total de hogares
x <- tapply(BD1$factor,BD1$Nhog,sum)

## Deciles
y <- tapply(BD1$factor,BD1$DECIL,sum)
## Se calcula el promedio de ingreso para el total y para cada uno de los deciles
ing_cormed_t <- tapply(BD1$factor*BD1$ing_alt,BD1$Nhog,sum)/x
ing_cormed_d <- tapply(BD1$factor*BD1$ing_alt,BD1$DECIL,sum)/y
## Cuadros
## Guarda los resultados en un data frame
prom_rub <- data.frame (c(ing_cormed_t,ing_cormed_d))
## Agrega el nombre a las filas
row.names(prom_rub) <- Numdec
## Cálculo del coeficiente de GINI
deciles_hog_ingcor <- data.frame(hogaresxdecil=c(x,x,x,x,x,x,x,x,x,x),
                                 ingreso=c(ing_cormed_d[1],ing_cormed_d[2],
                                           ing_cormed_d[3],ing_cormed_d[4],
                                           ing_cormed_d[5],ing_cormed_d[6],
                                           ing_cormed_d[7],ing_cormed_d[8],
                                           ing_cormed_d[9],ing_cormed_d[10]))
## Se efectúa la función GINI y se guarda en el vector
a<-gini(deciles_hog_ingcor$ingreso,weights=deciles_hog_ingcor$hogares)
## Se renombran las variables (columnas)
names(prom_rub) <- c("INGRESO CORRIENTE")
names(a) <- "GINI"
## Muestra el resultado en pantalla
round(prom_rub)
round(a,3)
