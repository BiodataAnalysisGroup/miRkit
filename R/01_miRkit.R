

# A script working as a wrapper for executing miRkit' pipeline:
#
# 1. Quality control
# 2. Differential analysis
# 3. Functional analysis
#

# clear #############
# cat("\014")
# rm(list = ls())
# dev.off(dev.list()["RStudioGD"])
getwd()
analysis.path=getwd()  ;analysis.path
#analysis.path <- "D://exosomes//data" 

#setwd(analysis.path)
getwd()

# Source files
# qc.R : quality control
# diff_analysis.R : differential analysis
# fa.R : functional analysis
source("02a_qc.R")
source("02b_diff_analysis.R")
source("02c_fa.R")
source("03a_save_as_pdf.R")
source("03b_save_image.R")

# Libraries
library(data.table)
library(tidyverse)
library(naniar)
library(gsubfn)
library(yaml)
library(ComplexHeatmap)
library(multiMiR)
library(enrichR)
library(limma)
library(lubridate)

# Memory
gc1 <- gc(reset = TRUE)

################# SETTING UP OUTPUT DIRECTORIES AND REPORT FILE ################
# Creating output folders
output_dir <- paste(dirname(getwd()), "/output", sep = '')
diff_analysis_directory <- paste(output_dir,"/Differential Analysis", sep = '')
fa_directory <- paste(output_dir,"/Functional Analysis", sep = '')
tables_directory <- paste(output_dir,"/Tables", sep = '')

dir.create(output_dir)
dir.create(diff_analysis_directory)
dir.create(fa_directory)
dir.create(tables_directory)

# Creating the report file
report_file <- paste(output_dir, '/report.txt',sep = '')
file.create(report_file)


############## LOADING INPUTS FROM YAML FILE ###################################
inputfolder <- paste(dirname(getwd()), "/data/", sep = '')
yaml_path <- paste(inputfolder, 'input.yml', sep = '')
input_parameters <- read_yaml(yaml_path)

# Num of plates
plates <- input_parameters$plates
for (plate in plates){
  to_create <- paste(output_dir,'/plate', plate, sep = '')
  dir.create(to_create)
}

# Threshold percentage (values: from 0 to 1)
# In case the percentage of NA's is higher than threshold, the sample is excluded
na_threshold_perc <- input_parameters$na_threshold
to_report <- paste('Selected NAs percentage threshold: ', na_threshold_perc, sep = '')
cat(to_report, file = report_file, sep = '\n', append = TRUE)

# RTC criterion threshold: THIS IS STANDARD
rtc_threshold <- 5
to_report <- paste('Standard RTC threshold: ', rtc_threshold, sep = '')
cat(to_report, file = report_file, sep = '\n', append = TRUE)

# Select endogenous or exogenous normalization
normalization_en_ex <- input_parameters$normalization_en_ex

# Select sign.f.table p-val criterion
sign_table_pval <- input_parameters$sign_table_pval

# Mirs: select validated or predicted
validated_or_predicted <- input_parameters$validated_or_predicted

# select go_enrich criterion
go_criterion <- input_parameters$go_criterion

# select the KEGG enrich criterion
kegg_enrich_criterion <- input_parameters$kegg_enrich_criterion


######################### MAIN CODE ############################################

list.files()

mirs<- fread(paste(inputfolder, "/miRs_annotation_3plates.csv", sep = ''))
data<- fread(paste(inputfolder, "/miRNome_data.csv", sep = ''))
meta<- fread(paste(inputfolder, "/phenodata.csv", sep = ''))

head(meta)

data<- setDF(data)
data$ID<- mirs$`miRNA ID`
data$plate<- mirs$Plate
head(data)

# Substitutes the ',' charachter with '.' and then converts strings to numeric data
# 2 stands for "iterate over columns"
data[,c(2:7)]<- apply(apply(data[,c(2:7)], 2, gsub, patt=",", replace="."), 2, as.numeric)

# Drop data with "blank" ID
data <- data[c(which(data$ID != "blank")), ]

#TO DO: merge the three plates before the diff analysis
# Initial sample names
normalized_data <- NULL

# Time start
start_time <- proc.time()
total_start_time <- start_time

# QC analysis

for (plate in plates){
  print(paste('Analysis for plate ', plate, sep = ''))
  norm_data <- QC(data, plate, output_dir, na_threshold_perc, rtc_threshold ,normalization_en_ex, report_file)
  norm_data$plate <- paste('Plate', plate, sep = ' ')
  
  if (is.null(normalized_data)){
    normalized_data <- rbind(normalized_data, norm_data)
    
  } else {
    normalized_data <- normalized_data[,which(colnames(normalized_data) %in% colnames(norm_data))]
    norm_data <- norm_data[,which(colnames(norm_data) %in% colnames(normalized_data))]
    normalized_data <- rbind(normalized_data, norm_data)
  }
}

qc_time_secs <- proc.time() - start_time
qc_time_secs <- qc_time_secs[3]
qc_time_secs <- as.character(seconds_to_period(qc_time_secs))


if (!is.null(normalized_data)){
  
  # Some samples(rows) may have the same IDS
  # In these IDs we assign the information of their index in their names, in order to distinguish them.
  indices_duplicated <- which(duplicated(normalized_data$ID))
  normalized_data$ID[indices_duplicated] <- paste(normalized_data$ID[indices_duplicated], ' - index ', indices_duplicated, sep = '') 
  
  # Saving normalized_data to csv
  fwrite(normalized_data, paste(tables_directory, '/normalized_data.csv', sep = ''))
  
  # diff analysis 
  start_time <- proc.time()
  sign.table.f <- diff_analysis(normalized_data[,-dim(normalized_data)[2]], meta, diff_analysis_directory, tables_directory, sign_table_pval)
  da_time_secs <- proc.time() - start_time
  da_time_secs <- da_time_secs[3]
  da_time_secs <- as.character(seconds_to_period(da_time_secs))
  
  # functional analysis
  start_time <- proc.time()
  functional_analysis(sign.table.f, validated_or_predicted, kegg_enrich_criterion, go_criterion, fa_directory, tables_directory)
  fa_time_secs <- proc.time() - start_time
  fa_time_secs <- fa_time_secs[3]
  fa_time_secs <- as.character(seconds_to_period(fa_time_secs))
  
  } else{
  # Todo: add some warnings - tasks here
  print("All plates were rejected from quality control analysis")
}

total_end_time <- proc.time()
total_time_secs <- total_end_time - total_start_time
total_time_secs <- total_time_secs[3]
total_time_secs <- as.character(seconds_to_period(total_time_secs))


# Saving execution time to report
to_report <- "\nExecution time:"
cat(to_report, file = report_file, sep = '\n', append = TRUE)

to_report <- paste("Total execution time: ", total_time_secs, sep = '')
cat(to_report, file = report_file, sep = '\n', append = TRUE)

to_report <- paste("QC execution time: ", qc_time_secs, sep = '')
cat(to_report, file = report_file, sep = '\n', append = TRUE)

to_report <- paste("Differential analysis execution time: ", da_time_secs, sep = '')
cat(to_report, file = report_file, sep = '\n', append = TRUE)

to_report <- paste("Functional analysis execution time: ", fa_time_secs, sep = '')
cat(to_report, file = report_file, sep = '\n', append = TRUE)

# Memory
gc2 <- gc()
cat(sprintf("Max memory used: %.1fMb.\n", sum(gc2[,6] - gc1[,2])))

to_report <- paste("\nMax memory used:", sum(gc2[,6] - gc1[,2]), 'Mb', sep = ' ')
cat(to_report, file = report_file, sep = '\n', append = TRUE)

