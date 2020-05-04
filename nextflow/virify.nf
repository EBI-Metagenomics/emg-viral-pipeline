#!/usr/bin/env nextflow
nextflow.preview.dsl=2

/*
* Nextflow -- Virus Analysis Pipeline
* Author: hoelzer.martin@gmail.com
*/

/************************** 
* Help messages & user inputs & checks
**************************/

/* Comment section:
First part is a terminal print for additional user information, followed by some help statements (e.g. missing input)
Second part is file channel input. This allows via --list to alter the input of --nano & --illumina to
add csv instead. name,path   or name,pathR1,pathR2 in case of illumina
*/

// terminal prints
println " "
println "\u001B[32mProfile: $workflow.profile\033[0m"
println " "
println "\033[2mCurrent User: $workflow.userName"
println "Nextflow-version: $nextflow.version"
println "Starting time: $nextflow.timestamp"
println "Workdir location:"
println "  $workflow.workDir\u001B[0m"
println " "
if (workflow.profile == 'standard') {
  println "\033[2mCPUs to use: $params.cores"
  println "Output dir name: $params.output\u001B[0m"
  println " "
}
println "\033[2mDev ViPhOG database: $params.version\u001B[0m"
println " "
        
if( !nextflow.version.matches('20.01+') ) {
    println "This workflow requires Nextflow version 20.01 or greater -- You are running version $nextflow.version"
    exit 1
}

if (params.help) { exit 0, helpMSG() }
if (params.profile) {
  exit 1, "--profile is WRONG use -profile" }
if (params.illumina == '' &&  params.fasta == '' ) {
  exit 1, "input missing, use [--illumina] or [--fasta]"}

/************************** 
* INPUT CHANNELS 
**************************/

    // illumina reads input & --list support
        if (params.illumina && params.list) { illumina_input_ch = Channel
                .fromPath( params.illumina, checkIfExists: true )
                .splitCsv()
                .map { row -> ["${row[0]}", [file("${row[1]}"), file("${row[2]}")]] }
                }
        else if (params.illumina) { illumina_input_ch = Channel
                .fromFilePairs( params.illumina , checkIfExists: true )
                }
    
    // direct fasta input w/o assembly support & --list support
        if (params.fasta && params.list) { fasta_input_ch = Channel
                .fromPath( params.fasta, checkIfExists: true )
                .splitCsv()
                .map { row -> ["${row[0]}", file("${row[1]}")] }
                }
        else if (params.fasta) { fasta_input_ch = Channel
                .fromPath( params.fasta, checkIfExists: true)
                .map { file -> tuple(file.simpleName, file) }
                }

/************************** 
* MODULES
**************************/

/* Comment section: */

//db
include pprmetaGet from './modules/pprmeta' 
include metaGetDB from './modules/ratio_evalue'
include virsorterGetDB from './modules/virsorterGetDB' 
include viphogGetDB from './modules/viphogGetDB' 
include ncbiGetDB from './modules/ncbiGetDB' 
include rvdbGetDB from './modules/rvdbGetDB' 
include pvogsGetDB from './modules/pvogsGetDB' 
include vogdbGetDB from './modules/vogdbGetDB' 
include vpfGetDB from './modules/vpfGetDB'
include imgvrGetDB from './modules/imgvrGetDB'
//include './modules/kaijuGetDB' params(cloudProcess: params.cloudProcess, cloudDatabase: params.cloudDatabase)

//preprocessing
include rename from './modules/rename'
include restore from './modules/restore'

//assembly (optional)
include fastp from './modules/fastp'
include fastqc from './modules/fastqc'
include multiqc from './modules/multiqc' 
include spades from './modules/spades' 

