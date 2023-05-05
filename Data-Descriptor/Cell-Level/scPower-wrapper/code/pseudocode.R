
loadPackages <- function() {
  Packages <- c("DBI", "devtools", "DropletUtils", "HardyWeinberg", "MKmisc",
                "plotly", "pwr", "reshape2", "RPostgreSQL", "RPostgres", "scPower",
                "scuttle", "Seurat", "SeuratData", "SeuratDisk", "shiny", "stringr", "zeallot")

  suppressPackageStartupMessages(lapply(Packages, library, character.only = TRUE))

  print("Packages are loaded successfully.")
}

# Flags do not have to be in order and each flag can have whitespaces between. 
# But keywords has to be "hostIP", "assay", "tissue", "cellType"
# An example usage:
# Rscript main.R hostIP=[HOSTIP] assay=[assayName] tissue=[tissueName] cellType=[cellTypeName]
handleFlagsTags <- function(argList) {

  argSequence <- paste(unlist(argList), collapse = " ")

  hostIPSequence <- str_extract(argSequence, "hostIP(\\s)*=(\\s)*[1-9]+.[0-9]+.[0-9]+.[0-9]+")
  assaySequence <- str_extract(argSequence, "assay(\\s)*=(\\s)*[a-zA-Z0-9_]+")
  tissueSequence <- str_extract(argSequence, "tissue(\\s)*=(\\s)*[a-zA-Z0-9_]+")
  cellTypeSequence <- str_extract(argSequence, "cellType(\\s)*=(\\s)*[a-zA-Z0-9_]+")

  # arranging HOSTIP as a global variable
  if(!is.na(hostIPSequence)) HOSTIP <<- strsplit(gsub(" ", "", hostIPSequence), split = "=")[[1]][[2]] else stop("hostIP not provided.")

  # arranging assay, tissue and cell type names as a global variable
  if(!is.na(assaySequence)) ASSAYNAME <<- strsplit(gsub(" ", "", assaySequence), split = "=")[[1]][[2]] else ASSAYNAME <<- "assay"
  if(!is.na(tissueSequence)) TISSUENAME <<- strsplit(gsub(" ", "", tissueSequence), split = "=")[[1]][[2]] else TISSUENAME <<- "tissue"
  if(!is.na(cellTypeSequence)) CELLTYPENAME <<- strsplit(gsub(" ", "", cellTypeSequence), split = "=")[[1]][[2]] else CELLTYPENAME <<- "cell_type"

  print("Flags are arranged successfully.")
}

establishDBConnection <- function(hostIP) {
  connectionInstance <- dbConnect(
      Postgres(),
      dbname = "todos",
      host = toString(hostIP),
      port = 5432,
      user = "postgres",
      password = "asdasd12x")

  print("Connection to database established successfully.")
  return(connectionInstance)
}

# Converting from AnnData to Seurat via h5Seurat
convertH5Seurat <- function(file.name) {
  converted <- Convert(file.name, dest = "h5seurat", overwrite = TRUE)

  return(converted)
}

outputResults <- function(dataFrame) {
  write.table(dataFrame, "results.txt", row.names = FALSE, append = TRUE)
  write("\n", "results.txt", append = TRUE)
}

# clear everything from runtime memory
# except specified variable string
flushMemoryExcept <- function(except) {
  rm(list = setdiff(ls(), except))
}

listWarnings <- function() {
  warningList <- paste0(unlist(unique(names(last.warning))), collapse = "\n")
  cat(warningList)
}

# Downsamples the reads for each molecule by the specified "prop",
# using the information in "sample".
# Please see: https://rdrr.io/bioc/DropletUtils/man/downsampleReads.html
# return: a list consisting of downsampled reads, proportions of 0.25, 0.5, 0.75 and complete
subsampleIntoList <- function(counts.subsampled) {
  tmp <- list()
  tmp[[length(tmp) + 1]] <- counts.subsampled

  for(s in c(0.75, 0.5, 0.25)){
    subsample <- downsampleMatrix(counts.subsampled, prop = s, bycol = TRUE)
    tmp[[length(tmp) + 1]] <- subsample
  }

  tmp <- setNames(tmp, c("complete", "subsampled75", "subsampled50", "subsampled25"))

  print("Subsampling process done successfully.")
  return(tmp)
}

# Conversion from dgCMatrix (sparse matrix) to list
sparseToList <- function(counts) {
  tmp <- matrix(data = 0L, nrow = counts@Dim[1], ncol = counts@Dim[2])

  row_pos <- counts@i + 1
  col_pos <- findInterval(seq(counts@x) - 1, counts@p[-1]) + 1
  val <- counts@x

  for (i in seq_along(val)){
      tmp[row_pos[i], col_pos[i]] <- val[i]
  }

  row.names(tmp) <- counts@Dimnames[[1]]
  colnames(tmp) <- counts@Dimnames[[2]]
  return(tmp)
}

