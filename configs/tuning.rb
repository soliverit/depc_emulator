require "./configs/basics.rb"
##
# Include all supervised models
##
Lpr.p """
##
# Load the HP-Tuning libraries
##
"""
Dir[TUNING_PATH + "*"].sort{|a,b|
	a = a.split("/").last.split("\\").last.split(".").first
	b = b.split("/").last.split("\\").last.split(".").first
	a.match("_").to_s <=> b.match("_").to_s
}.each{|path|
	Lpr.d "Loading: #{path}"
	require path
}