# ============================================================
# PSMC plotting - TT_02
# ============================================================

library(stringr)
library(ggplot2)
library(scales)
library(dplyr)
library(extrafont)

loadfonts(device = "pdf")


# ------------------------------------------------------------
# 1. Input directory
# ------------------------------------------------------------

parent.folder <- "/media/birdlab/HDD_16/raw_seq_data/NCGM_5022/PSMC/PSMC_out/TT_02/txt_files"


# ------------------------------------------------------------
# 2. Identify TT_02 PSMC output files
# ------------------------------------------------------------

all_files <- list.files(
  path = parent.folder,
  pattern = "^60707400250.*\\.txt$",
  full.names = TRUE
)


# ------------------------------------------------------------
# 3. Read and format PSMC output
# ------------------------------------------------------------

data_list <- lapply(all_files, function(file) {

  df <- read.table(file, header = FALSE)

  cbind(
    df[-1, 1:2],
    File = basename(file)
  )

})

TT <- do.call("rbind", data_list)

colnames(TT) <- c("YearsAgo", "Ne", "File")

TT$New.Ne <- TT$Ne * 1e4


# ------------------------------------------------------------
# 4. Extract bootstrap replicate number
# ------------------------------------------------------------

TT$Rep <- str_split_fixed(TT$File, "\\.", 3)[, 2]

TT$Rep <- factor(
  TT$Rep,
  levels = c(as.character(1:100), "0")
)


# ------------------------------------------------------------
# 5. Assign sample names
# ------------------------------------------------------------

TT$Sample <- NA

TT$Sample[grepl("AB4046", TT$File)] <- "TT_AB4046"
TT$Sample[grepl("B74045", TT$File)] <- "TT_B74045"
TT$Sample[grepl("AB4028", TT$File)] <- "TT_AB4028"
TT$Sample[grepl("B74044", TT$File)] <- "TT_B74044"

# TT$Sample[grepl("SRR765714", TT$File)] <- "TT_SRR765714"


# ------------------------------------------------------------
# 6. Assign colour groups
# ------------------------------------------------------------

TT$colour <- NA

# Bootstrap replicates
TT$colour[
  TT$Sample == "TT_AB4046" & TT$Rep != "0"
] <- "bootstrap.TT1"

TT$colour[
  TT$Sample == "TT_B74045" & TT$Rep != "0"
] <- "bootstrap.TT2"

TT$colour[
  TT$Sample == "TT_AB4028" & TT$Rep != "0"
] <- "bootstrap.TT3"

TT$colour[
  TT$Sample == "TT_B74044" & TT$Rep != "0"
] <- "bootstrap.TT4"

# TT$colour[
#   TT$Sample == "TT_SRR765714" & TT$Rep != "0"
# ] <- "bootstrap.TT3"


# Main PSMC trajectories
TT$colour[
  TT$Sample == "TT_AB4046" & TT$Rep == "0"
] <- "main.TT1"

TT$colour[
  TT$Sample == "TT_B74045" & TT$Rep == "0"
] <- "main.TT2"

TT$colour[
  TT$Sample == "TT_AB4028" & TT$Rep == "0"
] <- "main.TT3"

TT$colour[
  TT$Sample == "TT_B74044" & TT$Rep == "0"
] <- "main.TT4"

# TT$colour[
#   TT$Sample == "TT_SRR765714" & TT$Rep == "0"
# ] <- "main.TT3"


TT$colour <- factor(
  TT$colour,
  levels = c(
    "bootstrap.TT1",
    "bootstrap.TT2",
    "bootstrap.TT3",
    "bootstrap.TT4",
    "main.TT1",
    "main.TT2",
    "main.TT3",
    "main.TT4"
  )
)


# ------------------------------------------------------------
# 7. Assign line sizes
# ------------------------------------------------------------

TT$size <- ifelse(
  TT$Rep == "0",
  "main",
  "bootstrap"
)


# ------------------------------------------------------------
# 8. Separate bootstrap and main trajectories
# ------------------------------------------------------------

TT_bootstrap <- TT %>%
  filter(Rep != "0")

