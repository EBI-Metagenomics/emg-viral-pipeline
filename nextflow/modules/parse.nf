process parse {
    publishDir "${params.output}/${name}/", mode: 'copy', pattern: "*.fna"
    publishDir "${params.output}/${name}/", mode: 'copy', pattern: "virsorter_metadata.tsv"
    publishDir "${params.output}/${name}/${params.finaldir}/", mode: 'copy', pattern: "${name}_virus_predictions.log"
    label 'python3'

    input:
      tuple val(name), file(fasta), val(contig_number), file(virfinder), file(virsorter), file(pprmeta)

    when: 
      contig_number.toInteger() > 0 

    output:
      tuple val(name), file("*.fna"), file('virsorter_metadata.tsv'), file("${name}_virus_predictions.log"), optional: false
    
    script:
    if (params.use_virsorter2)
        """
    touch virsorter_metadata.tsv
    parse_viral_pred.py -a ${fasta} -f ${virfinder} -p ${pprmeta} -z ${virsorter} &> ${name}_virus_predictions.log
    """
    else
    """
    touch virsorter_metadata.tsv
    parse_viral_pred.py -a ${fasta} -f ${virfinder} -p ${pprmeta} -s ${virsorter}/Predicted_viral_sequences/*.fasta &> ${name}_virus_predictions.log
    """
}

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
