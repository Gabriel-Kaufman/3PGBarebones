# Streamlined 3PG Model - Biomass Only
# Load required packages
library(r3PG)
library(dplyr)
library(lubridate)
library(ggplot2)  # Make sure ggplot2 is loaded for visualizations

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
if ("Pinus sylvestris" %in% d_species$species) {
  my_species <- d_species %>% filter(species == "Pinus sylvestris")
} else {
  my_species <- d_species[1, ]
  my_species$species <- "Custom_Pine"
}

# Set initial conditions
my_species$planted <- "2021-01"
my_species$fertility <- 0.7
my_species$stems_n <- 1000
my_species$biom_stem <- 10
my_species$biom_root <- 3
my_species$biom_foliage <- 2

# Run the 3PG model
cat("Running 3PG model...\n")
model_results <- tryCatch({
  run_3PG(
    site = site_data,
    climate = climate_data,
    species = my_species,
    thinning = NULL,
    parameters = d_parameters,
    size_dist = NULL,
    settings = list(light_model = 1, transp_model = 1, phys_model = 1),
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

# Extract biomass data only
biomass_results <- model_results %>%
  filter(variable %in% c("biom_stem", "biom_foliage", "biom_root")) %>%
  select(date, species, variable, value)

# Calculate total biomass (sum of stem, foliage, and root)
total_biomass <- biomass_results %>%
  group_by(date, species) %>%
  summarize(total_biomass = sum(value), .groups = "drop")

# Calculate monthly changes
monthly_biomass_change <- total_biomass %>%
  arrange(date) %>%
  mutate(
    prev_biomass = lag(total_biomass),
    biomass_change = total_biomass - prev_biomass,
    percent_change = ifelse(!is.na(prev_biomass), 
                          (total_biomass - prev_biomass) / prev_biomass * 100,
                          NA)
  )

# Print initial and final biomass values
initial_biomass <- total_biomass %>% filter(date == min(date))
final_biomass <- total_biomass %>% filter(date == max(date))

cat("\n=== BIOMASS SUMMARY ===\n")
cat("Species:", my_species$species[1], "\n")
cat("Initial total biomass:", round(initial_biomass$total_biomass, 2), "Mg/ha\n")
cat("Final total biomass:", round(final_biomass$total_biomass, 2), "Mg/ha\n")
cat("Total biomass change:", round(final_biomass$total_biomass - initial_biomass$total_biomass, 2), "Mg/ha\n")
cat("Percent increase:", round((final_biomass$total_biomass / initial_biomass$total_biomass - 1) * 100, 1), "%\n\n")

# Print summary of component biomass
component_summary <- biomass_results %>%
  group_by(variable) %>%
  summarize(
    initial = first(value),
    final = last(value),
    change = final - initial,
    percent_change = (final / initial - 1) * 100
  )

cat("=== BIOMASS COMPONENTS ===\n")
print(component_summary)

# Calculate carbon sequestration
# Standard conversion: ~50% of dry biomass is carbon
biomass_change <- final_biomass$total_biomass - initial_biomass$total_biomass
carbon_sequestered <- biomass_change * 0.5  # Convert biomass to carbon (50%)
co2_equivalent <- carbon_sequestered * (44/12)  # Convert C to CO2 (molecular weight ratio)

# Create carbon sequestration table
carbon_table <- data.frame(
  Metric = c(
    "Total biomass increase (Mg/ha)", 
    "Carbon sequestered (Mg C/ha)",
    "CO2 equivalent (Mg CO2/ha)",
    "CO2 equivalent per year (Mg CO2/ha/yr)"
  ),
  Value = c(
    round(biomass_change, 2),
    round(carbon_sequestered, 2),
    round(co2_equivalent, 2),
    round(co2_equivalent / 3, 2)  # Divided by 3 years of simulation
  )
)

cat("\n=== CARBON SEQUESTRATION ESTIMATES ===\n")
print(carbon_table)

# Calculate component-specific carbon sequestration
carbon_by_component <- component_summary %>%
  mutate(
    carbon_sequestered = change * 0.5,
    co2_equivalent = carbon_sequestered * (44/12),
    annual_co2_equivalent = co2_equivalent / 3  # 3 years of simulation
  ) %>%
  select(variable, carbon_sequestered, co2_equivalent, annual_co2_equivalent)

cat("\n=== CARBON SEQUESTRATION BY COMPONENT ===\n")
print(carbon_by_component)

# Calculate carbon sequestration through time
biomass_carbon_time <- total_biomass %>%
  mutate(
    carbon = total_biomass * 0.5,  # 50% of biomass is carbon
    co2_equivalent = carbon * (44/12)  # Convert C to CO2
  )

# Create visualizations
# ---------------------

# 1. Total biomass over time
p1 <- ggplot(total_biomass, aes(x = date, y = total_biomass)) +
  geom_line(color = "forestgreen", size = 1) +
  geom_point(color = "darkgreen", size = 2) +
  labs(title = paste("Total Biomass Over Time -", my_species$species[1]),
       x = "Date", 
       y = "Total Biomass (Mg/ha)") +
  theme_minimal()

# 2. Biomass components over time
p2 <- biomass_results %>%
  mutate(variable = factor(variable, 
                          levels = c("biom_stem", "biom_root", "biom_foliage"),
                          labels = c("Stem", "Root", "Foliage"))) %>%
  ggplot(aes(x = date, y = value, color = variable)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = c("darkgreen", "brown", "olivedrab"), name = "Component") +
  labs(title = "Biomass Components Over Time",
       x = "Date",
       y = "Biomass (Mg/ha)") +
  theme_minimal()

# 3. Carbon sequestered over time
p3 <- ggplot(biomass_carbon_time, aes(x = date, y = carbon)) +
  geom_line(color = "steelblue", size = 1) +
  geom_point(color = "navyblue", size = 2) +
  labs(title = "Carbon Sequestered Over Time",
       x = "Date",
       y = "Carbon (Mg C/ha)") +
  theme_minimal()

# 4. CO2 equivalent over time
p4 <- ggplot(biomass_carbon_time, aes(x = date, y = co2_equivalent)) +
  geom_line(color = "purple4", size = 1) +
  geom_point(color = "purple4", size = 2) +
  labs(title = "CO2 Equivalent Over Time",
       x = "Date",
       y = expression(CO[2]~Equivalent~(Mg~CO[2]/ha))) +
  theme_minimal()

# 5. Monthly carbon sequestration rate
monthly_carbon_rate <- monthly_biomass_change %>%
  filter(!is.na(biomass_change)) %>%
  mutate(
    carbon_change = biomass_change * 0.5,
    co2_change = carbon_change * (44/12)
  )

p5 <- ggplot(monthly_carbon_rate, aes(x = date, y = co2_change)) +
  geom_col(fill = "purple4", alpha = 0.7) +
  labs(title = "Monthly CO2 Sequestration Rate",
       x = "Date",
       y = expression(CO[2]~Sequestered~(Mg~CO[2]/ha/month))) +
  theme_minimal()

# Print all the plots
cat("\n=== VISUALIZATIONS ===\n")
cat("Showing plots for biomass and carbon over time\n\n")
print(p1)
print(p2)
print(p3)
print(p4)
print(p5)

# Save the plots
ggsave("total_biomass_over_time.png", plot = p1, width = 8, height = 5)
ggsave("biomass_components_over_time.png", plot = p2, width = 8, height = 5)
ggsave("carbon_over_time.png", plot = p3, width = 8, height = 5)
ggsave("co2_equivalent_over_time.png", plot = p4, width = 8, height = 5)
ggsave("monthly_co2_sequestration.png", plot = p5, width = 8, height = 5)

cat("\nPlots saved as PNG files:\n")
cat("- total_biomass_over_time.png\n")
cat("- biomass_components_over_time.png\n")
cat("- carbon_over_time.png\n")
cat("- co2_equivalent_over_time.png\n")
cat("- monthly_co2_sequestration.png\n")

# Save results to CSV files
write.csv(biomass_results, "biomass_results.csv", row.names = FALSE)
write.csv(monthly_biomass_change, "monthly_biomass_change.csv", row.names = FALSE)
write.csv(carbon_table, "carbon_sequestration.csv", row.names = FALSE)
write.csv(carbon_by_component, "carbon_by_component.csv", row.names = FALSE)

cat("\nResults saved to CSV files:\n")
cat("- biomass_results.csv\n")
cat("- monthly_biomass_change.csv\n")
cat("- carbon_sequestration.csv\n")
cat("- carbon_by_component.csv\n") 