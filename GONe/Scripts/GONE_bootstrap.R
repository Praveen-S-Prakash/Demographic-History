
## Plot GONE bootstrap results

setwd("/Users/praveenp/Desktop/gonett/")

library(ggplot2)
library(dplyr)

# Parameters
GenTime <- 1
CurrentYear <- 2026

prefix <- "EV_final_boot"
suffix <- "_GONE2_Ne"
n_boot <- 100

# Read bootstrap files
data_list <- lapply(0:n_boot, function(i) {
  
  file <- paste0(prefix, i, suffix)
  
  if (file.exists(file)) {
    
    df <- read.table(file, header = TRUE)
    
    df$Boot <- i
    
    # Keep first 200 generations
    df <- df[df$Generation <= 200, ]
    
    # Convert generations to calendar year
    df$Year <- CurrentYear - df$Generation * GenTime
    
    return(df)
    
  } else {
    
    warning(paste("Missing:", file))
    return(NULL)
    
  }
})

# Combine all data
data_all <- do.call(rbind, data_list)

# Mean Ne
mean_data <- data_all %>%
  group_by(Generation) %>%
  summarise(
    Mean_Ne = mean(Ne_diploids, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Year = CurrentYear - Generation * GenTime
  )

# 95% Confidence Interval
ci_data <- data_all %>%
  group_by(Generation) %>%
  summarise(
    lower = quantile(Ne_diploids, 0.025, na.rm = TRUE),
    upper = quantile(Ne_diploids, 0.975, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Year = CurrentYear - Generation * GenTime
  )

# X-axis breaks every 25 years
years_all <- seq(
  from = CurrentYear,
  to = floor(min(data_all$Year)),
  by = -25
)

# Plot
p1 <- ggplot() +
  
  # Bootstrap trajectories
  geom_line(
    data = data_all,
    aes(
      x = Year,
      y = Ne_diploids,
      group = Boot,
      colour = "Bootstraps"
    ),
    linewidth = 0.5,
    alpha = 0.35
  ) +
  
  # Confidence interval
  geom_ribbon(
    data = ci_data,
    aes(
      x = Year,
      ymin = lower,
      ymax = upper
    ),
    fill = "#08306B",
    alpha = 0.25
  ) +
  
  # Mean Ne
  geom_line(
    data = mean_data,
    aes(
      x = Year,
      y = Mean_Ne,
      colour = "Mean Ne"
    ),
    linewidth = 1.3
  ) +
  
  scale_color_manual(
    values = c(
      "Bootstraps" = "lightblue",
      "Mean Ne" = "#08306B"
    ),
    name = NULL
  ) +
  
  scale_x_reverse(
    breaks = years_all,
    labels = years_all,
    expand = expansion(mult = c(0.02, 0.02))
  ) +
  
  scale_y_continuous(
    n.breaks = 6,
    expand = expansion(mult = c(0, 0.05))
  ) +
  
  labs(
    title = "Themeda triandra",
    x = "Year",
    y = "Effective Population Size (Ne)"
  ) +
  
  theme_bw(base_size = 15) +
  
  theme(
    plot.title = element_text(
      size = 18,
      face = "bold",
      hjust = 0.5
    ),
    axis.title = element_text(
      size = 16,
      face = "bold"
    ),
    axis.text = element_text(
      size = 13,
      colour = "black"
    ),
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    ),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = c(0.82, 0.85),
    legend.background = element_rect(
      fill = "white",
      colour = "grey80"
    ),
    legend.text = element_text(size = 12)
  )

# Display plot
print(p1)

# Save figure
ggsave(
  "EV_GONe.png",
  plot = p1,
  width = 10,
  height = 6,
  dpi = 600
)
