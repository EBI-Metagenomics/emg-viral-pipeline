process prodigal {
      publishDir "${params.output}/${assembly_name}/${params.prodigaldir}", mode: 'copy', pattern: "*.faa"
      publishDir "${params.output}/${assembly_name}/${params.finaldir}/cds/", mode: 'copy', pattern: "*.faa"
      label 'prodigal'

    input:
      tuple val(assembly_name), val(confidence_set_name), file(fasta) 
    
    output:
      tuple val(assembly_name), val(confidence_set_name), file("*.faa")
    
    shell:
    """
    prodigal -p "meta" -a ${confidence_set_name}_prodigal.faa -i ${fasta}
    """
}
