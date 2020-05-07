#!/usr/bin/env Rscript

#load libraries
library(optparse)
library(ggplot2)
library(gggenes)
library(RColorBrewer)

#prepare arguments
option_list <- list(
	make_option(c("-t", "--table"), type = "character", default = NULL,
		help = "Annotation table containing ViPhOG hmmer results for viral contig file",
		metavar = "table"),
	make_option(c("-o", "--outdir"), type = "character", default = ".",
		help = "Output directory (default: cwd)", metavar = "outdir"))

opt_parser <- OptionParser(option_list = option_list);
opt <- parse_args(opt_parser);

if (is.null(opt$table)) {
	print_help(opt_parser)
	stop("Provide table containing ViPhOG hmmer results for viral contig file")/Users/kates/Desktop/CWL_viral_pipeline/CWL/prodigal
}

#prepare input file
path <- normalizePath(opt$table)
annotation_table <- read.delim(path, stringsAsFactors = FALSE)

#Create column indicating significance of hmmer hits
colour_func <- function(x) {
	if (is.na(x)) {
		"No hit"
	} else if (x < 10) {
		"Low confidence"
	} else {
		"High confidence"
	}
}
annotation_table$Colour <- factor(lapply(annotation_table$Abs_Evalue_exp, colour_func), levels = c("No hit", "Low confidence", "High confidence"))

#Create column for label position
annotation_table$Position <- annotation_table$Start + (annotation_table$End - annotation_table$Start)/2

#Create vector of colours for different levels of significance of annotations
myColors <- c("#808080", "#EAEA1E", "#08B808")
names(myColors) <- levels(annotation_table$Colour)

dir.create(opt$outdir, showWarnings = FALSE)

#Generate maps for each viral contig identified
for (item in unique(annotation_table$Contig)) {
	sample_data <- subset(annotation_table, Contig == item)
	pdf(file.path(normalizePath(opt$outdir), paste(item, ".pdf", sep = "")), width = 25, height = 10)
	print(ggplot(sample_data, aes(xmin = Start, xmax = End, y = Contig, fill = Colour, forward = Direction))
	+ geom_gene_arrow(arrowhead_height = unit(3, "mm"), arrowhead_width = unit(1, "mm"))
	+ geom_text(aes(x = Position, label = Label), angle = 90, colour = "black", size = 3, hjust = -0.2)
	+ scale_fill_manual(name = "Confidence", values = myColors)
	+ theme_genes())
	dev.off()
}
