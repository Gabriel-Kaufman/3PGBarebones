# 3PG Forest Growth Model Scripts

This repository contains scripts for running the 3PG (Physiological Principles Predicting Growth) forest growth model in R using the `r3PG` package. The scripts are designed to help simulate tree growth and carbon sequestration.

## Overview

The 3PG model is a process-based model that predicts the growth of forest stands using basic principles of tree physiology. It accounts for factors like climate, site conditions, and species characteristics to estimate growth and biomass accumulation over time.

## Repository Contents

This repository contains two main scripts:

1. **`simple_3pg_example.R`** - A minimal example script that demonstrates basic 3PG model usage with the built-in example datasets.
2. **`3pg_biomass_only.R`** - A more comprehensive script that focuses on biomass accumulation and carbon sequestration, with visualizations and detailed outputs.

## How to Use

### Prerequisites

- R (version 4.0 or higher recommended)
- Required packages: `r3PG`, `dplyr`, `lubridate`, `ggplot2`

You can install these packages using:

```r
install.packages(c("r3PG", "dplyr", "lubridate", "ggplot2"))
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

The biomass script produces the following outputs:

1. **Text summaries**:
   - Biomass summary (initial, final, change)
   - Component-specific biomass changes (stem, root, foliage)
   - Carbon sequestration estimates
   - CO2 equivalent values

2. **CSV files**:
   - `biomass_results.csv` - Biomass values for each component over time
   - `monthly_biomass_change.csv` - Monthly changes in biomass
   - `carbon_sequestration.csv` - Summary of carbon metrics
   - `carbon_by_component.csv` - Carbon by tree component

3. **Visualization plots**:
   - `total_biomass_over_time.png`
   - `biomass_components_over_time.png`
   - `carbon_over_time.png`
   - `co2_equivalent_over_time.png`
   - `monthly_co2_sequestration.png`

## Customizing for Your Needs

### Modifying Parameters

To adapt the scripts for your specific forest stand:

1. Change the site parameters in the `site_data` data frame
2. Modify the climate data or create your own based on local weather records
3. Adjust the species parameters (fertility, initial biomass, etc.)
4. Change the simulation time period by modifying the date range

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