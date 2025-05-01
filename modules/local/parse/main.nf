/*
  usage: parse_viral_pred.py [-h] -a ASSEMB -f FINDER -s SORTER [-o OUTDIR]

  description: script generates three output_files: High_confidence.fna, Low_confidence.fna, Prophages.fna

  optional arguments:
  -h, --help            show this help message and exit
  -a ASSEMB, --assemb ASSEMB
                        Metagenomic assembly fasta file
  -p PPRMETA, --pmout PPRMETA
                        Absolute or relative path to PPR-Meta output file
  -f FINDER, --vfout FINDER
                        Absolute or relative path to VirFinder output file
  -s SORTER, --vsdir SORTER
                        Absolute or relative path to directory containing
                        VirSorter output
  -o OUTDIR, --outdir OUTDIR
                        Absolute or relative path of directory where output
                        viral prediction files should be stored (default: cwd)
                        
  NOTE: only outputs .fna files if some low confidence or high confidence viral seqs were identified, otherwise outputs nothing.
*/

process PARSE {

  label 'process_low'

  tag "${meta.id}"

  container 'quay.io/microbiome-informatics/virify-python3:1.2'

  input:
  tuple val(meta), path(fasta), val(contig_number), path(virfinder), path(virsorter), path(pprmeta)

  output:
  tuple val(meta), path("*.fna"), path('virsorter_metadata.tsv'), path("${meta.id}_virus_predictions.stats"), optional: true

  when: contig_number.toInteger() > 0

  script:
  if (!params.use_virsorter_v1) {
    """
    touch virsorter_metadata.tsv
    parse_viral_pred.py -a ${fasta} -f ${virfinder} -p ${pprmeta} -z ${virsorter} &> ${meta.id}_virus_predictions.stats
    """
  }
  else {
    """
    touch virsorter_metadata.tsv
    parse_viral_pred.py -a ${fasta} -f ${virfinder} -p ${pprmeta} -s ${virsorter}/Predicted_viral_sequences/*.fasta &> ${meta.id}_virus_predictions.stats
    """
  }
}
