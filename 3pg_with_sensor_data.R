# 3PG Model with Sensor Data
# This script processes data from db-80.Cluster0.csv and runs the 3PG model

# Load required packages
library(r3PG)
library(dplyr)
library(lubridate)
library(ggplot2)
library(readr)

# ==========================================
# PART 1: READ AND PROCESS SENSOR DATA
# ==========================================

# Read the CSV file
cat("Reading sensor data from db-80.Cluster0.csv...\n")
sensor_data <- read.csv("db-80.Cluster0.csv")

# Convert timestamp to date 
sensor_data$date <- as.POSIXct(sensor_data$timestamp, format="%Y-%m-%dT%H:%M:%S")

# Check date range
min_date <- min(sensor_data$date)
max_date <- max(sensor_data$date)
cat("Data range:", format(min_date, "%Y-%m-%d"), "to", format(max_date, "%Y-%m-%d"), "\n")

# Extract year and month for aggregation
sensor_data <- sensor_data %>%
  mutate(
    year = year(date),
    month = month(date)
  )

# Aggregate data to monthly averages (required by 3PG)
monthly_data <- sensor_data %>%
  group_by(year, month) %>%
  summarize(
    # Temperature data
    tmp_min = min(variables.temperature, na.rm = TRUE),
    tmp_max = max(variables.temperature, na.rm = TRUE), 
    tmp_ave = mean(variables.temperature, na.rm = TRUE),
    
    # Other measurements
    humidity = mean(variables.humidity, na.rm = TRUE),
    visible_light = mean(variables.visibleLight, na.rm = TRUE),
    infrared_light = mean(variables.infraredLight, na.rm = TRUE),
    soil_moisture = mean(variables.soilMoisture, na.rm = TRUE),
    soil_temp = mean(variables.soilTemp, na.rm = TRUE),
    .groups = "drop"
  )

# Print summary of the processed sensor data
cat("\nSummary of monthly sensor data:\n")
print(summary(monthly_data))

# ==========================================
# PART 2: FILL IN MISSING DATA WITH SAMPLE VALUES
# ==========================================

# Function to create a realistic precipitation estimate based on humidity
# This is a SAMPLE FUNCTION - replace with actual data if available
estimate_precipitation <- function(humidity) {
  # SAMPLE DATA: This is a simplified relationship between humidity and precipitation
  # In reality, this relationship is complex and location-dependent
  # Base precipitation (mm) with random variation
  base_precip <- 20 + humidity * 1.5
  # Add some monthly variation
  base_precip + rnorm(length(humidity), mean = 0, sd = 10)
}

# Function to convert light measurements to solar radiation
# This is a SAMPLE FUNCTION - replace with calibrated conversion if available
convert_light_to_srad <- function(visible, infrared) {
  # SAMPLE DATA: This is a simplified conversion from light readings to MJ/m²/day
  # In reality, this requires proper calibration for your specific sensor
  # Base conversion with minimum value to ensure positive readings
  pmax(5, (visible + infrared) * 0.15)
}

# Complete the climate data with the required variables for 3PG
climate_data <- monthly_data %>%
  mutate(
    # Estimate precipitation from humidity
    # SAMPLE DATA: Estimated precipitation based on humidity
    prcp = estimate_precipitation(humidity),
    
    # Convert light readings to solar radiation
    # SAMPLE DATA: Converted from light sensors to approximate MJ/m²/day
    srad = convert_light_to_srad(visible_light, infrared_light),
    
    # Estimate frost days based on temperature
    # SAMPLE DATA: Simple estimate based on minimum temperature
    frost_days = ifelse(tmp_min < 0, 5, 0),
    
    # Add CO2 concentration
    # SAMPLE DATA: Current approximate atmospheric CO2 level
    co2 = 410, 
    
    # Add delta 13C in atmosphere 
    # SAMPLE DATA: Standard value
    d13catm = -8
  ) %>%
  # Select only the columns required by 3PG
  select(year, month, tmp_min, tmp_max, tmp_ave, prcp, srad, frost_days, co2, d13catm)

# Print summary of the complete climate data
cat("\nSummary of prepared climate data for 3PG:\n")
print(summary(climate_data))

# ==========================================
# PART 3: SET UP SITE DATA
# ==========================================

# SAMPLE DATA: The following site data is fictional and should be replaced with real values
# from your specific site location

