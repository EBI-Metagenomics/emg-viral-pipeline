process BLAST_FILTER {
    label 'process_single'
    tag "${meta.id} ${confidence_set_name}"      
    container 'quay.io/microbiome-informatics/virify-python3:1.2'

    input:
      tuple val(meta), val(confidence_set_name), path(blast), path(blast_filtered)
      path(db)
    
    output:
      tuple val(meta), path(confidence_set_name), path("*.meta")
    
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
