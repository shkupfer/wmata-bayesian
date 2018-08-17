source("Functions.R")

# Set to TRUE if you want to use the informed priors below, or to FALSE to use beta(1,1) for all time intervals
informedPriors = TRUE

# File of train departure bin times and on-time/not on-time (0 or 1)
inputFile = "../data/lenfant_foggybottom_class.csv"
# Make a directory for output graphs, since there are lots of them
outputs_dir = '../data/output_graphs'
dir.create(outputs_dir, showWarnings = FALSE)


binFAFigName = "FAFig"

# Takes the input file, removes trips from before 4:00
allresults = loadData(inputFile)
allresults = subset(allresults, subset=binned_mins_since_start>=60)
allbins = sort(unique(allresults$binned_mins_str))
num_mins = sort(unique(allresults$binned_mins_since_start))

# These are the beta distribution parameters for the "informed" priors for each time interval
prior_beta_params = list()
for (bin_name in allbins) {
  if (bin_name < '04:30 PM' || bin_name > '04:55 PM') {
    prior_beta_params[bin_name] = list(c(1, 20))
  } else if (bin_name >= '04:38 PM' && bin_name <= '04:45 PM') {
    prior_beta_params[bin_name] = list(c(5, 1.2))
  } else {
    prior_beta_params[bin_name] = list(c(1.5, 1.5))
  }
}

best_thetas = c()
for (this_bin in allbins) {
  this_bin_df = subset(allresults, subset=binned_mins_str==this_bin)
  N = length(this_bin_df$OnTime)
  z = sum(this_bin_df$OnTime)

  # If informedPriors == TRUE, use the beta parameters above. If not, use (1,1)
  if (informedPriors == TRUE) {
    a = prior_beta_params[this_bin][[1]][1]
    b = prior_beta_params[this_bin][[1]][2]
  } else {
    a = 1
    b = 1
  }
  
  thetas = seq(from = 0, to = 1, by = 0.01)
  
  FAFigFileName = paste(outputs_dir, paste(this_bin, binFAFigName, sep="_"), sep='/')
  best_theta = formalAnalysis(z, N, a, b, thetas, FAFigFileName, this_bin)
  
  # Aggregate the thetas with the highest p(theta | D) in this vector for plotting below
  best_thetas = c(best_thetas, best_theta)
}

# Plot the thetas with the highest probability for each time interval
# to show relationship of departure time and on-time probabliity
peakthetas_df = data.frame(num_mins, best_thetas)
openGraph(width = 9, height = 5)
par(mar=c(4.5, 5, 4, 2) + 0.1)
plot(peakthetas_df$num_mins, peakthetas_df$best_thetas, type='o', xaxt='n', col='blue', main="Most Likely On-Time Probabilities\nby Departure Time",
     xlab="Departure Time Bin", ylab=expression("Most Likely " ~ theta))
axis(1, at=num_mins, labels=allbins)
saveGraph(file=paste(outputs_dir, "probas_by_dep_time", sep='/'), type = "jpg")


# Below code adapted from Jags-Ydich-XnomSsubj-Mbernbeta-Example.R
# Specify filename root and graphical format for saving output
fileNameRoot = "LenfantFoggy" 
graphFileType = "jpg"

# These are the two time interval names to compare
use_bins = c("04:36 PM", "04:39 PM")

finalData = allresults[allresults$binned_mins_str %in% use_bins, ]
finalData = finalData[order(finalData$binned_mins_str, decreasing=FALSE), ]
finalData$binned_mins_str = factor(finalData$binned_mins_str)

# Generate the MCMC chain:
mcmcCoda = genMCMC( data=finalData , numSavedSteps=50000 , saveName=fileNameRoot )

# Display diagnostics of chain, for specified parameters:
parameterNames = varnames(mcmcCoda) # get all parameter names
for ( parName in parameterNames ) {
  diagMCMC( codaObject=mcmcCoda , parName=parName , 
            saveName=fileNameRoot , saveType=graphFileType )
}

# Display posterior information:
plotMCMC( mcmcCoda , data=finalData , compVal=NULL ,
          compValDiff=0.0 ,
          saveName=paste(outputs_dir, fileNameRoot, sep='/'), saveType=graphFileType )
