class Building
	##
	# TEMPORARY!!!!!!!!!!!!!
	##
	attr_reader :data, :corrupt
	################
	LIGHTING_GAINS_BASE		= 59.73	# From SAP doc Appendix L
	APPLIANCE_GAINS_BASE	= 207.8 #L2 Appendix L
	METABOLIC_RATE			= 60.0	# From SAP doc 
	HEAT_LOSSES				= -40.0	# From SAP doc
	QUALITY_ENUMS 			= ["N/A", "Very Poor", "Poor", "Average", "Good", "Very Good"]
	QUALITY_FEATURES		= [:SHEATING_ENERGY_EFF, :HOT_WATER_ENERGY_EFF,						
								:LIGHTING_ENERGY_EFF, :ROOF_ENERGY_EFF, 
								:WALLS_ENERGY_EFF, :WINDOWS_ENERGY_EFF, 
								:MAINHEAT_ENERGY_EFF]
	GLAZED_AREA_ENUMS	= ["NO DATA!","Less Than Typical", "Normal",
						 "More Than Normal","Much More Than Normal"]
	HEAT_LOSS_CORRIDOOR_ENUMS = [ "heated corridor", "unheated corridor"]
	### 
	# Static stuff
	###
	class BuildingReference
		attr_reader :ageBandDataSet, :windowParams, :glazingTypes, :roofTypes, :floorTypes, :wallTypes, :thermalBData, :heatingAdjData, :wallThicknessData, :heatingControls
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
		HEAT_CONTROL_PATH	= "/heating_controls.csv"
		DATA_DIR_PATH		= "./data/"
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
			@heatingControls	= RegressionDataSet.parseGemCSV @path + HEAT_CONTROL_PATH
			@corrupt			= false
		end
	end
	def extractFeatures features
		Hash[features.map{|feature|
			[ feature, send(feature)]
		}]
	end
	def errors?
		@corrupt
	end
	def reference
		@@reference ||= BuildingReference.new BuildingReference::DATA_DIR_PATH 
	end
	######
	# Initialise
	######
	def clone 
		self.class.new @data.clone, true
	end
	def initialize data, fromCache = false
		@data 		= data
		@original 	= data.dup
		# Do this now  
		doBuildingStates unless fromCache
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
	#
	#	WARNING: No idea what losses were but no time to worry.
	##
	def internalGains
		occupants * METABOLIC_RATE + lighting + appliances # - losses
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
		lighting = LIGHTING_GAINS_BASE	+ (@data[:TOTAL_FLOOR_AREA] * occupants) ** 0.4714 * lowEnergyLigthingCorrection # From SAP doc
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
		@foundAge ||= reference.ageBandDataSet.find{|ageData| 
			@data[:CONSTRUCTION_AGE_BAND].match(ageData[:LABEL].to_s)
		}
	end
	def ageIndex
		findAge[:INDEX]
	end
	def ageLabel
		findAge[:LABEL]
	end
	def ageBand
		findAge[:BAND]
	end
	def ageGroup
		ageIndex / 4
	end
	#####
	def propertyType
		@data[:PROPERTY_TYPE]
	end
	def mainFuelFactor
		@mainFuelFactor ||= case @data[:MAIN_FUEL]
		when /electricity/i
			 0.519
		when /lpg/i
			 0.245
		when /oil/
			 0.297
		when /gas/i
			 0.216
		when /dual/i
			 0.206
		when /smokeless/i
			 0.392
		when /coal/i
			 0.291
		when /no heating/i
			 0
		when /community/i
			 0.24
		else
			 -1	
		end
	end
	
	def doBuildingStates
		##
		# First error case: Can't find age
		##
		if ! findAge
			@corrupt = "Error: Couldn't find age"
			return
		end
		if ! area || ! area.is_a?(Numeric) || area <=0 
			@corrupt = "Zero area"
			return
		end
		@data[:IS_MID] 		= 0
		@data[:IS_END] 		= 0
		@data[:IS_ENCLOSED]	= 0
		@data[:IS_DETACHED]	= 0
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
			@data[:MECHANICAL_SUPPLY] 		= 0
		when  "mechanical, supply and extract"
			@data[:MECHANICAL_EXTRACT] 		= 1
			@data[:MECHANICAL_SUPPLY] 		= 1	
		else 
			@data[:MECHANICAL_EXTRACT] 		= 0
			@data[:MECHANICAL_SUPPLY] 		= 0
		end
		# Glazing
		if @data[:GLAZED_TYPE].match(/double/i)
			gType = reference.glazingTypes.find{|gType| 
					@data[:GLAZED_TYPE].downcase.match(/double/i) && 
					@data[:GLAZED_TYPE].downcase.match(gType[:When].downcase)
			}
		elsif @data[:GLAZED_TYPE].match(/invalid|not def|no data/i)
			@corrupt = "Error: Glazed type: #{@data[:GLAZED_TYPE]}"
			return
		else
			gType = reference.glazingTypes.find{|gType|  @data[:GLAZED_TYPE].downcase.match(gType[:LABEL])}
		end
		unless gType
			gType = {U_Value: 0, g_Value: 0}
		end

		@data[:GLASS_U_VALUE] = gType[:U_Value]
		@data[:GLASS_G_VALUE] = gType[:g_Value]
		
		case @data[:GLAZED_AREA]
		when /less/i
			-1
		when /more/i
			1
		when /normal/i
			0
		else
			0
		end
		### Constructions 
		roofAgeRecord = reference.roofTypes.find{|rData|
			findAge[:BAND] == rData[:BAND]}
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

		floorType = reference.floorTypes.find{|fData|fData[:LABEL] == @data[:AGE_BAND]}
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
		else
			@corrupt = "Unable to find Floor U Value"
			return
		end
		
		@data[:WALL_THICKNESS] = reference.wallThicknessData.find{|wtData|
			@data[:WALLS_DESCRIPTION].match(wtData[:Key])}[ageBand.to_sym] rescue -1
		if uValue = @data[:WALLS_DESCRIPTION].to_s.match(/(0\.\d{1,3})/)
			@data[:WALL_U_VALUE] 	= uValue[1].to_f
		else
			wallType = reference.wallTypes.find{|wData|
				@data[:WALLS_DESCRIPTION].downcase.match(wData[:"Wall Type"].downcase) && 
				@data[:WALLS_DESCRIPTION].downcase.match(wData[:Insulation].downcase)
			}
			unless wallType
				@corrupt = "Error: Couldn't match construction type"
				return	
			end

			@data[:WALL_U_VALUE] = wallType[ageBand.to_sym]

		end
		
		@data[:MAIN_HEATING_CONTROLS] 	= 0 if @data[:MAIN_HEATING_CONTROLS].nil?
		@data[:THERMAL_BRIDGING_FACTOR]	= reference.thermalBData.find{|tbData| tbData[:LABEL] == @data[:AGE_LABEL]}[:FACTOR]
		
		windowFuncParams = reference.windowParams.find{|wData|wData[:LABEL] == ageBand}
		factor = case @data[:GLAZED_AREA]
		when /much less/i
			-1.4
		when /less/i
			-1.25
		when /normal/i
			1.0
		when /much more/i
			1.4
		when /more/i
			1.25	
		else
			0
		end
		#Identify building type
		if @data[:PROPERTY_TYPE].match(/house|bungalow/i)
			@data[:WINDOW_AREA] = area * windowFuncParams[:house] + windowFuncParams[:house_plus] * factor
		else
			@data[:WINDOW_AREA] = area * windowFuncParams[:flat] + windowFuncParams[:flat_plus] * factor
		end 
		
		@data[:WAR] = 1 - @data[:WINDOW_AREA].to_f / @data[:TOTAL_FLOOR_AREA]
		if @data[:WAR].nan?
			@corrupt = true
			puts "WAR is wrong #{@data[:WAR]}"
			return
		end
		##
		# Do Quality properties  (1 to 5, poor to excellent)
		##
		QUALITY_FEATURES.each{|qFeature|
			@data[qFeature] = QUALITY_ENUMS.find_index @data[qFeature]
		}
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
		@data[:HEATING_CONTROL_ENUM] ||= reference.heatingAdjData.find{|hcData| 
			@data[:MAIN_HEATING_CONTROLS] == hcData[:ID]
		}
	end
	def mainControllerDescription
		@data[:MAINHEATCONT_DESCRIPTION]
	end
	def heatingControlIndex
		return @data[:HEATING_CONTROL_INDEX] if @data[:HEATING_CONTROL_INDEX]
		controls = mainHeatingControls
		@data[:HEATING_CONTROL_INDEX] = if controls 
			mainHeatingControls[:Control_Type]
		else
		################### Should probably be  0 or -1
			0
		end
		
	end
	def setHeatingContronIndex value
		@data[:HEATING_CONTROL_INDEX] = value
	end
	def extensionCount
		@data[:EXTENSION_COUNT] || 0
	end
	def isTopStoreyFlat?
		@data[:IS_TOP_STOREY] ||= @data[:FLAT_TOP_STOREY].downcase == "y" ? 1 : 0
	end
	def isBasement?
		@data[:IS_BASEMENT] 
	end
	def trvs?
		@data[:TEMP_ADJUSTMENT] != 0 && @data[:HEATING_CONTROL_INDEX] != 2
	end
	def temperatureAdjustment
		return @data[:TEMP_ADJUSTMENT] if @data[:TEMP_ADJUSTMENT]
		controls = mainHeatingControls
		if controls
			@data[:TEMP_ADJUSTMENT] = controls[:Temperature_Adjustment] 
		else
			@data[:TEMP_ADJUSTMENT] = 0
		end
	end
	
	def setTemperatureAdjustment value
		@data[:TEMP_ADJUSTMENT] = value
	end
	def mainHeatEnergyEff
		@data[:MAINHEAT_ENERGY_EFF]
	end
	def setMainHeatEnergyEff value
		@data[:MAINHEAT_ENERGY_EFF] = value
	end
	def roofEnergyEff
		@data[:ROOF_ENERGY_EFF]
	end
	def setRoofEnergyEff value
		@data[:ROOF_ENERGY_EFF] = value
	end
	def wallsEnergyEff
		@data[:WALLS_ENERGY_EFF]
	end
	def setWallsEnergyEff value
		@data[:WALLS_ENERGY_EFF] = value
	end
	def windowsEnergyEff 
		@data[:WINDOWS_ENERGY_EFF]
	end
	def setWindowsEnergyEff value
		@data[:WINDOWS_ENERGY_EFF] = value
	end
	def mainsGasFlag
		@data[:MAINS_HAS_GAS_FLAG] ||= case @data[:MAINS_GAS_FLAG].to_s.downcase
		when "y"
			 1
		when "n"
			0
		else
			@data[:MAIN_FUEL].to_s.match(/gas/i) ? 1 : 0
		end
	end
	def mechanicalExtract
		@data[:MECHANICAL_EXTRACT]
	end
	def mechanicalSupply
		@data[:MECHANICAL_SUPPLY]
	end
	def energyTariff
		@data[:ENERGY_TARIFF_FLAG] ||= case @data[:ENERGY_TARIFF]
		when /single/i
			0
		when /dual/i
			1
		else
			0
		end
	end
	def wallThickness
		@data[:WALL_THICKNESS]
	end
	def wallUValue
		@data[:WALL_U_VALUE]
	end
	def wallUValue= value
		@data[:WALL_U_VALUE] = value
	end
	def wetRooms
		@data[:WET_ROOMS] ||= case @data[:NUMBER_HABITABLE_ROOMS]
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
	def hwEnergyEff
		@data[:HOT_WATER_ENERGY_EFF]
	end
	def setHotwaterEnergyEff value
		@data[:HOT_WATER_ENERGY_EFF] = value
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
	def floorUValue
		@data[:FLOOR_U_VALUE]
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
	def energyEfficiency
		@data[:CURRENT_ENERGY_EFFICIENCY]
	end
	def co2Emissions
		@data[:CO2_EMISSIONS_CURRENT]
	end
	def energyConsumption
		@data[:ENERGY_CONSUMPTION_CURRENT]
	end
	def mainHeatDescription
		puts "WARNING Main heat description not enumerated"
		@data[MAINHEAT_DESCRIPTION]
	end
	def glazedSizeFactor
		@data[:GLAZED_SIZE_FACTOR]
	end
	def roofUValue 
		@data[:ROOF_U_VALUE]
	end
	def roofUValue= value
		@data[:ROOF_U_VALUE] = value
	end
	def thermalBridgingFactor
		@data[:THERMAL_BRIDGING_FACTOR]
	end
	def windowArea
		@data[:WINDOW_AREA]
	end
	def windowFloorArea
		@data[:WAR]
	end
	def heatedRooms
		@data[:NUMBER_HABITABLE_ROOMS]
	end
	def fireplaces
		@data[:NUMBER_OPEN_FIREPLACES] || 0
	end
	def photoSupply
		@data[:PHOTO_SUPPLY_FLAG] ||= @data[:PHOTO_SUPPLY].to_s.match(/\d/) ? 1 : 0
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