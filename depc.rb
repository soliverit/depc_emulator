 ################################
 # This script is designed to data points from
 # the domestic EPC historical results database
 # and methodology document to produce an 
 # emulator for RdSAP

################################
# Includes
################################
### Native 
require "json"

# Debug dumping stuff
require "yaml"
### Project 
#Prettify console outputs
 ################################
 # There's nothing worse than ill-formatted text
 # on a console. It's worth writing your own formatter
 # that suits your needs specifically. Lpr (LRPrintHelper)
 # is OllieMl's
require "./lib/print_helper.rb"
# Configure to keep tabs on process time
Lpr.startTimer
Lpr.silentMode 	= ARGV[3] ? true : false
# Inline data table handling
 ################################
 # Many operations on data are repeated. Might
 # as well create your own data handler or tolerate
 # something someone else has written; Pandas is good
 # in Python but unless there's specific functions in
 # the library you can't replicate, it's worth creating
 # a personal handler.
 
 # Buliding
 require "./lib/building.rb"
 
 # RegressionDataSet is OllieMl's
require "./lib/regression_data_set.rb"

# EPSRegressor - linear regression library (OllieMlSupervisedBase)
require "./lib/supervised/eps_regressor.rb"
# require "./lib/supervised/knn.rb"
# require "./lib/supervised/lib_svm.rb"
# require "./lib/supervised/fast_ann.rb"
# require "./configs/supervised.rb"
# Prediction - store prediction data and inputs
require "./lib/predictions/prediction.rb"

Lpr.p "
 ################################
 # This script is designed to data points from
 # the domestic EPC historical results database
 # and methodology document to produce an 
 # emulator for RdSAP
 ################################md"
# puts File.open("temp.txt").read.split("\n").sort.uniq
# exit

################################
# Constants
################################
Lpr.p "
##
# Define constants and other handy variables
##"
###File system
Lpr.d "Define file system constants"
DATA_PATH			= "./data/"
DATA_INPUT_PATH		= DATA_PATH 		+ "/input_data/"
TEMP_PATH			= DATA_PATH 		+ "/temp.csv"
AGE_BAND_PATH		= DATA_PATH 		+ "/age_band_lookup.csv"
WINDOW_PARAMS_PATH	= DATA_PATH 		+ "/window_parameters.csv"
GLAZING_TYPES_PATH	= DATA_PATH 		+ "/glazing_types.csv"
ROOF_TYPES_PATH		= DATA_PATH 		+ "/roof_constructions.csv"
FLOOR_TYPES_PATH	= DATA_PATH 		+ "/floor_constructions.csv"
WALL_TYPES_PATH		= DATA_PATH 		+ "/wall_constructions.csv"
THERMAL_BRIDGE_PATH	= DATA_PATH 		+ "/thermal_bridging.csv"
HEATING_ENUMS_PATH	= DATA_PATH			+ "/heating_table_4e.csv"
WALL_THICKNESS_PATH	= DATA_PATH			+ "/wall_thickness.csv"
INPUT_DATA_PATH		= DATA_INPUT_PATH	+ ARGV[1] + ".csv"

### Features
Lpr.d "Define feature constants (FEATURES is mutable so not really constant)"
TARGET				= ARGV.first.to_sym
FEATURES 			= File.open("domestic_features.txt").read.split(/\n/).map{|line| line.strip.to_sym}

### Feature ENUMs
Lpr.d "Define feature raw data ENUMs"

# All features in QUALITY_FEATURES are enumerated by these values
QUALITY_ENUMS 		= ["Very Poor", "Poor", "Average", "Good", "Very Good"]
QUALITY_FEATURES	= [:SHEATING_ENERGY_EFF, :HOT_WATER_ENERGY_EFF, :LIGHTING_ENERGY_EFF, :ROOF_ENERGY_EFF, 
						:WALLS_ENERGY_EFF, :WINDOWS_ENERGY_EFF, :MAINHEAT_ENERGY_EFF]
# # Glazing adjustment factor values ("NO DATA!" will be jimmied in the next video
GLAZED_AREA_ENUMS	= ["NO DATA!","Less Than Typical", "Normal", "More Than Normal","Much More Than Normal"]

