process rename {
      publishDir "${params.output}/${name}/", mode: 'copy', pattern: "${name}_renamed.fasta"
      label 'python3'

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

/*
usage: rename_fasta.py [-h] -i INPUT [-m MAP] -o OUTPUT {rename,restore} ...
*/
