process RENAME {
    /*
    usage: rename_fasta.py [-h] -i INPUT [-m MAP] -o OUTPUT {rename,restore} ...
    */

    label 'process_single'
    tag "${meta.id}"
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
    tuple val(meta), path(fasta), val(contigs_count)

    output:
    tuple val(meta), path("${meta.id}_renamed.fasta"), val(contigs_count), emit: renamed_fasta
    tuple val(meta), path("${meta.id}_map.tsv"),                           emit: mapfile

    script:
    """
    if [[ ${fasta} =~ \\.gz\$ ]]; then
      zcat ${fasta} > tmp.fasta
      echo "compressed"
    else
      cp ${fasta} tmp.fasta
      echo "uncompressed"
    fi
    rename_fasta.py -i tmp.fasta -m ${meta.id}_map.tsv -o ${meta.id}_renamed.fasta rename
    """
}
