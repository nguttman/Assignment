#!/usr/bin/env python

import os
import hashlib
from collections import defaultdict

def get_file_hash(file_path, block_size=65536):
    hash_object = hashlib.sha256()
    with open(file_path, 'rb') as f:
        while True:
            data = f.read(block_size)
            if not data:
                break
            hash_object.update(data)
    return hash_object.hexdigest()

def find_duplicate_files(directory):
    file_hash_dict = defaultdict(list)

    for root, _, files in os.walk(directory):
        for file_name in files:
            file_path = os.path.join(root, file_name)
            file_hash = get_file_hash(file_path)
            file_hash_dict[file_hash].append(file_name)

    duplicate_files = {hash_: file_names for hash_, file_names in file_hash_dict.items() if len(file_names) > 1}
    
    return duplicate_files

def main():
    import sys

    if len(sys.argv) != 2:
        print("Usage: python script_name.py directory_path")
        return

    directory = sys.argv[1]
    if not os.path.isdir(directory):
        print(f"Error: '{directory}' is not a valid directory.")
        return

    duplicate_files = find_duplicate_files(directory)
    for hash_, file_names in duplicate_files.items():
        print("Duplicate files:")
        for file_name in file_names:
            print(f"• {file_name}")
        print()

if __name__ == "__main__":
    main()
