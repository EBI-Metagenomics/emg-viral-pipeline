/*************  
* --help
*************/
def helpMSG() {
    c_green = "\033[0;32m";
    c_reset = "\033[0m";
    c_yellow = "\033[0;33m";
    c_blue = "\033[0;34m";
    c_dim = "\033[2m";
    log.info """
    ____________________________________________________________________________________________
    
    VIRify
    
    ${c_yellow}Usage example:${c_reset}
    nextflow run virify.nf --fasta 'assembly.fasta' 

    ${c_yellow}Input:${c_reset}
    ${c_green} --fasta ${c_reset}             '*.fasta'                   -> one fasta file, no assembly produced (if you need to process more than one assembly use --samplesheet option)
    ${c_green} --samplesheet ${c_reset}       '*.csv'                     -> use to provide multiple assemblies/sets of raw reads
    ${c_green} --assemble ${c_reset}          'true/false'                -> should be provided with samplesheet containing raw reads if you need to assemble reads first (experimental feature that performs SPAdes assembly)
    ${c_dim}  ..change above input to csv:${c_reset} ${c_green}--list ${c_reset}            

    ${c_yellow}Options:${c_reset}
    --cores             max cores per process for local use [default: $params.cores]
    --max_cores         max cores per machine for local use [default: $params.max_cores]
    --memory            max memory for local use [default: $params.memory]
    --output            name of the result folder [default: $params.output]

    ${c_yellow}Databases (automatically downloaded by default):${c_reset}
    --virsorter         a virsorter database provided as 'virsorter/virsorter-data' [default: $params.virsorter]
    --virfinder         a virfinder model [default: $params.virfinder]
    --viphog            the ViPhOG database, hmmpress'ed [default: $params.viphog]
    --rvdb              the RVDB, hmmpress'ed [default: $params.rvdb]
    --pvogs             the pVOGS, hmmpress'ed [default: $params.pvogs]
    --vogdb             the VOGDB, hmmpress'ed [default: $params.vogdb]
    --vpf               the VPF from IMG/VR, hmmpress'ed [default: $params.vpf]
    --ncbi              a NCBI taxonomy database, from ete3 import NCBITaxa, named ete3_ncbi_tax.sqlite [default: $params.ncbi]
    --checkv            the CheckV reference database for virus QC [default: $params.checkv]
    --imgvr             the IMG/VR, viral (meta)genome sequences [default: $params.imgvr]
    --pprmeta           the PPR-Meta github [default: $params.pprmeta]
    --meta              the tsv dictionary w/ meta information about ViPhOG models [default: $params.meta]

    Important! If you provide your own HMM database follow this format:
        rvdb/rvdb.hmm --> <folder>/<name>.hmm && 'folder' == 'name'
    and provide the database following this command structure
        --rvdb /path/to/your/rvdb

    ${c_yellow}Parameters:${c_reset}
    --evalue            E-value used to filter ViPhOG hits in the ratio_evalue step [default: $params.evalue]
    --prop              Minimum proportion of proteins with ViPhOG annotations to provide a taxonomic assignment [default: $params.prop]
    --taxthres          Minimum proportion of annotated genes required for taxonomic assignment [default: $params.taxthres]
    --virome            VirSorter parameter, set when running a data set mostly composed of viruses [default: $params.virome]
    --hmmextend         Use additional databases for more hmmscan results [default: $params.hmmextend]
    --blastextend       Use additional BLAST database (IMG/VR) for more annotation [default: $params.blastextend]
    --chromomap         WIP feature to activate chromomap plot [default: $params.chromomap]
    --balloon           WIP feature to activate balloon plot [default: $params.balloonp]
    --length            Initial length filter in kb [default: $params.length]
    --sankey            select the x taxa with highest count for sankey plot, try and error and use '-resume' to change plot [default: $params.sankey]
    --chunk             WIP: chunk FASTA files into smaller pieces for parallel calculation [default: $params.chunk]
    --onlyannotate      Only annotate the input FASTA (no virus prediction, only contig length filtering) [default: $params.onlyannotate]
    --mashmap           Map the viral contigs against the provided reference ((fasta/fastq)[.gz]) with mashmap [default: $params.mashmap]
    --mashmap_len       Mashmap mapping segment length, shorter sequences will be ignored [default: $params.mashmap_len]
    --factor            Path to file with viral assemblies metadata, including taxon-specific factors [default: $params.factor]

    ${c_yellow}Developing:${c_reset}
    --viphog_version    define the ViPhOG db version to be used [default: $params.viphog_version]
                        v1: no additional bit score filter (--cut_ga not applied, just e-value filtered)
                        v2: --cut_ga, min score used as sequence-specific GA, 3 bit trimmed for domain-specific GA
                        v3: --cut_ga, like v2 but seq-specific GA trimmed by 3 bits if second best score is 'nan' (current default)
    --meta_version      define the metadata table version to be used [default: $params.meta_version]
                        v1: older version of the meta data table using an outdated NCBI virus taxonomy, for reproducibility 
                        v2: 2020 version of NCBI virus taxonomy
                        v3: 2022 version of NCBI virus taxonomy
                        v4: 2022 version of NCBI virus taxonomy

    ${c_dim}Nextflow options:
    -with-report rep.html    cpu / ram usage (may cause errors)
    -with-dag chart.html     generates a flowchart for the process tree
    -with-timeline time.html timeline (may cause errors)

    ${c_yellow}HPC computing:${c_reset}
    Especially for execution of the workflow on a HPC (LSF, SLURM) adjust the following parameters if needed:
    --databases               defines the path where databases are stored [default: $params.dbs]
    --workdir                 defines the path where nextflow writes tmp files [default: $params.workdir]
    --singularity_cachedir    defines the path where images (singularity) are cached [default: $params.singularity_cachedir] 

    ${c_yellow}Profiles: Execution/Engine:${c_reset}
     VIRify supports profiles to run via different ${c_green}Executers${c_reset} and ${c_blue}Engines${c_reset} e.g.:
         -profile ${c_green}local${c_reset},${c_blue}docker${c_reset} 

      ${c_green}Executer${c_reset} (choose one):
        local
        slurm
        lsf
      ${c_blue}Engines${c_reset} (choose one):
        docker
        singularity
        conda         (not fully supported! Unless you manually install PPR-Meta)

      Or use a ${c_yellow}pre-configured${c_reset} setup instead:
        standard (local,docker) [default]
        ebi (lsf,singularity; preconfigured for the EBI cluster)
        gcloud (use this as template for your own GCP setup)
      ${c_reset}

    """.stripIndent()
}