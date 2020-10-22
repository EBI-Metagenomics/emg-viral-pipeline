#!/usr/bin/env Rscript

library(dplyr)
library(tidyr)
library(ggplot2)
library(svglite)

args = commandArgs(trailingOnly = TRUE)

cols <- c('name', 'rank', 'variable', 'number')
df.virify <- as_tibble(read.table(args[1]))
names(df.virify) <- cols

# add a "row" column which will be the y position in the plot: group by rank and name, then set "row" as group index
df.virify <- df.virify %>% mutate(row = group_indices(df.virify, .dots=c('name')))

# define order of columns in the plot, sort df.virify
order <- c("order", "family", "subfamily", "genus")
df.virify <- df.virify %>% 
    mutate(rank =  factor(rank, levels = order)) %>%
    arrange(rank)

df.virify <- df.virify %>% unite(rank, variable, col = "col_order", remove = F)
col_levels <- unique(df.virify$col_order)

# ask trice if something is unclear ;D
df.virify <- df.virify %>% 
    mutate(col_order = factor(col_order, levels = col_levels)) %>%
    mutate(col = group_indices(., col_order))

# get character vector of variable names for the x axis. the order is important, hence arrange(col)!
vars_x_axis <- (df.virify %>% arrange(col) %>% select(variable) %>% distinct())$variable
# get character vector of observation names for the y axis. again, the order is important but "df" is already ordered
names_y_axis <- (df.virify %>% group_by(row) %>% distinct(name) %>% ungroup() %>% arrange(row) %>% select(name))$name


plot <- ggplot(df.virify, aes(x=factor(col), y=factor(row), color=rank, size=number, alpha=number)) +
  geom_point() +  # plot as points
  geom_text(aes(label=number, x=col + 0.25), alpha=1.0, size=3) +   # display the number next to the "balloons"
  scale_alpha_continuous(range=c(0.3, 0.7)) +
  scale_size_area(max_size = 5) +
  scale_x_discrete(breaks=1:length(vars_x_axis), labels=vars_x_axis, position='top') +   # set the labels on the X axis
  scale_y_discrete(breaks=1:length(names_y_axis), labels=names_y_axis) +                 # set the labels on the Y axis
  theme_bw() +
  theme(axis.line = element_blank(),            # disable axis lines
        axis.title = element_blank(),           # disable axis titles
        panel.border = element_blank(),         # disable panel border
        panel.grid.major.x = element_blank(),   # disable lines in grid on X-axis
        panel.grid.minor.x = element_blank(),   # disable lines in grid on X-axis
        axis.text.x = element_text(angle = 90))  # rotate x axis labels

ggsave(file=args[2], plot=plot, width=as.numeric(args[3]), height=as.numeric(args[4]))
ggsave(file=sub('.svg','.pdf',args[2]), plot=plot, width=as.numeric(args[3]), height=as.numeric(args[4]))
