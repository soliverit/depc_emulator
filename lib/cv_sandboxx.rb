
class CrossValidatorSet
	##
	# Acceptable sort types. Keys passed via send (evil) to safeSort (ironic name)
	##
	@@acceptableSortMethods = [
		:rmse,
		:max,
		:min,
		:perMin,
		:perMax
	]
	##
	# Map with index
	##
	def mapWithIndex &block
		i = -1
		@set.map{|cv|
			i += 1
			yield(cv,i)
		}
	end
	##
	# @set:		Array of CrossValidatorBase descendants, ideally the same
	#			though not end of the world material, actually might be useful.
	##
	def initialize 
		@set = []
	end
	##
	# Cool array access to set!
	#
	# Retrieve an item from the set as if it were an array
	#
	# Output:	CrossValidatorBase descendant
	##
	def [](id)
		@set[id]
	end
	##
	# Add CrossValidatorBase descendant to the set
	#
	# TODO: Ensure it's a CV that's being added not something else
	##
	def push cv
		@set.push cv
	end
	##
	# Get the first CV in the set
	#
	# Output:	First CrossValidatorBase descendant in the set
	##
	def first
		@set.first
	end
	##
	# Get the last CV in the set
	#
	# Output:	Last CrossValidatorBase descendant in the set
	##
	def last
		@set.last
	end
	##
	# Return the CrossValidator with the best total <type Symbol>
	#
	# Output:	CrossValidatordescendant with best machine <type Symbol>
	#
	# WARNGING:	Does this even make sense! Having machine in something
	#			called CV when really, it's more a Struct at this point?
	##
	def best type = :rmse
		safeSort(type).first
	end
	##
	# Return the CrossValidator with the worst total <type Symbol>
	#
	# Output:	CrossValidatorBase descendant with the worst machine <type Symbol>
	##
	def worst type = :rmse
		safeSort(type).last
	end
	##
	# Sort and clone, Kind of lazy reduction of best/worst
	##
	def safeSort type
		raise "CrossValidatorSet::InvalidSortType" if ! @@acceptableSortMethods.include? type.to_sym
		@set.sort{|a, b| a.getError.rmse <=> b.getError}
	end
	##
	# Number of cross validators in the set
	#
	# Output:	Integer
	##
	def length
		@set.length
	end
