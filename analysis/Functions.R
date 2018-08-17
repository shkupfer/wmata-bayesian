source("DBDA2E-utilities.R")

# Load train trips data into a dataframe. Re-used from homeworks
loadData = function(inFile) {
  data = read.csv(inFile)
  return(data)
}

# Takes as input the data, the parameters of the prior, the theta "bins", the name of the figure, and the title to use in the figure,
# and derives the posterior using formal analysis, and plots the density of the posterior distribution
# Returns the theta with the highest P(theta | D)
formalAnalysis = function(z, N, a, b, thetas, formalAnalysisFig, title) {
  # Derive posterior using formal analysis
  posteriors = thetas^(a + z - 1) * (1 - thetas)^(b + N - z - 1) / beta(z + a, N - z + b)
  
  # Plot the density of posterior distribution
  plotPosteriors(thetas, posteriors, formalAnalysisFig, title)
  
  # Get the theta with the highest P(theta | D) and return it
  thetas_posteriors_df = data.frame(thetas, posteriors)
  best_theta = thetas_posteriors_df[which.max(thetas_posteriors_df$posteriors),]$thetas
  
  return(best_theta)
}


# Takes as input the vector of thetas, the vector of posteriors, and name and title of the figure, and outputs the figure to a file
plotPosteriors = function(thetas, posteriors, posteriorsFig, title) {
  openGraph(width = 5, height = 5)
  par(mar=c(4,4,2,2),mgp=c(2,0.7,0))
  
  # Plot the data in the screen window
  plot(thetas, posteriors, xlab = expression(theta), ylab = expression("p(" ~ theta ~ "| D)"), type = "h", col = "red", lwd = 3, main=title)
  
  # Uncomment these lines to also plot the prior distribution on the same graph
  #par(mar=c(4,4,2,2),mgp=c(2,0.7,0), new=TRUE, ann=FALSE)
  #plot(thetas, dbeta(thetas, a, b), type='l', xlab=NULL, ylab=NULL, xaxt='n', yaxt='n')
  
  # Save the graph as a .jpg
  saveGraph(file = posteriorsFig, type = "jpg")
}


# Functions below adapted from Jags-Ydich-XnomSsubj-Mbernbeta.R, from the book:
#   Kruschke, J. K. (2014). Doing Bayesian Data Analysis: 
#   A Tutorial with R, JAGS, and Stan. 2nd Edition. Academic Press / Elsevier.

genMCMC = function( data , numSavedSteps=50000 , saveName=NULL ) { 
  require(rjags)
  # THE DATA.
  # N.B.: This function expects the data to be a data frame, 
  # with one component named OnTime being a vector of integer 0,1 values,
  # and one component named binned_mins_str being a factor of departure time intervals
  y = data$OnTime
  s = as.numeric(data$binned_mins_str) # converts character to consecutive integer levels

  # Do some checking that data make sense:
  if ( any( y!=0 & y!=1 ) ) { stop("All y values must be 0 or 1.") }
  Ntotal = length(y)
  Nsubj = length(unique(s))
  
  # Specify the data in a list, for later shipment to JAGS:
  dataList = list(
    y = y ,
    s = s ,
    Ntotal = Ntotal ,
    Nsubj = Nsubj
  )
  
  # THE MODEL.
  modelString = "
  model {
  for ( i in 1:Ntotal ) {
  y[i] ~ dbern( theta[s[i]] )
  }
  for ( sIdx in 1:Nsubj ) {
  theta[sIdx] ~ dbeta( 1 , 1 ) # Using a uniform prior
  }
  }
  " # close quote for modelString
  writeLines( modelString , con="TEMPmodel.txt" )
  
  # INTIALIZE THE CHAINS.
  # Initial values of MCMC chains based on data:
  # Using a function that generates random values near MLE:
  initsList = function() {
    thetaInit = rep(0,Nsubj)
    for ( sIdx in 1:Nsubj ) { # for each time interval
      includeRows = ( s == sIdx ) # identify rows of this interval
      yThisSubj = y[includeRows]  # extract data of this interval
      resampledY = sample( yThisSubj , replace=TRUE ) # resample
      thetaInit[sIdx] = sum(resampledY)/length(resampledY) 
    }
    thetaInit = 0.001+0.998*thetaInit # keep away from 0,1
    return( list( theta=thetaInit ) )
  }
  
  # RUN THE CHAINS
  parameters = c( "theta")     # The parameters to be monitored
  adaptSteps = 500             # Number of steps to adapt the samplers
  burnInSteps = 500            # Number of steps to burn-in the chains
  nChains = 4                  # nChains should be 2 or more for diagnostics 
  thinSteps = 1
  nIter = ceiling( ( numSavedSteps * thinSteps ) / nChains )
  # Create, initialize, and adapt the model:
  jagsModel = jags.model( "TEMPmodel.txt" , data=dataList , inits=initsList , 
                          n.chains=nChains , n.adapt=adaptSteps )
  # Burn-in:
  cat( "Burning in the MCMC chain...\n" )
  update( jagsModel , n.iter=burnInSteps )
  # The saved MCMC chain:
  cat( "Sampling final MCMC chain...\n" )
  codaSamples = coda.samples( jagsModel , variable.names=parameters , 
                              n.iter=nIter , thin=thinSteps )
  # resulting codaSamples object has these indices: 
  #   codaSamples[[ chainIdx ]][ stepIdx , paramIdx ]
  if ( !is.null(saveName) ) {
    save( codaSamples , file=paste(saveName,"Mcmc.Rdata",sep="") )
  }
  return( codaSamples )
}

