#!/bin/bash 

ultra="/home/aleph/ultracopycat.txt"
files=$(find . -iname "*.lua")

for file in $files; do
  echo "--$file" >> $ultra
  cat $file >> $ultra
done