TT_main <- TT %>%
  filter(Rep == "0")


# ------------------------------------------------------------
# 9. Define colours
# ------------------------------------------------------------

group.colours <- c(
  bootstrap.TT1 = "#A6CEE3",
  bootstrap.TT2 = "#B2DF8A",
  bootstrap.TT3 = "#FDBF6F",
  bootstrap.TT4 = "#CAB2D6",
  main.TT1 = "#1F78B4",
  main.TT2 = "#33A02C",
  main.TT3 = "#FF7F00",
  main.TT4 = "#6A3D9A"
)


# ------------------------------------------------------------
# 10. Define MIS intervals
# ------------------------------------------------------------

mis_blocks <- data.frame(
  xmin = c(71, 300, 374),
  xmax = c(130, 337, 424),
  ymin = 0,
  ymax = Inf,
  label = c("IG (MIS5)", "IG (MIS9)", "IG (MIS11)"),
  label_x = c(
    (71 + 122) / 2,
    (300 + 337) / 2,
    (374 + 424) / 2
  ),
  label_y = c(140000, 140000, 140000)
)


# ------------------------------------------------------------
# 11. Generate plot
# ------------------------------------------------------------

TT_plot <- ggplot() +

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

  # Bootstrap trajectories
  geom_path(
    data = TT_bootstrap,
    aes(
      x = YearsAgo / 1000,
      y = New.Ne,
      group = interaction(Sample, Rep),
      colour = colour,
      size = size
    ),
    show.legend = FALSE
  ) +

  # Main PSMC trajectories
  geom_path(
    data = TT_main,
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

  # Line widths
  scale_size_manual(
    values = c(
      "main" = 1.2,
      "bootstrap" = 0.4
    )
  ) +

  # Colours and legend
  scale_color_manual(
    values = group.colours,
    breaks = c(
      "main.TT1",
      "main.TT2",
      "main.TT3",
      "main.TT4"
    ),
    labels = c(
      "TT_AB4046",
      "TT_B74045",
      "TT_AB4028",
      "TT_B74044"
    )
  ) +

  labs(
    x = expression(
      paste("Time (x ", 10^3, " Years Ago)")
    ),
    y = "Effective Population Size (Ne)"
  ) +

  ggtitle(
    expression(
      "Themeda triandra 02 (" *
        italic("Themeda triandra") *
        ")"
    )
  ) +

  # Log-scaled x-axis
  scale_x_log10(
    limits = c(10, 2000),
    breaks = c(
      10, 20, 50, 100,
      200, 500, 1000, 2000
    )
  ) +

  # Y-axis
  scale_y_continuous(
    labels = comma,
    n.breaks = 10,
    limits = c(0, 1500000)
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
    text = element_text(family = "sans"),
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

  # Key palaeoclimate lines
  geom_vline(
    xintercept = 20,
    linetype = "dashed",
    color = "darkgrey"
  ) +

  geom_vline(
    xintercept = 120,
    linetype = "dashed",
    color = "darkgrey"
  ) +

  # Event annotations
  annotate(
    "text",
    label = "LGM",
    x = 20,
    y = 150000,
    size = 4,
    family = "sans"
  ) +

  annotate(
    "text",
    label = "LIG",
    x = 120,
    y = 150000,
    size = 4,
    family = "sans"
  )


# ------------------------------------------------------------
# 12. Display plot
# ------------------------------------------------------------

TT_plot


# ------------------------------------------------------------
# 13. Save high-resolution outputs
# ------------------------------------------------------------

ggsave(
  "/media/birdlab/HDD_16/raw_seq_data/NCGM_5022/PSMC/PSMC_out/TT_02/TT/TT_02_1500000.png",
  plot = TT_plot,
  width = 8,
  height = 6,
  dpi = 600
)

ggsave(
  "/media/birdlab/HDD_16/raw_seq_data/NCGM_5022/PSMC/PSMC_out/TT_02/TT/TT_02_1500000.pdf",
  plot = TT_plot,
  width = 8,
  height = 6,
  device = cairo_pdf
)
