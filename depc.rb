################################
# Includes
################################
### Native 

### Project
# Debug dumping stuff
require "./lib/print_helper.rb"
# Buliding
require "./lib/building.rb"
# RegressionDataSet is OllieMl's
require "./lib/regression_data_set.rb"
# EPSRegressor - linear regression library (OllieMlSupervisedBase)
require "./lib/supervised/eps_regressor.rb"
require "./lib/predictions/prediction.rb"

Lpr.p "
 ################################
 # This script is designed to data points from
 # the domestic EPC historical results database
 # and methodology document to produce an 
 # emulator for RdSAP
 ################################md"

################################
# Processs input arguments
################################
# Make sure something has been passed
if ARGV.empty?
	Lpr.d "Missing all input parameters"
	exit
end
# Check file path, set it if it exists
if ! File.exists? ARGV.first
	Lpr.d "Input data path not found (#{ARGV.firs})"
	exit
end
rgDataSet	= RegressionDataSet.parseGemCSV(ARGV.first)
# Check target
if !ARGV[1]
	Lpr.d "Target feature not defined"
	exit
end
target	= ARGV[1].to_sym
# Check for a features input file (list of Building instance methods)
if ! ARGV[2] 
	Lpr.d "Features list input file hasn't been passed"
	exit
elsif ! File.exists? ARGV[2]
	Lpr.d "Features list input file doesn't exist"
	exit
end
features = File.open(ARGV[2]).readlines.map{|line| line.strip.to_sym}
##
# Deal with any input params here.
##
# Set default train/test split
splitRatio 	= 0.5
if ARGV.length > 3
	ARGV[3,].each{|param|
		case param
		## Define the train/test split, default 50/50
		when /--train-split:/
			# Go mental if it's not formatted like a number
			hopefullyANumber = param.split(":").first
			if !hopefullyANumber.match(/^-?\d+(\.\d+)?$/)
				Lpr.p "-train-split train/test split property is not numeric"
				exit
			else
				splitRatio = hopefullyANumber.last.to_f
			end
		end
	}
end

################################
# Do data preparation
################################
##
# Convert input data into new dataset with the target features
# and add input data record to the new dataset.
#
# This is done by converting the record into a Building object
# then extracting the features into an implicitly ordered array.
##
# The machine features dataset
trainingRGDatSet	= RegressionDataSet.new false, features
require "yaml"
# Populate the dataset
rgDataSet.each{|record|
	# The class designed for handling EPC records
	building 			= Building.new record
	next if building.errors?
	# The features list are function names that return a number
	buildingFeatures	= building.extractFeatures features 
	# Dataset figures out what to do with it
	trainingRGDatSet.push buildingFeatures
}

##
# Shuffle the data then split it into its test/train compoents.
##
# Shuffle the data then split it by the train/test split
trainingRGDatSet.shuffle
rgDataSets		= trainingRGDatSet.split(splitRatio)
# Set training data. The target feature stays int he dataset
trainData		= rgDataSets.first
# Set the test data. The target feature is later removed from the dataset
testData		= rgDataSets.last
# Set the test targets and drop the target column (the true is for drop column)
testTargets		= testData.retrieveFeatureAsArray target, true

trainData.toCSV "SHOE.csv"
################################
# Generate a machine
################################
# Create a new EPS regressor wrapper. (see https://github.com/soliverit/ollieml) 
machine		= EPSRegressor.new trainData, target, {}
# Train the model
machine.train

################################
# Do a prediction and print errors
################################
# Run a test using the standard Prediction struct
predictions	= machine.validateSet testData, testTargets, Prediction
# Print the model metrics
predictions.getError.printTable


