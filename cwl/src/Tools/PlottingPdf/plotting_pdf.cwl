cwlVersion: v1.2
class: CommandLineTool

label: "Viral contig plotting"

#hints:
#  DockerRequirement:
#    dockerPull: mhoelzer/mapping_viral_predictions:0.1

baseCommand: ['Rscript', 'Make_viral_contig_map.R']

arguments: ["-o", $(inputs.input_table.nameroot)_mapping_results]

inputs:
  input_table:
    type: File
    inputBinding:
      separate: true
      prefix: "-t"

stderr: stderr.txt
stdout: stdout.txt

outputs:
  stdout: stdout
  stderr: stderr

  folder:
    type: Directory
    outputBinding:
      glob: $(inputs.input_table.nameroot)_mapping_results

  #mapping_results:
  #  type:
  #    type: array
  #    items: File
  #  outputBinding:
  #    glob: $(inputs.outdir+"/"+"*.pdf")
