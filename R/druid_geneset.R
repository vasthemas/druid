#' DRUID geneset
#'
#' This function generates the query gene set that is to be used as input into DRUID.
#'
#' @param dge_matrix This is a 2 column matrix for gene expression changes, where column 1 is the gene fold change and column 2 is the corresponding p-value for the fold change. NOTE: Use log2 of the fold changes as output, for example, from `limma` or `DESeq2`.
#' @param desired_effect Desired effect for DRUID to run on: "pos" mimics query phenotype, "neg" reverts query phenotype. Defaults to "neg".
#' @param fold_thr Threshold for the fold change to be considered. Defaults to 0 (i.e., log2(1), where fold change is not used as filter)
#' @param pvalue_thr Threshold for the p-value of the fold change to be considered. Defaults to 0.05.
#' @param entrez EntrezIDs for genes in differentially expressed set. Must be same order as the input matrix.
#' @param gene_space EntrezIDs from TF.IDF matrix (column names of this matrix).
#' @return A gene set to be used as input in DRUID as a Nx4 matrix.
druid_geneset <- function(dge_matrix, 
                          desired_effect = c("pos", "neg"), 
                          fold_thr, 
                          pvalue_thr, 
                          entrez, 
                          gene_space)
{
  if(ncol(dge_matrix) != 2) stop("Differential expression data needs to be Nx2 matrix.")
  if(missing(desired_effect)) desired_effect <- "neg"
  if(missing(fold_thr)) fold_thr <- 0
  if(missing(pvalue_thr)) pvalue_thr <- 0.05
  if(missing(entrez)) stop("Need EntrezID of genes in data.")
  
  query_vector <- integer(length = length(gene_space))
  
  if(desired_effect == "neg")
  {
    dge_matrix[, 1] <- -1 * dge_matrix[, 1]
  }

  up_genes <- which(dge_matrix[, 1] > 0)
  down_genes <- which(dge_matrix[, 1] < 0)
  gs_dir <- character(length = nrow(dge_matrix))
  gs_dir[up_genes] <- "up"
  gs_dir[down_genes] <- "down"
  gs_eff <- paste(entrez, gs_dir) # <--- entrez with direction
  
  # check differential expression ----
  b1 <- which(abs(dge_matrix[, 1]) > fold_thr)
  b2 <- which(dge_matrix[, 2] < pvalue_thr)
  
  if (length(b1) != 0 & length(b2) != 0) { # <-- there are differentially expressed genes
    x1 <- intersect(b1, b2)
    x2 <- gs_eff[x1]
    query_vector[which(gene_space %in% x2)] <- 1
  } else if (length(b1) != 0 & length(b2) == 0) { # <-- fold but no p-value
    pvalue_thr <- 0.05
    b2 <- which(dge_matrix[, 2] < pvalue_thr)
    x1 <- intersect(b1, b2)
    if(length(x1) == 0) {
      message("No differentially expressed genes.")
    } else {
      message("q-value threshold yielded no statistically significant genes. Changing threshold to 0.05.")
      x2 <- gs_eff[x1]
      query_vector[which(gene_space %in% x2)] <- 1
    }
  } else if (length(b1) == 0 & length(b2) != 0) {
    fold_thr <- 0
    b1 <- which(abs(dge_matrix[, 1]) > fold_thr)
    x1 <- intersect(b1, b2)
    if (length(x1) == 0) {
      message("No differentially expressed genes.")
    } else {
      message("Fold-change threshold yielded no statistically significant genes. Changing threshold to 0.")
      x2 <- gs_eff[x1]
      query_vector[which(gene_space %in% x2)] <- 1
    }
  } else if (length(b1) == 0 & length(b2) == 0) {
    message("No differentially expressed genes.")
  }
  
  # if(length(b2) == 0) {
  #   message("No differentially expressed genes at this p-value threshold.")
  # } 
  
  # if(length(b1) == 0 & fold_thr != 0) {
  #   message("Fold threshold yielded no differentially expressed genes. Setting threshold to 0.")
  #   b1 <- which(abs(dge_matrix[, 1]) != 0)
  # }
  
  # x1 <- intersect(b1, b2)
  # if (length(x1) == 0) {
  #   message("No differentially expressed genes.")
  #   } else {
  #     x2 <- gs_eff[x1]
  #    query_vector[which(gene_space %in% x2)] <- 1
  #   }
   
  qsize <- sum(query_vector)
  if(qsize == 0) message("No genes macthed in drug profiles.")
  
  return(query_vector)
}
