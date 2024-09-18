#!/usr/bin/env nextflow

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
println "  $workflow.workDir"
println "Databases location:"
println "  $params.databases\u001B[0m"
println " "
if (workflow.profile == 'standard') {
  println "\033[2mCPUs to use: $params.cores"
  println "Output dir name: $params.output\u001B[0m"
  println " "
}
println "\033[2mDev ViPhOG database: $params.viphog_version\u001B[0m"
println "\033[2mDev Meta database: $params.meta_version\u001B[0m"
println " "
println "\033[2mOnly run annotation: $params.onlyannotate\u001B[0m"
println " "

if (params.help) { exit 0, helpMSG() }
if (params.profile) {
  exit 1, "--profile is WRONG use -profile" }
if (params.illumina == '' &&  params.fasta == '' ) {
  exit 1, "input missing, use [--illumina] or [--fasta]"}

if (params.meta_version == "v4") { printMetadataV4Warning() }

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

    // mashmap input
        if (params.mashmap) { mashmap_ref_ch = Channel
                .fromPath( params.mashmap, checkIfExists: true)
              }
              
    // factor file input
        if (params.factor) { factor_file = file( params.factor, checkIfExists: true) }


/************************** 
* MODULES
**************************/

/* Comment section: */

//db
include {pprmetaGet} from 'modules/pprmeta' 
include {metaGetDB} from 'modules/metaGetDB'
include {virsorterGetDB} from 'modules/virsorterGetDB' 
include {viphogGetDB} from 'modules/viphogGetDB' 
include {ncbiGetDB} from 'modules/ncbiGetDB' 
include {rvdbGetDB} from 'modules/rvdbGetDB' 
include {pvogsGetDB} from 'modules/pvogsGetDB' 
include {vogdbGetDB} from 'modules/vogdbGetDB' 
include {vpfGetDB} from 'modules/vpfGetDB'
include {imgvrGetDB} from 'modules/imgvrGetDB'
include {checkvGetDB} from 'modules/checkvGetDB'
//include './modules/kaijuGetDB' params(cloudProcess: params.cloudProcess, databases: params.databases)

//preprocessing
include { rename} from 'modules/rename'
include { restore} from 'modules/restore'

//assembly (optional)
include { fastp} from 'modules/fastp'
include { fastqc} from 'modules/fastqc'
include { multiqc} from 'modules/multiqc' 
include { spades} from 'modules/spades' 

//detection
include { virsorter} from 'modules/virsorter' 
include { virfinder; virfinderGetDB} from 'modules/virfinder' 
include { pprmeta} from 'modules/pprmeta'
include { length_filtering} from 'modules/length_filtering' 
include { parse} from 'modules/parse' 
include { prodigal} from 'modules/prodigal'
include { hmmscan as hmmscan_viphogs} from 'modules/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'viphogs', version: params.viphog_version)
include { hmmscan as hmmscan_rvdb} from 'modules/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'rvdb', version: params.viphog_version)
include { hmmscan as hmmscan_pvogs} from 'modules/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'pvogs', version: params.viphog_version)
include { hmmscan as hmmscan_vogdb} from 'modules/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'vogdb', version: params.viphog_version)
include { hmmscan as hmmscan_vpf} from 'modules/hmmscan' params(output: params.output, hmmerdir: params.hmmerdir, db: 'vpf', version: params.viphog_version)
include { hmm_postprocessing} from 'modules/hmm_postprocessing'
include { ratio_evalue} from 'modules/ratio_evalue' 
include { annotation} from 'modules/annotation' 
include { assign} from 'modules/assign' 
include { blast} from 'modules/blast' 
include { blast_filter} from 'modules/blast_filter'
include { mashmap} from 'modules/mashmap'

//visuals
include { plot_contig_map} from 'modules/plot_contig_map' 
include { generate_krona_table} from 'modules/krona' 
include { generate_sankey_table} from 'modules/sankey'
include { generate_chromomap_table} from 'modules/chromomap'
include { krona} from 'modules/krona'
include { sankey} from 'modules/sankey'
include { chromomap} from 'modules/chromomap'
include { balloon} from 'modules/balloon'

/************************** 
* SUB WORKFLOWS
**************************/

include { PREPROCESS } from '../subworkflows/preprocess'

