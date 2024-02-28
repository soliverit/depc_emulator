# RdSAP domestic EPC emulator (prototype)
An estimator for English domestic EPCs built on the publically available survey data from the UK government's Open Data Communities.

### Features
depc.rb: Script for translating single climate region datasets from https:/opendatacommunities.org England and Wales domestic EPC register and generating a Gradient Boosting Regressor model through OllieMl's EPS (https://github.com/ankane/eps) wrapper

# Overview
The emulator takes the CSV output format from Open Data Communities and translates each entry into a set of features which enable reasonable existing energy efficiency prediction.

### Performance
Results are from transferring training data created by depc.rb to Python for scikit-learn's gradient boosting decision trees. The Ruby sandbox uses EPSRegressor which performs marginally lower.

#### v2 (using sckit-learn GradientBoostingRegressor and https://github.com/soliverit/scikit_hp_tuner)

  **RMSE**: 3.437 **MAE**:  2.34  **R²**:   0.924

# Getting started with the Ruby sandbox environment

- Install Ruby > 2.4
- Install the bundler gem `gem install bundler`
- Install the package `bundle install`

- Call: ruby depc.rb \<target\> \<data directory path\> \<features list . E.g ./domestic_features.txt\> \<train/test split ratio\>
  
    Target:                         target column name (written primarily for CURRENT_ENERGY_EFFICIENCY)
  
    Data directory for the project: Typically should be the root's ./data/ directory but any data directory will do
    
    Test train split:               Ratio of input records used for training and testing 0 < 1
  
    "ruby CURRENT_ENERGY_EFFICIENCY ./data/