### Model
# Fraction of whole data set used for training, remainder used for testing accuracy
TRAIN_TEST_SPLIT= ARGV[2].to_f || 0.25
# Heat loss corridor states
HEAT_LOSS_CORRIDOOR_ENUMS = [ "heated corridor", "unheated corridor"]
################################
# Load data etc
################################
Lpr.p "
##
# Parse data etc
##"
rgDataSet 		= RegressionDataSet.parseGemCSV(INPUT_DATA_PATH)#.sample(1)
Lpr.d "Input data loaded - #{rgDataSet.length} records"

ageBandDataSet	= RegressionDataSet.parseGemCSV AGE_BAND_PATH
Lpr.d "Age band data loaded"

windowParams	= RegressionDataSet.parseGemCSV WINDOW_PARAMS_PATH
Lpr.d "Window area function parameters loaded"

glazingTypes	= RegressionDataSet.parseGemCSV GLAZING_TYPES_PATH
Lpr.d "Glazing thermal properties loaded"

roofTypes		= RegressionDataSet.parseGemCSV ROOF_TYPES_PATH
Lpr.d "Roof thermal properties loaded"

floorTypes		= RegressionDataSet.parseGemCSV FLOOR_TYPES_PATH
Lpr.d "Floor thermal properties loaded"

wallTypes		= RegressionDataSet.parseGemCSV WALL_TYPES_PATH
Lpr.d "External envelope thermal properties loaded"

thermalBData	= RegressionDataSet.parseGemCSV THERMAL_BRIDGE_PATH
Lpr.d "Thermal bridging properties loaded"

heatingAdjData	= RegressionDataSet.parseGemCSV HEATING_ENUMS_PATH
Lpr.d "Heating control adjustments loaded"

wallThicknessData= RegressionDataSet.parseGemCSV WALL_THICKNESS_PATH
################################
# Feature extraction
################################
# Occupants
rgDataSet.injectFeatureByFunction(:OCCUPANTS){|data|
	building = Building.new data
	building.occupants
}
## Site level
# Construction age band
Lpr.d "Do construction age band to ENUM"
labelKey		= ageBandDataSet.features.first #Hack and slash (worry about these later)
rgDataSet		= rgDataSet.select{|data| !data[:CONSTRUCTION_AGE_BAND].match(/INVALID|NO DATA/i) && data[:CONSTRUCTION_AGE_BAND] != ""}
rgDataSet.injectFeatureByFunction(:AGE_LABEL){|data|
	ageRecord	= ageBandDataSet.find{|ageData| data[:CONSTRUCTION_AGE_BAND].match(ageData[labelKey].to_s)}
	ageRecord[:BAND]
}
rgDataSet.injectFeatureByFunction(:AGE_INDEX){|data|
	ageRecord	= ageBandDataSet.find{|ageData| data[:CONSTRUCTION_AGE_BAND].match(ageData[labelKey].to_s)}
	ageRecord[:INDEX]
}

# Energy tariff (Dual or Single (don't worry abuot more for now)
rgDataSet.apply{|data|
	case data[:ENERGY_TARIFF]
	when /single/i
		data[:ENERGY_TARIFF] = 0
	when /dual/i
		data[:ENERGY_TARIFF] = 1
	else
		data[:ENERGY_TARIFF] = 0
	end
}
# Property type
rgDataSet.injectFeatures({IS_FLAT: 0,	IS_HOUSE: 0})
rgDataSet.apply{|data|
	case data[:PROPERTY_TYPE].to_s
	when "Bungalow"
		data[:IS_HOUSE] = 1
	when "House"
		data[:IS_HOUSE] = 1
	when "Flat" 
		data[:IS_FLAT] = 1
	else
		data[:IS_FLAT] = 1
	end
}
# Has gas on site
Lpr.d "Do has gas on site?"
rgDataSet.apply{|data|
	gasFlag	= data[:MAINS_GAS_FLAG].to_s.downcase
	case gasFlag
	when "y"
		data[:MAINS_GAS_FLAG] = 1
	when "n"
		data[:MAINS_GAS_FLAG] = 0
	else
		data[:MAINS_GAS_FLAG] = data[:MAIN_FUEL].to_s.match(/gas/i) ? 1 : 0
	end
}



