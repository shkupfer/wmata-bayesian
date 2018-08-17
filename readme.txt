#Readme file


Bayesian Analysis of WMATA Metro Transit Data Final Project
------------------------------------------------------------------------------------


File/directory layout:
* pull_data/
   * This contains two scripts that were used to pull the data from Metro’s API. These require an API key to work, and don’t need to be run, since the data is already in the data/ directory
* preprocess_data/
   * This contains an IPython notebook file for preprocessing and filtering the data from the API
* analysis/
   * Contains two .R files, one (Driver.R) needs to be run, it sources the other (Functions.R)
* data/
   * This contains many files (starting in “2018”) from the API, along with the preprocessed data (lenfant_foggybottom_class.csv) and the .jpg graph outputs of the analysis (these are under the output_graphs/ subdirectory)
* Readme.txt
   * (this file)
* Requirements.txt
   * A python package required to pull the dat


The Driver.R file in analysis/ can be run on its own, since the preprocessed data is already in data/. Or, the preprocessing can be re-run if you wish.