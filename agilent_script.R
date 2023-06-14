#this is a R script for agilent data analysis for GSE44447
#agilent data analysis
#set your working path 
setwd("C:/Users/ADMIN/Dropbox/PC/Desktop/projects/GSE44447")

#download GEOquery package to retrive datasets from geo database
install.packages("GEOquery")

#package to do extract expression data from Agilent sequenced microarray data and to do Differential expression analysis
install.packages("limma") 

#call the installed packages
library(limma) 
library(GEOquery) 
library(R.utils)

#download the completedataset of the study from GEO database.
getGEOSuppFiles("GSE44447") 

##untar and make sure all your samples are available and remove remainaning samples####
setwd("C:/Users/ADMIN/Dropbox/PC/Desktop/projects/GSE44447/data_GSE44447")
untar("GSE44447/GSE44447_RAW.tar", exdir="data_GSE44447")
files <- list.files("data_GSE44447/", pattern = "[gz]")
sapply(paste("data_GSE44447", files, sep="/"), gunzip)
setwd("C:/Users/ADMIN/Dropbox/PC/Desktop/projects/GSE44447/data_GSE44447")
dat=read.maimages(files=dir(), source="agilent", green.only=TRUE)

#extract expression data from all your sample files in your current directory
raw_BGcorrected =backgroundCorrect(dat, "normexp", offset=50) # normalize the expression across the samples

#Then normalize and log-transformed the data. 
raw_BGandNormalized = normalizeBetweenArrays(raw_BGcorrected,method="quantile")
write.csv( raw_BGandNormalized, file="norm.csv")

#Finally calculate the average intensity values from the probes of each gene.   
raw_aver <- avereps(raw_BGandNormalized,ID=raw_BGandNormalized$genes$ProbeName)
write.csv(raw_aver,file="avg_intensity.csv")

##### Differential Expression Analysis ############
setwd("C:/Users/ADMIN/Dropbox/PC/Desktop/projects/GSE44447/data_GSE44447")

##load package ##
library(limma)

##read phenotypefile ## ## defines the categories in the data ##
pheno =read.table("pheno_file.txt",row.names=1)
colnames(pheno) <- pheno[1, ]
pheno<-pheno[-1, ]
pheno

## load the expression file ##
data<- raw_aver

## prepare a design matrix ##
d.levels = unique(pheno$target)
d.factor = factor(pheno$target, levels=d.levels)
d.design = model.matrix(~0 + d.factor)
colnames(d.design) = levels(d.factor)

## fit the linear model ##
fit = lmFit(data,d.design)  ### make sure your colnames in data and rownames in design are same and equal#####
contrast.matrix <- makeContrasts(tumor = tumor - normal, levels=d.design)
contrast.matrix
tumor_fits <- contrasts.fit(fit, contrast.matrix)
tumor_ebFit <- eBayes(tumor_fits)
topTable(tumor_ebFit, number=1000, coef=1)
nrow(topTable(tumor_ebFit, coef=1, number=10000000000, lfc=1))  

## perform the statistical Analysis ##
#fit = eBayes(fit)
## report the top 20 Differentially Expressed genes ##
x<-topTable(fit,number=20,coef =2)

## write the Differentially Expressed genes to the output file ## 
write.csv(x,file="result_deg.csv",sep="\t")



