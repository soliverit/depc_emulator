#
# Includes
#
# Native ##
require "xgb"
# Library ##
require "./lib/ollie_ml_supervised_base.rb"
#################################################################
# XGBoost
#################################################################
Lpr.p "MESSAGE FROM XGBoost!!! At some point you need to alias a predict method
so you don't need a conditional check on every prediction. predict(input) calls predict_it
or something like that"
class XGB < OllieMlSupervisedBase
	DEFAULT_PARAMETERS = {objective: "reg:squarederror", type: XGBoost::Classifier}
	def initialize data, target, parameters
		super data, target, parameters
		DEFAULT_PARAMETERS.each{|key, value| @parameters[key] ||= value}
	end
	def trainingData
		getFeatureData(@trainingData).data	
	end
	def trainingTargets
		@trainingData.retrieveFeatureAsArray @target
	end
	def train
		data		= XGBoost::DMatrix.new(trainingData, label: trainingTargets)
		constructor	= @parameters[:type]
		@parameters.delete :type
		@lr			= constructor.new @parameters
		@lr.fit(trainingData, trainingTargets)
	end
	def translateFeatureInput input
		[input]
	end
	def predict input 
		if @parameters[:type] == XGBoost::Classifier
			# @lr.predict_proba input
			@lr.predict input
		else
			@lr.predict input
		end
	end
end
