# make_banner.R: draws assets/banner.png for the GitHub profile README
#
# Left: name and what I do. Right: one small square per forecasting model,
# coloured by what happened when it was tested against market prices, read
# from the forecast-honesty-lab scorecard (computed, never typed). Run from
# this repo's root:
#
#   Rscript assets/make_banner.R

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(ragg)
})

# ---- the scorecard: local sibling checkout first, else the published copy ----
local_csv  <- "../forecast-honesty-lab/data/models.csv"
remote_csv <- paste0("https://raw.githubusercontent.com/ItsMikeF/",
                     "forecast-honesty-lab/main/data/models.csv")
models <- read_csv(if (file.exists(local_csv)) local_csv else remote_csv,
                   show_col_types = FALSE)

# ---- palette (same as the scorecard chart) ----------------------------------
BG    <- "#12151a"
INK   <- "#f2f4f7"
INK2  <- "#c3cbd6"
MUTED <- "#8d97a4"
LINE  <- "#39414c"
GOLD  <- "#e8b93b"
CORAL <- "#e07a5f"
SLATE <- "#1d232c"

FONT_TEXT  <- "Segoe UI"
FONT_TITLE <- "Bahnschrift"

tier_style <- tibble(
  tier = c("proven", "thin edge", "no edge", "untested", "legacy"),
  rank = 1:5,
  fill = c("#5fd08a", GOLD, CORAL, SLATE, BG),
  edge = c("#5fd08a", GOLD, CORAL, LINE, LINE)
)
stopifnot(all(models$tier %in% tier_style$tier))

# ---- the model grid: 9 columns, filled row by row in tier order -------------
COLS <- 9
STEP <- 0.52
X0   <- 10.55   # x of the first column (canvas is 16 x 4 units = 1600 x 400 px)
Y0   <- 3.25    # y of the top row

grid <- models %>%
  inner_join(tier_style, by = "tier") %>%
  arrange(rank) %>%
  mutate(i = row_number() - 1,
         x = X0 + (i %% COLS) * STEP,
         y = Y0 - (i %/% COLS) * STEP)

n_all    <- nrow(models)
n_tested <- sum(models$tier %in% c("proven", "thin edge", "no edge"))
grid_mid <- X0 + (COLS - 1) * STEP / 2
y_cap    <- min(grid$y) - 0.52

# Legend as coloured words: the colour is never the only cue.
legend <- tibble(
  label = c("thin edge", "no edge", "not yet tested"),
  col   = c(GOLD, CORAL, INK2),
  x     = c(grid_mid - 1.55, grid_mid, grid_mid + 1.6)
)

p <- ggplot() +
  # left: who and what
  annotate("segment", x = 0.75, xend = 1.55, y = 3.2, yend = 3.2,
           colour = GOLD, linewidth = 1.6) +
  annotate("text", x = 0.7, y = 2.45, label = "Michael Francis", hjust = 0,
           family = FONT_TITLE, size = 15, colour = INK) +
  annotate("text", x = 0.72, y = 1.55, hjust = 0, family = FONT_TEXT, size = 5,
           colour = INK2,
           label = "Supply chain planning  ·  forecasting models  ·  data pipelines") +
  annotate("text", x = 0.72, y = 0.85, hjust = 0, family = FONT_TEXT, size = 3.9,
           colour = MUTED,
           label = "R  ·  SQL  ·  Python  ·  SAP MRP  ·  New Jersey") +
  # right: one square per model
  geom_tile(data = grid, aes(x = x, y = y, fill = fill, colour = edge),
            width = 0.42, height = 0.42, linewidth = 0.45) +
  annotate("text", x = grid_mid, y = y_cap, family = FONT_TEXT, size = 3.7,
           colour = INK2,
           label = sprintf("%d forecasting models  ·  %d tested against market prices",
                           n_all, n_tested)) +
  geom_text(data = legend, aes(x = x, y = y_cap - 0.42, label = label, colour = col),
            family = FONT_TEXT, size = 3.4) +
  scale_fill_identity() +
  scale_colour_identity() +
  coord_fixed(xlim = c(0, 16), ylim = c(0, 4), expand = FALSE) +
  theme_void() +
  theme(plot.background  = element_rect(fill = BG, colour = NA),
        panel.background = element_rect(fill = BG, colour = NA),
        plot.margin = margin(0, 0, 0, 0))

ragg::agg_png("assets/banner.png", width = 1600, height = 400, res = 150,
              background = BG)
print(p)
invisible(dev.off())
message("wrote assets/banner.png  (", n_all, " models, ", n_tested, " tested)")