//detection
include virsorter from './modules/virsorter' 
include virfinder from './modules/virfinder' 
include pprmeta from './modules/pprmeta'
include length_filtering from './modules/length_filtering' 
include parse from './modules/parse' 
include prodigal from './modules/prodigal'
//include phanotate from './modules/phanotate' 
include hmmscan as hmmscan_viphogs from './modules/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'viphogs', version: params.version)
include hmmscan as hmmscan_rvdb from './modules/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'rvdb', version: params.version)
include hmmscan as hmmscan_pvogs from './modules/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'pvogs', version: params.version)
include hmmscan as hmmscan_vogdb from './modules/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'vogdb', version: params.version)
include hmmscan as hmmscan_vpf from './modules/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'vpf', version: params.version)
include hmm_postprocessing from './modules/hmm_postprocessing'
include ratio_evalue from './modules/ratio_evalue' 
include annotation from './modules/annotation' 
include assign from './modules/assign' 
include blast from './modules/blast' 
include blast_filter from './modules/blast_filter' 

//visuals
include plot_contig_map from './modules/plot_contig_map' 
include generate_krona_table from './modules/krona' 
include generate_sankey_table from './modules/sankey'
include generate_chromomap_table from './modules/chromomap'
include krona from './modules/krona'
include sankey from './modules/sankey'
include chromomap from './modules/chromomap'

//include './modules/kaiju' params(output: params.output, illumina: params.illumina, fasta: params.fasta)
//include './modules/filter_reads' params(output: params.output)


/************************** 
* DATABASES
**************************/

/* Comment section:
The Database Section is designed to "auto-get" pre prepared databases.
It is written for local use and cloud use.*/

workflow download_pprmeta {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { pprmetaGet(); git = pprmetaGet.out }
    // cloud storage via preload.exists()
    if (params.cloudProcess) {
      preload = file("${params.cloudDatabase}/pprmeta")
      if (preload.exists()) { git = preload }
      else  { pprmetaGet(); git = pprmetaGet.out } 
    }
  emit: git
}

workflow download_model_meta {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { metaGetDB(); db = metaGetDB.out }
    // cloud storage via preload.exists()
    if (params.cloudProcess) {
      preload = file("${params.cloudDatabase}/models/Additional_data_vpHMMs.dict")
      if (preload.exists()) { db = preload }
      else  { metaGetDB(); db = metaGetDB.out } 
    }
  emit: db
}

workflow download_virsorter_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { virsorterGetDB(); db = virsorterGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.cloudDatabase}/virsorter/virsorter-data")
      if (db_preload.exists()) { db = db_preload }
      else  { virsorterGetDB(); db = virsorterGetDB.out } 
    }
  emit: db    
}

workflow download_viphog_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { viphogGetDB(); db = viphogGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.cloudDatabase}/vpHMM_database_${params.version}")
      if (db_preload.exists()) { db = db_preload }
      else  { viphogGetDB(); db = viphogGetDB.out } 
    }
  emit: db    
}

workflow download_ncbi_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { ncbiGetDB(); db = ncbiGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.cloudDatabase}/ncbi/ete3_ncbi_tax.sqlite")
      if (db_preload.exists()) { db = db_preload }
      else  { ncbiGetDB(); db = ncbiGetDB.out } 
    }
  emit: db    
}

workflow download_rvdb_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { rvdbGetDB(); db = rvdbGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.cloudDatabase}/rvdb")
      if (db_preload.exists()) { db = db_preload }
      else  { rvdbGetDB(); db = rvdbGetDB.out } 
    }
  emit: db    
}

workflow download_pvogs_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { pvogsGetDB(); db = pvogsGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.cloudDatabase}/pvogs")
      if (db_preload.exists()) { db = db_preload }
      else  { pvogsGetDB(); db = pvogsGetDB.out } 
    }
  emit: db    
}

workflow download_vogdb_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { vogdbGetDB(); db = vogdbGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.cloudDatabase}/vogdb")
      if (db_preload.exists()) { db = db_preload }
      else  { vogdbGetDB(); db = vogdbGetDB.out } 
    }
  emit: db    
}