# Main fuel
Lpr.d "Do mains fuel"
Lpr.d "WARNING: Like hot water + there's a lot of values here but we probably only need 4"
Lpr.d "NOTE: All we really need is a CO2 factor roughly"
rgDataSet.apply{|data|
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
}
rgDataSet = rgDataSet.select{|data| data[:MAIN_FUEL] != -1}
# Main heating controls 
Lpr.d "Finally: Fix and enumerate heating controls"
labelKey = heatingAdjData.features.first
rgDataSet.injectFeatureByFunction(:TEMP_ADJUSTMENT){|data| 
	heatingAdjData.find{|haData| data[:MAIN_HEATING_CONTROLS] == haData[labelKey]}[:Temperature_Adjustment] rescue 0
}
# rgDataSet.apply{|data|
	# data[:MAIN_HEATING_CONTROLS] = heatingAdjData.find{|haData| data[:MAIN_HEATING_CONTROLS] == haData[labelKey]}[:Control_Type]
# }
rgDataSet.enumerate :MAIN_HEATING_CONTROLS



#Situation
rgDataSet.injectFeatures({	IS_DETACHED: 0, 
							IS_END: 0, 
							IS_MID: 0})
rgDataSet.apply{|data|
	case data[:BUILT_FORM].to_s
	when "Detached"
		data[:IS_DETACHED] = 1
	when "Mid-Terrace"
		data[:IS_MID] = 1
	when "End-Terrace"
		data[:IS_END] = 1
	when "Semi-Detached"
		data[:IS_END] = 1
	when "Enclosed Mid-Terrace"
		data[:IS_MID] = 1
	when "Enclosed End-Terrace"
		data[:IS_END] = 1
	end
}
rgDataSet.dropFeatures [:BUILT_FORM]
# Extensions
Lpr.d "Do extension count. It's dirty! (add missing values)**"
rgDataSet.apply{|data|
	unless data[:EXTENSION_COUNT].to_s.match(/\d/)
		data[:EXTENSION_COUNT] = 0
	end
	data[:EXTENSION_COUNT] /= data[:TOTAL_FLOOR_AREA].to_f

}
# Top floor of flat?
Lpr.d "Do is top storey"
rgDataSet.apply{|data|data[:FLAT_TOP_STOREY] = data[:FLAT_TOP_STOREY].downcase == "y" ? 1 : 0}

# Floor level
Lpr.d "Do is it bottom, top or anywhere else floor of flat"
rgDataSet.injectFeatures({IS_BASEMENT: 0, IS_ROOF: 0})
rgDataSet.apply{|data|
	case data[:FLOOR_LEVEL].to_s
	when /basement/i
		data[:IS_BASEMENT] = 1
	when /ground/i
		data[:FLOOR_LEVEL] = 0
	when /top/i
		data[:IS_ROOF] = 1
	else
		data[:FLOOR_LEVEL] = 1
	end
}
# Wet rooms
rgDataSet.injectFeatureByFunction(:WET_ROOMS){|data|
	case data[:NUMBER_HABITABLE_ROOMS]
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
}

# Heat loss corridor
Lpr.d "Do heat loss corridor stuff"
rgDataSet.apply{|data|
	if data[:HEAT_LOSS_CORRIDOOR] == "NO DATA!"
		data[:HEAT_LOSS_CORRIDOOR] = 0
	elsif data[:HEAT_LOSS_CORRIDOOR] == "no corridor"
		data[:HEAT_LOSS_CORRIDOOR] = 0
	else
		data[:HEAT_LOSS_CORRIDOOR] = HEAT_LOSS_CORRIDOOR_ENUMS.find_index data[:HEAT_LOSS_CORRIDOOR]
	end
}
rgDataSet.dropFeatures [:FLOOR_LEVEL]
## Renewables

rgDataSet.enumerate :PHOTO_SUPPLY

