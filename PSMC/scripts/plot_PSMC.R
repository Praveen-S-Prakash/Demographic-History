
library(stringr)
library(ggplot2)
library(scales)
library(dplyr)
library(extrafont)

loadfonts(device = "pdf")

# Set folder path
parent.folder <- "/media/birdlab/bird_hdd3/vishwa/psmc_biogeo/04_psmc/RUBA/all_txt/"

# List all RUBA .txt files
all_files <- list.files(
  path = parent.folder,
  pattern = "^RUBA.*\\.txt$",
  full.names = TRUE
)

# Read and format
data_list <- lapply(all_files, function(file) {
  
  df <- read.table(file, header = FALSE)
  cbind(df[-1, 1:2], File = basename(file))
  
})

RUBA <- do.call("rbind", data_list)

colnames(RUBA) <- c("YearsAgo", "Ne", "File")
RUBA$New.Ne <- RUBA$Ne * 1e4

# Extract replicate
RUBA$Rep <- str_split_fixed(RUBA$File, "\\.", 3)[, 2]
RUBA$Rep <- factor(
  RUBA$Rep,
  levels = c(as.character(1:100), "0")
)

# Manual sample mapping
RUBA$Sample <- NA

RUBA$Sample[grepl("AB4046", RUBA$File)] <- "RUBA_AB4046"
RUBA$Sample[grepl("B74045", RUBA$File)] <- "RUBA_B74045"
RUBA$Sample[grepl("AB4028", RUBA$File)] <- "RUBA_AB4028"
RUBA$Sample[grepl("B74044", RUBA$File)] <- "RUBA_B74044"

# RUBA$Sample[grepl("SRR765714", RUBA$File)] <- "RUBA_SRR765714"


# Assign colour groups
RUBA$colour <- NA

RUBA$colour[RUBA$Sample == "RUBA_AB4046" & RUBA$Rep != "0"] <- "bootstrap.RUBA1"
RUBA$colour[RUBA$Sample == "RUBA_B74045" & RUBA$Rep != "0"] <- "bootstrap.RUBA2"
RUBA$colour[RUBA$Sample == "RUBA_AB4028" & RUBA$Rep != "0"] <- "bootstrap.RUBA3"
RUBA$colour[RUBA$Sample == "RUBA_B74044" & RUBA$Rep != "0"] <- "bootstrap.RUBA4"

# RUBA$colour[RUBA$Sample == "RUBA_SRR765714" & RUBA$Rep != "0"] <- "bootstrap.RUBA3"

RUBA$colour[RUBA$Sample == "RUBA_AB4046" & RUBA$Rep == "0"] <- "main.RUBA1"
RUBA$colour[RUBA$Sample == "RUBA_B74045" & RUBA$Rep == "0"] <- "main.RUBA2"
RUBA$colour[RUBA$Sample == "RUBA_AB4028" & RUBA$Rep == "0"] <- "main.RUBA3"
RUBA$colour[RUBA$Sample == "RUBA_B74044" & RUBA$Rep == "0"] <- "main.RUBA4"

# RUBA$colour[RUBA$Sample == "RUBA_SRR765714" & RUBA$Rep == "0"] <- "main.RUBA3"

RUBA$colour <- factor(
  RUBA$colour,
  levels = c(
    "bootstrap.RUBA1",
    "bootstrap.RUBA2",
    "bootstrap.RUBA3",
    "bootstrap.RUBA4",
    "main.RUBA1",
    "main.RUBA2",
    "main.RUBA3",
    "main.RUBA4"
  )
)

RUBA$size <- ifelse(
  RUBA$Rep == "0",
  "main",
  "bootstrap"
)

# Separate main and bootstrap results
RUBA_bootstrap <- RUBA %>% filter(Rep != "0")
RUBA_main <- RUBA %>% filter(Rep == "0")

# Colors
group.colours <- c(
  bootstrap.RUBA1 = "#A6CEE3",
  bootstrap.RUBA2 = "#B2DF8A",
  bootstrap.RUBA3 = "#FDBF6F",
  bootstrap.RUBA4 = "#CAB2D6",
  main.RUBA1 = "#1F78B4",
  main.RUBA2 = "#33A02C",
  main.RUBA3 = "#FF7F00",
  main.RUBA4 = "#6A3D9A"
)

