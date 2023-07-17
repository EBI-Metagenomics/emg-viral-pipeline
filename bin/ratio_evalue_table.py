#!/usr/bin/env python3

import os
import argparse
from pathlib import Path

import pandas as pd


def ratio_evalue(vphmm_df, taxa_dict, evalue):
    """This function takes a dataframe containing the result of the comparison
       between predicted viral proteins and the ViPhOG database, and outputs a
       table storing the profile hit length ratio and total sequence Evalue for
       each profile-protein hit
    """

    # Keep only informative hits to ViPhOG database and those whose i-Evalue
    # is <= 0.01 (default)

    informative_df = vphmm_df[
        (vphmm_df["target name"].isin(taxa_dict.keys())) &
        (vphmm_df["i-Evalue"] <= evalue)
    ]

    if len(informative_df) < 1:
        return None

    informative_df = informative_df.reset_index(drop=True)
    vphmm_hits = list(informative_df["target name"].value_counts().index)
    final_hit_list = []

    for vphmm in vphmm_hits:
        vphmm_specific_df = informative_df[informative_df["target name"] == vphmm] \
            .reset_index(drop=True)
        query_vcounts = vphmm_specific_df["query name"].value_counts()
        more_than_one = list(query_vcounts[query_vcounts > 1].index)

        query_list = []

        for i in range(len(vphmm_specific_df)):

            query_name = vphmm_specific_df["query name"][i]
            coord_to = vphmm_specific_df["hmm coord to"][i]
            coord_from = vphmm_specific_df["hmm coord from"][i]
            t_len = vphmm_specific_df["tlen"][i]

            if query_name in query_list:
                continue

            query_list.append(query_name)

            if query_name in more_than_one:
                number = query_vcounts[query_name]
                coords_list = sorted([(
                    vphmm_specific_df["hmm coord from"][i + j],
                    vphmm_specific_df["hmm coord to"][i + j]) for j in range(number)
                ])
                reference_pair = list(coords_list[0])

                final_coords_list = []
                for elem in range(1, len(coords_list)):
                    if coords_list[elem][0] <= reference_pair[1]:
                        reference_pair[1] = max(
                            reference_pair[1], coords_list[elem][1])
                    else:
                        final_coords_list.append(tuple(reference_pair))
                        reference_pair[0] = coords_list[elem][0]
                        reference_pair[1] = coords_list[elem][1]

                final_coords_list.append(tuple(reference_pair))
                total_hmm_align = sum(
                    [final - initial + 1 for initial, final in final_coords_list]
                )
                hmm_ratio = total_hmm_align / t_len
            else:
                hmm_ratio = (coord_to - coord_from + 1) / t_len

            fs_e_value = float(vphmm_specific_df["full sequence E-value"][i])
            e_value_exponential = abs(int(("%E" % fs_e_value).split("E")[-1]))

            final_hit_list.append((
                vphmm,
                vphmm_specific_df["query name"][i],
                hmm_ratio,
                e_value_exponential
            ))

        final_df = pd.DataFrame(final_hit_list, columns=[
                                "ViPhOG", "query", "Ratio", "Abs_Evalue_exp"])

        # TODO: explain
        final_df["Abs_Evalue_exp"] = final_df["Abs_Evalue_exp"].apply(
            lambda x: 277 if x == 0 else x
        )

        final_df["Taxon"] = final_df["ViPhOG"].apply(lambda x: taxa_dict[x])

    return final_df


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate dataframe that stores the profile alignment ratio "
                    " and total e-value for each ViPhOG-query pair")
    parser.add_argument("-i", "--input", dest="input_file",
                        help="domtbl generated with Generate_vphmm_hmmer_matrix.py",
                        required=True)
    parser.add_argument("-t", "--taxa", dest="taxa_tsv",
                        help="TSV file: additional_data_vpHMMs_v{1,2,3,4}.tsv", required=True)
    parser.add_argument("-o", "--outfile", dest="out_file",
                        help="Output table name (default: cwd)",
                        default=".")
    parser.add_argument("-e", "--evalue", dest="evalue",
                        help="E-value cutoff for each HMM hit",
                        default=0.01)
    args = parser.parse_args()

    input_file = args.input_file
    output_file = args.out_file
    evalue = args.evalue

    input_df = pd.read_csv(input_file, sep="\t")

    taxa_dict = {}

    tsv_df = pd.read_csv(args.taxa_tsv, sep="\t")

    for i in range(len(tsv_df)):
        taxa_dict["ViPhOG" + str(tsv_df["Number"][i]) + ".faa"] = tsv_df["Associated"][i]

    output_df = ratio_evalue(input_df, taxa_dict, float(evalue))

    if output_df is None or output_df.empty:
        print("No informative hits against the ViPhOG database "
              "were obtained for the contigs provided")
    else:
        with open(output_file, "w") as of_handle:
            output_df.to_csv(of_handle, sep="\t", index=False)