rgDataSet.injectFeatureByFunction(:HW_PIPE_INSULATION){|data| ["J", "K", "L"].include?( data[:AGE_BAND]) ? 1 : 0}	
rgDataSet.injectFeatureByFunction(:HW_COMMUNITY){|data| data[:HOTWATER_DESCRIPTION].match(/community/i) ? 1 : 0}	
rgDataSet.injectFeatureByFunction(:HW_INSTANTANEOUS){|data| data[:HOTWATER_DESCRIPTION].match(/instantaneous/i) ? 1 : 0}	
rgDataSet.injectFeatureByFunction(:HAS_SOLAR_WATER){|data| data[:HOTWATER_DESCRIPTION].match(/solar/i) ? 1 : 0}	
rgDataSet.injectFeatureByFunction(:HW_OFF_PEAK){|data| data[:HOTWATER_DESCRIPTION].match(/off(-| )peak/i) ? 1 : 0}	
rgDataSet.injectFeatureByFunction(:HW_GAS){|data| data[:HOTWATER_DESCRIPTION].match(/gas/i) ? 1 : 0}	

## Services
Lpr.d "Do low energy lighting patch"
rgDataSet.apply{|data|
	if ! data[:LOW_ENERGY_LIGHTING].to_s.match(/\d/) 
		data[:LOW_ENERGY_LIGHTING] = 0
	end
}
# Ventilation strategy
Lpr.d "Do ventilation strategy"
rgDataSet.injectFeatures({MECHANICAL_EXTRACT: 0, MECHANICAL_SUPPLY: 0})
rgDataSet.apply{|data|
	case data[:MECHANICAL_VENTILATION]
	when "mechanical, extract only"
		data[:MECHANICAL_EXTRACT] = 1
	when  "mechanical, supply and extract"
		data[:MECHANICAL_EXTRACT] = 1
		data[:MECHANICAL_SUPPLY] = 1
	end
}

# Hot water system
Lpr.d "Do hot water description"
Lpr.d "WARNING: This is a bugger since hot water is the primary indicator of residential consumption"
Lpr.d "WARING: Cont'd. I'd wager decision trees would handle enums fine, not line reg (see other discussion)"
rgDataSet.injectFeatureByFunction(:FROM_MAIN_SYSTEM){|data| data[:HOTWATER_DESCRIPTION].match(/from main system/i) ? 1 : 0}
rgDataSet.injectFeatureByFunction(:CYLINDER){|data| data[:HOTWATER_DESCRIPTION].match(/no cylinder/i) ? 0 : 1}
rgDataSet.enumerate :HOTWATER_DESCRIPTION
# rgDataSet.apply{|data|
	# case data[:HOTWATER_DESCRIPTION]
	# when "community"
		# data[:HOTWATER_DESCRIPTION] = 0
	# when "from main"
		# data[:HOTWATER_DESCRIPTION] = 1
	# else
		# data[:HOTWATER_DESCRIPTION] = 2
	# end
# }

# Heating
Lpr.d "Do heating system has tank"
rgDataSet.injectFeatureByFunction(:HAS_TANK){|data| 
	data[:MAINHEAT_DESCRIPTION].match(/boiler|storage|immersion/i) ? 1: 0
}
rgDataSet.injectFeatureByFunction(:HAS_RADIATORS){|data| data[:MAINHEAT_DESCRIPTION].match(/radiator/i) ? 1 : 0}
rgDataSet.injectFeatureByFunction(:UNDERFLOOR_HEATING){|data| data[:MAINHEAT_DESCRIPTION].match(/underfloor/i) ? 1 : 0}

rgDataSet.injectFeatureByFunction(:HEAT_PUMP){|data|
	data[:MAINHEAT_DESCRIPTION].match(/heat pump/i) ? 1 : 0
}
rgDataSet.enumerate :MAINHEAT_DESCRIPTION

