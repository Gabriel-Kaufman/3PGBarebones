# 3PG Carbon Model with Stand-Level Analysis
# Combines 3PG model with stand-level carbon calculations

# Load required packages
library(r3PG)
library(dplyr)
library(lubridate)
library(ggplot2)

# ==========================================
# PART 1: RUN THE 3PG MODEL (similar to 3pg_biomass_only.R)
# ==========================================

# Generate synthetic site data (3 years, 2021-2023)
set.seed(123)
dates <- seq(as.Date("2021-01-01"), as.Date("2023-12-31"), by = "month")
months <- month(dates)
years <- year(dates)
n_months <- length(dates)

# Temperature data
temp_mean <- 15 + 10 * sin((months - 6) * pi/6) + rnorm(n_months, 0, 1)
temp_min <- temp_mean - runif(n_months, 3, 6)
temp_max <- temp_mean + runif(n_months, 3, 7)

# Precipitation data
precip <- pmax(10, 70 + 40 * sin((months - 3) * pi/6) + rnorm(n_months, 0, 15))

# Solar radiation (ensuring all values are positive)
solarrad <- pmax(5, 15 + 8 * sin((months - 6) * pi/6) + rnorm(n_months, 0, 0.5))

# Frost days
frost_days <- ifelse(temp_min < 0, runif(n_months, 0, 10), 0)

# Format climate data for r3PG
climate_data <- data.frame(
  year = years,
  month = months,
  tmp_min = temp_min,
  tmp_max = temp_max,
  tmp_ave = temp_mean,
  prcp = precip,
  srad = solarrad,
  frost_days = frost_days,
  co2 = rep(410, n_months),
  d13catm = rep(-8, n_months)
)

# Site data for r3PG
site_data <- data.frame(
  latitude = 45.5,
  altitude = 250,
  soil_class = 2,
  asw_i = 120,
  asw_min = 50,
  asw_max = 200,
  from = "2021-01",
  to = "2023-12"
)

# Load example species data
data("d_species")

# Create a data frame with TWO species for our stand
# First: Pinus sylvestris (Pine)
if ("Pinus sylvestris" %in% d_species$species) {
  species1 <- d_species %>% filter(species == "Pinus sylvestris")
} else {
  species1 <- d_species[1, ]
  species1$species <- "Pine"
}

# Second: Fagus sylvatica (Beech) or another species
if ("Fagus sylvatica" %in% d_species$species) {
  species2 <- d_species %>% filter(species == "Fagus sylvatica")
} else {
  species2 <- d_species[1, ]
  species2$species <- "Hardwood"
}

# Set initial conditions for both species
species1$planted <- "2021-01"
species1$fertility <- 0.7
species1$stems_n <- 700  # Fewer stems for species 1
species1$biom_stem <- 8
species1$biom_root <- 2.5
species1$biom_foliage <- 1.5

species2$planted <- "2021-01"
species2$fertility <- 0.6  # Slightly less fertile conditions for species 2
species2$stems_n <- 300    # Fewer stems for species 2
species2$biom_stem <- 6
species2$biom_root <- 2
species2$biom_foliage <- 1

# Combine the two species
my_species <- bind_rows(species1, species2)

# Run the 3PG model
cat("Running 3PG model for two species...\n")
model_results <- tryCatch({
  run_3PG(
    site = site_data,
    climate = climate_data,
    species = my_species,
    thinning = NULL,
    parameters = d_parameters,
    size_dist = NULL,
    settings = list(light_model = 2, transp_model = 1, phys_model = 1),
    check_input = TRUE,
    df_out = TRUE
  )
}, error = function(e) {
  # If first attempt fails, try alternative settings
  cat("First attempt failed. Trying alternative settings...\n")
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
})

# ==========================================
# PART 2: PREPARE SPECIES & STAND BIOMASS DATA
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

# ==========================================
# PART 3: STAND-LEVEL CARBON CALCULATIONS
# ==========================================

# Compute stand-level carbon (Mg C/ha)
stand_carbon <- stand_biomass %>%
  mutate(stand_carbon_ha = stand_biomass_ha * 0.5)  # 50% carbon

# Convert from per-ha to total for your 0.1 acres
one_acre_in_ha <- 0.4046856
plot_area_ha   <- 0.1 * one_acre_in_ha  # 0.1 acres in hectares

stand_carbon_project <- stand_carbon %>%
  mutate(total_carbon_tonnes = stand_carbon_ha * plot_area_ha)
# Now 'total_carbon_tonnes' is in metric tonnes (Mg) for the entire 0.1 acres

# Print initial & final stand biomass (per ha)
initial_biomass <- head(stand_biomass, 1)
final_biomass   <- tail(stand_biomass, 1)
cat("\n=== STAND BIOMASS (per hectare) ===\n")
cat("Initial (Mg/ha):", round(initial_biomass$stand_biomass_ha, 4), "\n")
cat("Final   (Mg/ha):", round(final_biomass$stand_biomass_ha, 4), "\n")
cat("Change  (Mg/ha):", 
    round(final_biomass$stand_biomass_ha - initial_biomass$stand_biomass_ha, 4), "\n")

# Print final total carbon for the 0.1 acres in metric tonnes
final_carbon <- tail(stand_carbon_project, 1)$total_carbon_tonnes
cat("\n=== TOTAL CARBON on 0.1 acres (both species, metric tonnes) ===\n")
cat("Final carbon (Mg C):", round(final_carbon, 4), "\n")

# ----------------------------------------------------------------------------
# PLOT 1: Total Carbon Over Time in SHORT TONS
# ----------------------------------------------------------------------------
# 1 metric tonne (Mg) = ~1.10231 short tons
stand_carbon_project_short_tons <- stand_carbon_project %>%
  mutate(total_carbon_short_tons = total_carbon_tonnes * 1.10231)

p_total_carbon_short_tons <- ggplot(
  stand_carbon_project_short_tons,
  aes(x = date, y = total_carbon_short_tons)
) +
  geom_line(color = "blue", size = 1) +
  geom_point(color = "darkblue", size = 2) +
  labs(
    title = "Total Carbon Over Time (0.1 acres, 2 species)",
    x = "Date",
    y = "Carbon (short tons)"
  ) +
  theme_minimal()

print(p_total_carbon_short_tons)

ggsave(
  "total_carbon_over_time_0.1_acres_short_tons.png",
  plot = p_total_carbon_short_tons,
  width = 8,
  height = 5
)

# ----------------------------------------------------------------------------
# PLOT 2: Species-Specific Carbon Per Hectare
# ----------------------------------------------------------------------------
species_carbon <- species_biomass %>%
  mutate(carbon_ha = total_biomass_ha * 0.5)

p_species <- ggplot(species_carbon, aes(x = date, y = carbon_ha, color = species)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(
    title = "Species-Specific Carbon Over Time (Mg C/ha)",
    x = "Date",
    y = "Carbon (Mg C/ha)"
  ) +
  theme_minimal()

print(p_species)
ggsave("carbon_over_time_by_species_per_ha.png", plot = p_species, width = 8, height = 5)

# Save key outputs
write.csv(species_biomass, "species_biomass_per_ha.csv", row.names = FALSE)
write.csv(stand_biomass, "stand_biomass_per_ha.csv", row.names = FALSE)
write.csv(stand_carbon_project, "stand_carbon_0.1_acres_metric_tonnes.csv", row.names = FALSE)
write.csv(
  stand_carbon_project_short_tons,
  "stand_carbon_0.1_acres_short_tons.csv",
  row.names = FALSE
)

cat("\n=== Model Run Complete ===\n")
cat("Plots and CSVs saved.\n") 