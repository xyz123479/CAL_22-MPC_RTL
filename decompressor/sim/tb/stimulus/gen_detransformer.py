#!/usr/bin/env python
# coding: utf-8

import os, sys
from copy import deepcopy

import numpy as np

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-l", "--link", type=str, required=False,
        default="/home/jin8495/projects/vpc/v1_dataType/IEEE_CompArchiLetters/python",
        help="The link path of python compressor model")
parser.add_argument("input-dataset", type=str, required=True,
        help="The input dataset path")
parser.add_argument("input-config", type=str, required=True,
        help="The input json config path")
parser.add_argument("output-dir", type=str, required=True,
        help="The output directory path")
args = parser.parse_args()

linkpath = args.link
dataset_path = args.input_dataset
config_path = args.input_config
output_dir = args.output_dir

p = os.path.abspath(linkpath)
sys.path.insert(1, p)

from src.compressor import *
from src.decompressor import *

# dataset
dataset = np.load(dataset_path).astype(np.uint8)
rand_dataset = dataset[np.random.choice(len(dataset), size=10000)]
rand_dataset = np.concatenate([rand_dataset,
                              [[0] * 32],
                              [[0,1,2,3] * 8]]).astype(np.uint8)

# compressor / decompressor
compressor = Compressor(json_path)
decompressor = Decompressor(json_path)


# input
diff_i_stimulus = []

# output
preds_o_stimulus = []
data_o_stimulus = []

for data in rand_dataset:
    ## compress
    result = compressor(data)
    original_size = result['original_size']
    compressed_size = result['compressed_size']
    codeword = deepcopy(result['codeword'])
    selected_class = result['selected_class']
    
    # test a module of class #2
    if(selected_class == 2):
        ## defpc / dedbx
        codeword = result['codeword']
        selected_class = result['selected_class']
    
        scanned_array = decompressor.decomp_modules[selected_class].defpc_module(codeword)
        residue_line = decompressor.decomp_modules[selected_class].debpx_module(scanned_array)
        original_data, preds = decompressor.decomp_modules[selected_class].deresidue_module(residue_line, True)
        
        assert ((data == original_data).all())
        
        diff_i_stimulus.append(residue_line)
        data_o_stimulus.append(original_data)
        preds_o_stimulus.append(preds)
        
diff_i_path = stimulus_path + '/diff_i.txt'
with open(diff_i_path, 'w') as f:
    for diff_i in diff_i_stimulus:
        for byte in diff_i:
            f.write('{:02x}'.format(byte))
        f.write('\n')
        
data_o_path = stimulus_path + '/data_o.txt'
with open(data_o_path, 'w') as f:
    for data_o in data_o_stimulus:
        for byte in data_o:
            f.write('{:02x}'.format(byte))
        f.write('\n')
        
pred_o_path = stimulus_path + '/pred.txt'
with open(pred_o_path, 'w') as f:
    for pred_o in preds_o_stimulus:
        for byte in pred_o:
            f.write('{:02x}'.format(byte))
        f.write('\n')

