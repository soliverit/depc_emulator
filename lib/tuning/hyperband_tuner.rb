class HyperbandTuner
	DEFAULT_PARAMETERS = {
		base_population: 	3,
		max_population: 	5,
		mutations:			2
	}
	DEFAULT_SCORER = Proc.new{|a, b| a.error <=> b.error}
	def initialize modelClass, tunerParameters, modelParameters
		@modelClass			= modelClass
		@tunerParameters	= tunerParameters
		
		@modelParameters	= modelParameters
		DEFAULT_PARAMETERS.each{|key, value|@modelParameters[key] ||= value}
		##-> Might want to force or at least allow setting this during init
		@scorer				= DEFAULT_PARAMETERS
	end
	def tune trainingData, testData, target 
		##
		# Semi-persistent properties.  Changed only here		##
		@population 	= TunerLeaderBoard.new @scorer
		@trainingData 	= trainingData
		@target			= target
		@testData		= testData
		#Retrieve the target values and remove them from the test data
		@testTargets	= @testData.retrieveFeatureAsArray @target
		@testData.dropFeatures [@target]
		##
		# Create a base population
		##
		(0...@modelParameters[:base_population]).each{
			##
			# Configure and build a model
			##
			params = Hash[@tunerParameters.map{|param| [param.key, param.mutate]}]
			model 	= train params
			##
			# Do testing and push new Ancestor
			##		
			results = model.validateSet @testData, @testTargets, Prediction
			@population.push TunerAncestor.new(model, results, @tunerParameters, params)
		}
		@population.listError
		##
		# Start tuning
		##
		keepRunning 		= true
		currentPopulation	= []
		generation			= 0
		while keepRunning
			##
			# With existing population
			## 
			@population.each{|ancestor|
				##
				# 
				##
				(0...@modelParameters[:mutations]).each{
					##
					# New machine
					##
					params	= createHPParameterSet ancestor
					model 	= train params
					results = model.validateSet @testData, @testTargets, Prediction
					candidateAncestor = TunerAncestor.new(model, results, @tunerParameters, params)
					currentPopulation.push candidateAncestor if @population.betterThanAny? candidateAncestor
				}
			}
			
			Lpr.info "The next gen"
			
			@population.listError
			##
			# Merge current generation and let them fight to the death
			##
			currentPopulation.each{|ancestor| @population.push ancestor}
			##
			# Combat! Fight for survival to the next generation
			##
			@population.reduceByTournament 15
		end
	end
	protected
	def createHPParameterSet ancestor
		while true 
			parameterSet = Hash[ancestor.tunerParameters.map{|tunerParam| 
			[tunerParam.key, tunerParam.mutate]}]
			return parameterSet unless @population.include? parameterSet
		end
	end
	def train params
	# Lpr.info """Training #{@modelClass}\nParams: #{params}"""
		model = @modelClass.new @trainingData, @target, params	
		model.train
		model
	end
end