workflow download_vpf_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { vpfGetDB(); db = vpfGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.cloudDatabase}/vpf")
      if (db_preload.exists()) { db = db_preload }
      else  { vpfGetDB(); db = vpfGetDB.out } 
    }
  emit: db    
}

workflow download_imgvr_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { imgvrGetDB(); db = imgvrGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.cloudDatabase}/imgvr/IMG_VR_2018-07-01_4")
      if (db_preload.exists()) { db = db_preload }
      else  { imgvrGetDB(); db = imgvrGetDB.out } 
    }
  emit: db    
}

/*
workflow download_kaiju_db {
    main:
    // local storage via storeDir
    if (!params.cloudProcess) { kaijuGetDB(); db = kaijuGetDB.out }
    // cloud storage via db_preload.exists()
    if (params.cloudProcess) {
      db_preload = file("${params.cloudDatabase}/kaiju/nr_euk")
      if (db_preload.exists()) { db = db_preload }
      else  { kaijuGetDB(); db = kaijuGetDB.out } 
    }
  emit: db    
}
*/

/************************** 
* SUB WORKFLOWS
**************************/

/* Comment section:
*/
workflow detect {
    take:   assembly
            virsorter_db  
            pprmeta_git  

    main:
        // rename contigs
        rename(assembly)

        // filter contigs by length
        length_filtering(rename.out)

        // virus detection --> VirSorter, VirFinder and PPR-Meta
        virsorter(length_filtering.out, virsorter_db)     
        virfinder(length_filtering.out)
        pprmeta(length_filtering.out, pprmeta_git)

        // parsing predictions
        parse(length_filtering.out.join(virfinder.out).join(virsorter.out).join(pprmeta.out))

        // restore contig names
        restore(parse.out.join(rename.out).transpose())

    emit:
        restore.out
}



/* Comment section:
*/
workflow annotate {
    take:   predicted_contigs
            viphog_db
            ncbi_db
            rvdb_db
            pvogs_db
            vogdb_db
            vpf_db
            imgvr_db
            additional_model_data

    main:
        // ORF detection --> prodigal
        prodigal(predicted_contigs)
        //phanotate(predicted_contigs)

        // annotation --> hmmer
        hmmscan_viphogs(prodigal.out, viphog_db)
        hmm_postprocessing(hmmscan_viphogs.out)

        // calculate hit qual per protein
        ratio_evalue(hmm_postprocessing.out, additional_model_data)

        // annotate contigs based on ViPhOGs
        annotation(ratio_evalue.out)

        // plot visuals --> PDFs
        plot_contig_map(annotation.out)

        // assign lineages
        assign(annotation.out, ncbi_db)

        // blast IMG/VR for more information
        if (params.blastextend) {
          blast(predicted_contigs, imgvr_db)
          blast_filter(blast.out, imgvr_db)
        }

        // hmmer additional databases
        if (params.hmmextend) {
          hmmscan_rvdb(prodigal.out, rvdb_db)
          hmmscan_pvogs(prodigal.out, pvogs_db)
          hmmscan_vogdb(prodigal.out, vogdb_db)
          hmmscan_vpf(prodigal.out, vpf_db)
        }
        
    predicted_contigs_filtered = predicted_contigs.map { id, set_name, fasta -> [set_name, id, fasta] }
    plot_contig_map_filtered = plot_contig_map.out.map { id, set_name, dir, table -> [set_name, table] }
    chromomap_ch = predicted_contigs_filtered.join(plot_contig_map_filtered).map { set_name, assembly_name, fasta, tsv -> [assembly_name, set_name, fasta, tsv]}

    emit:
      assign.out
      chromomap_ch
}


