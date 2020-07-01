#!/usr/bin/env python3

# The script downloads and uncompresses the ete3 file from EBI's ftp site 
# if the uncompressed file is not present in the working directory. 
# Then it updates the file using the most up-to-date taxonomy file from NCBI

import sys, subprocess, os
from urllib.request import urlretrieve
from ete3 import NCBITaxa

if not os.path.exists('ete3_ncbi_tax.sqlite'):
    ete3_tax_file = 'ete3_ncbi_tax.sqlite.gz'
    print('Downloading ete3_ncbi_tax.sqlite.gz from EBI ftp site (via HTTP)...', file=sys.stderr)
    urlretrieve('http://ftp.ebi.ac.uk/pub/databases/metagenomics/viral-pipeline/ete3_ncbi_tax.sqlite.gz', ete3_tax_file)
    print('Done, uncompressing...', file=sys.stderr)
    command_list = ['gunzip', '-f', ete3_tax_file]
    subprocess.run(command_list)
    print('Done', file=sys.stderr)
    
else:
    print('ete3_ncbi_tax.sqlite is present in current working directory')

ncbi = NCBITaxa(dbfile = 'ete3_ncbi_tax.sqlite')
ncbi.update_taxonomy_database()

