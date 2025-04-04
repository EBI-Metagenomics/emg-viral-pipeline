#!/usr/bin/env Rscript

library(sankeyD3)
library(magrittr)

args = commandArgs(trailingOnly = TRUE)

Taxonomy <- jsonlite::fromJSON(args[1])

# print to HTML file
sankey = sankeyNetwork(Links = Taxonomy\$links, Nodes = Taxonomy\$nodes, Source = "source", Target = "target", Value = "value", NodeID = "name", units = "count", fontSize = 22, nodeWidth = 30, nodeShadow = TRUE, nodePadding = 30, nodeStrokeWidth = 1, nodeCornerRadius = 10, dragY = TRUE, dragX = TRUE, numberFormat = ",.3g", align = "left", orderByPath = TRUE)
saveNetwork(sankey, file = '${id}.sankey.html')