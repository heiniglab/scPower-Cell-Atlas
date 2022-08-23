# Dataset: https://cellxgene.cziscience.com/collections/62ef75e4-cbea-454e-a0ce-998ec40223d3
# Small dataset: https://cellxgene.cziscience.com/collections/fbc5881f-1ee3-4ffe-8095-35e15e1a08fc

loadPackages <- function() {
  Packages <- c("DBI", "devtools", "DropletUtils", "HardyWeinberg", "MKmisc",
              "plotly", "pwr", "reshape2", "RPostgreSQL", "RPostgres", "scPower",
              "scuttle", "Seurat", "SeuratData", "SeuratDisk", "shiny", "zeallot")

  suppressPackageStartupMessages(lapply(Packages, library, character.only = TRUE))

  print("Packages are loaded successfully.")
}

# Downsamples the reads for each molecule by the specified "prop",
# using the information in "sample".
# Please see: https://rdrr.io/bioc/DropletUtils/man/downsampleReads.html
# return: a list consisting of downsampled reads, proportions of 0.25, 0.5, 0.75 and complete
subsampleIntoList <- function(counts.subsampled){
  tmp <- list()
  tmp[[length(tmp)+1]] <- counts.subsampled

  for(s in c(0.75,0.5,0.25)){
    subsample <- downsampleMatrix(counts.subsampled, prop = s, bycol = TRUE)
    tmp[[length(tmp)+1]] <- subsample
  }

  tmp <- setNames(tmp, c("complete", "subsampled75", "subsampled50", "subsampled25"))

  print("Subsampling process done successfully.")
  return(tmp)
}

# return: a data frame consisting of:
# matrix titles, number of cells and expressed gene counts
countObservedGenes <- function(counts.subsampled){

  print("Dimensions of each count matrices:")
  print(sapply(counts.subsampled, dim))

  expressed.genes.df <- NULL

  # Iterate over each count matrix
  for(name in names(counts.subsampled)){

    count.matrix <- counts.subsampled[[name]]

    # Create an annotation file (here containing only one cell type, but can be more)
    annot.df <- data.frame(individual = paste0("S", rep(1:14, length.out = ncol(count.matrix))),
                            cell.type = rep("default_ct", ncol(count.matrix)))

    # Reformat count matrix into 3d pseudobulk matrix
    pseudo.bulk <- create.pseudobulk(count.matrix, annot.df)

    # Calculate expressed genes in the pseudobulk matrix
    # threshold of more than 3 counts in more 50% of the individuals
    expressed.genes <- calculate.gene.counts(pseudo.bulk, min.counts=3, perc.indiv=0.5)

    # Get the number of expressed genes
    num.expressed.genes <- nrow(expressed.genes)

    # Save expressed genes
    expressed.genes.df <- rbind(expressed.genes.df,
                                data.frame(matrix = name,
                                           num.cells = ncol(count.matrix),
                                           expressed.genes = num.expressed.genes))
  }

  print("Counting process done successfully.")
  return(expressed.genes.df)
}

# Estimation of negative binomial parameters for each gene
# return: a list with three elements: the normalized mean values,
# the dispersion values and the parameters of the mean-dispersion function fitted from DESeq
negBinomParamEstimation <- function(counts.subsampled) {

  # Data frame with normalized mean values
  norm.mean.values <- NULL

  # Parameter of the mean - dispersion function
  disp.param <- NULL

  for(name in names(counts.subsampled)){
    temp <- nbinom.estimation(counts.subsampled[[name]], sizeFactorMethod = "poscounts")

    # Save the normalized mean values
    norm.mean.values.temp <- temp[[1]]
    norm.mean.values.temp$matrix <- name
    norm.mean.values <- rbind(norm.mean.values, norm.mean.values.temp)

    # Save the parameter of the mean-dispersion function
    disp.param.temp <- temp[[3]]
    disp.param.temp$matrix <- name
    disp.param <- rbind(disp.param, disp.param.temp)
  }

  print("Estimation of negative binomial parameters done successfully.")
  return(list(norm.mean.values, disp.param))
}

