require_relative "../../predictions/prediction.rb"
require_relative "../../regression_data_set.rb"
class MachineSet
	def initialize
		@machines = []
	end
	def push machine
		@machines.push machine
	end
	def [] idx
		@machines[idx]
	end
	def length 
		@machines.length
	end
	def keys
		(0...@machines.length).map{|i| i.to_s.to_sym}
	end
	def each 
		@machines.each{|machine|
			yield machine	
		}
	end
	def predictWithAll rgDataSet, targets
		results = RegressionDataSet.new false, (0...@machines.length).map{|idx| idx.to_s.to_sym}
		rows	= (0...rgDataSet.length).map{[]}
		@machines.each_with_index{|machine, idx|
			predictions = machine.validateSet rgDataSet, targets, Prediction
			predictions.getError.printTable
			(0...predictions.length).each{|i| 
				rows[i][idx] = predictions.set[i].prediction}
		}
		rows.each{|row| results.push row}
		results
	end
end