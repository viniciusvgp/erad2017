#!/bin/bash
# Script for producing .csv from .org files

# Read parameters
simple=0
links=0
variables=0
states=1 #default export
info=0
keeptrace=0
probabilistic=""
help_script()
{
    cat << EOF
Usage: $0 options

First parameter is input file, second parameter is output file.

OPTIONS:
   -h      Show this message
   -s      For using simple trace files as input (not .org) 
   -t      Keep .trace file   
   -l      Export links as well
   -v      Export variables as well
   -e      Export states as well
   -i      Print info about commands in execution
   -p      For probabilistic output of pj_dump
EOF
}
# Parsing options
while getopts "stlveiph" opt; do
    case $opt in
	h)
	    help_script
	    exit 4
	    ;;
        s)
	    simple=1
	    ;;
        t)
	    keeptrace=1
	    ;;
        l)
	    links=1
	    ;;
	v)
	    variables=1
	    ;;
	e)
	    states=1
	    ;;
	i)
	    info=1
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
rm -rf tmp.trace
rm -rf $outputfile.trace

# Get the trace from .org file
if [[ $simple == 0 ]]; then
    if [[ $info == 1 ]]; then
	echo "Info: considering $inputfile as an org file."
    fi
    sed -n '/* PAJE TRACE:/,/####/{/####/!p}' $inputfile >> tmp.trace
    tail -n +2 tmp.trace > $outputfile.trace
    if [[ $info == 1 ]]; then
	echo "Info: extraction of $outputfile.trace completed."
    fi
else
    if [[ $info == 1 ]]; then
	echo "Info: considering $inputfile as a paje trace file."
    fi
    cp $inputfile $outputfile.trace
fi

# Fixing formatof .trace file
if [[ $info == 1 ]]; then
    echo "Info: fixing header names in paje trace file..."
fi
sed -i -e 's/SourceContainer/StartContainer/' -e 's/DestContainer/EndContainer/' -e 's/[\t]ContainerType/\tType/' -e 's/EntityType/Type/'  $outputfile.trace

# Divide trace in preambule and the real trace
if [[ $info == 1 ]]; then
    echo "Info: sorting the trace according to timestamps..."
fi
grep -e '^\(\(%\)\|\(\(1\|2\|3\|4\|5\|6\|7\)\>\)\)' $outputfile.trace > start.trace
grep -e '^\(\(%\)\|\(\(1\|2\|3\|4\|5\|6\|7\)\>\)\)' -v  $outputfile.trace > end.trace

#always remove lines starting 

# Deleting variables if necessary
if [[ $variables == 0 ]]; then
   sed -i -e '/^13/d' end.trace
fi

# Deleting links if necessary
if [[ $links == 0 ]]; then
    sed -i -e '/^18/d' -e '/^19/d' end.trace
fi

cp end.trace outputDel.trace

# Sorting, merging and dumping trace
sort -s -V --key=2,2 outputDel.trace > endSorted.trace
cat start.trace endSorted.trace > outputSorted.trace
cp outputSorted.trace $outputfile.trace

COMMAND="pj_dump -u -n $probabilistic $outputfile.trace > $outputfile.csv"
if [[ $info == 1 ]]; then
    echo "Info: Executing '$COMMAND'..."
fi
eval $COMMAND

if [[ $states == 1 ]]; then
    SFILE=$outputfile-states.csv
    if [[ $info == 1 ]]; then
	echo "Info: Keeping states in file $SFILE"
    fi
    perl -ne 'print if /^State/' $outputfile.csv > $SFILE
    sed -i '1s/^/Nature, ResourceId, Type, Start, End, Duration, Depth, Value, Footprint , JobId , Params, Size, Tag\n/' $SFILE
fi

if [[ $variables == 1 ]]; then
    VFILE=$outputfile-variables.csv
    if [[ $info == 1 ]]; then
	echo "Info: Keeping variables in file $VFILE"
    fi
    cat $outputfile.csv | grep -e ^Variable | sed -e "s/^Variable.*Ready Tasks/Ready/" -e "s/^Variable.*Submitted.*Tasks/Submitted/" | cut -d"," -f1,2,3,5 | grep  -e Ready -e Submitted > $VFILE
   sed -i '1s/^/Variable, Start, End, Value\n/' $VFILE
 fi

if [[ $links == 1 ]]; then
    LFILE=$outputfile-links.csv
    if [[ $info == 1 ]]; then
	echo "Info: Keeping variables in file $LFILE"
    fi
    cat $outputfile.csv | grep ^Link > $LFILE
    sed -i '1s/^/Header to be defined\n/' $LFILE
fi

# Delete temporary files
rm outputDel.trace
rm start.trace
rm end.trace
rm endSorted.trace

# Remove temporary files
rm -rf tmp.trace
if [[ $keeptrace == 0 ]]; then
    rm -rf $outputfile.trace
fi

