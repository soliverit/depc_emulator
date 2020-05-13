##
# Includes
##
## Native ##
require "dnn"
## Library ##
require "./lib/ollie_ml_supervised_proxy_base.rb"


#################################################################
# NIMBUS Random Forest
#################################################################

class NimbusRF < OllieMlSupervisedProxyBase
	DEFAULT_PARAMS 	= {
		CONFIG_PATH: 		"config.yml",
		INPUT_PATH:			"nimbus_input.csv",
		TEST_PATH:			"nimbus_test.csv",
		FOREST_PATH:		"nimbus_forest.yml",
		FOREST_SIZE:		10,
		SNP_SAMP_SIZE:		60,
		SNP_TOTAL_COUNT:	200,
		MIN_NODE_SIZE:		3
	}
	def initialize data, target, parameters
		raise "NIMBUS-RF: Yet to be tested / finished"
		super data, target, parameters
	end
	def setParameters parameters
		@parameters = @parameters.dup
		DEFAULT_PARAMS.each{|key, value|
			@parameters[key] ||= value
		}
	end
	def train
		currentWD = Dir.pwd
		Dir.chdir "./tmp/"
		writeConfigs
		puts "nimbus #{@parameters[:CONFIG_PATH]}"
		system "nimbus #{@parameters[:CONFIG_PATH]}"
		Dir.chdir currentWD
	end
	def writeConfigs
		##
		# Write config file
		##
		file = File.open(@parameters[:CONFIG_PATH], "w")
		file.write "input:
	training: #{@parameters[:INPUT_PATH]}
	forest: #{@parameters[:FOREST_PATH]}
forest:
	forest_size: #{@parameters[:FOREST_SIZE]}
	SNP_sample_size_mtry: #{@parameters[:SNP_SAMP_SIZE]}
	SNP_total_count: #{@parameters[:SNP_TOTAL_COUNT]}
	tree_node_min_size: #{@parameters[:MIN_NODE_SIZE]}"
		file.close
		##
		# Write training file
		##
		file = @trainingData.toCSV @parameters[:INPUT_PATH], false, " "
		file = @trainingData.toCSV @parameters[:TEST_PATH], false, " "
	end
end