/* Comment section:
*/
workflow plot {
    take:
      assigned_lineages_ch
      annotated_proteins_ch

    main:
        // krona
        combined_assigned_lineages_ch = assigned_lineages_ch.groupTuple().map { tuple(it[0], 'all', it[2]) }.concat(assigned_lineages_ch)
        //combined_assigned_lineages_ch.view()
        krona(
          generate_krona_table(combined_assigned_lineages_ch)
        )

        // sankey
        if (workflow.profile != 'conda') {
          sankey(
            generate_sankey_table(generate_krona_table.out)
         )
        }

        // chromomap
        if (workflow.profile != 'conda' && params.chromomap) {
          combined_annotated_proteins_ch = annotated_proteins_ch.groupTuple().map { tuple(it[0], 'all', it[2], it[3]) }.concat(annotated_proteins_ch)
          chromomap(
            generate_chromomap_table(combined_annotated_proteins_ch)
          )
        }
}


/* Comment section:
Maybe as an pre-step
*/
workflow assemble_illumina {
    take:    reads

    main:
        // trimming --> fastp
        fastp(reads)
 
        // read QC --> fastqc/multiqc
        multiqc(fastqc(fastp.out))

        // assembly with asembler choice --> metaSPAdes
        spades(fastp.out)

    emit:
        spades.out
}


/************************** 
* WORKFLOW ENTRY POINT
**************************/

/* Comment section: */