# Estimation of a gamma mixed distribution over all means
# return: a data frame consisting of p1, p2, s1, s2, r1 and r2
# p1=emfit@proportions[1]     p2=emfit@proportions[2]
# s1=emfit@models[[2]]@shape  s2=emfit@models[[3]]@shape
# r1=emfit@models[[2]]@rate   r2=emfit@models[[3]]@rate
gammaMixedDistEstimation <- function(norm.mean.values, censor.points) {

  gamma.fits <- NULL

  for(name in unique(norm.mean.values$matrix)){

    # Number of cells per cell type as censoring point
    censoredPoint <- censor.points[name]

    norm.mean.values.temp <- norm.mean.values[norm.mean.values$matrix == name,]
    gamma.fit.temp <- mixed.gamma.estimation(norm.mean.values.temp$mean,
                                             num.genes.kept = 21000,
                                             censoredPoint = censoredPoint)
    gamma.fit.temp$matrix <- name
    gamma.fits <- rbind(gamma.fits, gamma.fit.temp)
  }

  print("Estimation of a gamma mixed distribution done successfully.")
  return(gamma.fits)
}

# Comparison of gamma mixed fits with original means
compareGammaFixedFits <- function(norm.mean.values, gamma.fits){
  g <- visualize.gamma.fits(norm.mean.values$mean[norm.mean.values$matrix == "complete"],
                    gamma.fits[gamma.fits$matrix == "complete",],
                    nGenes = 21000)
  print(g)
}

# Parameterization of the parameters of the gamma fits by the mean UMI counts per cell
# return: umi values (a data frame of mean UMIs for each subsample) and
# gamma linear fits (a data frame of )
parameterizationOfGammaFits <- function(gamma.fits, mean.umi.counts) {

  umi.values <- data.frame(mean.umi = mean.umi.counts, matrix = names(mean.umi.counts))
  
  gamma.fits <- merge(gamma.fits, umi.values, by = "matrix")

  # Convert the gamma fits from the shape-rate parametrization to the mean-sd parametrization
  gamma.fits <- convert.gamma.parameters(gamma.fits)

  # Visualize the linear relationship between gamma parameters and UMI values in plots
  visualizeLinearRelation(gamma.fits)

  # Fit relationship between gamma parameters and UMI values
  gamma.linear.fits <- umi.gamma.relation(gamma.fits)

  print("Parameterization of the gamma fits done successfully.")
  print(gamma.linear.fits)

  return(list(umi.values, gamma.linear.fits))
}

visualizeLinearRelation <- function(gamma.fits) {
  plot.values <- melt(gamma.fits, id.vars = c("matrix", "mean.umi"))
  plot.values <- plot.values[plot.values$variable %in% c("mean1", "mean2", "sd1", "sd2", "p1", "p2"),]
  ggplot(plot.values, aes(x = mean.umi, y = value)) +
        geom_point() +
        geom_line() +
        facet_wrap(~variable, ncol = 2, scales = "free")
}

# Validation of expression probability model
validationOfModel <- function(expressed.genes.df, mapped.reads) {
  #Merge the observed numbers of expressed genes with the read depth
  expressed.genes.df <- merge(expressed.genes.df, mapped.reads, by = "matrix")

  #Get the number of cells per cell type and individual
  expressed.genes.df$cells.indiv <- expressed.genes.df$num.cells / 14
  expressed.genes.df$estimated.genes <- NA

  for(i in 1:nrow(expressed.genes.df)){
    #Vector with the expression probability for each gene
    expr.prob <- estimate.exp.prob.param(nSamples = 14,
                                        readDepth = expressed.genes.df$transcriptome.mapped.reads[i],
                                        nCellsCt = expressed.genes.df$cells.indiv[i],
                                        read.umi.fit = read.umi.fit.new,
                                        gamma.mixed.fits = gamma.linear.fit.new,
                                        ct = "New_ct",
                                        disp.fun.param = disp.fun.general.new,
                                        min.counts = 3,
                                        perc.indiv = 0.5)

    #Expected number of expressed genes
    expressed.genes.df$estimated.genes[i] <- round(sum(expr.prob))
  }

  print("Validation of model done successfully.")
  return(expressed.genes.df)
}

visualizeEstimatedvsExpressedGenes <- function(expressed.genes.df) {
  plot.expressed.genes.df <- reshape2::melt(expressed.genes.df,
                                          id.vars = c("matrix", "num.cells", "cells.indiv", "transcriptome.mapped.reads"))

  ggplot(plot.expressed.genes.df, aes(x = transcriptome.mapped.reads,
                                      y = value,
      color = variable)) +
      geom_point() +
      geom_line()
}

