require "./configs/basics.rb"

Lpr.info "Load all Predictions and PredictionSet(s)"

Dir[PREDICTION_MODELS_PATH + "*"].sort{|a,b|
	a = a.split("/").last.split("\\").last.split(".").first
	b = b.split("/").last.split("\\").last.split(".").first
	a.match("_").to_s <=> b.match("_").to_s
}.each{|path|
	Lpr.d "Loading: #{path}"
	require path
}