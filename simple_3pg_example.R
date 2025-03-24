# Simple 3PG Model Example
# A minimal script to demonstrate 3PG model usage

# Load required packages
library(r3PG)
library(dplyr)

# Step 1: Load example data from the package
data("d_climate")    # Climate data
data("d_site")       # Site data
data("d_species")    # Species data
data("d_parameters") # Model parameters
data("d_thinning")   # Thinning data (empty for our example)

# Print basic information about the loaded data
cat("Using example data from r3PG package:\n")
cat("- Site location: Latitude", d_site$latitude, "°, Altitude", d_site$altitude, "m\n")
cat("- Simulation period:", d_site$from, "to", d_site$to, "\n")
cat("- Tree species:", d_species$species[1], "\n")
cat("- Initial stems per hectare:", d_species$stems_n[1], "\n")

# Step 2: Run the 3PG model with example data
cat("\nRunning 3PG model...\n")
results <- run_3PG(
  site = d_site,
  climate = d_climate,
  species = d_species[1,],  # Using just the first species
  thinning = NULL,          # No thinning
  parameters = d_parameters,
  settings = list(light_model = 1, transp_model = 1, phys_model = 1),
  check_input = TRUE,
  df_out = TRUE
)

# Step 3: Extract and show key growth results
key_variables <- c("stems_n", "height", "dbh", "biom_stem", "biom_root", "biom_foliage")

# Create a summary of initial and final values
summary_results <- results %>%
  filter(variable %in% key_variables) %>%
  group_by(variable) %>%
  summarize(
    initial_value = first(value),
    final_value = last(value),
    change = final_value - initial_value,
    percent_change = round((final_value/initial_value - 1) * 100, 1)
  )

# Print the results
cat("\n=== GROWTH SUMMARY ===\n")
print(summary_results)

# Calculate total biomass and carbon
initial_biomass <- summary_results %>%
  filter(variable %in% c("biom_stem", "biom_root", "biom_foliage")) %>%
  summarize(total = sum(initial_value)) %>%
  pull(total)

final_biomass <- summary_results %>%
  filter(variable %in% c("biom_stem", "biom_root", "biom_foliage")) %>%
  summarize(total = sum(final_value)) %>%
  pull(total)

biomass_change <- final_biomass - initial_biomass
carbon_change <- biomass_change * 0.5  # Approximately 50% of biomass is carbon
co2_equivalent <- carbon_change * (44/12)  # Convert C to CO2 (molecular weight ratio)

cat("\n=== CARBON SUMMARY ===\n")
cat("Initial total biomass:", round(initial_biomass, 2), "Mg/ha\n")
cat("Final total biomass:", round(final_biomass, 2), "Mg/ha\n")
cat("Biomass increase:", round(biomass_change, 2), "Mg/ha\n")
cat("Carbon sequestered:", round(carbon_change, 2), "Mg C/ha\n")
cat("CO2 equivalent:", round(co2_equivalent, 2), "Mg CO2/ha\n")

# Save results to CSV if needed
# write.csv(results, "simple_3pg_results.csv", row.names = FALSE)

cat("\nModel run complete! For more detailed analysis, see the 3pg_biomass_only.R script.\n") 