# MIS shading
mis_blocks <- data.frame(
  xmin = c(71, 300, 374),
  xmax = c(130, 337, 424),
  ymin = 0,
  ymax = Inf,
  label = c("IG (MIS5)", "IG (MIS9)", "IG (MIS11)"),
  label_x = c((71 + 122) / 2, (300 + 337) / 2, (374 + 424) / 2),
  label_y = c(140000, 140000, 140000)
)

# Plot
RUBA_plot <- ggplot() +
  
  # Interglacial shading
  geom_rect(
    data = mis_blocks,
    aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax
    ),
    fill = "forestgreen",
    alpha = 0.2
  ) +
  
  # Bootstraps
  geom_path(
    data = RUBA_bootstrap,
    aes(
      x = YearsAgo / 1000,
      y = New.Ne,
      group = interaction(Sample, Rep),
      colour = colour,
      size = size
    ),
    show.legend = FALSE
  ) +
  
  # Main lines
  geom_path(
    data = RUBA_main,
    aes(
      x = YearsAgo / 1000,
      y = New.Ne,
      colour = colour,
      size = size
    )
  ) +
  
  # MIS labels
  geom_text(
    data = mis_blocks,
    aes(
      x = label_x,
      y = label_y,
      label = label
    ),
    angle = 90,
    size = 4
  ) +
  
  scale_size_manual(
    values = c(
      "main" = 1.2,
      "bootstrap" = 0.4
    )
  ) +
  
  scale_color_manual(
    values = group.colours,
    breaks = c(
      "main.RUBA1",
      "main.RUBA2",
      "main.RUBA3",
      "main.RUBA4"
    ),
    labels = c(
      "RUBA_AB4046",
      "RUBA_B74045",
      "RUBA_AB4028",
      "RUBA_B74044"
    )
  ) +
  
  labs(
    x = expression(paste("Time (x ", 10^3, " Years Ago)")),
    y = "Effective Population Size (Ne)"
  ) +
  
  ggtitle(
    expression(
      "Rufous Babbler (" * italic("Argya subrufa") * ")"
    )
  ) +
  
  scale_x_log10(
    limits = c(10, 2000),
    breaks = c(10, 20, 50, 100, 200, 500, 1000, 2000)
  ) +
  
  scale_y_continuous(
    labels = comma,
    n.breaks = 10,
    limits = c(0, 150000)
  ) +
  
  guides(
    size = FALSE,
    colour = guide_legend(
      override.aes = list(
        size = 10,
        lwd = 1.3
      )
    )
  ) +
  
  theme_bw() +
  
  theme(
    text = element_text(family = "Arial"),
    panel.grid = element_blank(),
    legend.text = element_text(size = rel(1.2)),
    axis.text = element_text(size = 12),
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    plot.title = element_text(size = 14),
    legend.margin = margin(t = -6),
    legend.title = element_blank(),
    legend.position = "bottom"
  ) +
  
  # Key paleo-climate lines
  geom_vline(
    xintercept = 20,
    linetype = "dashed",
    color = "darkgrey"
  ) +   # LGM, PGM
  
  geom_vline(
    xintercept = 120,
    linetype = "dashed",
    color = "darkgrey"
  ) +   # LIG
  
  # Event annotations
  annotate(
    "text",
    label = "LGM",
    x = 20,
    y = 150000,
    size = 4,
    family = "Arial"
  ) +
  
  annotate(
    "text",
    label = "LIG",
    x = 120,
    y = 150000,
    size = 4,
    family = "Arial"
  )


# Show plot
RUBA_plot

# Save high-resolution outputs
ggsave(
  "/media/birdlab/bird_hdd3/vishwa/psmc_biogeo/04_psmc/RUBA/RUBA.png",
  plot = RUBA_plot,
  width = 8,
  height = 6,
  dpi = 600
)

ggsave(
  "/media/birdlab/bird_hdd3/vishwa/psmc_biogeo/04_psmc/RUBA/RUBA.pdf",
  plot = RUBA_plot,
  width = 8,
  height = 6,
  device = cairo_pdf
)
