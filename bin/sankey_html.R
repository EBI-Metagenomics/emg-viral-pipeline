#!/usr/bin/env Rscript

# Load necessary libraries
suppressPackageStartupMessages({
  library(sankeyD3)
  library(magrittr)
  library(jsonlite)
})

# Parse command-line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: script.R input.json output.html")
}

# Read JSON input
Taxonomy <- fromJSON(args[1])

# Generate the Sankey diagram
sankey <- sankeyNetwork(
  Links = Taxonomy$links,
  Nodes = Taxonomy$nodes,
  Source = "source",
  Target = "target",
  Value = "value",
  NodeID = "name",
  units = "count",
  fontSize = 22,
  nodeWidth = 30,
  nodeShadow = TRUE,
  nodePadding = 30,
  nodeStrokeWidth = 1,
  nodeCornerRadius = 10,
  dragY = TRUE,
  dragX = TRUE,
  numberFormat = ",.3g",
  align = "left",
  orderByPath = TRUE
)

# Save to HTML
saveNetwork(sankey, file = args[2])