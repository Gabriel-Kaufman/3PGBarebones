# 3PG Forest Growth Model Scripts

This repository contains scripts for running the 3PG (Physiological Principles Predicting Growth) forest growth model in R using the `r3PG` package. The scripts are designed to help simulate tree growth and carbon sequestration.

## Overview

The 3PG model is a process-based model that predicts the growth of forest stands using basic principles of tree physiology. It accounts for factors like climate, site conditions, and species characteristics to estimate growth and biomass accumulation over time.

## Repository Contents

This repository contains four main scripts:

1. **`simple_3pg_example.R`** - A minimal example script that demonstrates basic 3PG model usage with the built-in example datasets.

2. **`3pg_biomass_only.R`** - A more comprehensive script that focuses on biomass accumulation and carbon sequestration, with visualizations and detailed outputs.

3. **`3pg_carbon_standlevel.R`** - An advanced script for modeling mixed-species stands and calculating carbon sequestration on a specific land area (0.1 acres). Includes outputs in both metric tonnes and short tons.

4. **`3pg_with_sensor_data.R`** - A specialized script that processes real sensor data from CSV files and combines it with sample values for missing variables to run the 3PG model. Ideal for integrating IoT sensor networks with forest growth models.

## How to Use

### Prerequisites

- R (version 4.0 or higher recommended)
- Required packages: `r3PG`, `dplyr`, `lubridate`, `ggplot2`, `readr`

You can install these packages using:

```r
install.packages(c("r3PG", "dplyr", "lubridate", "ggplot2", "readr"))
```

### Running the Scripts

#### Simple Example

Run `simple_3pg_example.R` to see a basic demonstration of the 3PG model with example data. This script:

- Loads example data from the `r3PG` package
- Runs the model for one tree species
- Prints a summary of growth results and carbon sequestration

#### Biomass and Carbon Analysis

Run `3pg_biomass_only.R` for a more detailed analysis focused on biomass and carbon sequestration. This script:

- Creates synthetic climate data for a 3-year period
- Sets up model parameters for a single tree species
- Runs the model and analyzes biomass changes
- Calculates carbon sequestration and CO2 equivalent values
- Generates visualizations showing biomass and carbon changes over time
- Saves results to CSV files and plots as PNG images

#### Stand-Level Carbon Analysis

Run `3pg_carbon_standlevel.R` for an advanced multi-species carbon analysis. This script:

- Models two different tree species in the same stand
- Calculates stand-level biomass and carbon sequestration
- Converts from per-hectare values to a specific land area (0.1 acres)
- Provides carbon values in both metric tonnes and short tons
- Creates species-specific carbon visualizations
- Saves detailed CSV outputs for further analysis

#### Using Sensor Data

Run `3pg_with_sensor_data.R` to process and use real sensor data with the 3PG model. This script:

- Reads and processes sensor data from a CSV file (`db-80.Cluster0.csv`)
- Aggregates high-frequency sensor readings to monthly averages required by 3PG
- Fills in missing variables (like precipitation) with sample estimates
- Converts sensor light readings to solar radiation estimates
- Runs the 3PG model with a mix of real and estimated data
- Produces biomass and carbon sequestration results and visualizations
- All sample/estimated data is clearly marked in the code

The sensor data script expects a CSV file with columns for timestamp, temperature, humidity, light levels, and soil measurements. It will automatically convert this data to the format required by the 3PG model.

## Customizing for Your Needs

### Modifying Parameters

To adapt the scripts for your specific forest stand:

1. Change the site parameters in the `site_data` data frame
2. Modify the climate data or create your own based on local weather records
3. Adjust the species parameters (fertility, initial biomass, etc.)
4. Change the simulation time period by modifying the date range
5. For the stand-level script, adjust the plot area (currently set to 0.1 acres)

### Working with Sensor Data

If using the sensor data script, you can customize it by:

1. Replacing sample estimates with actual data where available
2. Calibrating the light-to-solar-radiation conversion for your specific sensors
3. Developing more accurate precipitation estimations based on local data
4. Specifying the actual tree species present at your monitoring site
5. Providing real initial biomass values if you have inventory data

### Adding More Species

To model multiple tree species:

1. Add additional rows to the `my_species` data frame
2. Ensure each species has the required parameters
3. The model will automatically handle competition between species

## References

- Landsberg, J.J. and Waring, R.H. (1997). A generalised model of forest productivity using simplified concepts of radiation-use efficiency, carbon balance and partitioning. Forest Ecology and Management, 95(3), 209-228.
- [r3PG package documentation](https://CRAN.R-project.org/package=r3PG)

## Support

For questions about these scripts, please open an issue in this repository.

For questions about the r3PG package or the 3PG model itself, refer to the package documentation or vignettes:

```r
?r3PG
vignette("r3PG")
``` 
