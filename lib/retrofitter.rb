class Retrofitter
	ALL_RECS_SET 	= [:envelopes, :windows, :hotwater, :roof]
	HW_EFF			= 5
	ROOF_EFF		= 5
	WALL_EFF		= 5
	WINDOW_EFF		= 5
	HW_COST			= 1000
	ROOF_COST		= 15
	WALL_COST		= 660 / 80
	WINDOW_COST		= 110
	SITE_VISIT_COST	= 100
	def self.powerset input
		output = [input]
		if input.length > 1
			input.each_with_index{|key|
				keyID = input.find_index{|val| val == key}
				output.push input.select{|inKey| inKey != key}
				if output.last.any?
					newSet = powerset output.last
					newSet.each{|n| output.push n}
				end
			}
		end
		output.uniq
	end
	def initialize building, scorer
		@building 	= building
		@scorer		= scorer
	end
	def apply recs
		@patient = @building.clone
		cost = recs.sum{|rec|
			value = send rec
			if value == 0
				return Retrofit.new recs, -1, -1
			end
			value
		}
		score = @scorer.predict @patient.extractFeatures(@scorer.features)
		@patient			= false
		Retrofit.new recs, score, cost
		
	end
	def hotwater
		return 0 if @patient.hwEnergyEff == HW_EFF
		@patient.setHotwaterEnergyEff HW_EFF
		HW_COST
	end
	def roof
		return 0 if @patient.roofEnergyEff == ROOF_EFF
		@patient.setRoofEnergyEff ROOF_EFF
		@patient.roofUValue = 0.18
		@patient.area * ROOF_COST
	end
	def windows
		return 0 if @patient.windowsEnergyEff == WINDOW_EFF
		@patient.setWindowsEnergyEff WINDOW_EFF
		@patient.area * WINDOW_COST
	end
	def envelopes
		return 0 if @patient.wallsEnergyEff == WALL_EFF
		@patient.setWallsEnergyEff WALL_EFF
		@patient.wallUValue = 0.3
		@patient.area * WALL_COST
	end
end
class Retrofit
	attr_reader :recs, :score, :cost
	def initialize recs, score, cost
		@recs 		= recs
		@score		= score
		@cost		= cost
	end
	def key
		recs.sort{|a, b| b <=> b}.join("_")
	end
	def costKey
		key + "-Cost"
	end
	def energyEffKey
		key + "-Eff"
	end
end
