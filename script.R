# Ensure the 'data' directory exists and prepare 'images' directory for output
if (!dir.exists("data"))  dir.create("data")
if (!dir.exists("images")) dir.create("images")

# Load the tidyverse collection of packages for data manipulation and ggplot2 for plotting
library(tidyverse)

# Load showtext for using Google fonts in plots
library(showtext)

# Load ggtext for rich text elements in ggplot2 annotations
library(ggtext)

# Add the "Libre Franklin" font from Google Fonts and assign it the family name "franklin"
font_add_google("Libre Franklin", "franklin")

# Set showtext options: render at 300 dpi for high-quality output
showtext_opts(dpi = 300)

# Automatically use showtext for future plots
showtext_auto()

# List all CSV files in the 'data' folder whose names include "Sympathies"
csv_files <- list.files("data", pattern = ".*Sympathies.*\\.csv$", full.names = TRUE)

# Read Gallup data from the CSV files:
# - Use the file names as an identifier column named 'party'
# - Skip the first row, which contains extraneous headers
# - Provide consistent column names for year and sympathy percentages
gallup_data <- read_csv(csv_files, id = "party", skip = 1, col_names = c("year", "israelis", "palestinians")) %>%
  mutate(
    # Remove trailing text from the 'party' identifier
    party = str_replace(party, "' Sympathies.*", ""),
    # For the overall Americans category, insert a line break in the label
    party = if_else(party == "Americans", "All\nAmericans", party),
    # Strip '%' and convert to numeric
    israelis = str_replace(israelis, "%", "") %>% as.numeric,
    palestinians = str_replace(palestinians, "%", "") %>% as.numeric,
    # Compute difference: positive means more support for Israelis
    difference = israelis - palestinians,
    # Construct a Date for January 1 of each year to use on the time axis
    date = as.Date(paste0(year, "-01-01"))
  ) %>%
  # Keep only the variables needed for plotting
  select(party, year, date, difference) %>%
  mutate(party = str_remove(party, "^data/"))

# Build the line plot showing how sympathy differences evolve over time
gallup_plot <- gallup_data %>%
  ggplot(aes(x = date, y = difference, color = party)) +
  
  # Add text labels for each party at the most recent year
  geom_text(
    data = filter(gallup_data, year == max(year)),
    aes(label = party, y = difference + 1.5),  # offset text slightly above the point
    x = as.Date(paste0(max(gallup_data$year) + 1, "-10-01")),                # place labels just to the right of the data
    hjust = 0, vjust = 1,
    family = "franklin", size = 9, size.unit = "pt",
    lineheight = 0.8
  ) +
  
  # Draw small connector lines from labels back to the data points
  geom_segment(
    data = filter(gallup_data, year == max(year)),
    aes(xend = as.Date(paste0(max(gallup_data$year) + 1, "-08-01"))),
    linetype = "21", linewidth = 0.4
  ) +
  
  # Add horizontal grid lines (major at 0, minor above/below)
  geom_hline(yintercept = seq(-40, 80, 40), linewidth = 0.25,
             color = c("gray80", "black", "gray80", "gray80")) +
  
  # Draw the time series lines for each party
  geom_line(linewidth = 1) +
  
  # Annotate vertical reference lines for key dates
  annotate(geom = "segment",
           x = as.Date(c("2016-01-01", "2023-10-07")),
           y = -40, yend = 80,
           linewidth = 0.25,
           color = "gray80") +
  
  # Label the key dates along the bottom
  annotate(geom = "text",
           x = as.Date(c("2016-01-01", "2023-10-07")),
           y = -25,
           label = c("2016", "Oct. 7, 2023"),
           family = "franklin", size = 8.5, size.unit = "pt",
           hjust = 1.1) +
  
  # Add rich text annotations to describe quadrants of the plot
  annotate(
    geom = "richtext",
    x = as.Date(c("2000-07-01", "2000-07-01")),
    y = c(-4, 4),
    label = c("More support for **Palestinians**",
              "More support for **Israelis**"),
    hjust = 0, family = "franklin", size = 3.25, label.size = 0
  ) +
  
  # Set titles and caption with HTML formatting via ggtext
  labs(
    title = "Sympathy for Palestinians has surged since 2016 -- driven by Democrats",
    subtitle = "How much more likely Americans and members of the two major parties were to express sympathy with Israelis over Palestinians.",
    caption = "Question text: \"In the Middle East situation, are your sympathies more with the Israelis or more with the Palestinians?\"<br><br><span style='font-size:8.5pt;'>Source: Gallup, March 2025</span>"
  ) +
  
  # Customize the y-axis breaks and labels, allowing room above -40
  scale_y_continuous(
    limits = c(-40, NA),
    breaks = seq(-40, 80, 40),
    labels = c("-40", "±0", "+40", "+80")
  ) +
  
  # Customize the x-axis to span from 2000 through the end of the final year
  scale_x_date(
    limits = as.Date(c("2000-01-01", paste0(max(gallup_data$year) + 1, "-10-01"))),
    breaks = as.Date(paste0(seq(2005, max(gallup_data$year), 5), "-01-01")),
    date_labels = "%Y"
  ) +
  
  # Ensure expanded labels are not clipped
  coord_cartesian(expand = FALSE, clip = "off") +
  
  # Define custom colors for each party
  scale_color_manual(
    breaks = c("Republicans", "All\nAmericans", "Democrats"),
    values = c("#BC2B24", "#494949", "#1366B3")
  ) +
  
  # Tweak the overall theme, text, and margins
  theme(
    text = element_text(family = "franklin"),
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    axis.text = element_text(color = "black", size = 9),
    panel.grid = element_blank(),
    panel.background = element_blank(),
    plot.title.position = "plot",
    plot.title = element_textbox_simple(face = "bold", size = 13.5,
                                        margin = margin(t = 5, r = -48)),
    plot.subtitle = element_textbox_simple(
      margin = margin(t = 23, b = 10, r = -48),
      size = 11.25, lineheight = 1.3),
    plot.caption.position = "plot",
    plot.caption = element_textbox_simple(size = 9,
                                          margin = margin(t = 13, r = -45)),
    plot.margin = margin(t = 5, r = 53, b = 0, l = 0),
    legend.position = "none"
  )

# Save the final plot to a PNG file in the 'images' folder with specified dimensions
ggsave("images/israelis-palestinians.png", plot = gallup_plot, width = 6, height = 6.97)

