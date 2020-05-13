require_relative "./supervised_ensemble_base.rb"
require_relative "../../print_helper.rb"

class Committee < SupervisedEnsembleBase
	DEFAULT_PARAMS = {
		machineCount: 	10
		# featureCount:	1
	}
	def initialize rgDataSet, target, machineClass, parameters
		super rgDataSet, target, machineClass, parameters
		@committee	= false
		@machines	= MachineSet.new 
		DEFAULT_PARAMS.each{|key, value| @parameters[key] ||= value}
	end
	def randomFeatures
		@trainingData.features.shuffle[0, @parameters[:featureCount] || @trainingData.features.length - 1 ].concat([@target])
	end
	def train
		##
		# Generate N machines on random features	
		##
		Lpr.s "Training #{@parameters[:machineCount]} #{@machineClass.name} models"
		(0...@parameters[:machineCount]).each{|idx|
			Lpr.d "Training model #{idx}"
			newMachine = @machineClass.new(@trainingData.segregate(randomFeatures), @target, {})
			newMachine.train 
			@machines.push newMachine 
		}
		Lpr.s "Predict with each machine and classify scores based on min\nerror for each entry"
		i 					= 0
		groupPredictions 	= @machines.predictWithAll @testData, @testTargets
		groupPredictions.injectFeatures({choice: -1})
		groupPredictions.apply{|data|
			data[:choice] = @testTargets[i]
			i += 1			
		}
		## Bind classifications to the test data 
		# @testData.join groupPredictions.segregate([:choice])
		##
		# SVC-committee
		##
		groupPredictions.toCSV "c:/university/com_com_com.csv"
		Lpr.s "Train Committee"
		@committee = LibSvmRegressor.new groupPredictions, :choice,  {}
		@committee.train
	end
	##
	# Score the committee by running each machine individually then
	# delegating through committee.
	##
	def score rgDataSet
		##
		# Each machine
		##
		# Make data interaction safearrayish
		inputData 	= rgDataSet.clone	
		# Get the targets and drop (true) the feature from the dataset
		targets		= inputData.segregate([@target]) 
		inputData.dropFeatures [@target]
		##
		# Ok, let's do this: Score with each machine indiscriminately
		##
		Lpr.s "Score each machine individually"
		groupedPredictions = @machines.predictWithAll inputData, targets.retrieveFeatureAsArray(@target)
		####
		## Do the predict with 
		##
		####
		##
		# Delegate entries to specific machines via committee
		## 
		committeePredictions 	= @committee.predictSet groupedPredictions
		##
		# Sort input data features 
		##
		inputData.injectFeatures({prediction: -1000})
		i 						= 0
		inputData.apply{|data|
			data[:prediction] = committeePredictions.set[i].prediction
			i += 1
		}
		
		inputData.join groupedPredictions
		inputData.join targets
		inputData.toCSVGem "c:/university/committee.csv"
	end
end