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
