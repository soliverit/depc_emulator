# RdSAP domestic EPC emulator (prototype)
A base emulator for predicting domestic EPC ratings from data limited to those available from inputs retrievable from output certificates

### Features
depc.rb: Script for translating single climate region datasets from https:/opendatacommunities.org England and Wales domestic EPC register and generating a Gradient Boosting Regressor model through OllieMl's EPS (https://github.com/ankane/eps) wrapper

# Overview
The emulator takes the CSV output format from Open Data Communities and translates each entry into a set of features which enable reasonable existing energy efficiency prediction.

### Performance

#### v0.1.2 (using sckit-learn GradientBoostingRegressor and https://github.com/soliverit/scikit_hp_tuner)

  **RMSE**: 4.418 **MAE**:  3.07  **R²**:   0.865
 #### v0.1.2

  **RMSE**: 4.26 **MAE**:  3.06  **R²**:   0.869
  - **n_estimators**: 694, **learning_rate**: 0.0496, **min_samples_split**: 26, **min_samples_leaf**: 11, **min_weight_fraction_leaf**: 0.0133

# Getting started

- Install Ruby > 2.4
- Install the bundler gem `gem install bundler`
- Install the package `bundle install`

- Call: ruby depc.rb \<target\> \<data directory path\> \<train/test split ratio\>
  
    Target:                         target column name (written primarily for CURRENT_ENERGY_EFFICIENCY)
  
    Data directory for the project: Typically should be the root's ./data/ directory but any data directory will do
    
    Test train split:               Ratio of input records used for training and testing 0 < 1
  
    "ruby CURRENT_ENERGY_EFFICIENCY ./data/