# [cellCount]_[#assays]_[#tissues]_[#cellTypes]: single dataset specific distinguisher
# [assayID]_[tissueID]_[cellTypeID]: result table specific distinguisher
# gammaLinearFits: parameter, intercept, meanUMI)
mergeFinalStatus <- function(cellCount, numberOfAssays, numberOfTissues, numberOfCellTypes, 
                             assayID, tissueID, cellTypeID, gammaLinearFits) {
  
  datasetBodySpecific <- paste(cellCount, numberOfAssays, numberOfTissues, numberOfCellTypes, sep = "_")
  resultTableSpecific <- paste(assayID, tissueID, cellTypeID, sep = "_")

  resultingDataFrame <- data.frame(datasetBodySpecific, resultTableSpecific, gammaLinearFits)

  print("Merging of the finals informations done successfully.")
  return(resultingDataFrame)
}

establishDBConnection <- function() {
  connectionInstance <- dbConnect(
      Postgres(),
      dbname = "todos",
      host = "localhost",
      port = 5432,
      user = "postgres",
      password = "asdasd12x"
  )

  return(connectionInstance)
}

# clear everything from runtime memory 
# except specified variable string
clearMemoryExcept <- function(except) {
  rm(list = setdiff(ls(), except))
}

listWarnings <- function() {
  warningList <- paste0(unlist(unique(names(last.warning))), collapse = "\n")
  cat(warningList)
}

main <- function (argv) {

  loadPackages()
  connectionInstance <- establishDBConnection()
  datasetFilePath <- "MouseFibromuscular_2Tissues_normal_2Assays_Musmusculus.h5seurat"

  # Reading the data in seurat format
  wholeDataset <- LoadH5Seurat(datasetFilePath, assays = "RNA")

  # Split for each unique singular assay, tissue, cell type combination
  datasetCollectionCombinedID <- unique(paste(wholeDataset@meta.data$assay_ontology_term_id,
                                              wholeDataset@meta.data$tissue_ontology_term_id,
                                              wholeDataset@meta.data$cell_type_ontology_term_id,
                                              sep="_"))

  for(datasetID in datasetCollectionCombinedID){
    # datasetID: {[assayID], [tissueID], [cellTypeID]}
    datasetID <- strsplit(datasetID, split = "_")[[1]]

    dataset <- subset(wholeDataset, assay_ontology_term_id == datasetID[[1]] &
                                    tissue_ontology_term_id == datasetID[[2]] &
                                    cell_type_ontology_term_id == datasetID[[3]])

    # cell count threshold
    # if under 50, skip to the next sample
    cellCount <- dataset@assays$RNA@counts@Dim[[2]]
    if(cellCount < 50) {
      next
    }

    counts <- dataset@assays$RNA@counts
    countsSubsampled <- subsampleIntoList(counts)

    censorPoints <- rep(NA, length(countsSubsampled))
    names(censorPoints) <- names(countsSubsampled)
    
    meanUmi <- rep(NA, length(countsSubsampled))
    names(meanUmi) <- names(countsSubsampled)

    for(matrixName in names(countsSubsampled)) {
      # Number of cells per cell type as censoring point
      censorPoints[matrixName] <- 1 / ncol(countsSubsampled[[matrixName]])
      
      # Estimate the mean umi values per cell for each matrix
      meanUmi[matrixName] <- scPower::meanUMI.calculation(countsSubsampled[[matrixName]])
    }

    # Counting observed expressed genes
    expressedGenesDF <- countObservedGenes(countsSubsampled)

    # Estimation of negative binomial paramters for each gene
    c(normMeanValues, dispParam) %<-% negBinomParamEstimation(countsSubsampled)

    # Estimation of a gamma mixed distribution over all means
    gammaFits <- gammaMixedDistEstimation(normMeanValues, censorPoints)

    # Parameterization of the parameters of the gamma fits by the mean UMI counts per cell
    c(umiValues, gammaLinearFits) %<-% parameterizationOfGammaFits(gammaFits, meanUmi)

    # Merging cellCount, #assays, #tissues, #cellTypes,
    # assayID, tissueID, cellTypeID, gammaLinearFits, into a data frame
    resultingDataFrame <- mergeFinalStatus(wholeDataset@assays$RNA@counts@Dim[[2]],
                                           length(levels(wholeDataset$assay_ontology_term_id)),
                                           length(levels(wholeDataset$tissue_ontology_term_id)),
                                           length(levels(wholeDataset$cell_type_ontology_term_id)),
                                           datasetID[[1]], datasetID[[2]], datasetID[[3]],
                                           gammaLinearFits)
    
    # Writing resulting data frame to table named "priorsResult"
    dbWriteTable(connectionInstance, "priorsResult", resultingDataFrame, append = TRUE)
    print("Data written into database successfully.")
  }
}

if(identical(environment(), globalenv()) && commandArgs()[1] != "RStudio")
  quit(status = main(commandArgs(trailingOnly = TRUE)))
