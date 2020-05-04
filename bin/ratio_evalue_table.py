#!/usr/bin/env python3.7

import os
import re
import decimal
import sys
import argparse
import pickle

import pandas as pd


def ratio_evalue(vphmm_df, taxa_dict):
    """This function takes a dataframe containing the result of the comparison
       between predicted viral proteins and the ViPhOG database, and outputs a
       table storing the profile hit length ratio and total sequence Evalue for
       each profile-protein hit"""
    # Keep only informative hits to ViPhOG database and those whose i-Evalue is <= 0.01
    informative_df = vphmm_df[(vphmm_df["target name"].isin(
        taxa_dict.keys())) & (vphmm_df["i-Evalue"] <= 0.01)]
    if len(informative_df) < 1:
        return "non informative"
    else:
        informative_df = informative_df.reset_index(drop=True)
        vphmm_hits = list(informative_df["target name"].value_counts().index)
        final_hit_list = []
        for vphmm in vphmm_hits:
            vphmm_specific_df = informative_df[informative_df["target name"] == vphmm]
            vphmm_specific_df = vphmm_specific_df.reset_index(drop=True)
            more_than_one = list(vphmm_specific_df["query name"].value_counts()[
                                 vphmm_specific_df["query name"].value_counts() > 1].index)
            query_list = []
            for i in range(len(vphmm_specific_df)):
                if vphmm_specific_df["query name"][i] not in query_list:
                    query_list.append(vphmm_specific_df["query name"][i])
                    if vphmm_specific_df["query name"][i] in more_than_one:
                        number = vphmm_specific_df["query name"].value_counts()[
                            vphmm_specific_df["query name"][i]]
                        coords_list = sorted([(vphmm_specific_df["hmm coord from"][i + j],
                                               vphmm_specific_df["hmm coord to"][i + j]) for j in range(number)])
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
                            [final - initial + 1 for initial, final in final_coords_list])
                        hmm_ratio = total_hmm_align / \
                            vphmm_specific_df["tlen"][i]
                    else:
                        hmm_ratio = (vphmm_specific_df["hmm coord to"][i] -
                                     vphmm_specific_df["hmm coord from"][i] + 1)/vphmm_specific_df["tlen"][i]
                    final_hit_list.append((vphmm, vphmm_specific_df["query name"][i], hmm_ratio, abs(int(
                        ("%E" % decimal.Decimal(vphmm_specific_df["full sequence E-value"][i])).split("E")[-1]))))
        final_df = pd.DataFrame(final_hit_list, columns=[
                                "ViPhOG", "query", "Ratio", "Abs_Evalue_exp"])
        final_df["Abs_Evalue_exp"] = final_df["Abs_Evalue_exp"].apply(
            lambda x: 277 if x == 0 else x)
        final_df["Taxon"] = final_df["ViPhOG"].apply(lambda x: taxa_dict[x])
        return final_df


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate dataframe that stores the profile alignment ratio and total e-value for each ViPhOG-query pair")
    parser.add_argument("-i", "--input", dest="input_file",
                        help="domtbl generated with Generate_vphmm_hmmer_matrix.py", required=True)
    parser.add_argument("-t", "--taxa", dest="taxa_dict",
                        help="Pickle serialized dict (taxa_dict) obtained with generate_vphmm_object.py", required=True)
    parser.add_argument("-o", "--outdir", dest="outdir",
                        help="Directory where you want output table to be stored (default: cwd)", default=".")
    if len(sys.argv) == 1:
        parser.print_help()
    else:
        args = parser.parse_args()
        input_file = args.input_file
        output_file = os.path.join(args.outdir, re.split(
            r"\.[a-z]+$", os.path.basename(input_file))[0] + "_informative.tsv")
        input_df = pd.read_csv(input_file, sep="\t")

        taxa_dict = {}
        with open(args.taxa_dict, "rb") as taxa_file:
            taxa_dict = pickle.load(taxa_file)

        output_df = ratio_evalue(input_df, taxa_dict)
        if isinstance(output_df, str):
            print("No informative hits against the ViPhOG database were obtained for the contigs provided")
        else:
            output_df.to_csv(output_file, sep="\t", index=False)