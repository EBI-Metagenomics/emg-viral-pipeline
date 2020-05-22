#!/bin/env python

import unittest

from bin.generate_counts_table import _clean


class GenerateCountTable(unittest.TestCase):

    def test_collapse_tail_unclassified(self):
        inp_one = "0.3333333333333333	0.3333333333333333	0.3333333333333333	Caudovirales"
        exp_one = ("Caudovirales",)
        self.assertEqual(_clean(inp_one.split("\t")), exp_one)

        inp_sec = "0.3333333333333333	0.3333333333333333	Myoviridae	Caudovirales"
        exp_sec = ("Caudovirales", "Myoviridae")
        self.assertEqual(_clean(inp_sec.split("\t")), exp_sec)

        inp_t = "0.3333333333333333		0.3333333333333333	Caudovirales"
        exp_t = ("Caudovirales",)
        self.assertEqual(_clean(inp_t.split("\t")), exp_t)

        inp_f = "	Chordopoxvirinae	Poxviridae	"
        exp_f = ("unclassified", "Poxviridae", "Chordopoxvirinae")
        self.assertEqual(_clean(inp_f.split("\t")), exp_f)

    def test_incomplete_lineage(self):
        inp = "Punalikevirus		Myoviridae	Caudovirales"
        exp = ("Caudovirales", "Myoviridae", "unclassified", "Punalikevirus")
        self.assertEqual(_clean(inp.split("\t")), exp)

        inp_sec = "Bppunalikevirus	0.3333333333333333	Podoviridae	Caudovirales"
        exp_sec = ("Caudovirales", "Podoviridae",
                   "unclassified", "Bppunalikevirus")
        self.assertEqual(_clean(inp_sec.split("\t")), exp_sec)

    def test_head_and_tail(self):
        inp = "0.3333333333333333	Chordopoxvirinae	Poxviridae	0.3333333333333333"
        exp = ("unclassified", "Poxviridae", "Chordopoxvirinae")
        self.assertEqual(_clean(inp.split("\t")), exp)

    def test_order_unclassified(self):
        inp = ("Microvirus", "", "Microviridae", "")
        exp = ("unclassified", "Microviridae", "unclassified", "Microvirus")
        self.assertEqual(_clean(inp), exp)

    def test_all_unclassified(self):
        inp = "				"
        exp = ("unclassified",)
        self.assertEqual(_clean(inp.split("\t")), exp)

        inp_t = "0.2	0.4	0.4	0.4"
        self.assertEqual(_clean(inp_t.split("\t")), exp)


if __name__ == '__main__':
    unittest.main()
