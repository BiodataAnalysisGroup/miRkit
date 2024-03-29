
# A function for executing differential analysis between the provided samples
#diff_analysis(normalized_data[,-dim(normalized_data)[2]], meta, diff_analysis_directory, tables_directory, sign_table_pval)
diff_analysis <- function(normalized_data, meta, output_dir, tables_dir, sign_table_pval){
  
  
  meta <- meta[which(meta$Sample_ID %in% names(normalized_data)),]
  list<- as.character(meta$Sample_ID)
  dfexp<- setDF(normalized_data[,list])
  rownames(dfexp)<- normalized_data$ID
  
  pheno <- factor(meta$Group)
  groups <- unique(meta$Group)
  
  phenoMat <- model.matrix(~pheno)
  colnames(phenoMat) <- sub("^pheno","",colnames(phenoMat))
  phenoMat;dim(phenoMat)
  
  fit <- lmFit(object = dfexp,design = phenoMat)
  gc()
  set.seed(6)
  fit <- eBayes(fit)
  
  gc()
  degCLLs <- topTable(fit,number =nrow(dfexp),adjust.method = "fdr",sort.by = "p")
  head(degCLLs)
  
  sign.table<- setDF(degCLLs)
  sign.table$ID<- row.names(sign.table)
  sign.table.f<- sign.table[sign.table$adj.P.Val<= sign_table_pval, ] #TO DO: user's selection
  
  ##Heatmap
  data<-setDF(normalized_data)
  head(data)
  #data$ID<- row.names(data)
  
  
  data.all<-merge(data, sign.table.f, by.x = "ID", by.y = "ID")
  n_data_indices <- which(startsWith(toupper(names(data.all)), toupper(groups[1])))
  c_data_indices <- which(startsWith(toupper(names(data.all)), toupper(groups[2])))
  fwrite(data.all, paste(tables_dir, '/data_all.csv',sep = ''))
  

  colnames(data.all)
  heat.data<- data.all[,c(n_data_indices, c_data_indices)]
#  row.names(heat.data)<- data.all$ID
  
  z.mat <- t(scale(t(heat.data), center=TRUE, scale=TRUE))
  head(z.mat)
  
  column_ha3 <- HeatmapAnnotation(Groups = meta$Group, na_col="white")
  
  #png(file=paste(output_dir,'/heatmap.png', sep = ''), width=900, height=600)
  myplot <- Heatmap(as.matrix(z.mat), clustering_distance_columns = "euclidean",
         clustering_method_columns = "complete", 
         top_annotation = column_ha3, row_names_gp = gpar(fontsize = 4), show_row_names = FALSE) #column_km = 2)
  save_as_pdf({print(myplot)}, file.name = paste(output_dir,'/heatmap.pdf', sep = ''), width = 6, height = 4)
  save_image({print(myplot)}, file.name = paste(output_dir,'/heatmap.png', sep = ''))
  #print(h)
  #dev.off()
  
  return(sign.table.f)
}
