process checkVGetDB {
    label 'process_low'    
    container 'quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10'
    
    if (params.cloudProcess) { 
        publishDir "${params.databases}/checkv", mode: 'copy' 
    }
    else { 
        storeDir "${params.databases}/checkv" 
    }
      
    output:
        path("checkv-db-v*", type: 'dir')
    script:
        """
        wget https://portal.nersc.gov/CheckV/checkv-db-v1.0.tar.gz
        tar -zxvf checkv-db-v1.0.tar.gz
        rm checkv-db-v1.0.tar.gz
        """
    stub:
        """
        mkdir -p checkv-db-v1.0
        """
}