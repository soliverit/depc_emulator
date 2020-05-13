# ollieml
Simplified ML and data handling library for Ruby

### Features
- Regression
- Classification
- Clustering
- Hyperband hyperparameter tuning
- Data handling
- Plotting (work in progress)

# Overview

### OllieML

#### (Use `ruby run_example.rb list` to list ./examples/ then pass a name in "lists"'s place to explore)
#### The RegressionDataSet and OllieMl supervised models are verbosely commented. Might be helpful at some point

This library is deisnged for anyone who wants to try ML but doesn't have all the skills necessary to dive in. Its running theme is single-line everything.

` <someModelClass>.new dataSet, targetFeatureName, parametersHash`

```ruby
#Built-in data management class. Covered later
rgDataSet = RegressionDataSet.parseCSV "./data/data.csv"
#Target feature for the ML model. RegressionDataSet works with symbols by default
target      = :heat
#Parameters the ML model will accept. Params are applied to models with virtual methods
params      = {max_mse: 2.0}
#Create a Fast-ANN. FastANN can be anything supported by the library
fANN        = FastANN.new rgDataSet, target, params
#Train
fANN.train
#Do multiple predictions
predictions  = fANN.preidctSet(testData)
# Do predictions with validation and error information
predictionSet = fANN.validateSet testData, testTargets
```

Currently supports 24ish models based from these existing libs (credits to follow):

  (Supervised)
  - RubyLinRegression
  - LibLinRegressor
  - LibSVM
  - LibLogisticRegressor
  - FastANN
  
  (Unsupervised)
  - K-Means clustering

### RegresssionDataSet

An over-the-top inline Sql-type data handling model.

Example usage
```ruby
##
# Create two new data sets for the examples, split one into two.
#
# Example: User and Phone data (name, id) and phone (type, user_id)
##
# New takes two params, data and features. One should always be false
userData  = RegressionDataSet.new false,[:name, :id]
phoneData = RegressionDataSet.new false, [:type, :user_id]
#Add some data. The Push method accepts an Array or Hash
userData.push ["Dave", 1]
userData.push({name: "Tam", id: 5})
userData.push ["Shug", 3]
userData.push ["Harold", 2]
userData.push ["Dug", 4]

phoneData.push ["Nokia", 2]
phoneData.push({type: "Samsung", user_id: 1})
phoneData.push ["Apple", 3]
phoneData.push["Nokia", 4]
phoneData.push ["Samsung" 5]
#####################
# Functions         #
#####################
### Properties ###
userData.features #List of features
userData.length #Number of records
### Querying, joining and splitting ###
##
# Filter data by function. Retrun new RegressionDataSet
##
filteredUserData  = userData.filterByFunction{|data| data[:id] > 2}
##
# Select data by function. Return new RegressionDataSet
##
selectedUserData = userData.select{|data| data[:name].match(/^Dav(e|id)$/)
##
# Splitting (Returns [RegressionDataSet, RegressionDataSet]
#
#Takes one param, split ratio / No. records. < 1 = ratio, > 1 = No.
##
splitUserData = userData.split 0.5
##
# Partitioning. Returns an N-sized Array of RegressionDataSets
# Takes one param, Number of output RegressionDataSets
##
splitPhoneData = userData.partition 3
##
# Retrieve a sample of records from the data based on the 0 < input < 1 passed parameter
##
sampleUserData = userData.sample 0.3
##
# Segregating (Vertical split by feature aliases)
#
# Split data into two data sets veritcally. Pass feature list for the output.
#
# Param 1:  An Array of features names which are in teh dataset
# Param 2:  Boolean, should these output features be dropped from the base dataset?
##
userDataFeatureSplit = userData.segregate [:name], true
##
# Merge two RegressionDataSets
##
mergedData = splitUserData.first << splitUserData.last
##
# Join two RegressionDataSets with differing features
#
# NOTE: This method assumes a 1:1 relationship between the first and second sets' row ID
joinedData = userData.join phoneData
##
# Group by feature Retruns Array of RegressionDataSets where length == dataset.<feature> unique values length
##
groupedUserData = userData.groupBy :name
##
# Group by function (Returns Array of RegressionDataSets where length == dataset.<feature> unique values length
##
groupedUserData = userData.groupByFunction{|data| data[:name] != "Dave"}
##
# Apply a function to the data
##
userData.apply{|data| data[:name] = data[:name].titlecase}
### Sorting ###
##
# Sort the data (Inline). Takes function (Proc) as any other <=> sort operator use
##
userData.sort!{|a, b| a[:id] <=> b[:id]} 
### Adding new features to the data ###
## 
# Inject features with default values from a Hash
##
userData.injectFeatures({age:20})
##
# Inject a feature and set values by function
##
userData.injectFeatureByFunction(:type){|data| data[:age] < 18 ? "dependent" : "adult"}
### Getting the data from the dataset
##
# Retrieve a Hash for the requested feature
#
# Param 1: Symbol / String. Which feature
# Param 2:  Boolean (Optional), should the feature be removed from the dataset?
##
nameHash = userData.retrieveFeatureAsHash :name, false
### Getting the data from the dataset
##
# Retrieve an Array for the requested feature
#
# Param 1: Symbol / String. Which feature
# Param 2:  Boolean (Optionaal), should the feature be removed from the dataset?
nameArray = userData.retrieveFeatureAsArray :name, false
```
# Getting started

- Install Ruby > 2 (possibly 2.4)
- Install the bundler gem `gem install bundler`
- Install the package `bundle install`

To get a feel for what's happening do the following

- List examples and select `ruby run_example.rb`
- Run "geneva_scehdule_climate_translation" `ruby run_example.rb geneva_scehdule_climate_translation --data-alias:geneva_schedule_climate --target:target`
- Run "simple_tuning" `ruby run_example.rb simple_linear_regression --data-alias:data --target:heat`

the outputs int he console will be enough to go from there. Check out the related ./examples/ file for further info.

![alt text](https://i.imgur.com/uR007Cv.png "Sample console output")


