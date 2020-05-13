require "./lib/ollie_ml_base.rb"
#################################################################
# Base class for Unsupervised learning							#
#################################################################
class OllieMlUnsupervisedBase < OllieMlBase
	def initialize data, parameters
		super data, parameters
	end
	def train
		raise "OllieMlUnsupervisedBase::TrainMethodNotDefined"
	end
end
