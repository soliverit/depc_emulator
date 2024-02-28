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
								:MAINHEAT_ENERGY_EFF, :MAINHEATC_ENV_EFF]
	GLAZED_AREA_ENUMS	= ["NO DATA!","Less Than Typical", "Normal",
						 "More Than Normal","Much More Than Normal"]
	HEAT_LOSS_CORRIDOOR_ENUMS = [ "heated corridor", "unheated corridor"]
	### 
	# Reference data struct. Stores all ./data/<reference>.csv data
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
	##
	# Extract features.
	#
	# Get the features from the building that are relevant to the regressor
	# you're creating. Returns hash of features which can be pushed straight
	# to the RegressionDataSet holding the training/input data
	##
	def extractFeatures features
		Hash[features.map{|feature|
			[ feature, @data[feature.to_sym] || send(feature)] 
		}]
	end
	##
	# Get Boolean model has errors?
	##
	def errors?
		@corrupt
	end
	##
	# Retrieve or define the BuildingReference class
	##
	def reference
		@@reference ||= BuildingReference.new BuildingReference::DATA_DIR_PATH 
	end
	######
	# Initialise
	######
	def clone 
		self.class.new @data.clone, true
	end
	##
	# data:	Hash of data from the certificates.csv file of the county/region
	##
	def initialize data, fromCache = false
		@data 		= data
		@original 	= data.dup
		# Do this now  
		doBuildingStates unless fromCache
	end
	##
	# Subscripted accessor for the @data hash. Return whatever's there
	##
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
		@lighting	= LIGHTING_GAINS_BASE	+ (@data[:TOTAL_FLOOR_AREA] * occupants) ** 0.4714 * lowEnergyLigthingCorrection # From SAP doc
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
			@data[:CONSTRUCTION_AGE_BAND].to_s.match(ageData[:LABEL].to_s)
		}
	end

	##
	# Stuff that's unaviodable for the first versino 
	# of the buildingfMAIN_HEATING_CONTROLS
	##
	def doBuildingStates
	
		##
		# Don't do it twice. Doesn't matter where the flag's switched, here.
		##
		return if @buildingStatesDone
		@buildingStatesDone	= true
		
		##
		# First error case: Can't find age
		##
		if ! findAge
			@corrupt = "Error: Couldn't find age"
			return
		end
		
		##
		# Fail if area is null, can't be converted to a number
		# or is Zero (or less)
		##
		if ! area || ! area.is_a?(Numeric) || area <=0 
			@corrupt = "Zero area"
			return
		end
		
		##
		# Home position amongst surrounding buildings.
		#
		# Note: these on their own don't completely define 
		# the implied statues of these properties but they
		# do tell the regressor something of value.
		##
		## Set defaults
		# Mid terrace?
		@data[:IS_MID] 		= 0
		# End terrace
		@data[:IS_END] 		= 0
		# Is mid-mid terrace (4 of 6 surfaces internal)
		@data[:IS_ENCLOSED]	= 0
		# Is home/bungalow
		@data[:IS_DETACHED]	= 0
		
		##
		# Define these properties.
		#
		# Note: Features don't necessarily align with
		#		the real-world definition. Some times
		#		it's enough to merge properties.
		##
		case @data[:BUILT_FORM].to_s
		when "Detached"
			@data[:IS_DETACHED] = 1
		when "Mid-Terrace"
			@data[:IS_MID] 		= 1
		when "End-Terrace"
			@data[:IS_END] 		= 1
		when "Semi-Detached"
			@data[:IS_END] 		= 1
		when "Enclosed Mid-Terrace"
			@data[:IS_MID]		= 1
			@data[:IS_ENCLOSED] = 1
		when "Enclosed End-Terrace"
			@data[:IS_END] 		= 1
			@data[:IS_ENCLOSED] = 1
		end
		
		##
		# Do floor level features
		##
		@data[:IS_BASEMENT]	= 0
		@data[:IS_ROOF]		= 0
		case @data[:FLOOR_LEVEL].to_s
		when /basement/i
			@data[:IS_BASEMENT] = 1
		when /ground/i
			@data[:FLOOR_LEVEL] = 0
		when /top/i
			@data[:IS_ROOF] 	= 1
		else
			@data[:FLOOR_LEVEL] = 1
		end
		
		##
		# Do heat loss corridors.
		##
		# If there's no data, there's no corridor
		if @data[:HEAT_LOSS_CORRIDOOR] == "NO DATA!"
			@data[:HEAT_LOSS_CORRIDOOR] 	= 0
		# Sekf explanatory
		elsif @data[:HEAT_LOSS_CORRIDOOR] == "no corridor"
			@data[:HEAT_LOSS_CORRIDOOR] 	= 0
		# Otherwise look up the corridor type index
		else
			@data[:HEAT_LOSS_CORRIDOOR] = HEAT_LOSS_CORRIDOOR_ENUMS.find_index @data[:HEAT_LOSS_CORRIDOOR]
		end
		
		##
		# Do lighting stuff
		##
		# If the low energy lighting property isn't defined, set it to 0
		if ! @data[:LOW_ENERGY_LIGHTING].to_s.match(/\d/) 
			@data[:LOW_ENERGY_LIGHTING] 	= 0
		end
		
		##
		# Do ventilation strategy stuff.
		#
		# Figure out the ventilation strategy 
		##
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
		
		##
		# Do glazing stuff
		#
		# Note:	This is mess. The first and default condition
		#		can probably be merged. But, since we just 
		#		processed the entire dataset, I'm not touching
		#		it right now.
		##
		# If it's double, find the closest appropriate double glazing 
		if @data[:GLAZED_TYPE].match(/double/i)
			gType = reference.glazingTypes.find{|gType| 
					@data[:GLAZED_TYPE].downcase.match(/double/i) && 
					@data[:GLAZED_TYPE].downcase.match(gType[:When].downcase)
			}
		# If there's no glazing properties for a look up, fail gracefully
		elsif @data[:GLAZED_TYPE].match(/invalid|not def|no data/i)
			@corrupt = "Error: Glazed type: #{@data[:GLAZED_TYPE]}"
			return
		# Otherwise, do a less constrained lookup (than double)
		else
			gType = reference.glazingTypes.find{|gType|  @data[:GLAZED_TYPE].downcase.match(gType[:LABEL])}
		end
		# If we've got this far without defining gType, there's zero glazing
		unless gType
			gType = {U_Value: 0, g_Value: 0}
		end
		# Set glazing thermal properties.
		@data[:GLASS_U_VALUE] = gType[:U_Value]
		@data[:GLASS_G_VALUE] = gType[:g_Value]
		
		##
		# Do windows
		##
		# Find RdSAP windows parameters reference
		@windowFuncParams = reference.windowParams.find{|wData|wData[:LABEL] == ageBand}
		factor = case @data[:GLAZED_AREA]
		
		##
		# Assign a reasonable factor for the scaling.
		##
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
		#Identify building type, use it with the glazing lookup to calculate window area
		if @data[:PROPERTY_TYPE].match(/house|bungalow/i)
 			 @data[:WINDOW_AREA] = area * @windowFuncParams[:house] + @windowFuncParams[:house_plus] * factor
		else
			@data[:WINDOW_AREA] = area * @windowFuncParams[:flat] + @windowFuncParams[:flat_plus] * factor
		end 
		@data[:MULTI_GLAZE_PROPORTION] = 0 if @data[:MULTI_GLAZE_PROPORTION].class == "".class
		
		###
		# Do envelop materials stuff. the SAP reference
		##
		# Find the roof construction thermal properties reference
		roofAgeRecord = reference.roofTypes.find{|rData|
			findAge[:BAND] == rData[:BAND]}
		# Identy the roof state flag. Set properties based on the type
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
		
		##
		# Do floor stuff. the SAP reference
		##
		# Find the floor construction thermal properties reference
		floorType = reference.floorTypes.find{|fData|fData[:LABEL] == @data[:AGE_BAND]}
		# Identy the floor state flag. Set properties based on the type
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
		
		##
		# Do wall stuff. Taken from the SAP reference
		##
		# Figure out wall thickness reference from the wall desc and building age
		@data[:WALL_THICKNESS] = reference.wallThicknessData.find{|wtData|
			@data[:WALLS_DESCRIPTION].match(wtData[:Key])}[ageBand.to_sym] rescue -1
		# If the wall type explicitly defines a U-Value, use it
		if uValue = @data[:WALLS_DESCRIPTION].to_s.match(/(0\.\d{1,3})/)
			@data[:WALL_U_VALUE] 	= uValue[1].to_f
		# Else use a lookup on the walls material description
		else
			wallType = reference.wallTypes.find{|wData|
				@data[:WALLS_DESCRIPTION].downcase.match(wData[:"Wall Type"].downcase) && 
				@data[:WALLS_DESCRIPTION].downcase.match(wData[:Insulation].downcase)
			}
			# If you can't find a material, fail gracefully
			unless wallType
				@corrupt = "Error: Couldn't match construction type"
				return	
			end
			# Define wall U-Value
			@data[:WALL_U_VALUE] = wallType[ageBand.to_sym]
		end
		
		##
		# Do thermal bridging 
		##
		# Find the thermal bridging reference and 
		@data[:THERMAL_BRIDGING_FACTOR]	= reference.thermalBData.find{|tbData| tbData[:LABEL] == @data[:AGE_LABEL]}[:FACTOR]

		##
		# Do heating controls. (only sanitises the field. Full feature
		# built elsewhere.
		#
		# Note: There's a reference table with all control measures
		#		split by the control description. But, they don't
		#		have much effect on the model accuracy
		##
		# Set heating controls to zero if there's none defined
		if @data[:MAIN_HEATING_CONTROLS].class == "".class
			@corrupt = true
			return
		end

		##
		# Window to floor area ratio.
		#
		# Wall to floor area ratio is a ideal feature but wall area isn't
		# available. 
		##
		# Attempt to set the window to floor area ratio
		@data[:WAR] = 1 - @data[:WINDOW_AREA].to_f / @data[:TOTAL_FLOOR_AREA]
		# If something went wrong then total floor area is undefined in certificates.csv
		if @data[:WAR].nan?
			@corrupt = true
			puts "WAR is wrong #{@data[:WAR]}"
			return
		end
		
		##
		# Do Quality properties  (1 to 5, poor to excellent)
		#
		# Typically, these would be categorical features -
		# multiple feature keys for the same feature, each key for a Boolean value
		##
		QUALITY_FEATURES.each{|qFeature|
			@data[qFeature] = QUALITY_ENUMS.find_index @data[qFeature]
		}
		##
		# Lodgement date 
		##
		@data[:LODGEMENT_DATE]	= @data[:LODGEMENT_DATE].match(/2\d\d\d$/).to_s
		if !@data[:LODGEMENT_DATE]
			@corrupt	= true
			return
		end
		##
		# Finally, do open fire places
		##
		@data[:NUMBER_OPEN_FIREPLACES] = 0 if @data[:NUMBER_OPEN_FIREPLACES].to_s.strip == ""
	end
	######
	# Feature extraction methods
	#
	# The feature extraction process uses an input set of feature names which
	# correspond with either a direct property in @data or a derivable value.
	# In any case, we don't want to have the feature extraction check whether
	# it should reference @data in some cases and functions for others. So, 
	# instead we give each feature a dedicated Getter method and the extractFeatures
	# function calls the method.
	#
	# Note: We define as many static features as possible in @data so when we
	# want to perform a retrofit on the Building we don't need to reprocess
	# with doBuildingStates or static features
	######
	##
	# Get floating point total floor area m²
	##
	def area
		@data[:TOTAL_FLOOR_AREA]
	end
	##
	# Get Integer building age index (representing A through L)
	##
	def ageIndex
		findAge[:INDEX]
	end
	##
	# Get string building age label 
	##
	def ageLabel
		findAge[:LABEL]
	end
	##
	# Get character building age band
	##
	def ageBand
		findAge[:BAND]
	end
	##
	# Get Integer age group
	#
	# Note:	This feature isn't used but it's been left in because it's
	# 		an ok example of reducing features to meaningful intervals
	##
	def ageGroup
		ageIndex / 4
	end
	##
	# Get string building property type (house/bunglaw/flat)
	##
	def propertyType
		@data[:PROPERTY_TYPE]
	end
	##
	# Get floating point main fuel carbon emissions factor kgCO2/kWh
	##
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

	##
	# Home situation
	##
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
	##
	# Heating controls
	##
	# Find the heating controls reference data
	def mainHeatingControls
		@data[:HEATING_CONTROL_ENUM] ||= reference.heatingAdjData.find{|hcData| 
			@data[:MAIN_HEATING_CONTROLS] == hcData[:ID]
		}
	end
	# Retrive the heating control description
	def mainControllerDescription
		@data[:MAINHEATCONT_DESCRIPTION]
	end
	# Find the heating control's row ID in the heating control reference data
	def heatingControlIndex
		return @data[:HEATING_CONTROL_INDEX] if @data[:HEATING_CONTROL_INDEX]
		controls = mainHeatingControls
		@data[:HEATING_CONTROL_INDEX] = if controls 
			mainHeatingControls[:Control_Type]
		else
			0
		end
		
	end
	##
	# Get the number of extensions
	##
	def extensionCount
		@data[:EXTENSION_COUNT] ||= 0
	end
	##
	# Get Bool is top storey flat
	##
	def isTopStoreyFlat?
		@data[:IS_TOP_STOREY] ||= @data[:FLAT_TOP_STOREY]..to_s.downcase == "y" ? 1 : 0
	end
	##
	#  Get Bool is a basement flat
	##
	def isBasement?
		@data[:IS_BASEMENT] 
	end
	##
	# Get Bool heating outlets have TRVs
	##
	def trvs?
		(@data[:TEMP_ADJUSTMENT] != 0 && @data[:HEATING_CONTROL_INDEX] != 2) ? 1 : 0
	end
	##
	# Get floating point temperature adjustment for heating control set up
	##
	def temperatureAdjustment
		return @data[:TEMP_ADJUSTMENT] if @data[:TEMP_ADJUSTMENT]
		controls = mainHeatingControls
		if controls
			@data[:TEMP_ADJUSTMENT] = controls[:Temperature_Adjustment] 
		else
			@data[:TEMP_ADJUSTMENT] = 0
		end
	end
	##
	# Get Integer 0 to 5 Heating energy efficiency rating
	##
	def mainHeatEnergyEff
		@data[:MAINHEAT_ENERGY_EFF]
	end
	##
	# Get Integer roof Efficiency (0 to 5)
	## 
	def roofEnergyEff
		@data[:ROOF_ENERGY_EFF]
	end
	##
	# Get Integer wall Efficiency rating (0 to 5)
	## 
	def wallsEnergyEff
		@data[:WALLS_ENERGY_EFF]
	end
	
	##
	# Get Integer  window Efficiency rating (0 to 5)
	##
	def windowsEnergyEff 
		@data[:WINDOWS_ENERGY_EFF]
	end
	##
	# Get Bool does the site have gas available
	##
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
	##
	# Get Bool air extract is mechanical
	##
	def mechanicalExtract
		@data[:MECHANICAL_EXTRACT]
	end
	##
	# Get Bool air suplly is mechanical
	##
	def mechanicalSupply
		@data[:MECHANICAL_SUPPLY]
	end
	##
	# Get Bool energy tariff (single/dual)
	##
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
	##
	# Get Integer wall thickness mm
	##
	def wallThickness
		@data[:WALL_THICKNESS]
	end
	##
	# Get floating point wall U-Value W/m²k
	##
	def wallUValue
		@data[:WALL_U_VALUE]
	end
	##
	# Get floating point roof U-Value W/m²K
	##
	def roofUValue
		@data[:ROOF_U_VALUE]
	end
	##
	# Number of rooms with non-heating hot water usage
	##
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
	##
	# Get Bool het loos corridor present (mabye deprecated)
	##
	def heatLossCorridor
		@data[:HEAT_LOSS_CORRIDOR]
	end
	##
	# Get Integer floor level of flats
	##
	def floorLevel
		@data[:FLOOR_LEVEL] 		||= 0
	end
	##
	# Get Bool hot water pipe network is insulated
	##
	def hwPipeInsulation
		@data[:HW_PIPE_INSULATION] 	||= ["J", "K", "L"].include?( data[:AGE_BAND]) ? 1 : 0
	end
	##
	# Get Bool hot water is from district heating
	##
	def hwCommunity
		@data[:HW_COMMUNITY] 		||= data[:HOTWATER_DESCRIPTION].match(/community/i) ? 1 : 0
	end
	##
	# Get Bool hot water is served by instantaneous point of use system
	##
	def hwIsInstantaneous?
		@data[:HW_IS_INSTANTANEOUS] ||= @data[:HOTWATER_DESCRIPTION].match(/instantaneous/i) ? 1 : 0
	end
	##
	# Get Bool on-site solar water heating
	##
	def hasSolarWater?
		@data[:HAS_SOLAR_WATER] 	||= @data[:HOTWATER_DESCRIPTION].match(/solar/i) ? 1 : 0
	end
	##
	# Get Bool off peak hot water generation
	##
	def offPeakHotWater?
		@data[:HW_IS_OFF_PEAK] 		||= @data[:HOTWATER_DESCRIPTION].match(/off(-| )peak/i) ? 1 : 0
	end
	##
	# Get Bool hot water is gas-fired
	##
	def hwIsGas?
		 @data[:HW_IS_GAS] 			||= @data[:HOTWATER_DESCRIPTION].match(/gas/i) ? 1 : 0
	end
	##
	# Get percentage of space served by low-energy lighting
	##
	def lowEnergyLighting
		@data[:LOW_ENERGY_LIGHTING]
	end
	##
	# Get Bool hot water is from main heating system
	##
	def hwFromMainSystem?
		@data[:HW_FROM_MAIN_SYSTEM]	||= @data[:HOTWATER_DESCRIPTION].match(/from main system/i) ? 1 : 0
	end
	##
	# Get Integer hot water energy Efficiency rating (0 to 5)
	## 
	def hwEnergyEff
		@data[:HOT_WATER_ENERGY_EFF]
	end
	##
	# Get Bool heating has a boiler
	##
	def heatingHasTank?
		@data[:HAS_TANK] 			||= @data[:MAINHEAT_DESCRIPTION].match(/boiler|storage|immersion/i) ? 1: 0
	end
	##
	# Get Bool has wet radiators
	##
	def hasRadiators?
		@data[:HAS_RADIATORS] 		||= @data[:MAINHEAT_DESCRIPTION].match(/radiator/i) ? 1 : 0
	end
	##
	# Get Bool home has underfloor heating
	##
	def hasUnderfloorHeating?
		@data[:UNDERFLOOR_HEATING]	||= @data[:MAINHEAT_DESCRIPTION].match(/underfloor/i) ? 1 : 0
	end
	##
	# Get floating point floot U-Value W/m²K
	##
	def floorUValue
		@data[:FLOOR_U_VALUE]
	end
	##
	# Get floating point second heating system feature. kgCO2/kWh
	#
	# This feature translates second heating into an
	# emissions contributor. 
	##
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
	##
	# Get integer base model energy efficiency rating 
	## 
	def energyEfficiency
		@data[:CURRENT_ENERGY_EFFICIENCY]
	end
	##
	# Get Integer base model carbon emissions kgCO2/m²
	##
	def co2Emissions
		@data[:CO2_EMISSIONS_CURRENT]
	end
	##
	# Get Integer base model energy consumption kWh/m²
	##
	def energyConsumption
		@data[:ENERGY_CONSUMPTION_CURRENT]
	end
	##
	# Get floating point glazing sise adjustment factor
	##
	def glazedSizeFactor
		@data[:GLAZED_SIZE_FACTOR]
	end
	##
	# Roof U-Value W/m²K
	##
	def roofUValue= value
		@data[:ROOF_U_VALUE] = value
	end
	##
	# Thermal bridiging W/mK
	##
	def thermalBridgingFactor
		@data[:THERMAL_BRIDGING_FACTOR]
	end
	##
	# Get floating point window total glazed area m²
	##
	def windowArea
		@data[:WINDOW_AREA]
	end
	##
	# Get integer window to floor rate m²
	##
	def windowFloorArea
		@data[:WAR]
	end
	##
	# Number of heated rooms
	##
	def heatedRooms
		@data[:NUMBER_HABITABLE_ROOMS]
	end
	##
	# Get Integer number of fireplaces
	##
	def fireplaces
		@data[:NUMBER_OPEN_FIREPLACES]
	end
	##
	# On-site solar panels
	##
	def photoSupply
		if ! @data[:PHOTO_SUPPLY].to_s.match(/\d/)
			@data[:PHOTO_SUPPLY_FLAG] 	||= @data[:PHOTO_SUPPLY].to_s.match(/\d/).to_i 
		else
			@data[:PHOTO_SUPPLY] 		||= 0
		end
	end
	####
	# Setters
	##
	# Set heating control index (for retrofitting)
	def setHeatingContronIndex value
		i = 1
		f = 1.0
		if value.class == 1.0.class || value.class !=  1.class
			@data
			puts value
			exit
		end
		@data[:HEATING_CONTROL_INDEX] = value
	end
	##
	# Set temperature adjustment value floating point (0 <= 3)
	#
	# Temperature adjustment is an adjustment to the
	# space heating set point to reflect some heating
	# control state. (for retrofitting)
	##
	def setTemperatureAdjustment value
		@data[:TEMP_ADJUSTMENT] = value
	end
	# Set window Efficiency rating (for retrofitting) (0 to 5 Integer)
	def setWindowsEnergyEff value
		@data[:WINDOWS_ENERGY_EFF] = value
	end
	# Set heating Efficiency rating (0 to 5 Integer)
	def setMainHeatEnergyEff value
		@data[:MAINHEAT_ENERGY_EFF] = value
	end
	# Set hot water Efficiency rating (0 to 5 integer)
	def setHotwaterEnergyEff value
		@data[:HOT_WATER_ENERGY_EFF] = value
	end
	# Set wall U-Vaue floating point W/m²K
	def wallUValue= value
		@data[:WALL_U_VALUE] = value
	end
	# Set wall energy Efficiency rating Integer (0 to 5)
	def setWallsEnergyEff value
		@data[:WALLS_ENERGY_EFF] = value
	end
	##
	# Set roof Efficiency Integer (0 to 5)
	##
	def setRoofEnergyEff value
		@data[:ROOF_ENERGY_EFF] = value
	end
end