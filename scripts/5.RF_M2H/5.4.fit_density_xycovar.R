#### STEP 5-4

## Univariate random forest fit to MODERN
## TOTAL STEM DENSITY and CLIMATE and SOIL covariates
## plus COORDINATES

## NOTE that the random forest model is saved to an external hard
## drive. The object isn't THAT big, so it can be saved locally,
## but I elected to save it externally. The directory should be
## saved according to your file structure

## 1. Load data
## 2. Hyperparameter tuning
## 3. Fit random forest

## Input: data/processed/FIA/xydata_in.RData
## Dataframe of in-sample grid cells with modern (FIA) era
## vegetation, soil, and climate data
## From 2.4.Split_data.R

## Output: /Volumes/FileBackup/SDM_bigdata/out/rf/M/density/xycovar.RData
## Fitted random forest object saved to external hard drive
## Used in 5.5.density_historical_predictions.R,
## 5.6.density_modern_predictions.R

rm(list = ls())

#### 1. Load data ####

# Load FIA data
load('data/processed/FIA/xydata_in.RData')

# Select relevant columns
rf_data <- fia_in |>
  dplyr::ungroup() |>
  dplyr::rename(total_density = total_stem_density) |>
  dplyr::select(total_density, # response variable
                clay, sand, silt, caco3, awc, flood, # edaphic variables
                ppt_sum, tmean_mean, ppt_cv,
                tmean_sd, tmin, tmax, vpdmax, # climatic variables
                x, y) |> # coordinates
  dplyr::distinct()

# Convert to regular dataframe
rf_data <- as.data.frame(rf_data)

#### 2. Hyperparameter tuning ####

# Tune mtry and nodesize
tune_rf <- randomForestSRC::tune(formula = total_density ~ ., # formula
                                 data = rf_data,
                                 nodesizeTry = 1:10, # node sizes to try
                                 ntreeTry = 500) # number of trees to grow

# Optimal hyperparameter combination
opt_hyper <- tune_rf$optimal
opt_hyper

# Format error rate for all combinations of hyperparameters
tune_hyper <- as.data.frame(tune_rf$results)

# Plot error rate for all combinations
tune_hyper |>
  ggplot2::ggplot() +
  ggplot2::geom_tile(ggplot2::aes(x = nodesize, y = mtry,
                                  fill = err)) +
  ggplot2::theme_minimal()

# Plot error rate for all mtry options with nodesize = 1
tune_hyper |>
  dplyr::filter(nodesize == 1) |>
  ggplot2::ggplot() +
  ggplot2::geom_bar(ggplot2::aes(x = mtry, y = err),
                    stat = 'identity') +
  ggplot2::geom_vline(ggplot2::aes(xintercept = tune_rf$optimal[2],
                                   color = 'optimal')) +
  ggplot2::geom_vline(ggplot2::aes(xintercept = round(sqrt(15)),
                                   color = 'default')) +
  ggplot2::scale_color_discrete(name = '') + 
  ggplot2::theme_minimal()

## Use nodesize = 1, mtry = 5

#### 3. Fit random forest ####

# Fit random forest
density_rf_M_xycovar <- randomForestSRC::rfsrc(formula = total_density ~ ., # formula
                                               data = rf_data, # data
                                               ntree = 1000, # number of trees to grow
                                               mtry = 5, # from above decision
                                               nodesize = 1, # from above decision
                                               importance = TRUE, # calculate variable importance
                                               forest = TRUE) # save forest variables

# Save
# Change directory according to your file structure
save(density_rf_M_xycovar,
     file = '/Volumes/FileBackup/SDM_bigdata/out/rf/M/density/xycovar.RData')