rgDataSet.apply{|data| 
	case data[:SECONDHEAT_DESCRIPTION]
	when /electricity/i
		data[:SECONDHEAT_DESCRIPTION] = 0.519
	when /lpg/i
		data[:SECONDHEAT_DESCRIPTION] = 0.245
	when /oil/
		data[:SECONDHEAT_DESCRIPTION] = 0.297
	when /gas/i
		data[:SECONDHEAT_DESCRIPTION] = 0.216
	when /dual/i
		data[:SECONDHEAT_DESCRIPTION] = 0.206
	when /smokeless/i
		data[:SECONDHEAT_DESCRIPTION] = 0.392
	when /coal/i
		data[:SECONDHEAT_DESCRIPTION] = 0.291
	when /no heating/i
		data[:SECONDHEAT_DESCRIPTION] = 0
	when /community/i
		data[:SECONDHEAT_DESCRIPTION] = 0.24
	else
		data[:SECONDHEAT_DESCRIPTION] = -1
	end
	
}
rgDataSet.enumerate :MAINHEAT_DESCRIPTION
### Service efficiency
Lpr.d "Do service / material efficiencies"
QUALITY_FEATURES.each{|feature|
	rgDataSet.apply{|data|
		data[feature] = QUALITY_ENUMS.find_index(data[feature]) || -1
	}
}
Lpr.d "Do HOT WATER efficiency adjustment for occupancy"

Lpr.d "Do internal gains"
rgDataSet.injectFeatureByFunction(:INTERNAL_LIGHTING){|data|
	building	= Building.new data
	building.lighting / building.area
}
rgDataSet.injectFeatureByFunction(:INTERNAL_GAINS){|data|
	building	= Building.new data 
	building.internalGains / building.area
}
### Glazing and fabric
# Glazing
Lpr.d "Do glazing U and g values"
labelKey 		= glazingTypes.features.first
rgDataSet.injectFeatures({GLASS_U_VALUE: 0, GLASS_G_VALUE: 0})
rgDataSet		= rgDataSet.select{|data| ! data[:GLAZED_TYPE].match(/NO DATA|INVALID|not defined/)}
rgDataSet.apply{|data|
	if data[:GLAZED_TYPE].match(/double/i)
		gType = glazingTypes.find{|gType| 
					data[:GLAZED_TYPE].downcase.match(/double/i) && 
					data[:GLAZED_TYPE].downcase.match(gType[:When].downcase)
				}
	else
		gType = glazingTypes.find{|gType| data[:GLAZED_TYPE].downcase.match(gType[labelKey])}
	end
	data[:GLASS_U_VALUE] = gType[:U_Value]
	data[:GLASS_G_VALUE] = gType[:g_Value]
}

Lpr.d "Do glazing area adjustment"
rgDataSet.injectFeatureByFunction(:GLAZING_SIZE_FACTOR){|data|
	case data[:GLAZED_AREA]
	when /less/i
		-1
	when /normal/i
		0
	when /more/i
		1
	end
}

# Roof
Lpr.d "Do roof U values"
labelKey 		= roofTypes.features.first
rgDataSet.injectFeatureByFunction(:ROOF_U_VALUE){|data|
	roofAgeRecord = roofTypes.find{|rData| data[:AGE_LABEL] == rData[labelKey]}
	case data[:ROOF_DESCRIPTION]
	when /pitch/i
		data[:ROOF_U_VALUE] = roofAgeRecord[:U_Value_Pitched]
	when /flat/i
		data[:ROOF_U_VALUE] = roofAgeRecord[:U_Value_Flat]
	when /room/i
		data[:ROOF_U_VALUE] = roofAgeRecord[:U_Value_Pitched]
	else # Adiabtic 
		data[:ROOF_U_VALUE] = 0
	end
}

