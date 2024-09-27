process RENAME {
    /*
    usage: rename_fasta.py [-h] -i INPUT [-m MAP] -o OUTPUT {rename,restore} ...
    */
    
    label 'process_low'
    
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
      tuple val(name), file(fasta) 
    
    output:
      tuple val(name), file("${name}_renamed.fasta"), file("${name}_map.tsv")
    
    script:
    """    
    if [[ ${fasta} =~ \\.gz\$ ]]; then
      zcat ${fasta} > tmp.fasta
    else
      cp ${fasta} tmp.fasta
    fi
    rename_fasta.py -i tmp.fasta -m ${name}_map.tsv -o ${name}_renamed.fasta rename
    """
}


