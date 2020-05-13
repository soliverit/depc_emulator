##
# Includes
##
## Native ##
require "dnn"
## Library ##
require "./lib/ollie_ml_supervised_base.rb"
#################################################################
# Ruby-DNN base class											#
#																#
# The base class for any models based on Ruby-DNN			   	#
#																#
# 		WORK IN PROGRESS!!!!!!!!!!!!!!!!!!!!!!!!!				#
#################################################################
class OllieDNN < OllieMlSupervisedBase
	#########################
	# Includes from Ruby-DNN
	##
	include DNN::Models
	include DNN::Layers
	include DNN::Optimizers
	include DNN::Losses
	#########################
	def self.isNN?
		true
	end
	def initialize data, targets, parameters
		super data, targets, parameters
	end
	def trainingData
		output = Numo::SFloat.new(@trainingData.length, @trainingData.data.first.length)
		output.seq
		@trainingData.data.each_with_index{|row, x|
			row.each_with_index{|cell, y|
				output[x,y] = cell
			}
		}
		output
	end
	def targetData
		output = Numo::SFloat.new(@trainingData.length, @trainingData.data.first.length)
		output.seq
		@target.data.each_with_index{|row, x|
			row.each_with_index{|cell, y|			
				output[x, y] = cell
			}
		}
		output
	end
	def train
		puts DNN::Optimizers::constants
		# exit
		trainSets 	= trainingData.split(2)
		testSets	= targetData.split(2)
		model = Sequential.new

		model << InputLayer.new(@trainingData.features.length)

		# model << Dense.new(256)
		# model << ReLU.new

		# model << Dense.new(256)
		# model << ReLU.new

		model << Dense.new(@trainingData.features.length)

		# model.setup(RMSProp.new, SoftmaxCrossEntropy.new)
		model.setup(SGD.new, SigmoidCrossEntropy.new)
		
		model.train(trainSets.first, testSets.first, 3000,verbose: true, batch_size: 100, test: [trainSets.last, testSets.last])
	end
end