end
#################################################################
# Cross validators base (abstract) class						#
#																#
# Abstract class for basing cross validation classes on for		#
# making their development and application generic				#
#################################################################
class CrossValidatorBase
	attr_reader :target, :trainTestStruct, :machine
	cattr_accessor :printFeatures, :printIndividual
	@@printFeatures 	= false
	@@printIndividual	= true
	##
	# @trainTestStruct:	TrainTestStruct containing training and test data sets
	# @target:			Symbol of the desired target feature
	# @machineClass:	The Class of the machine to be generated
	# @machine:			Instance of the @machineClass 
	# @kernel:			Alias for the desired kernel if applicable
	# @predictionType:	Prediction or descendant class
	##
	def initialize trainTestStruct, target, machineClass, parameters = false
		@trainTestStruct	= trainTestStruct
		@target				= target
		if machineClass.class == Class
			@machineClass	= machineClass
		else
			@machine		= machineClass
			@machineClass	= machineClass.class
		end
		@predictionType		= Prediction
		@parameters			= parameters || {}
	end
	##
	# Train a model. Skip if one exists already
	##
	def prepare
		@machine 	||= @machineClass.new @trainTestStruct.trainingData, @target, @parameters
		@machine.train
	end
	##
	# Do validation. Iterate over training data sets, predict and record output PredictionSets
	##
	def doValidation
		prepare if ! @machine
		i = 0 
		while i < @trainTestStruct.testSetCount
			trainTestDataSplit = getTargets @trainTestStruct.testSets(i)
			@trainTestStruct.pushResult @machine.validateSet(trainTestDataSplit.first, trainTestDataSplit.last, @predictionType)
			i += 1
		end
	end
	##
	# Get test targets: to be overridden! (if necessary)
	#
	# Retrieve target information in the given expected format. 
	#
	# fullData:		RegressionDataSet including target feature
	#	
	# Output:	By default retrieve the a simple Array of expectations
	##
	def getTargets fullData
		puts "Base Get Targets"
		#Get training set, retrieve target and remove from the RegressionDataSet
		[fullData, fullData.retrieveFeatureAsArray(@target, true)]
	end
	##
	# Do greedy training if a method is called before the validator is prepared
	#
	# forceValidation:	Boolean should it force run prepare or spit the dummy out?
	#
	# Output:			Boolean, as above
	##
	def doGreedy? forceValidation
		if ! @trainTestStruct.equalTestSetAndResults?
			if ! forceValidation
				return false
			else
				doValidation 
			end
		end
		true
	end
	##
	# Retrieve the results for each validation(prediction? whatever)
	#
	# forceValidation:	Should it force training if the machine is ready?
	#
	# Output:			Array of ErrorInformation
	##
	def errorResults forceValidation = true
		return false unless doGreedy? forceValidation
		i = 0
		output = []
		while i < @trainTestStruct.testSetCount
			output.push @trainTestStruct.results(i).getError
		end
		output
	end
	##
	# Print helper for presenting the results of the cross validation to the console
	#
	# forceValidation:	Should the machine be prepared if it's not ready? Boolean
	##
	def printResults withRejection = true, forceValidation = true
		raise "Cross validation: Pre-validate print request exception. Run doValidate first" unless doGreedy? forceValidation
		
		i 			= 0
		lowRMSE 	= 9999999999999999999
		highRMSE	= -1
		best		= -1
		worst		= -1
		
		puts "======== Cross Validation results ======"
		puts "Machine:\t" + @machine.name
		puts "No. Train:\t#{@trainTestStruct.trainingData.length}"
		if @@printFeatures
			puts "Features:"
			puts @trainTestStruct.trainingData.printFeatureBounds 
		end
		Lpr.s "Error summary"
		printifiableTableHash = {"Predictions" =>{}, "RMSE" => {},"Abs min" => {}, "Abs max" => {}, "Min" => {}, "Max" => {}, "Average" =>{}}
		while i < @trainTestStruct.testSetCount
			printKey	= i.to_s.to_sym
			set			= withRejection ? @trainTestStruct.results(i).reduceByRejection : @trainTestStruct.results(i)
			results		= set.getError
			if @@printIndividual
				resultKey = i.to_s
				printifiableTableHash["Predictions"][printKey] = set.length
				printifiableTableHash["RMSE"][printKey] 	= results.rmse
				printifiableTableHash["Abs min"][printKey] 	= results.absMin
				printifiableTableHash["Abs max"][printKey] 	= results.absMax
				printifiableTableHash["Min"][printKey] 	= results.min
				printifiableTableHash["Max"][printKey] 	= results.max
				printifiableTableHash["Average"][printKey] 	= results.average
			end
			if results.rmse < lowRMSE
				lowRMSE 	= results.rmse.round(4)
				best		= i
			elsif results.rmse > highRMSE
				highRMSE 	= results.rmse.round(4)
				worst		= i
			end
			i += 1
		end
		puts Lpr.hashToTable printifiableTableHash.dup
		## Do total prediction ###
		set = getTotalledResult
		
		@genErrorResults = set.getError
		@worstRMSE = worst
		@bestRMSE = best
		print "Total:    Count: #{set.length}\tRMSE: #{results.rmse.round(4)}\tAverage: #{results.simple.round(4)}"
		print "\tMin: #{results.min.round(4)}\tMax: #{results.max.round(4)}\n"
		puts "----------------------------------------"
		puts "Result ranks - Best: ID=#{best + 1}\tRMSE=#{lowRMSE}\tWorst: ID=#{worst + 1}\tRMSE:#{highRMSE}"
		puts "========================================"
	end
	##
	# Get PredictionSet for all records in all test data sets
	#
	# Output:	PredictionSet containing Predictions for every test record
	##
	def getTotalledResult
		return @totalResult if @totalResult
		dataSet = RegressionDataSet.new nil, @trainTestStruct.trainingData.features
		i 		= 0
		while i < @trainTestStruct.testSetCount
			dataSet << @trainTestStruct.testSets(i)
			i 		+= 1
		end
		inputAndTargets	= getTargets dataSet
		@totalResult 	= @trainTestStruct.setTotalResult(@machine.validateSet inputAndTargets.first, inputAndTargets.last, @predictionType)
	end
	##
	# Self-indulgent train/test plotting, nothing important
	##
	def printTrainRecordsSummary count = 1, scale = 20
		data = @trainTestStruct.trainingData.getDataStructure(true)
		Lpr.p "Print summary for #{@machineClass.name}"
		(0...count).each{|index|
			Lpr.s "Record #{index} regular"
			Lpr.graphIt @trainTestStruct.trainingData.getDataStructure(true)[index], scale
			Lpr.graphIt @trainTestStruct.testSets(index).getDataStructure(true)[index], scale
		}
	end
	##
	# Create a CrossValidatorBase descendant. Standardises the the generation process
	# for any inheriting class unless overridden. Produces new validator
	#
	# machineClass:		The OllieMlSupervisedBase descendant Class object that the machine
	# 					is to be trained as
	# data:				RegressionDataSet containing all train/test data including targets
	# target:			Symbol of the target feature name
	# trainPercent:		Percentage of the input data to be used for training initially,
	#					though this might be removed or otherwise make flexible in the instance
	#					methods. For example: Merge train/test data and resample at differing percentage
	#					or shuffled
	# parititionCount:	Number of subsets created from the test data. Defines how many tests are carried out
	#					by the associated CrossValidatorBase descendant
	#
	# Output:			Instance of a descent of this abstract class
	########## DIRTY FIX FOR SVM-TYPE FOR CLASSIFIER, FIX LATER!!!!!!!! (Gone, you can sleep at night now...)
	def self.createCrossValidator machineClass, data, target, trainPercent, partitionCount, parameters
		### Let's face it, you won't implement everything any time soon. throw a fit when this is an issue ###
		raise "CV train split must be between 0 and 0.99, given#{trainPercent}" if trainPercent < 0 || trainPercent > 0.99
		raise "Cross validation partition count must be 1 < paritionCount < data.length * trainPercent" if partitionCount <= 1 || data.length * trainPercent <  partitionCount
		raise "Cross validation target must be in the given data set" if ! data.hasFeature? target.to_sym
		Lpr.p "WARNING! FastANN error analysis not implemented yet!" 	if machineClass ==FastANN
		#raise "Neural network cross validation not implemented yet" if machineClass.isNN?
		#Split the data
		trainTestDataSets 	= data.split(trainPercent)
		#Create storage struct for the data 
		trainTestStruct		= TrainTestStruct.new(trainTestDataSets[0], trainTestDataSets[1].partition(partitionCount))
		# Return an instance of the current class
		self.new trainTestStruct, target, machineClass, parameters
	end
	##
	# PICTURE THIS!!!!!!
	#	It's 2:22am and your listening to Amy Schumer's soul destroying new set
	#	but you're sure you can churn out a classifier and ultimately half error
	#	with an unknown set.
	#
	#	Who knows what it does/will do, will update if anything exciting happens
	#
	#	SIGH: The dream has been crushed for now. Negligible if not deteriorated 
	# 		  results. Worry about it later.
	##
	def self.makeMeProud machineClass, data, target, trainBounds, partitionCount, parameters, machineCount
		CrossValidator::printIndividual = true
		Lpr.p "Make me proud! (CV Analyst)"
		Lpr.d "Total records:\t #{data.length}"
		Lpr.startTimer
		### Do data, split into stuff for train/testing for both types of machine
		tempData 		= data.split(0.1)
		#Emulator data
		machineData		= tempData.first
		#Classifier data
		tempData		= tempData.last.split(0.6)
		classData		= tempData[0]
		#Class test data 
		classTestData 	= tempData[1]
		classEndTest	= classTestData.clone
		#Output CV set
		cvSet 			= CrossValidatorSet.new
		Lpr.s "Generate #{machineClass.to_s} machines"
		### Generate machine set ###
		i 				= 0 
		Lpr.d "Train data size boundaries: #{(machineData.length * trainBounds[:min]).to_i} and #{(machineData.length * trainBounds[:max]).to_i}"
		while i < machineCount
			puts "Machine ID #{i+1} of #{machineCount}"
			cvSet.push self.createCrossValidator(machineClass, data.sample, target, trainBounds[:min] + (trainBounds[:max] -trainBounds[:min]) * Random.rand, partitionCount, parameters)
			cvSet.last.printResults
			i += 1
		end
		Lpr.timeDelta true
		Lpr.p "Do classifier using SVM(SVM-C)"
		Lpr.d "Predict from CV set machines"
		### Do classifier
		classifiedData = RegressionDataSet.new nil, data.features.map{|f| f if f != target}.compact.concat([:target, :targetValue]), 10, true
		targetID = classData.features.find_index target
		groupRMSE  = 0
		errorTrack = {}
		(0...cvSet.length).each{|index|
			errorTrack[index.to_s.to_sym] = {
				rmse:0,
				count:0
			}
		}
		classData.data.each{|data|
			newData 	= []
			targetValue	= false
			data.each_with_index{|d, id|
				if id == targetID
					targetValue = d
				else
					newData.push d
				end
			}
			maxError	= 99999999
			bestID		= false
			i 			= 0
			res 		= []	#CAN PROBABLY BE REMOVED
			while i < cvSet.length
				res.push((cvSet[i].machine.translateAndPredict(newData) - targetValue).abs)	
				if res.last < maxError
					bestID		= i  
					maxError 	= res.last
				end
				i += 1
			end
			idKey = bestID.to_s.to_sym 
			errorTrack[idKey][:count] += 1
			errorTrack[idKey][:rmse] += maxError ** 2
			newData.push bestID
			newData.push targetValue
			classifiedData.push(newData)
		}
		sumRMSE = 0
		errorTrack.keys.each{|key|
			sumRMSE += errorTrack[key][:rmse]
			errorTrack[key][:rmse] = (errorTrack[key][:rmse] / errorTrack[key][:count]) ** 0.5
		}
		errorTrack[:"-1"]= {count:classifiedData.length, rmse:(sumRMSE / classifiedData.length) ** 0.5}
		puts Lpr.hashToTable errorTrack
		catCount = classifiedData.countKey :target
		puts Lpr.hashToTable catCount.hashedData.first
		Lpr.timeDelta true
		Lpr.p "Train SVM-C classifier"
		
		cv = CrossValidator.createCrossValidator LibSvmRegressor, classifiedData, :target, 0.15, 15, {svmType: "SVM-C"}
		cv.printResults #USE doValidation after testing
		Lpr.timeDelta true
		
		Lpr.p "Test classifier"
		Lpr.s "Classify data never seen by any machine"
		classVerificationValueTargets =classTestData.retrieveFeatureAsArray target, true
		classVerificationSet = RegressionDataSet.new nil, classTestData.features.concat([:target])
		targetID = classTestData.features.find_index
		classTestData.data.each{|data|
			classVerificationSet.push data.dup.concat([cv.machine.translateAndPredict(data)])
		}
		
		Lpr.timeDelta true
		Lpr.s "Generate predictions based on classifications"
		# Create set for classified data
		cSummary = classVerificationSet.countKey :target
		puts Lpr.hashToTable(cSummary.hashedData.first)
		grouped = classVerificationSet.groupBy :target
		outputSets = []
		i = 0
		
		t = 0
		Lpr.p "   "
		Lpr.p "   "
		Lpr.p "   "
		Lpr.p "   "
		Lpr.p "   "
		Lpr.p "   "
		Lpr.p "   "
		CrossValidator::printIndividual = false
		grouped.each{|key, rgDataSet|
			if rgDataSet.length == 0 
				Lpr.d "Machine: #{key} skipped since there's no associated predictions"
				nexts
			end
			a = 0
			rgDataSet.dropFeatures [target]
			expectations = rgDataSetTwo = RegressionDataSet.new nil, rgDataSet.features.concat([:target])
			while a < rgDataSet.length
				d = rgDataSet.data[a].dup.push(classVerificationValueTargets[t + a])
				expectations.push d		
				a += 1
			end
			t = a - 1	

			newKey = key.to_s.to_i
			Lpr.p "==== All machines using: #{newKey}"
			cv = self.createCrossValidator(cvSet[newKey].machine, expectations, :target, trainBounds[:min] + (trainBounds[:max] -trainBounds[:min]) * Random.rand, partitionCount, {})
			cv.printResults
			Lpr.s ">> Each machine <<"
			f = 0 
			rank = 99999
			while f < cvSet.length
				puts "Desired: #{newKey}\tCurrent: #{f}"
				# err = cvSet[f].machine.validateSet(rgDataSet, expectations).getError
				# err.printSimpleError
				cv = self.createCrossValidator(cvSet[f].machine, expectations, :target, trainBounds[:min] + (trainBounds[:max] -trainBounds[:min]) * Random.rand, partitionCount, {})
				cv.printResults
				
				f += 1
			end
			Lpr.p " "
		}
		puts outputSets[0].set.first
		#Print stuff, time and next section label
		Lpr.timeDelta true
		Lpr.p "Report classification to regression results"
		Lpr.s "Individual machines"
		#Print results
		outputSets.each{|set|
			set.predictor.name
			set.getError.printSimpleError
		}
		Lpr.s "Aggregated results"
		### Make PredictionSet merge method
		allPredTargetSets  = {input:[], targets: []}
		simpleRMSE = {rmse: 0, total: 0, count: 0}
		outputSets[1,outputSets.length - 1].each{|predictionSet|
			
			predictionSet.set.each{|prediction| 
				simpleRMSE[:count] += 1
				simpleRMSE[:total] += prediction.prediction - prediction.expected
				simpleRMSE[:rmse] += (prediction.prediction - prediction.expected) ** 2
				allPredTargetSets[:input].push  prediction.input
				allPredTargetSets[:targets].push prediction.expected
				outputSets.first.push prediction
			}
		}
		Lpr.s "Print simple counter RMSE"
		simpleRMSE[:rmse] = (simpleRMSE[:rmse] / simpleRMSE[:count]) ** 0.5
		simpleRMSE[:total] /= simpleRMSE[:count]
		puts simpleRMSE.to_json
		Lpr.s "Do prediction with best machine over all unseen data"
		i = 0
		trainAllSet = classEndTest.clone
		testAllSet  = classEndTest.retrieveFeatureAsArray :target
		puts testAllSet[0,5]
		
		while i < cvSet.length
			simpleRMSE = {rmse: 0, total: 0, count: 0}
			pSet = cvSet[i].machine.validateSet(trainAllSet, testAllSet)
			pSet.getError.printSimpleError
			pSet.set.each{|prediction| 
				simpleRMSE[:count] += 1
				simpleRMSE[:total] += prediction.prediction - prediction.expected
				simpleRMSE[:rmse] += (prediction.prediction - prediction.expected) ** 2
			}
			Lpr.p "????????????????"
			simpleRMSE[:rmse] = (simpleRMSE[:rmse] / simpleRMSE[:count]) ** 0.5
			simpleRMSE[:total] /= simpleRMSE[:count]
			puts simpleRMSE.to_json
			i += 1
		end

		Lpr.s "See how the simple RMSE went all machines in sum"
		
		exit
		outputSets.first.getError.printSimpleError
		Lpr.s "Print best CrossValidationSt results"
		cvSet.best.printResults
		Lpr.p "Print first machine results for comparison"
		targets classVerificationSet.retrieveFeatureAsArray :target, true
		cvSet.best.machine.validateSet(classVerificationSet, targets).getError.printTable
		exit
		Lpr.p "LAST STAND!!!"
		Lpr.s "Create a CV for each machine, process all data and see how it goes"
		i = 0
		lastStand
		while i < cvSet.length
			cv = self.createCrossValidator(cvSet[i].machine, lastStandData.sample, :target, trainBounds[:min] + (trainBounds[:max] -trainBounds[:min]) * Random.rand, partitionCount, kernel)
			cv.printResults
			i += 1
		end
		### Generate 
	end
