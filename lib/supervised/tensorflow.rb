##
# Includes
##
## Native ##
require "tensorflow"
## Library ##
require "./lib/ollie_ml_supervised_base.rb"
#################################################################
# TLearn 
#################################################################
class OllieTLearn < OllieMlSupervisedBase
	def train 
		raise "TLearn: Yet to be implemented. Should be base of its own, probably"
		
	end
end
