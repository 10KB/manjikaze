#!/usr/bin/bash

# This script requires a certain structure in the Projects directory.
# This works for me, but you might need to adjust it to your own structure.

if [ $# -eq 0 ]
then
    for i in $(ls -dft $HOME/Projects/*/*); do
        echo "$i" | sed -e 's/^\/home\/$USER\/Projects\///g';
    done
else
    coproc ( cursor $HOME/Projects/$1 > /dev/null 2>&1 )
    exec 1>&-
    exit
fi
