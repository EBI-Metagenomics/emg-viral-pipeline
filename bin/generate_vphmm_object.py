#!/usr/bin/env python3.7

import argparse
import pandas as pd
import pickle


def main(xls, output):
    """Read the xlsx file and save a pickle serialized object for ratio_evalue.cwl.
    """
    excel_file = pd.ExcelFile(xls)
    excel_df = excel_file.parse("Sheet1")
    excel_df["Number"] = excel_df["Number"].apply(
        lambda x: "ViPhOG" + str(x) + ".faa")
    taxa_dict = {}
    for i in range(len(excel_df)):
        taxa_dict[excel_df["Number"][i]] = excel_df["Associated"][i]
    with open(output, 'wb') as output_file:
        pickle.dump(taxa_dict, file=output_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Convert the vpHMMS xls file into a pickle object")
    parser.add_argument("-x", "--xlsx", help=".xlsx file", required=True)
    parser.add_argument("-o", "--out", help="Output file", required=True)
    args = parser.parse_args()
    main(args.xlsx, args.out)