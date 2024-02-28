require "active_support"
#################################################################
# Struct containing generic error rates produced, currently		#
# by PredictionSet's getError									#
#################################################################
class ErrorInformation 
	attr_reader :predictionIndex, :min, :max, :negativeMin, :negativeMax, 
				:absMin, :absMax, :rmse, :simple, :mae, :worstPrediction, 
				:bestPrediction, :perMin, :perMax, :pass, :fail, :r2
	cattr_accessor :bestWorstPrint, :bestWorstFeatures
	### Print the details of the best and worst Predictions in printOut
	@@bestWorstPrint 	= false
	### Print the features of the best and worst Predictions in printOut
	@@bestWorstFeatures	= false
	##
	# @min:				Minimum positive error. Numeric
	# @max:				Maximum positive error. Numeric
	# @negativeMin:		Minimum negative error. Numeric (@negativeMax < @negativeMin < 0)
	# @negativeMax		Maximum negative error. Numeric (@negativeMax < @negativeMin < 0)
	# @absMin:			Minimum absolute error. Numeric
	# @absMax:			Maximum absolute error. Numeric
	# @rmse:			Root mean squared error. Numeric
	# @mae:				Mean absolute error. Numeric
	# @mare:				Mean relative error
	# @simple:			Mean error. Numeric (couldn't remember the word for mean during creation)
	# @worstPrediction:	Prediction object with the highest absolute error
	# @bestPrediction:	Prediction object with the lowest absolute error
	# @predictionIndex:	The Prediction.predictionSet[] index the values are based on
	##
	def initialize pIndex, min, max, negativeMin, negativeMax, absMin, absMax,relErr, rmse, simple, mae, perMin, perMax, worstPrediction, bestPrediction, pass, fail, r2
		@min				= min
		@max				= max
		@negativeMin		= negativeMin
		@negativeMax		= negativeMax
		@absMin				= absMin
		@absMax				= absMax
		@perMin				= perMin
		@perMax				= perMax
		@rmse				= rmse
		@simple				= simple
		@mae				= mae
		@mare				= relErr
		@worstPrediction	= worstPrediction
		@bestPrediction 	= bestPrediction
		@pass				= pass
		@fail				= fail
		@r2					= r2
		@predictionIndex	= pIndex
	end
	##
	# SIGH: Convenience method for average error since
	#		I named it @simple for some reason.
	#
	# Output:	Average error. Numeric
	##
	def average
		@simple
	end
	##
	# Print simple Average and RMSE
	##
	def printSimpleError
		Lpr.p "Simple error"
		puts "Average: #{@simple}\tRMSE: #{@rmse}"
		printBestWorst if @@bestWorstPrint
	end
	##
	# Handy, pretty print method for dropping all struct info to the console
	##
	def printOut
		puts "=== Error rates ==="
		puts "STD   - Min:  +#{@min.round(3)}\tMax:+#{@max.round(3)}"
		puts "ABS   - Min:  +#{@absMin.round(3)}\tMax:+#{@absMax.round(3)}"
		puts "NEG   - Min:  #{@negativeMin.round(3)}\tMax: #{@negativeMax.round(3)}"
		puts "PER   - Min:  +#{@perMin.round(3)}\tMax: +#{@perMax.round(3)}"
		puts "ERR   - Avg:  +#{@simple.round(3)}\tRMSE: #{@rmse.round(3)}"
		if @pass
			puts "MATCH - Pass: #{@pass}\tFail: #{@fail}" 
		end
		printBestWorst if @@bestWorstPrint
	end
	##
	# Handy table printer for errors
	#
	# TODO:	Replace with LRPrintHelper table method(s)
	##
	def printTable
		
		puts "=== Error rates ==="
		print(LRPrintHelper.pad(""))
		print(LRPrintHelper.pad "Standard")
		print(LRPrintHelper.pad "Absolute")
		print(LRPrintHelper.pad "Negative")
		print(LRPrintHelper.pad "Percent")
		print(LRPrintHelper.pad "Scale")
		print(LRPrintHelper.pad "Centre")
		print("\n")
		print(LRPrintHelper.pad "Min")
		print(LRPrintHelper.pad @min.round(3))
		print(LRPrintHelper.pad @absMin.round(3))
		print(LRPrintHelper.pad @negativeMin.round(3))
		print(LRPrintHelper.pad @perMin.round(3))
		print(LRPrintHelper.pad (@min - @negativeMin).abs.round(3))
		print(LRPrintHelper.pad (@min + @negativeMin).abs.round(3))
		print("\n")
		print(LRPrintHelper.pad "Max")
		print(LRPrintHelper.pad @max.round(3))
		print(LRPrintHelper.pad @absMax.round(3))
		print(LRPrintHelper.pad @negativeMax.round(3))
		print(LRPrintHelper.pad @perMax.round(3))
		print(LRPrintHelper.pad (@max - @negativeMax).abs.round(3))
		print(LRPrintHelper.pad (@max + @negativeMax).abs.round(3))
		print("\n--- Totals ---\n")
		print(LRPrintHelper.pad "Average")
		print(LRPrintHelper.pad @simple.round(4).to_s)
		print("\n")
		print(LRPrintHelper.pad "MAE")
		print(LRPrintHelper.pad @mae.round(4).to_s)
		print("\n")
		print(LRPrintHelper.pad "RMSE")
		print(LRPrintHelper.pad @rmse.round(4).to_s)
		print("\n")
		print(LRPrintHelper.pad "RMAE")
		print(LRPrintHelper.pad @mare.round(4).to_s)
		print("\n")
		print(LRPrintHelper.pad "r²")
		print(LRPrintHelper.pad @r2.round(4).to_s)
		if @pass
			print("\n--- Classifer score ---\n")
			print(LRPrintHelper.pad "Passed")
			print(LRPrintHelper.pad @pass)
			print("\n")
			print(LRPrintHelper.pad "Failed")
			print(LRPrintHelper.pad @fail)
		end
		print("\n")
		printBestWorst if @@bestWorstPrint
	end
	##
	# Handy, pretty print method for the @best and @worst Prediction objects
	##
	def printBestWorst
		puts "--- Best and worst predictions ---"
		puts "Best  - Actual: #{@bestPrediction.expected.round(3)}\tPredicted: #{@bestPrediction.prediction(@predictionIndex).round(3)}\tPercent:#{@bestPrediction.errorPercent(@predictionIndex).round(3)}"
		@bestPrediction.printInputs if @@bestWorstFeatures
		puts "Worst - Actual: #{@worstPrediction.expected.round(3)}\tPredicted: #{@worstPrediction.prediction(@predictionIndex).round(3)}\tPercent:#{@worstPrediction.errorPercent(@predictionIndex).round(3)}"
		@worstPrediction.printInputs if @@bestWorstFeatures
	end
end
