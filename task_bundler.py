#!/usr/bin/env python

"""cellpainting_tools

This script is intended to provide various tools
too assist the cell profiler cell painting pipline on terra.

"""
import argparse
import subprocess
import csv
import os
import sys
from pathlib import Path
from shutil import move
from os.path import join
from os import listdir, rmdir
from shutil import move


def parse_args():
    parser = argparse.ArgumentParser(
        description = "Tool set for the Imaging Platform - Cell Paining")
    parser.add_argument("--input_csv",
        dest = "input_csv",
        help = "Specify the where the input csv file")
    parser.add_argument("--output_dir",
        dest = "output_dir",
        help = "Specify the where the output csv files are generated")
    parser.add_argument("--start_dir",
        dest = "start_dir",
        help = "Starting directory for the file search and move")
    parser.add_argument("--exp_dir_path",
        dest = "exp_dir_path",
        help = "Starting directory for the file search and move")
    parser.add_argument("--dir_level",
        dest = "dir_level",
        help = "Specifies what level the search and move fucntion works at")
    return parser.parse_args()

"""Splits the  

Go through every object in a collection and find any objects that do not
have a *file_status* entry.  Now, go through every object in the collection

Args:
    collection(obj): A Mongo Collection object
    subscription(str): The Firehose subscription name
    workspace(str): The Firehose workspace name
Returns:
    (list) A list of object IDs to delete
"""

def split_csv(file_path, out_dir):
	filepath = file_path

	with open(filepath) as fp:
		line = fp.readline()
		cnt = 0
		headder =""
		while True:
			if cnt == 0:
				headder = line
			else:
				line = fp.readline()
				if not line:
					break
				new_file = out_dir+"/illum_load_data_"+str(cnt)+".csv"
				f = open(new_file,"a")
				f.write(headder)
				f.write(line)
				f.close()
			cnt += 1
	fp.close()
	return 0

def move_files(path, glob_dir):
	path = path
	glab_dir = glob_dir
	for filename in listdir(join(path, glob_dir)):
		move(join(path, glob_dir, filename), join(path, filename))
#Default level is two
def get_shard_dir(file_path, level=2):
	common = file_path
	for i in range(level):
		common = os.path.dirname(common)
	return(common)
	#return os.path.relpath(file_path, common)

def get_base_dir(path):
	return os.path.basename(os.path.dirname((path)))

def export_dir(path):
	os.environ["SHARD_DIR"] = "/var/tmp/test"
#export SHARD_DIR=$(find . -type d -name "call-analysisPipeline")
def file_move(path, level):
	start_path = path
	ext = '.csv'

	for root, dirs, files in os.walk(start_path, topdown=False):
		for name in files:
			if ".csv" in name and "shard" in root:
				move_files(get_shard_dir(root+"/"+name, level), get_base_dir(root+"/"+name))
	# try:
	# 	p = Path(path).absolute()
	# 	parent_dir = p.parents[2]
	# 	print(p.name)
	# 	p.rename(parent_dir / p.name)
	# except IndexError:
	# # no upper directory
	# 	pass
	# cmd = ["find", .", "-type", "f", "-name", "*.csv"| awk -F'/' '{print "/var/tmp/"$7}'|xargs -L 1 mkdir -p"]
 #    try:
 #        out = subprocess.Popen(cmd, stdout=subprocess.PIPE)  
 #    except subprocess.CalledProcessError as e:
 #        print("Subprocess error creating dir", str(e))
 #        continue

	# cmd = ["echo '#!/bin/sh' |tee copy_man.sh"]
 #    try:
 #        out = subprocess.Popen(cmd, stdout=subprocess.PIPE)  
 #    except subprocess.CalledProcessError as e:
 #        print("Subprocess error creating dir", str(e))
 #        continue

# cmd = ["find . -type f -name "*.csv"| awk -F'/' '{print "mv "$0" /var/tmp/"$7"/" $9}' | tee -a copy_man.sh"]
 #    try:
 #        out = subprocess.Popen(cmd, stdout=subprocess.PIPE)  
 #    except subprocess.CalledProcessError as e:
 #        print("Subprocess error creating dir", str(e))if
 #        continue	

def main():
	args = parse_args()

	if args.start_dir:
		file_move(args.start_dir,int(args.dir_level))
	elif args.exp_dir_path:
		export_dir(args.exp_dir_path)
	else:	
		split_csv(args.input_csv, args.output_dir)

if __name__ == "__main__":
    main()
