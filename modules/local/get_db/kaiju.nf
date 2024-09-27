process kaijuGetDB {
  label 'noDocker'    
  if (params.cloudProcess) { 
    publishDir "${params.databases}/kaiju/", mode: 'copy', pattern: "viruses"//pattern: "nr_euk" 
  }
  else { 
    storeDir "${params.databases}/kaiju/" 
  }  

  output:
    //file("nr_euk")
    path("viruses", type: 'dir')

  script:
    """
    #this is the full database
    if [ 42 == 0 ]; then
    mkdir -p nr_euk
    cd nr_euk
    wget http://kaiju.binf.ku.dk/database/kaiju_db_nr_euk_2019-06-25.tgz 
    tar -xvzf kaiju_db_nr_euk_2019-06-25.tgz
    rm kaiju_db_nr_euk_2019-06-25.tgz
    fi

    # for testing purpose download a smaller one
    if [ 42 == 42 ]; then
    mkdir -p viruses
    cd viruses
    wget http://kaiju.binf.ku.dk/database/kaiju_db_viruses_2019-06-25.tgz
    tar -xvzf kaiju_db_viruses_2019-06-25.tgz
    rm kaiju_db_viruses_2019-06-25.tgz
    fi
    """
}


