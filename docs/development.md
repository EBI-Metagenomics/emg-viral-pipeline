# Development notes

## Table of contents

- [A note about metatranscriptomes](#metatranscriptome)
- [Frequently Asked Questions (FAQ)](#faq)
  - [GFF validation errors](#gff-validation-errors)
- [Technical Details](#technical)
  - [VirSorter2 Circular Genome Handling](#virsorter2-circular-genome-handling)

<a name="metatranscriptome"></a>

# A note about metatranscriptomes

Although VIRify has been benchmarked and validated with metagenomic data in mind, it is also possible to use this tool to detect RNA viruses in metatranscriptome assemblies (e.g. SARS-CoV-2). However, some additional considerations for this purpose are outlined below:

**1. Quality control:** As for metagenomic data, a thorough quality control of the FASTQ sequence reads to remove low-quality bases, adapters and host contamination (if appropriate) is required prior to assembly. This is especially important for metatranscriptomes as small errors can further decrease the quality and contiguity of the assembly obtained. We have used [TrimGalore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/) for this purpose.

**2. Pre-processing:** Metatranscriptomes generate highly fragmented assemblies. Therefore, filtering contigs based on a set minimum length has a substantial impact in the number of contigs processed in VIRify. It has also been observed that the number of false-positive detections of [VirFinder](https://github.com/jessieren/VirFinder/releases) (one of the tools included in VIRify) is lower among larger contigs. The choice of a length threshold will depend on the complexity of the sample and the sequencing technology used, but in our experience any contigs <2 kb should be analysed with caution.

**3. Classification:** The classification module of VIRify depends on the presence of a minimum number and proportion of phylogenetically-informative genes within each contig in order to confidently assign a taxonomic lineage. Therefore, short contigs typically obtained from metatranscriptome assemblies remain generally unclassified. For targeted classification of RNA viruses (for instance, to search for Coronavirus-related sequences), alternative DNA- or protein-based classification methods can be used. Two of the possible options are: (i) using [MashMap](https://github.com/marbl/MashMap/releases) to screen the VIRify contigs against a database of RNA viruses (e.g. Coronaviridae) or (ii) using [hmmsearch](http://hmmer.org/download.html) to screen the proteins obtained in the VIRify contigs against marker genes of the taxon of interest.

<a name="faq"></a>

# Frequently Asked Questions (FAQ)

## GFF validation errors

### Problem: GFF3 validation fails with error messages like:
```
gt gff3validator: error: token "ID" on line XXXX in file "SAMPLE_virify.gff" does not contain exactly one '='
```

**Cause:** This error typically occurs when FASTA headers contain special characters that interfere with GFF3 format requirements. Characters like hyphens (`-`), periods (`.`), and equals signs (`=`) in sequence identifiers can cause issues during the GFF validation step.

**Example of problematic FASTA headers:**
```
>k141_1615808-flag=1-multi=1.0000-len=1122
>contig-1.2=scaffold_01
```

**Solution:** Clean your FASTA headers before running VIRify by replacing problematic characters with underscores:

```bash
# Replace hyphens, periods, and equals signs with underscores
sed '/^>/ s/[-.=]/_/g' original.fasta > cleaned.fasta
```

<a name="technical"></a>

# Technical Details

## VirSorter2 Circular Genome Handling

VIRify includes special handling for circular genome artifacts produced by VirSorter2 (VS2). When processing circular genomes, VS2 extends the annotation beyond the end of the contig to avoid truncating the gene annotation. This can result in prophage coordinates that exceed the original contig boundaries.

VIRify automatically detects and truncates prophage end coordinates that exceed contig lengths, while preserving the original prophage start coordinates.

For more details, see [VirSorter2 issue #243](https://github.com/jiarong/VirSorter2/issues/243).

Note that CheckV carries over the overhang end from VirSorter2, so be mindful of this when using the results. In addition, extended genes are also trimmed in the final output of VIRIfy.