plotMCMC = function( codaSamples , data , compVal=0.5 , rope=NULL , 
                     compValDiff=0.0 , ropeDiff=NULL , 
                     saveName=NULL , saveType="jpg" ) {

  # N.B.: This function expects the data to be a data frame, 
  # with one component named y being a vector of integer 0,1 values,
  # and one component named s being a factor of subject identifiers.
  y = data$y
  s = as.numeric(data$s) # converts character to consecutive integer levels
  # Now plot the posterior:
  mcmcMat = as.matrix(codaSamples,chains=TRUE)
  chainLength = NROW( mcmcMat )
  Ntheta = length(grep("theta",colnames(mcmcMat)))
  openGraph(width=2.5*Ntheta,height=2.0*Ntheta)
  par( mfrow=c(Ntheta,Ntheta) )
  for ( t1Idx in 1:(Ntheta) ) {
    for ( t2Idx in (1):Ntheta ) {
      parName1 = paste0("theta[",t1Idx,"]")
      parName2 = paste0("theta[",t2Idx,"]")
      if ( t1Idx > t2Idx) {  
        # plot.new() # empty plot, advance to next
        par( mar=c(3.5,3.5,1,1) , mgp=c(2.0,0.7,0) )
        nToPlot = 700
        ptIdx = round(seq(1,chainLength,length=nToPlot))
        plot ( mcmcMat[ptIdx,parName2] , mcmcMat[ptIdx,parName1] , cex.lab=1.75 ,
               xlab=parName2 , ylab=parName1 , col="skyblue" )
      } else if ( t1Idx == t2Idx ) {
        par( mar=c(3.5,1,1,1) , mgp=c(2.0,0.7,0) )
        postInfo = plotPost( mcmcMat[,parName1] , cex.lab = 1.75 , 
                             compVal=compVal , ROPE=rope , cex.main=1.5 ,
                             xlab=parName1 , main="" )
        includeRows = ( s == t1Idx ) # identify rows of this subject in data
        dataPropor = sum(y[includeRows])/sum(includeRows) 
        points( dataPropor , 0 , pch="+" , col="red" , cex=3 )
      } else if ( t1Idx < t2Idx ) {
        par( mar=c(3.5,1,1,1) , mgp=c(2.0,0.7,0) )
        postInfo = plotPost(mcmcMat[,parName2]-mcmcMat[,parName1] , cex.lab = 1.75 , 
                            compVal=compValDiff , ROPE=ropeDiff , cex.main=1.5 ,
                            xlab=paste0(parName2,"-",parName1) , main="" )
        includeRows1 = ( s == t1Idx ) # identify rows of this subject in data
        dataPropor1 = sum(y[includeRows1])/sum(includeRows1) 
        includeRows2 = ( s == t2Idx ) # identify rows of this subject in data
        dataPropor2 = sum(y[includeRows2])/sum(includeRows2) 
        points( dataPropor1-dataPropor2 , 0 , pch="+" , col="red" , cex=3 )
      }
    }
  }

  if ( !is.null(saveName) ) {
    saveGraph( file=paste(saveName,"Post",sep=""), type=saveType)
  }
}
