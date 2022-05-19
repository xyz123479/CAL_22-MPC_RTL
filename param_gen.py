#!/usr/bin/env python
# coding: utf-8

# In[1]:


import json
from math import log2
import numpy as np

from collections import OrderedDict

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-c", "--config", required=True, type=str,
        help="The input config path")
parser.add_argument("-m", "--module", required=True, type=int,
        help="The number of module that want to be printed")
parser.add_argument("-d", "--decomp", required=False, type=bool, default=False,
        help="Want the decompressor to be printed?")
args = parser.parse_args()


def gen_parameters(cfg, num_module, is_comp):
    def make_tree(root_idx, base_table, weight_table, linesize):
        # construct a target idx tree with cfg level by level
        markerTable = np.zeros_like(base_table, dtype=int)
        markerTable[root_idx] = 1

        target_idx_table = OrderedDict()
        target_idx_table[-1] = [root_idx]

        level = 0
        while(not(markerTable == 1).all()):
            target_idx_table[level] = []
            for target_idx in range(len(base_table)):
                if markerTable[target_idx] == 1:
                    continue
                base_idx = base_table[target_idx]
                if base_idx in target_idx_table[level - 1]:
                    target_idx_table[level].append(target_idx)
                    markerTable[target_idx] = 1
            level += 1
            assert(level <= linesize)

        len_level = []
        for level in target_idx_table.keys():
            if level == -1:
                continue
            len_level.append(len(target_idx_table[level]))
        return level, len_level, target_idx_table

    module = cfg['modules'][str(num_module)]

    predictor = module['submodules']['ResidueModule']['PredictorModule']
    linesize = predictor['LineSize']
    root_idx = predictor['RootIndex']
    base_table = predictor['BaseIndexTable']
    weight_table = predictor['WeightTable']
    level, len_level, target_idx_table = make_tree(root_idx, base_table, weight_table, linesize)
    
#     for level in target_idx_table:
#         print(level, end='\t:')
#         print(target_idx_table[level])
    level += 1
    level_start = [0]
    for i in range(len(len_level)):
        start_accum = 0
        for ii in range(i+1):
            start_accum += len_level[ii]
        level_start.append(start_accum)
    len_level.extend([0] * (32 - len(len_level)))
    level_start.extend([0] * (32 - len(level_start)))
    tgt_idx_table = []
    for lvl in target_idx_table:
        if lvl == -1:
            continue
        for tgt_idx in target_idx_table[lvl]:
            tgt_idx_table.append(tgt_idx)
    tgt_idx_table.append(0)

    scanModule = module['submodules']['ScanModule']
    tableSize = scanModule['TableSize']
    rows = scanModule['Rows']
    cols = scanModule['Cols']

    if (is_comp):
        print_comp(root_idx, base_table, weight_table, rows, cols)
    else:
        print_decomp(root_idx, level, len_level, level_start, tgt_idx_table, base_table, weight_table, rows, cols)
    
    
def print_comp(root_idx, base_table, weight_table, rows, cols):
    # root idx
    print(".ROOT_IDX\t\t(8'd%d)," %(root_idx))
    
    # base idx
    print(".BASE_IDX\t\t({")
    for i, base in enumerate(base_table):
        if (i % 8 == 0):
            print('\t', end='')
        p = i if base == -1 else base
        if (i % 32 == 31):
            print(" 8'd%02d" %(p))
            print('}),')
        elif (i % 8 == 7):
            print(" 8'd%02d," %(p))
        else:
            print(" 8'd%02d," %(p), end='')

    # shift val
    print(".SHIFT_VAL\t\t({")
    for i, weight in enumerate(weight_table):
        if weight != 0:
            shift = log2(weight)
        else:
            shift = 0
            
        if (i % 8 == 0):
            print('\t', end='')
        if shift >= 0:
            if (i % 32 == 31):
                print("  8'd%1d" %(shift))
                print("}),")
            elif (i % 8 == 7):
                print("  8'd%1d," %(shift))
            else:
                print("  8'd%1d," %(shift), end='')
        else:
            if (i % 32 == 31):
                print(" -8'd%1d" %(-shift))
                print("}),")
            elif (i % 8 == 7):
                print(" -8'd%1d," %(-shift))
            else:
                print(" -8'd%1d," %(-shift), end='')
    
    # rows
    print('.SCAN_ROW\t\t({')
    for i, row in enumerate(rows):
        if (i % 8 == 0):
            print('\t', end='')
        if (i % 256 == 255):
            print(" 8'd%1d" %(row))
            print("}),")
        elif (i % 8 == 7):
            print(" 8'd%1d," %(row))
        else:
            print(" 8'd%1d," %(row), end='')
    
    # cols
    print('.SCAN_COL\t\t({')
    for i, col in enumerate(cols):
        if (i % 8 == 0):
            print('\t', end='')
        if (i % 256 == 255):
            print(" 8'd%02d" %(col))
            print("})")
        elif (i % 8 == 7):
            print(" 8'd%02d," %(col))
        else:
            print(" 8'd%02d," %(col), end='')
    
