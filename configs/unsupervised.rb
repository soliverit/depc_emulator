require "./configs/basics.rb"
##
# Include all unsupervised models
##
Lpr.p """
##
# Load all unsupervised learning models
##
"""
Dir[UNSUPERVISED_MODELS_PATH + "*"].each{|model|
	Lpr.d "Loading: #{model}"
	require model
}