site_data <- data.frame(
  # SAMPLE DATA: Example latitude and altitude
  latitude = 45.5,    # REPLACE with actual site latitude
  altitude = 250,     # REPLACE with actual site altitude (meters)
  
  # SAMPLE DATA: Soil parameters
  soil_class = 2,     # REPLACE: 1=sand, 2=sandy loam, 3=clay loam, 4=clay
  asw_i = 120,        # REPLACE: Initial available soil water (mm)
  asw_min = 50,       # REPLACE: Minimum available soil water (mm)
  asw_max = 200,      # REPLACE: Maximum available soil water (mm)
  
  # Date range based on actual data with buffer to ensure coverage
  from = paste0(min(climate_data$year), "-", sprintf("%02d", min(climate_data$month))),
  to = paste0(max(climate_data$year), "-", sprintf("%02d", max(climate_data$month)))
)

cat("\nSite data for 3PG model:\n")
print(site_data)

# ==========================================
# PART 4: SET UP SPECIES DATA
# ==========================================

# Load example species data to use as a template
data("d_species")
data("d_parameters")

# SAMPLE DATA: Creating fictional tree species data
# REPLACE this with actual species in your forest stand

# Create first species - Pine
if ("Pinus sylvestris" %in% d_species$species) {
  species1 <- d_species %>% filter(species == "Pinus sylvestris")
  # Rename to make it clear this is sample data
  species1$species <- "Sample_Pine" 
} else {
  species1 <- d_species[1, ]
  species1$species <- "Sample_Pine"
}

# Create second species - Hardwood
if ("Fagus sylvatica" %in% d_species$species) {
  species2 <- d_species %>% filter(species == "Fagus sylvatica")
  # Rename to make it clear this is sample data
  species2$species <- "Sample_Hardwood"  
} else {
  species2 <- d_species[2, ]
  species2$species <- "Sample_Hardwood"
}

# SAMPLE DATA: Set initial conditions for both species
# The following values are examples and should be replaced with actual initial conditions

# First species
species1$planted <- site_data$from  # Planting date (using start of data period)
species1$fertility <- 0.7           # SAMPLE DATA: Site fertility rating (0-1)
species1$stems_n <- 700             # SAMPLE DATA: Number of stems per hectare
species1$biom_stem <- 8             # SAMPLE DATA: Initial stem biomass (Mg/ha)
species1$biom_root <- 2.5           # SAMPLE DATA: Initial root biomass (Mg/ha)
species1$biom_foliage <- 1.5        # SAMPLE DATA: Initial foliage biomass (Mg/ha)

# Second species
species2$planted <- site_data$from  # Planting date (using start of data period)
species2$fertility <- 0.6           # SAMPLE DATA: Site fertility rating (0-1)
species2$stems_n <- 300             # SAMPLE DATA: Number of stems per hectare
species2$biom_stem <- 6             # SAMPLE DATA: Initial stem biomass (Mg/ha)
species2$biom_root <- 2             # SAMPLE DATA: Initial root biomass (Mg/ha)
species2$biom_foliage <- 1          # SAMPLE DATA: Initial foliage biomass (Mg/ha)

# Combine the two species
my_species <- bind_rows(species1, species2)

cat("\nSpecies data for 3PG model (SAMPLE DATA):\n")
print(my_species)

# ==========================================
# PART 5: RUN THE 3PG MODEL
# ==========================================

cat("\nRunning 3PG model with sensor data and sample values...\n")

# Use tryCatch to handle potential errors
model_results <- tryCatch({
  # First attempt with standard settings
  run_3PG(
    site = site_data,
    climate = climate_data,
    species = my_species,
    thinning = NULL,  # No thinning operations
    parameters = d_parameters,
    size_dist = NULL,
    settings = list(light_model = 2, transp_model = 1, phys_model = 1),
    check_input = TRUE,
    df_out = TRUE
  )
}, error = function(e) {
  # If first attempt fails, try alternative settings
  cat("First attempt failed with error:", e$message, "\n")
  cat("Trying alternative settings...\n")
  
  # Second attempt with different settings
  tryCatch({
    run_3PG(
      site = site_data,
      climate = climate_data,
      species = my_species,
      thinning = NULL,
      parameters = d_parameters,
      size_dist = NULL,
      settings = list(light_model = 2, transp_model = 2, phys_model = 2,
                     correct_bias = 1, calculate_d13c = 0),
      check_input = TRUE,
      df_out = TRUE
    )
  }, error = function(e2) {
    # If both attempts fail, provide diagnostic information
    cat("Second attempt also failed with error:", e2$message, "\n\n")
    cat("DIAGNOSTIC INFORMATION:\n")
    cat("1. Check if climate data has valid values for all required variables\n")
    cat("2. Ensure date ranges in site_data match available climate data\n")
    cat("3. Verify species parameters are within acceptable ranges\n\n")
    
    # Create an empty data frame to prevent further errors
    return(NULL)
  })
})

