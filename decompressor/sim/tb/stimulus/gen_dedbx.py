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
scanned_i_stimulus = []

# output
bpx_stimulus = []
bitplane_stimulus = []
diff_o_stimulus = []

for data in rand_dataset:
    ## compress
    result = compressor(data)
    original_size = result['original_size']
    compressed_size = result['compressed_size']
    codeword = deepcopy(result['codeword'])
    selected_class = result['selected_class']
    
    # test a module of class #2
    if(selected_class == 2):
        # attach encoding val
        sel_class = result['selected_class']
        if sel_class == -1: sel_class = 7
        sel_class = list(map(int, '{:03b}'.format(sel_class)))
        codeword = np.concatenate([sel_class, codeword], dtype=np.uint8, casting='unsafe')
        codeword = np.concatenate([codeword, [0] * (259 - len(codeword))], dtype=np.uint8, casting='unsafe')

        ## defpc / dedbx
        codeword = result['codeword']
        selected_class = result['selected_class']
    
        scanned_array = decompressor.decomp_modules[selected_class].defpc_module(codeword)
        bpx_array, bitplane_array, residue_line = decompressor.decomp_modules[selected_class].debpx_module(scanned_array, debug=True)
        
        scanned = scanned_array.reshape(-1)
        bpx = bpx_array.reshape(-1)
        bitplane = bitplane_array.reshape(-1)
        scanned_i_stimulus.append(scanned)
        bpx_stimulus.append(bpx)
        bitplane_stimulus.append(bitplane)
        diff_o_stimulus.append(residue_line)

scanned_i_path = output_dir + '/scanned_i.txt'
with open(scanned_i_path, 'w') as f:
    for scanned_i in scanned_i_stimulus:
        for binary in scanned_i:
            f.write('{:1d}'.format(binary))
        f.write('\n')

bpx_path = output_dir + '/bpx.txt'
with open(bpx_path, 'w') as f:
    for bpx in bpx_stimulus:
        for binary in bpx:
            f.write('{:1d}'.format(binary))
        f.write('\n')
        
bitplane_path = output_dir + '/bitplane.txt'
with open(bitplane_path, 'w') as f:
    for bitplane in bitplane_stimulus:
        for binary in bitplane:
            f.write('{:1d}'.format(binary))
        f.write('\n')
        
diff_o_path = output_dir + '/diff_o.txt'
with open(diff_o_path, 'w') as f:
    for diff_o in diff_o_stimulus:
        for byte in diff_o:
            f.write('{:02x}'.format(byte))
        f.write('\n')
        
