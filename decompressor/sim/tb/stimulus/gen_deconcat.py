#!/usr/bin/env python
# coding: utf-8

import os, sys
from copy import deepcopy

import numpy as np

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("input_dataset", type=str, help="The input dataset path")
parser.add_argument("input_config", type=str, help="The input json config path")
parser.add_argument("output_dir", type=str, help="The output directory path")
parser.add_argument("-l", "--link", type=str, required=False,
        default="/home/jin8495/projects/vpc/v1_dataType/IEEE_CompArchiLetters/python",
        help="The link path of python compressor model")
args = parser.parse_args()

linkpath = args.link
dataset_path = args.input_dataset
config_path = args.input_config
output_dir = args.output_dir

p = os.path.abspath(linkpath)
sys.path.insert(1, p)

from src.single_encoder_compressor import *
from src.decompressor import *

# dataset
dataset = np.load(dataset_path).astype(np.uint8)
rand_dataset = dataset[np.random.choice(len(dataset), size=10000)]
rand_dataset = np.concatenate([rand_dataset,
                              [[0] * 32],
                              [[0,1,2,3] * 8]]).astype(np.uint8)

# compressor / decompressor
compressor = SingleEncoderCompressor(config_path)
decompressor = Decompressor(config_path)

# input
data_i_stimulus = []

# output
data_o_stimulus = []

for data in rand_dataset:
    ## compress
    result = compressor(data)
    original_size = result['original_size']
    compressed_size = result['compressed_size']
    codeword = deepcopy(result['codeword'])
    selected_class = result['selected_class']
    
    # test a module which is not uncomp, all-zero, all-wordsame
    if(selected_class != -1 and selected_class != 0 and selected_class != 1):
        # attach encoding val
        sel_class = result['selected_class']
        if sel_class == -1: sel_class = 7
        sel_class = list(map(int, '{:03b}'.format(sel_class)))
        codeword = np.concatenate([sel_class, codeword], dtype=np.uint8, casting='unsafe')
        codeword = np.concatenate([codeword, [0] * (259 - len(codeword))], dtype=np.uint8, casting='unsafe')

        data_i_stimulus.append(codeword)

        ## defpc
        codeword = result['codeword']
        selected_class = result['selected_class']
    
        scanned = decompressor.decomp_modules[selected_class].defpc_module(codeword)
        scanned = scanned.reshape(-1)
        
        data_o_stimulus.append(scanned)

data_i_path = output_dir + '/data_i.txt'
with open(data_i_path, 'w') as f:
    for data_i in data_i_stimulus:
        for binary in data_i:
            f.write('{:1d}'.format(binary))
        f.write('\n')
        
data_o_path = output_dir + '/scanned_o.txt'
with open(data_o_path, 'w') as f:
    for data_o in data_o_stimulus:
        for binary in data_o:
            f.write('{:1d}'.format(binary))
        f.write('\n')
        


