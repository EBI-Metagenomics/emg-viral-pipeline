#!/bin/env python

import unittest

from bin.generate_counts_table import clean

ranks = ["superkingdom", "kingdom", "phylum", "subphylum", "class", "order", "suborder", "family", "subfamily", 
                 "genus"]

class GenerateCountTable(unittest.TestCase):

    def test_incomplete_lineage(self):
        inp = "Punalikevirus		Myoviridae	Caudovirales"
        exp = ("Punalikevirus", "undefined_family_Punalikevirus", "Myoviridae", "Caudovirales")
        self.assertEqual(clean(inp.split("\t"), ranks[-4:]), exp)

        inp_sec = "Bppunalikevirus	0.3333333333333333	Podoviridae	Caudovirales"
        exp_sec = ("Bppunalikevirus", "undefined_kingdom_Bppunalikevirus",
                   "Podoviridae", "Caudovirales")
        self.assertEqual(clean(inp_sec.split("\t"), ranks), exp_sec)

    def test_head_and_tail(self):
        inp = "0.3333333333333333	Chordopoxvirinae	Poxviridae	0.3333333333333333"
        exp = ("undefined_suborder", "Chordopoxvirinae", "Poxviridae")
        self.assertEqual(clean(inp.split("\t"), ranks[-4:]), exp)
        
    def test_tail(self):
        inp = "0.3333333333333333	Chordopoxvirinae	Poxviridae	0.3333333333333333	0.3333333333333333"
        exp = ("undefined_order", "Chordopoxvirinae", "Poxviridae")
        self.assertEqual(clean(inp.split("\t"), ranks[-5:]), exp)
        
    def test_order_unclassified(self):
        inp = ("Microvirus", "", "Microviridae", "")
        exp = ("Microvirus", "undefined_family_Microvirus", "Microviridae")
        self.assertEqual(clean(inp, ranks[-4:]), exp)

    def test_all_unclassified(self):
        inp = "				"
        exp = ("undefined",)
        self.assertEqual(clean(inp.split("\t"), ranks[-4:]), exp)

        inp_t = "0.2	0.4	0.4	0.4"
        self.assertEqual(clean(inp_t.split("\t"), ranks[-5:]), exp)


if __name__ == '__main__':
    unittest.main()
