process BLAST_FILTER {
    label 'process_low'
      
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
      tuple val(assembly_name), val(confidence_set_name), file(blast), file(blast_filtered)
      file(db)
    
    output:
      tuple val(assembly_name), val(confidence_set_name), file("*.meta")
    
    script:
    if (task.attempt.toString() == '1')
    """
      imgvr_merge.py -f ${blast_filtered} -d IMG_VR_2018-07-01_4/IMGVR_all_Sequence_information.tsv -o \$(basename ${blast_filtered} .blast).meta
    """
    else if (task.attempt.toString() == '2')
    """
      imgvr_merge.py -f ${blast_filtered} -d ${db}/IMG_VR_2018-07-01_4/IMGVR_all_Sequence_information.tsv -o \$(basename ${blast_filtered} .blast).meta
    """
}
