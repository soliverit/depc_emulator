require "./configs/basics.rb"
##
# Include all supervised models
##
Lpr.p"""
# Load all supervised learning models
"""
Dir[SUPERVISED_MODELS_PATH + "**.rb"].each{|model|
	Lpr.d "Loading: #{model}"
	require model
}