# Floor
Lpr.d "Do floor U Values"
labelKey	= floorTypes.features.first
rgDataSet.injectFeatureByFunction(:FLOOR_U_VALUE){|data|
	floorType = floorTypes.find{|fData| fData[floorTypes.features.first] == data[:AGE_LABEL]}
	case data[:FLOOR_DESCRIPTION]
	when /no\s|assumed|insulated/i
		floorType[:U_Value_Unknown]
	when /50 mm/
		floorType[:U_Value_50mm]
	when /100 mm/
		floorType[:U_Value_100mm]
	when /200 mm|premise/
		floorType[:U_Value_150mm]
	when /other dwelling/i #Adiabatic
		0
	end
}
rgDataSet.injectFeatureByFunction(:ROOF_FLOOR_U_VALUE){|data|
	1 - (data[:FLOOR_U_VALUE] / data[:ROOF_U_VALUE]) rescue 0
}
# Wall thickness
labelKey	= wallThicknessData.features.first
rgDataSet.injectFeatureByFunction(:WALL_THICKNESS){|data|
	wallThicknessData.find{|wtData| data[:WALLS_DESCRIPTION].match(wtData[labelKey])}[data[:AGE_LABEL].to_sym] rescue -1
}
# External envelopes
Lpr.d "Do external envelopes"
labelKey = wallTypes.features.first
rgDataSet.injectFeatureByFunction(:WALL_U_VALUE){|data|
	
	if uValue = data[:WALLS_DESCRIPTION].to_s.match(/(0\.\d{1,3})/)
		uValue[1].to_f
	else
		wallType = wallTypes.find{|wData|
			data[:WALLS_DESCRIPTION].downcase.match(wData[labelKey].downcase) && 
			data[:WALLS_DESCRIPTION].downcase.match(wData[:Insulation].downcase)
		}
		begin
		wallType[data[:AGE_LABEL].to_sym]
		rescue
			-1
		end
	end
}
rgDataSet = rgDataSet.select{|data| data[:WALL_U_VALUE] != -1}
# Thermal brdiging
labelKey	= thermalBData.features.first
rgDataSet.injectFeatureByFunction(:THERMAL_BRIDGING_FACTOR){|data|
	thermalBData.find{|tbData| tbData[labelKey] == data[:AGE_LABEL]}[:FACTOR]
}


### Geometry
# Windows
Lpr.d "Do window area"
labelKey	= windowParams.features.first
rgDataSet.injectFeatureByFunction(:WINDOW_AREA){|data|
	# Find label to link tables
	windowFuncParams = windowParams.find{|wData| wData[labelKey] == data[:AGE_LABEL]}
	case data[:GLAZED_AREA]
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
	if data[:PROPERTY_TYPE].match(/house|bungalow/i)
		data[:TOTAL_FLOOR_AREA] * windowFuncParams[:house] + windowFuncParams[:house_plus] * factor
	else
		data[:TOTAL_FLOOR_AREA] * windowFuncParams[:flat] + windowFuncParams[:flat_plus] * factor
	end 
}

rgDataSet.toCSVGem TEMP_PATH

# Window floor ratio
Lpr.d "Do Window floor area ratio"
rgDataSet.injectFeatureByFunction(:WAR){|data|1 - (data[:WINDOW_AREA] / data[:TOTAL_FLOOR_AREA])}

####
Lpr.p "
##
# Modify existing features from domestic_features.txt
# and create new ones.
##"

################################
# Train model stuff
################################
Lpr.p "
##
# Train a model and test it
##"
### Data handling
Lpr.d "Do data train/test split"
# Split data into train and test data. Split by the train/test split ratio 
rgDataSet.segregate([FEATURES, TARGET].flatten).toCSVGem "for_hp_tuner.csv"
trainTestData	= rgDataSet.segregate([FEATURES, TARGET].flatten).split(TRAIN_TEST_SPLIT)
# Assign the first set as the training data
trainData		= trainTestData.first
# Assign second set to the test data
testData		= trainTestData.last
# Extract the targets from the test data and drop its column from the test data (the machine doesn't need to see)
testTargets		= testData.retrieveFeatureAsArray TARGET, true
puts Lpr.hashToTable ({Train:{Size: trainData.length}, Test: {Size: testData.length}})
trainData.toCSV "TRAIN.csv"
### Model creation and training
Lpr.d "Do train model"
require "./lib/supervised/knn.rb"
# Create new model - third parameter is for passing hyperparameters. Not needed here
machine			= EPSRegressor.new trainData, TARGET, {SKIP_NORMALISE:  true}
# Train the model
machine.train


################################
# Test the model and evaluate performance
################################
Lpr.d "Do prediction and present error"
# Ask the model to predict the target for each test data record
results			= machine.validateSet testData, testTargets, Prediction
# Retrieve the error information (ErrorInformation) and print the gist of it
results.getError.printTable

puts Lpr.hashToTable machine.doPermutationImportance(testData, testTargets, Prediction)
testData << results.toRgDataSet
testData.injectFeatures({TARGET:0})
i			= 0
testData.apply{|data|
	data[:TARGET] = testTargets[i]
	i += 1
}
testData.toCSVGem "./predictions.csv"
# trainData 	<< results.toRgDataSet
Lpr.silentMode = false


Lpr.d "End"