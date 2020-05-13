##
# Includes
##
## Native ##
require "tensorflow"
## Library ##
require "./lib/ollie_ml_supervised_base.rb"
#################################################################
# Sequence 2 Sequence - Tensorflow							   	#
#																#
# 		WORK IN PROGRESS!!!!!!!!!!!!!!!!!!!!!!!!!				#
#################################################################
class Seq2Seq < OllieMlSupervisedBase
	def initialize data, targets, parameters
		super data, targets, parameters
			
	end
	def trainingData
		inputs = @trainingData.data
	end
	def trainingTarget
		 targets = @target.data #TensorFlow::placeholder(Integer, [nil, nil], name='targets') 
	end
	def train
		## Who knows what happenin' here, figure it out at some point
		inputData 		= trainingData
		targetData		= trainingTarget
		
		targetLength	= @trainingData.features.length#TensorFlow::placeholder(Integer, [nil], name='target_sequence_length')
		maxTargetLength = targetLength # TensorFlow::reduce_max(target_sequence_length) 
		
		go_id = 1 || target_vocab_to_int['<GO>']
    
		after_slice = inputData#TensorFlow::strided_slice(targetData, [0, 0], [targetLength, -1], [1, 1])
		after_concat = TensorFlow::concat( [TensorFlow::fill([inputData.length, 1], go_id), after_slice], 1)
	end
end
