class Building
	LIGHTING_GAINS_BASE		= 59.73	# From SAP doc Appendix L
	APPLIANCE_GAINS_BASE	= 207.8 #L2 Appendix L
	METABOLIC_RATE			= 60.0	# From SAP doc 
	HEAT_LOSSES				= -40.0	# From SAP doc
	### 
	# Static stuff
	###
	class BuildingReference
		attr_reader :ageBandDataSet, :windowParams, :glazingTypes, :roofTypes, :floorTypes,
					:wallTypes, :thermalBData, :heatingAdjData, :wallThicknessData
		TEMP_PATH			= "/temp.csv"
		AGE_BAND_PATH		= "/age_band_lookup.csv"
		WINDOW_PARAMS_PATH	= "/window_parameters.csv"
		GLAZING_TYPES_PATH	= "/glazing_types.csv"
		ROOF_TYPES_PATH		= "/roof_constructions.csv"
		FLOOR_TYPES_PATH	= "/floor_constructions.csv"
		WALL_TYPES_PATH		= "/wall_constructions.csv"
		THERMAL_BRIDGE_PATH	= "/thermal_bridging.csv"
		HEATING_ENUMS_PATH	= "/heating_table_4e.csv"
		WALL_THICKNESS_PATH	= "/wall_thickness.csv"
		def initialize path
			@path				= path
			@ageBandDataSet		= RegressionDataSet.parseGemCSV @path + AGE_BAND_PATH
			@windowParams		= RegressionDataSet.parseGemCSV @path + WINDOW_PARAMS_PATH
			@glazingTypes		= RegressionDataSet.parseGemCSV @path + GLAZING_TYPES_PATH
			@roofTypes			= RegressionDataSet.parseGemCSV @path + ROOF_TYPES_PATH
			@floorTypes			= RegressionDataSet.parseGemCSV @path + FLOOR_TYPES_PATH
			@wallTypes			= RegressionDataSet.parseGemCSV @path + WALL_TYPES_PATH
			@thermalBData		= RegressionDataSet.parseGemCSV @path + THERMAL_BRIDGE_PATH
			@heatingAdjData		= RegressionDataSet.parseGemCSV @path + HEATING_ENUMS_PATH
			@wallThicknessData	= RegressionDataSet.parseGemCSV @path + WALL_THICKNESS_PATH
		end
	end
	@@reference
	def self.loadReferrenceData path
		BuildingReference.new path
	end
	######
	# Initialise
	######
	def initialize data
		@data = data
	end
	def area
		@data[:TOTAL_FLOOR_AREA]
	end
	def [] key
		@data[key]
	end
	##################################################
	# Build features hee
	#
	#
	##################################################
	def ageBand 
	end
	##
	# Appliance power density  (L13)
	##
	def appliances
		APPLIANCE_GAINS_BASE * (area * occupants) ** 0.4714
	end
	
	
	##
	# Internal gains from lighting, appliances and people
	##
	def internalGains
		occupants * METABOLIC_RATE + lighting + appliances - losses
	end
	##
	#
	##
	def losses 
		occupants * HEAT_LOSSES
	end
	##
	# Lighting power density (L12)
	##
	def lighting
		if @data[:LOW_ENERGY_FIXED_LIGHT_COUNT]  && @data[:LOW_ENERGY_FIXED_LIGHT_COUNT] != "" && @data[:LOW_ENERGY_FIXED_LIGHT_COUNT] != 0 
			lowEnergyLigthingCorrection	= 1 - 0.5 * (@data[:LOW_ENERGY_FIXED_LIGHT_COUNT].to_f / @data[:FIXED_LIGHTING_OUTLETS_COUNT]) rescue 1
		else
			lowEnergyLigthingCorrection = 1
		end
		lighting = LIGHTING_GAINS_BASE	+ (@data[:TOTAL_FLOOR_AREA] * occupants) ** 0.4714 * 
						lowEnergyLigthingCorrection # From SAP doc
	end
	# From Table 1b SAP doc
	def occupants
		if area < 13.69
			1
		else
			1 + 1.76 * (1 - Math.exp(-0.000349 * (area - 13.9) ** 2)) + 0.0013 * (area - 13.69)
		end
	end
end