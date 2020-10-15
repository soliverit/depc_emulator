class Building
	LIGHTING_GAINS_BASE		= 59.73	# From SAP doc Appendix L
	APPLIANCE_GAINS_BASE	= 207.8 #L2 Appendix L
	METABOLIC_RATE			= 60.0	# From SAP doc 
	HEAT_LOSSES				= -40.0	# From SAP doc
	### 
	# Static stuff
	###
	class BuildingReference
		attr_reader :ageBandDataSet, :windowParams, :glazingTypes, :roofTypes, :floorTypes, :wallTypes, :thermalBData, :heatingAdjData, :wallThicknessData
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
			puts @glazingTypes.to_json
			@roofTypes			= RegressionDataSet.parseGemCSV @path + ROOF_TYPES_PATH
			@floorTypes			= RegressionDataSet.parseGemCSV @path + FLOOR_TYPES_PATH
			@wallTypes			= RegressionDataSet.parseGemCSV @path + WALL_TYPES_PATH
			@thermalBData		= RegressionDataSet.parseGemCSV @path + THERMAL_BRIDGE_PATH
			@heatingAdjData		= RegressionDataSet.parseGemCSV @path + HEATING_ENUMS_PATH
			@wallThicknessData	= RegressionDataSet.parseGemCSV @path + WALL_THICKNESS_PATH
		end
	end
	@@reference = false
	def self.referenceData path
		@@reference ||= BuildingReference.new path
	end
	######
	# Initialise
	######
	def initialize data
		@data 		= data
		@original 	= data.dup
		# Do this now  
		doBuildingStates
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
	# Heat losses
	##
	def latentGains 
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
	############################################
	# 	Feature extraction
	############################################
	### Age stuff ###
	def findAge
		@foundAge ||= BuildingReference.ageBandDataSet.find{|ageData| data[:CONSTRUCTION_AGE_BAND].match(ageData[labelKey].to_s)}
	end
	def ageIndex
		findAge[:INDEX]
	end
	def ageLabel
		findAge[:LABEL]
	end
	def ageGroup
		ageIndex / 4
	end
	#####
	def propertyType
		@data[:PROPERTY_TYPE]
	end
	def mainFuelFactor
		case data[:MAIN_FUEL]
		when /electricity/i
			data[:MAIN_FUEL] = 0.519
		when /lpg/i
			data[:MAIN_FUEL] = 0.245
		when /oil/
			data[:MAIN_FUEL] = 0.297
		when /gas/i
			data[:MAIN_FUEL] = 0.216
		when /dual/i
			data[:MAIN_FUEL] = 0.206
		when /smokeless/i
			data[:MAIN_FUEL] = 0.392
		when /coal/i
			data[:MAIN_FUEL] = 0.291
		when /no heating/i
			data[:MAIN_FUEL] = 0
		when /community/i
			data[:MAIN_FUEL] = 0.24
		else
			data[:MAIN_FUEL] = -1	
		end
	end
	def doBuildingStates
		case @data[:BUILT_FORM].to_s
		when "Detached"
			@data[:IS_DETACHED] = 1
		when "Mid-Terrace"
			@data[:IS_MID] = 1
		when "End-Terrace"
			@data[:IS_END] = 1
		when "Semi-Detached"
			@data[:IS_END] = 1
		when "Enclosed Mid-Terrace"
			@data[:IS_MID] = 1
			@data[:IS_ENCLOSED] = 1
		when "Enclosed End-Terrace"
			@data[:IS_END] = 1
			@data[:IS_ENCLOSED] = 1
		end
		case @data[:FLOOR_LEVEL].to_s
		when /basement/i
			@data[:IS_BASEMENT] = 1
		when /ground/i
			@data[:FLOOR_LEVEL] = 0
		when /top/i
			@data[:IS_ROOF] = 1
		else
			@data[:FLOOR_LEVEL] = 1
		end
		### Corridors
		if @data[:HEAT_LOSS_CORRIDOOR] == "NO DATA!"
			@data[:HEAT_LOSS_CORRIDOOR] 	= 0
		elsif @data[:HEAT_LOSS_CORRIDOOR] == "no corridor"
			@data[:HEAT_LOSS_CORRIDOOR] 	= 0
		else
			@data[:HEAT_LOSS_CORRIDOOR] = HEAT_LOSS_CORRIDOOR_ENUMS.find_index @data[:HEAT_LOSS_CORRIDOOR]
		end
		# Lighting
		if ! @data[:LOW_ENERGY_LIGHTING].to_s.match(/\d/) 
			@data[:LOW_ENERGY_LIGHTING] 	= 0
		end
		# Ventilation strategy
		case @data[:MECHANICAL_VENTILATION]
		when "mechanical, extract only"
			@data[:MECHANICAL_EXTRACT] 		= 1
		when  "mechanical, supply and extract"
			@data[:MECHANICAL_EXTRACT] 		= 1
			@data[:MECHANICAL_SUPPLY] 		= 1	
		end
		# Glazing
		if @data[:GLAZED_TYPE].match(/double/i)
		puts @glazingTypes
			gType = @glazingTypes.find{|gType| 
					@data[:GLAZED_TYPE].downcase.match(/double/i) && 
					@data[:GLAZED_TYPE].downcase.match(gType[:When].downcase)
			}
		else
			gType = @glazingTypes.find{|gType| @data[:GLAZED_TYPE].downcase.match(gType[labelKey])}
		end
		@data[:GLASS_U_VALUE] = gType[:U_Value]
		@data[:GLASS_G_VALUE] = gType[:g_Value]
		case @data[:GLAZED_AREA]
		when /less/i
			-1
		when /normal/i
			0
		when /more/i
			1
		end
		### Constructions 
		case @data[:ROOF_DESCRIPTION]
		when /pitch/i
			@data[:ROOF_U_VALUE] = roofAgeRecord[:U_Value_Pitched]
		when /flat/i
			@data[:ROOF_U_VALUE] = roofAgeRecord[:U_Value_Flat]
		when /room/i
			@data[:ROOF_U_VALUE] = roofAgeRecord[:U_Value_Pitched]
		else /other dwelling/ # Adiabtic 
			@data[:ROOF_U_VALUE] = 0
		end
		
		case @data[:FLOOR_DESCRIPTION]
		when /no\s|assumed|insulated/i
			@data[:FLOOR_U_VALUE] = floorType[:U_Value_Unknown]
		when /50 mm/
			@data[:FLOOR_U_VALUE] = floorType[:U_Value_50mm]
		when /100 mm/
			@data[:FLOOR_U_VALUE] = floorType[:U_Value_100mm]
		when /200 mm|premise/
			@data[:FLOOR_U_VALUE] = floorType[:U_Value_150mm]
		when /other dwelling/i #Adiabatic
			@data[:FLOOR_U_VALUE] = 0
		end
		
		@data[:WALL_THICKNESS] = wallThicknessData.find{|wtData| @data[:WALLS_DESCRIPTION].match(wtData[labelKey])}[@data[:AGE_LABEL].to_sym] rescue -1
	
		if uValue = data[:WALLS_DESCRIPTION].to_s.match(/(0\.\d{1,3})/)
			@data[:WALL_U_VALUE] 	= uValue[1].to_f
		else
			wallType = wallTypes.find{|wData|
				@data[:WALLS_DESCRIPTION].downcase.match(wData[labelKey].downcase) && 
				@data[:WALLS_DESCRIPTION].downcase.match(wData[:Insulation].downcase)
			}
			begin
				@data[:WALL_U_VALUE] = wallType[data[:AGE_LABEL].to_sym]
			rescue
				@data[:WALL_U_VALUE] = -1
			end
		end
		@data[:THERMAL_BRIDGING_FACTOR] = thermalBData.find{|tbData| tbData[labelKey] == @data[:AGE_LABEL]}[:FACTOR]
		
		windowFuncParams = windowParams.find{|wData| wData[labelKey] == data[:AGE_LABEL]}
		case @data[:GLAZED_AREA]
		when /much less/i
			factor = -1.4
		when /less/i
			factor = -1.25
		when /normal/i
			factor = 1.0
		when /much more/i
			factor = 1.4
		when /more/i
			factor = 1.25	
		end
		#Identify building type
		if @data[:PROPERTY_TYPE].match(/house|bungalow/i)
			@data[:WINDOW_AREA] = @data[:TOTAL_FLOOR_AREA] * windowFuncParams[:house] + windowFuncParams[:house_plus] * factor
		else
			@data[:WINDOW_AREA] = @data[:TOTAL_FLOOR_AREA] * windowFuncParams[:flat] + windowFuncParams[:flat_plus] * factor
		end 
		
		@data[:WAR] = 1 - @data[:WINDOW_AREA] / @data[:TOTAL_FLOOR_AREA]
	end
	def isMid?
		@data[:IS_MID]
	end
	def isEnd?
		@data[:IS_MID]
	end
	def isEnclosed?
		@data[:IS_ENCLOSED]
	end
	def isDetached?
		@data[:IS_DETACHED]
	end
	def mainHeatingControls
		puts "WARNING! Man heating controls doesn't enumerate yet!"
		@data[:MAIN_HEATING_CONTROLS]
	end
	def extensionCount
		@data[:EXTENSION_COUNT] || 0
	end
	def isTopStoreyFlat?
		@data|@data[:FLAT_TOP_STOREY] ||= @data[:FLAT_TOP_STOREY].downcase == "y" ? 1 : 0
	end
	def iBasement?
		@data[:IS_BASEMENT] 
	end
	def temperatureAdjustment
		@heatingAdjData.find{|haData| 
			data[:MAIN_HEATING_CONTROLS] == haData[labelKey]
		}[:Temperature_Adjustment] rescue 0
	end
	def minGasFlag
		@mainsGasFlag ||= case data[:MAINS_GAS_FLAG].to_s.downcase
		when "y"
			data[:MAINS_GAS_FLAG] = 1
		when "n"
			data[:MAINS_GAS_FLAG] = 0
		else
			data[:MAINS_GAS_FLAG] = data[:MAIN_FUEL].to_s.match(/gas/i) ? 1 : 0
		end
	end
	def energyTariff
		@energyTariff ||= case @data[:ENERGY_TARIFF]
		when /single/i
			data[:ENERGY_TARIFF] = 0
		when /dual/i
			data[:ENERGY_TARIFF] = 1
		else
			data[:ENERGY_TARIFF] = 0
		end
	end
	def wetRooms
		case @data[:NUMBER_HABITABLE_ROOMS]
		when 1..2
			1
		when 3..4
			2
		when 5..6
			3
		when 7..8
			4
		when 9..10
			5
		else
			6
		end
	end
	def heatLossCorridor
		@data[:HEAT_LOSS_CORRIDOR]
	end
	def floorLevel
		@data[:FLOOR_LEVEL] 		||= 0
	end
	def hwPipeInsulation
		@data[:HW_PIPE_INSULATION] 	||= ["J", "K", "L"].include?( data[:AGE_BAND]) ? 1 : 0
	end
	def hwCommunity
		@data[:HW_COMMUNITY] 		||= data[:HOTWATER_DESCRIPTION].match(/community/i) ? 1 : 0
	end
	def hwIsInstantaneous?
		@data[:HW_IS_INSTANTANEOUS] ||= @data[:HOTWATER_DESCRIPTION].match(/instantaneous/i) ? 1 : 0
	end
	def hasSolarWater?
		@data[:HAS_SOLAR_WATER] 	||= @data[:HOTWATER_DESCRIPTION].match(/solar/i) ? 1 : 0
	end
	def offPeakHotWater?
		@data[:HW_IS_OFF_PEAK] 		||= @data[:HOTWATER_DESCRIPTION].match(/off(-| )peak/i) ? 1 : 0
	end
	def hwIsGas?
		 @data[:HW_IS_GAS] 			||= @data[:HOTWATER_DESCRIPTION].match(/gas/i) ? 1 : 0
	end
	def lowEnergyLighting
		@data[:LOW_ENERGY_LIGHTING]
	end
	def hwFromMainSystem?
		@data[:HW_FROM_MAIN_SYSTEM]	||= @data[:HOTWATER_DESCRIPTION].match(/from main system/i) ? 1 : 0
	end
	def hasHotWaterCylinder?
		@data[:HW_CYLINDER] 		||= @data[:HOTWATER_DESCRIPTION].match(/no cylinder/i) ? 0 : 1
	end
	def hotWaterDescription
		puts "WARNING Hot water description isn't enumerated"
		@data[:HOTWATER_DESCRIPTION] 
	end
	def heatingHasTank?
		@data[:HAS_TANK] 			||= @data[:MAINHEAT_DESCRIPTION].match(/boiler|storage|immersion/i) ? 1: 0
	end
	def hasRadiators?
		@data[:HAS_RADIATORS] 		||= @data[:MAINHEAT_DESCRIPTION].match(/radiator/i) ? 1 : 0
	end
	def hasUnderfloorHeating?
		@data[:UNDERFLOOR_HEATING]	||= @data[:MAINHEAT_DESCRIPTION].match(/underfloor/i) ? 1 : 0
	end
	def secondHeatDescription
		case @data[:SECONDHEAT_DESCRIPTION]
		when /electricity/i
			@data[:SECONDHEAT_DESCRIPTION] = 0.519
		when /lpg/i
			@data[:SECONDHEAT_DESCRIPTION] = 0.245
		when /oil/
			@data[:SECONDHEAT_DESCRIPTION] = 0.297
		when /gas/i
			@data[:SECONDHEAT_DESCRIPTION] = 0.216
		when /dual/i
			@data[:SECONDHEAT_DESCRIPTION] = 0.206
		when /smokeless/i
			@data[:SECONDHEAT_DESCRIPTION] = 0.392
		when /coal/i
			@data[:SECONDHEAT_DESCRIPTION] = 0.291
		when /no heating/i
			@data[:SECONDHEAT_DESCRIPTION] = 0
		when /community/i
			@data[:SECONDHEAT_DESCRIPTION] = 0.24
		else
			@data[:SECONDHEAT_DESCRIPTION] = -1
		end
	end
	def mainHeatDescription
		puts "WARNING Main heat description not enumerated"
		@data[MAINHEAT_DESCRIPTION]
	end
	def qualityProperties
		puts "WARNING you've no done the quality properties"
	end
	def glazedSizeFactor
		@data[:GLAZED_SIZE_FACTOR]
	end
	def roofUValue
		@data[:ROOF_U_VALUE]
	end
	def thermalBridgingFactor
		@data[:THERMAL_BRIDGING_FACTOR]
	end
	def windowArea
		@data[:WINDOW_AREA]
	end
	def wndowFloorArea
		@data[:WAR]
	end
	
	
	
	############################################
	#	Retrofitting
	############################################
	
	
	MIN_WALL_U_VALUE 	= 0.6
	REP_WALL_U_VALUE	= 0.3
	
	MIN_FLOOR_U_VALUE	= 0.5
	REP_FLOOR_U_VALUE	= 0.18
	MIN_ROOF_U_VALUE	= 0.5
	REP_ROOF_U_VALUE	= 0.18
	
	REP_HW_EFF			= 4
	##
	# Replace low energy lightng 
	##
	def retrofitLightng 
		if @data[:LOW_ENERGY_LIGHTING] != 0
			@data[:LOW_ENERGY_LIGHTING] = 0
		else
			0
		end
	end
	##
	# Retrofit walls
	##
	def retrofitWalls u_value
		if @data[:WALL_U_VALUE] > MIN_WALL_U_VALUE
			@data[:WALL_U_VALUE] = REP_WALL_U_VALUE
		end
	end
	def retrofitRoof u_value
		if @data[:ROOF_U_VALUE] > MIN_ROOF_U_VALUE
			@data[:ROOF_U_VALUE] = REP_ROOF_U_VALUE
		end
	end
	def retrofitFloors u_value
		if @data[:FLOOR_U_VALUE] > MIN_FLOOR_U_VALUE
			@data[:FLOOR_U_VALUE] = REP_FLOOR_U_VALUE
		end
	end
	def replaceHotWater 
		if @data[:HOT_WATER_ENERGY_EFF] < REP_HW_EFF
			@data[:HOT_WATER_ENERGY_EFF] = REP_HW_EFF
		end
	end
end