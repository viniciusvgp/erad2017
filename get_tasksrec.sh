#!/bin/bash
# Script for producing .csv from .org files

# Read parameters
all=0
simple=0
links=0
probabilistic=""
help_script()
{
    cat << EOF
Usage: $0 options

First parameter is input file, second parameter is output file.

OPTIONS:
   -h      Show this message
   -a      Keep whole trace not only State
   -s      For using simple trace files as input (not .org)   
   -l      Export links as well
   -p      For probabilistic output of pj_dump
EOF
}
# Parsing options
while getopts "aslph" opt; do
    case $opt in
	a)
	    all=1
	    ;;
	h)
	    help_script
	    exit 4
	    ;;
        s)
	    simple=1
	    ;;
        l)
	    links=1
	    ;;
        p)
	    probabilistic="-p \"Worker State\""
	    ;;
	\?)
	    echo "Invalid option: -$OPTARG"
	    help_script
	    exit 3
	    ;;
    esac
done
shift $((OPTIND - 1))
inputfile=$1
outputfile=$2
if [[ $# != 2 ]]; then
    echo 'ERROR!'
    help_script
    exit 2
fi

# Remove previous files if necessary
rm -rf tmp.rec
rm -rf $outputfile.rec

# Get the trace from .org file
if [[ $simple == 0 ]]; then
    sed -n '/* TASKS REC:/,/####/{/####/!p}' $inputfile >> tmp.rec
    tail -n +2 tmp.rec > $outputfile.rec
else
    cp $inputfile $outputfile.rec
fi

# Remove temporary files
rm -rf tmp.rec
rm -rf $outputfile.trace