workflow {

    /**************************************************************/
    // check/ download all databases
    
    if (params.pprmeta) { pprmeta_git = file(params.pprmeta) }
    else { pprmeta_git = download_pprmeta() }

    if (params.meta) { additional_model_data = file(params.meta) }
    else { additional_model_data = download_model_meta() }
    
    if (params.virsorter) { virsorter_db = file(params.virsorter)} 
    else { download_virsorter_db(); virsorter_db = download_virsorter_db.out }

    if (params.viphog) { viphog_db = file(params.viphog)} 
    else {download_viphog_db(); viphog_db = download_viphog_db.out }

    if (params.rvdb) { rvdb_db = file(params.rvdb)} 
    else {download_rvdb_db(); rvdb_db = download_rvdb_db.out }

    if (params.pvogs) { pvogs_db = file(params.pvogs)} 
    else {download_pvogs_db(); pvogs_db = download_pvogs_db.out }

    if (params.vogdb) { vogdb_db = file(params.vogdb)} 
    else {download_vogdb_db(); vogdb_db = download_vogdb_db.out }

    if (params.vpf) { vpf_db = file(params.vpf)} 
    else {download_vpf_db(); vpf_db = download_vpf_db.out }

    if (params.ncbi) { ncbi_db = file(params.ncbi)} 
    else {download_ncbi_db(); ncbi_db = download_ncbi_db.out }

    if (params.imgvr) { imgvr_db = file(params.imgvr)} 
    else {download_imgvr_db(); imgvr_db = download_imgvr_db.out }

    
    //download_kaiju_db()
    //kaiju_db = download_kaiju_db.out
    /**************************************************************/

    // only detection based on an assembly
    if (params.fasta) {
      plot(
        annotate(
          detect(fasta_input_ch, virsorter_db, pprmeta_git), viphog_db, ncbi_db, rvdb_db, pvogs_db, vogdb_db, vpf_db, imgvr_db, additional_model_data)
      )
    } 

    // illumina data to build an assembly first
    if (params.illumina) { 
      assemble_illumina(illumina_input_ch)           
      plot(
        annotate(
          detect(assemble_illumina.out, virsorter_db, pprmeta_git), viphog_db, ncbi_db, rvdb_db, pvogs_db, vogdb_db, vpf_db, imgvr_db, additional_model_data)
      )
    }
}




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
    nextflow run main.nf --fasta 'assembly.fasta' 

    ${c_yellow}Input:${c_reset}
    ${c_green} --illumina ${c_reset}          '*.R{1,2}.fastq.gz'         -> file pairs
    ${c_green} --fasta ${c_reset}             '*.fasta'                   -> one sample per file, no assembly produced
    ${c_dim}  ..change above input to csv:${c_reset} ${c_green}--list ${c_reset}            

    ${c_yellow}Options:${c_reset}
    --cores             max cores for local use [default: $params.cores]
    --memory            max memory for local use [default: $params.memory]
    --output            name of the result folder [default: $params.output]

    ${c_yellow}Databases:${c_reset}
    --virsorter         a virsorter database provided as 'virsorter/virsorter-data' [default: $params.virsorter]
    --viphog            the ViPhOG database, hmmpress'ed [default: $params.viphog]
    --rvdb              the RVDB, hmmpress'ed [default: $params.rvdb]
    --pvogs             the pVOGS, hmmpress'ed [default: $params.pvogs]
    --vogdb             the VOGDB, hmmpress'ed [default: $params.vogdb]
    --vpf               the VPF from IMG/VR, hmmpress'ed [default: $params.vpf]
    --ncbi              a NCBI taxonomy database, from ete3 import NCBITaxa, named ete3_ncbi_tax.sqlite [default: $params.ncbi]
    --imgvr             the IMG/VR, viral (meta)genome sequences [default: $params.imgvr]
    --pprmeta           the PPR-Meta github [default: $params.pprmeta]
    --meta              the XLSX dictionary w/ meta information about ViPhOG models [default: $params.meta]
    Important! If you provide your own hmmer database follow this format:
        rvdb/rvdb.hmm --> <folder>/<name>.hmm && 'folder' == 'name'
    and provide the database following this command structure
        --rvdb /path/to/your/rvdb

    ${c_yellow}Parameters:${c_reset}
    --virome            VirSorter parameter, set when running a data set mostly composed of viruses [default: $params.virome]
    --hmmextend         Use additional databases for more hmmscan results [default: $params.hmmextend]
    --blastextend       Use additional BLAST database (IMG/VR) for more annotation [default: $params.blastextend]
    --chromomap         WIP feature [default: $params.chromomap]
    --length            Initial length filter in kb [default: $params.length]
    --sankey            select the x taxa with highest count for sankey plot, try and error to change plot [default: $params.sankey]
    --chunk             WIP: chunk FASTA files into smaller pieces for parallel calculation [default: $params.chunk]

    ${c_yellow}Developing:${c_reset}
    --version         define the ViPhOG db version to be used [default: $params.version]
                      v1: no additional bit score filter (--cut_ga not applied, just e-value filtered)
                      v2: --cut_ga, min score used as sequence-specific GA, 3 bit trimmed for domain-specific GA
                      v3: --cut_ga, like v2 but seq-specific GA trimmed by 3 bits if second best score is 'nan'

    ${c_dim}Nextflow options:
    -with-report rep.html    cpu / ram usage (may cause errors)
    -with-dag chart.html     generates a flowchart for the process tree
    -with-timeline time.html timeline (may cause errors)

    ${c_yellow}LSF computing:${c_reset}
    For execution of the workflow on a HPC with LSF adjust the following parameters:
    --databases         defines the path where databases are stored [default: $params.cloudDatabase]
    --workdir           defines the path where nextflow writes tmp files [default: $params.workdir]
    --cachedir          defines the path where images (singularity) are cached [default: $params.cachedir] 

    ${c_yellow}Profile:${c_reset}
    -profile                 standard (local, pure docker) [default]
                             conda
                             lsf (HPC w/ LSF, singularity/docker)
                             slurm (HPC w/ SLURM, singularity/docker)
                             ebi (HPC w/ LSF, singularity/docker, preconfigured for the EBI cluster)
                             ebi_cloud (HPC w/ LSF, conda, preconfigured for the EBI cluster)
                             yoda_cloud (HPC w/ LSF, conda, preconfigured for the EBI YODA cluster)
                             gcloudMartin (googlegenomics and docker, use this as template for your own GCP)
                             ${c_reset}

    """.stripIndent()
}