end
#################################################################
# Cross validation standard model								#
#																#
# The standard model for cross validation						#
#################################################################
class CrossValidator < CrossValidatorBase
	
end
#################################################################
# Cross validation with domain rejection						#
#																#
# Essentially, the standard CV but using domain rejection		#
# predictions 													#
#																#
# Notes:														#
#	- It's debatable if this should be replaced with about		#
#	  parameter in the standard CrossValidator init but			#
#	  if nothing else this keeps it clean and controllable		#
#	  on the off chance the distinction is needed in the future #
#################################################################
class DomainRejectionCV < CrossValidator
	def initialize trainTestStruct, target, machineClass, parameters, domainLowerBound, domainUpperBound
		super(trainTestStruct, target, machineClass, parameters)
		@predictionType 	= DomainRejectionPrediction
		@domainLowerBound	= domainLowerBound
		@domainUpperBound	= domainUpperBound
	end
	##
	# Get test targets: to be overridden! (if necessary)
	#
	# Retrieve target information in the given expected format. 
	#
	# fullData:		RegressionDataSet including target feature
	#	
	# Output:	Hash of the target and its domain boundaries
	##
	def getTargets fullData
		#Clone the test set, inject the target feature bounds, get the feature bounds/target Hash Array
		fullData.injectFeatures({domainLowerBound: @domainLowerBound, domainUpperBound: @domainUpperBound})
		targets = fullData.segregate([:domainLowerBound, :domainUpperBound, @target], true).getDataStructure(true)
		[fullData, targets]
	end
end
class PredictionDeltaRejectionCV < DomainRejectionCV
	##
	# Get test targets: to be overridden! (if necessary)
	#
	# Retrieve target information in the given expected format. 
	#
	# fullData:		RegressionDataSet including target feature
	#	
	# Output:	Hash of the target and its domain boundaries
	##
	def getTargets fullData
		#Clone the test set, inject the target feature bounds, get the feature bounds/target Hash Array
		fullData.injectFeatures({domainLowerBound: @domainLowerBound, domainUpperBound: @domainUpperBound})
		fullData.injectFeatureByFunction(:domainLowerBound){|record, feature|  record[@target] * @domainLowerBound}
		fullData.injectFeatureByFunction(:domainUpperBound){|record, feature| record[@target] * @domainUpperBound}
		targets = fullData.segregate([:domainLowerBound, :domainUpperBound, @target], true).getDataStructure(true)
		[fullData, targets]
	end
end