/* Comment section:
Plot results. Basically runs krona and sankey. ChromoMap and Balloon are still experimental features and should be used with caution. 
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

        // balloon plot
        if (params.balloon) {
          balloon(combined_assigned_lineages_ch)
        }
}


/* Comment section:
Optional assembly step, not fully implemented and tested. 
*/
workflow assemble_illumina {
    take:    reads

    main:
        // trimming
        fastp(reads)
 
        // read QC
        multiqc(fastqc(fastp.out))

        // assembly
        spades(fastp.out)

    emit:
        spades.out
}


/************************** 
* WORKFLOW ENTRY POINT
**************************/

/* Comment section: 
Here the main workflow starts and runs the defined sub workflows. 
*/

workflow {

    /**************************************************************/
    // check/ download all databases
    
    if (params.pprmeta) { pprmeta_git = file(params.pprmeta) }
    else { pprmeta_git = download_pprmeta() }
    
    if (params.virsorter) { virsorter_db = file(params.virsorter)} 
    else { download_virsorter_db(); virsorter_db = download_virsorter_db.out }

    if (params.virfinder) { virfinder_db = file(params.virfinder)} 
    else { download_virfinder_db(); virfinder_db = download_virfinder_db.out }

    if (params.meta) { additional_model_data = file(params.meta) }
    else { additional_model_data = download_model_meta() }

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

    if (params.checkv) { checkv_db = file(params.checkv)} 
    else {download_checkv_db(); checkv_db = download_checkv_db.out }

    //download_kaiju_db()
    //kaiju_db = download_kaiju_db.out
    /**************************************************************/

    PREPROCESS( fasta_input_ch )

    POSTPROCESS(
      PREPROCESS.out.map { name, renamed_fasta, map, filtered_fasta, contig_number -> tuple(name, filtered_fasta, map )}
    )

    ANNOTATE(
        fasta_input_ch,
        viphog_db,
        ncbi_db,
        rvdb_db,
        pvogs_db,
        vogdb_db,
        vpf_db,
        imgvr_db,
        additional_model_data,
        checkv_db,
        factor_file
    )

    // Post process
    restore( fasta )
  

    // only detection based on an assembly
    if (params.fasta) {
      
      // only annotate the FASTA
      if (params.onlyannotate) {
        
        plot(
        )
      } else {
          preprocess(fasta_input_ch)
          plot(
            annotate(
              fasta_input_ch,
              postprocess(
                  detect(
                      preprocess.out,
                      virsorter_db, virfinder_db, pprmeta_git
                  )
              ), 
              viphog_db, ncbi_db, rvdb_db, pvogs_db, vogdb_db, vpf_db, imgvr_db, additional_model_data, checkv_db, factor_file
          )
        )
      }
    } 

    // illumina data to build an assembly first
    if (params.illumina) { 
      assemble_illumina(illumina_input_ch)
      preprocess(assemble_illumina.out) 
      plot(
        annotate(
          assemble_illumina.out,
          postprocess(detect(preprocess.out, virsorter_db, virfinder_db, pprmeta_git)), 
          viphog_db, ncbi_db, rvdb_db, pvogs_db, vogdb_db, vpf_db, imgvr_db, additional_model_data, checkv_db)
      )
    }
}

def printMetadataV4Warning() {
    c_yellow = "\033[0;33m";
    c_reset = "\033[0m";

    println """
    ${c_yellow}Warning: --meta_version v4 does not include the following discontinued virus taxa 
    (according to ICTV) anymore and they have been excluded from the dataset.${c_reset}
    - Allolevivirus
    - Autographivirinae
    - Buttersvirus
    - Caudovirales
    - Chungbukvirus
    - Incheonvirus
    - Leviviridae
    - Levivirus
    - Mandarivirus
    - Pbi1virus
    - Phicbkvirus
    - Radnorvirus
    - Sitaravirus
    - Vidavervirus
    - Myoviridae
    - Siphoviridae
    - Podoviridae
    - Viunavirus
    - Orthohepevirus
    - Klosneuvirus
    - Hendrixvirus
    - Rubulavirus
    - Avulavirus
    - Catovirus
    - Nucleorhabdovirus
    - Viunavirus
    - Gammalipothrixvirus
    - Peduovirinae
    - Sedoreovirinae
    """.stripIndent()
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
    nextflow run virify.nf --fasta 'assembly.fasta' 

    ${c_yellow}Input:${c_reset}
    ${c_green} --fasta ${c_reset}             '*.fasta'                   -> one sample per file, no assembly produced
    ${c_green} --illumina ${c_reset}          '*.R{1,2}.fastq.gz'         -> file pairs, experimental feature that performs SPAdes assembly first
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