# Check if model run was successful
if(is.null(model_results)) {
  cat("Model run failed. Check the error messages above.\n")
  quit(save = "no", status = 1)
}

# ==========================================
# PART 6: PROCESS AND VISUALIZE RESULTS
# ==========================================

# Extract biomass data for all species
biomass_data <- model_results %>%
  filter(variable %in% c("biom_stem", "biom_foliage", "biom_root"))

# Create species-level biomass summary
species_biomass <- biomass_data %>%
  group_by(date, species) %>%
  summarize(
    total_biomass_ha = sum(value),  # Sum of stem, foliage, and root
    .groups = "drop"
  )

# Create stand-level biomass summary (across all species)
stand_biomass <- species_biomass %>%
  group_by(date) %>%
  summarize(
    stand_biomass_ha = sum(total_biomass_ha),  # Sum across all species
    .groups = "drop"
  )

# Compute stand-level carbon (Mg C/ha)
stand_carbon <- stand_biomass %>%
  mutate(stand_carbon_ha = stand_biomass_ha * 0.5)  # 50% carbon

# Convert from per-ha to total for 0.1 acres (sample plot size)
one_acre_in_ha <- 0.4046856
plot_area_ha <- 0.1 * one_acre_in_ha  # 0.1 acres in hectares

stand_carbon_project <- stand_carbon %>%
  mutate(total_carbon_tonnes = stand_carbon_ha * plot_area_ha)

# Print initial & final stand biomass (per ha)
initial_biomass <- head(stand_biomass, 1)
final_biomass <- tail(stand_biomass, 1)
cat("\n=== STAND BIOMASS (per hectare) ===\n")
cat("Initial (Mg/ha):", round(initial_biomass$stand_biomass_ha, 4), "\n")
cat("Final   (Mg/ha):", round(final_biomass$stand_biomass_ha, 4), "\n")
cat("Change  (Mg/ha):", 
    round(final_biomass$stand_biomass_ha - initial_biomass$stand_biomass_ha, 4), "\n")

# Print final total carbon for the 0.1 acres in metric tonnes
final_carbon <- tail(stand_carbon_project, 1)$total_carbon_tonnes
cat("\n=== TOTAL CARBON on 0.1 acres (both species, metric tonnes) ===\n")
cat("Final carbon (Mg C):", round(final_carbon, 4), "\n")

# ==========================================
# PART 7: CREATE VISUALIZATIONS
# ==========================================

# Total biomass over time
p1 <- ggplot(stand_biomass, aes(x = date, y = stand_biomass_ha)) +
  geom_line(color = "forestgreen", size = 1) +
  geom_point(color = "darkgreen", size = 2) +
  labs(title = "Total Stand Biomass Over Time",
       subtitle = "Based on sensor data with sample parameters",
       x = "Date", 
       y = "Biomass (Mg/ha)") +
  theme_minimal()

# Species-specific biomass
p2 <- ggplot(species_biomass, aes(x = date, y = total_biomass_ha, color = species)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = c("darkgreen", "chocolate4")) +
  labs(title = "Species-Specific Biomass Over Time",
       subtitle = "Based on sensor data with sample parameters",
       x = "Date",
       y = "Biomass (Mg/ha)") +
  theme_minimal()

# Carbon over time
p3 <- ggplot(stand_carbon_project, aes(x = date, y = total_carbon_tonnes)) +
  geom_line(color = "blue", size = 1) +
  geom_point(color = "darkblue", size = 2) +
  labs(title = "Total Carbon Over Time (0.1 acres)",
       subtitle = "Based on sensor data with sample parameters",
       x = "Date",
       y = "Carbon (metric tonnes)") +
  theme_minimal()

# Print plots
print(p1)
print(p2)
print(p3)

# Save plots
ggsave("total_biomass_from_sensor_data.png", plot = p1, width = 8, height = 5)
ggsave("species_biomass_from_sensor_data.png", plot = p2, width = 8, height = 5)
ggsave("carbon_from_sensor_data.png", plot = p3, width = 8, height = 5)

# ==========================================
# PART 8: SAVE RESULTS
# ==========================================

# Save processed climate data
write.csv(climate_data, "processed_climate_data.csv", row.names = FALSE)

# Save biomass results
write.csv(species_biomass, "species_biomass_results.csv", row.names = FALSE)
write.csv(stand_biomass, "stand_biomass_results.csv", row.names = FALSE)
write.csv(stand_carbon_project, "carbon_results.csv", row.names = FALSE)

cat("\n=== Analysis Complete ===\n")
cat("Results and plots saved to the current directory.\n")
cat("\nNOTE: This analysis used SAMPLE DATA for missing values.\n")
cat("Replace sample data with actual values for a more accurate assessment.\n") 