# return: a data frame consisting of:
# matrix titles, number of cells and expressed gene counts
countObservedGenes <- function(counts.subsampled, nSamples) {

  print("Dimensions of each count matrices:")
  print(sapply(counts.subsampled, dim))

  expressed.genes.df <- NULL

  # Iterate over each count matrix
  for(name in names(counts.subsampled)){

    count.matrix <- counts.subsampled[[name]]

    # Create an annotation file (here containing only one cell type, but can be more)
    annot.df <- data.frame(individual = paste0("S", rep(1:nSamples, length.out = ncol(count.matrix))),
                            cell.type = rep("default_ct", ncol(count.matrix)))

    # Reformat count matrix into 3d pseudobulk matrix
    pseudo.bulk <- create.pseudobulk(count.matrix, annot.df)

    # Calculate expressed genes in the pseudobulk matrix
    # threshold of more than 3 counts in more 50% of the individuals
    expressed.genes <- calculate.gene.counts(pseudo.bulk, min.counts = 3, perc.indiv = 0.5)

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
    # Converting from sparse matrix to normal one
    counts.subsampled.converted <- sparseToList(counts.subsampled[[name]])
    temp <- nbinom.estimation(counts.subsampled.converted, sizeFactorMethod = "poscounts")

    # Save the normalized mean values
    norm.mean.values.temp <- temp[[1]]
    norm.mean.values.temp$matrix <- name
    norm.mean.values <- rbind(norm.mean.values, norm.mean.values.temp)

    # Save the parameter of the mean-dispersion function
    disp.param.temp <- temp[[3]]
    disp.param.temp$matrix <- name
    disp.param <- rbind(disp.param, disp.param.temp)
  }

  # First rows of the data frame with normalized mean values
  head(norm.mean.values)

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

    norm.mean.values.temp <- norm.mean.values[norm.mean.values$matrix == name, ]
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
compareGammaMixedFits <- function(norm.mean.values, gamma.fits) {
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

  visualizeLinearRelation(gamma.fits)

  # Fit relationship between gamma parameters and UMI values
  gamma.linear.fits <- umi.gamma.relation(gamma.fits)

  print(gamma.linear.fits)

  print("Parameterization of the gamma fits done successfully.")
  return(list(umi.values, gamma.linear.fits))
}

# Visualize the linear relationship between gamma parameters and UMI values in plots
visualizeLinearRelation <- function(gamma.fits) {
  plot.values <- melt(gamma.fits, id.vars = c("matrix", "mean.umi"))
  plot.values <- plot.values[plot.values$variable %in% c("mean1", "mean2", "sd1", "sd2", "p1", "p2"),]
  ggplot(plot.values, aes(x = mean.umi, y = value)) +
         geom_point() +
         geom_line() +
         facet_wrap(~variable, ncol = 2, scales = "free")
}

mergeGeneCounts <- function(run, cellType, cellCount, evaluation, meanUmi, expressedGenes) {
  resultingDataFrame <- data.frame(run, names(meanUmi), cellType, cellCount,
                                   expressedGenes, meanUmi, evaluation)
  rownames(resultingDataFrame) <- NULL
  colnames(resultingDataFrame) <- c('run', 'sample', 'cell.type', 'num.cells', 'expressed.genes', 'meanUMI', 'evaluation')

  return(resultingDataFrame)
}

# [cellCount]_[#assays]_[#tissues]_[#cellTypes]: single dataset specific distinguisher
# [assayID]_[tissueID]_[cellTypeID]: result table specific distinguisher
# gammaLinearFits: parameter, intercept, meanUMI)
# There will be 3 tables in the end we'll be dealing with: datasetBody, downloadBody, []result (for each datasetBody)
mergeFinalStatus <- function(cellCount, numberOfAssays, numberOfTissues, numberOfCellTypes, 
                             assayID, tissueID, cellTypeID, gammaLinearFits, dispersionFunctionResults) {
  
  datasetBodySpecific <- paste(cellCount, numberOfAssays, numberOfTissues, numberOfCellTypes, sep = "_")
  resultTableSpecific <- paste(assayID, tissueID, cellTypeID, sep = "_")

  resultingDataFrame <- data.frame(datasetBodySpecific, resultTableSpecific, gammaLinearFits, dispersionFunctionResults)

  print("Merging of the finals informations done successfully.")
  return(resultingDataFrame)
}

# power.general.restrictedDoublets
powerSRDRD <- function(gamma.fits, disp.fun.general.new, name) {
  return(power.sameReadDepth.restrictedDoublets(nSamples = 100, nCells = 1500,
         ct.freq = 0.2, type = "eqtl",
         ref.study = scPower::eqtl.ref.study,
         ref.study.name = "Blueprint (Monocytes)",
         cellsPerLane = 20000,
         gamma.parameters = gamma.fits[gamma.fits$matrix == name, ],
         ct = "New_ct",
         disp.fun.param = disp.fun.general.new,
         mappingEfficiency = 0.8,
         min.UMI.counts = 3,
         perc.indiv.expr = 0.5,
         sign.threshold = 0.05,
         MTmethod = "Bonferroni"))
}

validationUsingModel <- function(gamma.fits, disp.param) {
  disp.fun.general.new <- dispersion.function.estimation(disp.param)
  disp.fun.general.new$ct <- "New_ct"
  gamma.fits$ct <- "New_ct"
  powerList <- list()

  for(name in c("complete", "subsampled75", "subsampled50", "subsampled25")) {
    power <- powerSRDRD(gamma.fits, disp.fun.general.new, name)
    
    powerList[[length(powerList) + 1]] <- power
  }

  print("Validation using model done successfully.")
  return(powerList)
}

main <- function(argv) {
  loadPackages()
  handleFlagsTags(argv)
  connectionInstance <- establishDBConnection(HOSTIP)
  datasetFilePath <- "MouseFibromuscular_2Tissues_normal_2Assays_Musmusculus.h5seurat"

  # Reading the data in seurat format
  wholeDataset <- LoadH5Seurat(datasetFilePath, assays = "RNA")
  print("Dataset loaded successfully.")

  # Split for each unique singular assay, tissue, cell type combination
  datasetCollectionCombinedID <- unique(paste(wholeDataset@meta.data[[ASSAYNAME]],
                                              wholeDataset@meta.data[[TISSUENAME]],
                                              wholeDataset@meta.data[[CELLTYPENAME]],
                                              sep = "_"))
  observedGeneCountsDF <- data.frame()

  for(datasetID in datasetCollectionCombinedID){
    
    # datasetID: {[assayID], [tissueID], [cellTypeID]}
    datasetID <- strsplit(datasetID, split = "_")[[1]]

    dataset <- tryCatch({
      subset(wholeDataset, assay == datasetID[[1]] &
                           tissue == datasetID[[2]] &
                           cell_type == datasetID[[3]])
    }, warning = function(w) {
      warning(w)
    }, error = function(e) {
      stop(e)
    })

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
      meanUmi[matrixName] <- meanUMI.calculation(countsSubsampled[[matrixName]])
    }

    # Counting observed expressed genes
    nSamples <- tryCatch({
      if(is.null(dataset@meta.data$Donor)) {
        length(levels(dataset@meta.data$Sample))
      } else {
        length(levels(dataset@meta.data$Donor))
      }
    }, warning = function(w) {
      warning(w)
    }, error = function(e) {
      stop("Both Donor and Sample not found in the meta data.")
    })
    expressedGenesDF <- countObservedGenes(countsSubsampled, nSamples)

    # Estimation of negative binomial paramters for each gene
    c(normMeanValues, dispParam) %<-% negBinomParamEstimation(countsSubsampled)

    # Estimation of a gamma mixed distribution over all means
    gammaFits <- gammaMixedDistEstimation(normMeanValues, censorPoints)

    # Parameterization of the parameters of the gamma fits by the mean UMI counts per cell
    c(umiValues, gammaLinearFits) %<-% parameterizationOfGammaFits(gammaFits, meanUmi)

    # Collecting data for validation of the model
    observedGeneCounts <- mergeGeneCounts("Run 5", datasetID[[3]], cellCount, "own_count10",
                                          meanUmi, expressedGenesDF$expressed.genes)
    observedGeneCountsDF <- rbind(observedGeneCountsDF, observedGeneCounts)
    
    # Merging cellCount, #assays, #tissues, #cellTypes,
    # assayID, tissueID, cellTypeID, gammaLinearFits, into a data frame
    resultingDataFrame <- mergeFinalStatus(cellCount,
                                           length(levels(dataset$assay_ontology_term_id)),
                                           length(levels(dataset$tissue_ontology_term_id)),
                                           length(levels(dataset$cell_type_ontology_term_id)),
                                           datasetID[[1]], datasetID[[2]], datasetID[[3]],
                                           gammaLinearFits,
                                           dispersion.function.estimation(dispParam))

    # Writing resulting data frame to table named "priorsResult"
    dbWriteTable(connectionInstance, "priorsResult", resultingDataFrame, append = TRUE)
    print("Data written into database successfully.")
  }

  # Validation of the model
  print(observedGeneCountsDF)
  
  #powerList <- validationUsingModel(gammaFits, dispParam)
}

if(identical(environment(), globalenv()) && commandArgs()[1] != "RStudio")
  main(commandArgs(trailingOnly = TRUE))