def print_decomp(root_idx, level, len_level, level_start, target_idx, base_table, weight_table, rows, cols):
    # rows
    print('.SCAN_ROW\t\t({')
    for i, row in enumerate(rows):
        if (i % 8 == 0):
            print('\t', end='')
        if (i % 256 == 255):
            print(" 8'd%1d" %(row))
            print("}),")
        elif (i % 8 == 7):
            print(" 8'd%1d," %(row))
        else:
            print(" 8'd%1d," %(row), end='')
    
    # cols
    print('.SCAN_COL\t\t({')
    for i, col in enumerate(cols):
        if (i % 8 == 0):
            print('\t', end='')
        if (i % 256 == 255):
            print(" 8'd%02d" %(col))
            print("})")
        elif (i % 8 == 7):
            print(" 8'd%02d," %(col))
        else:
            print(" 8'd%02d," %(col), end='')
    
    print()
    print()
    
    # root idx
    print(".ROOT_IDX\t\t(8'd%d)," %(root_idx))
    
    # level
    print(".LEVEL   \t\t(8'd%d)," %(level))
    
    # len level
    print(".LEN_LEVEL\t\t({")
    for i, length in enumerate(len_level):
        if (i % 8 == 0):
            print('\t', end='')
        if (i % 32 == 31):
            print(" 8'd%02d" %(length))
            print('}),')
        elif (i % 8 == 7):
            print(" 8'd%02d," %(length))
        else:
            print(" 8'd%02d," %(length), end='')
            
    # level_start
    print('.LEVEL_START\t\t({')
    for i, start_idx in enumerate(level_start):
        if (i % 8 == 0):
            print('\t', end='')
        if (i % 32 == 31):
            print(" 8'd%02d" %(start_idx))
            print('}),')
        elif (i % 8 == 7):
            print(" 8'd%02d," %(start_idx))            
        else:
            print(" 8'd%02d," %(start_idx), end='')
            
    # target idx
    print('.TARGET_IDX\t\t({')
    for i, target in enumerate(target_idx):
        if (i % 8 == 0):
            print('\t', end='')
        if (i % 32 == 31):
            print(" 8'd%02d" %(target))
            print('}),')
        elif (i % 8 == 7):
            print(" 8'd%02d," %(target))
        else:
            print(" 8'd%02d," %(target), end='')
    
    # base idx
    print(".BASE_IDX\t\t({")
    for i, base in enumerate(base_table):
        if (i % 8 == 0):
            print('\t', end='')
        p = i if base == -1 else base
        if (i % 32 == 31):
            print(" 8'd%02d" %(p))
            print('}),')
        elif (i % 8 == 7):
            print(" 8'd%02d," %(p))
        else:
            print(" 8'd%02d," %(p), end='')
                
    # shift val
    print(".SHIFT_VAL\t\t({")
    for i, weight in enumerate(weight_table):
        if weight != 0:
            shift = log2(weight)
        else:
            shift = 0
            
        if (i % 8 == 0):
            print('\t', end='')
        if shift >= 0:
            if (i % 32 == 31):
                print("  8'd%1d" %(shift))
                print("})")
            elif (i % 8 == 7):
                print("  8'd%1d," %(shift))
            else:
                print("  8'd%1d," %(shift), end='')
        else:
            if (i % 32 == 31):
                print(" -8'd%1d" %(-shift))
                print("}),")
            elif (i % 8 == 7):
                print(" -8'd%1d," %(-shift))
            else:
                print(" -8'd%1d," %(-shift), end='')
    

def main(args):
    num_module = args.module
    is_comp = not args.decomp
    cfg_path = args.config

    with open(cfg_path, 'r') as f:
        cfg = json.load(f)

    gen_parameters(cfg, num_module, is_comp)

if __name__ == "__main__":
    main(args)

