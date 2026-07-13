process checkVGetDB {
    label 'process_low'    
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/checkv:1.0.1--pyhdfd78af_0'
        : 'biocontainers/checkv:1.0.1--pyhdfd78af_0'}"
    
    publishDir "${params.databases}", mode: params.cloudProcess ? 'copy' : 'symlink'

    input:
    tuple val(meta), val(db_link)

    output:
        tuple val(meta), path("checkv-db-v*", type: 'dir'), emit: database_dir
    script:
        """
        wget -nH ${db_link} -O checkv-db.tar.gz
        tar -zxvf checkv-db.tar.gz
        rm checkv-db.tar.gz

        # build diamond database
        cd checkv-db-v*.*/genome_db
        diamond makedb --in checkv_reps.faa --db checkv_reps
        """
    stub:
        """
        mkdir -p checkv-db-v1.5
        """
}
