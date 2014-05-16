#!/bin/bash

#set -x

ORIG_FOLDER=""
MOD_FOLDER=""
OUTPUT_FOLDER=""

EXTR_RET=""

function show_usage() {
	echo "Usage: code_comparer.sh (-o | --orig)=<orig source dir> (-m | --modified)=<modified source dir> [-f] [-O= | --output=]"
	if [[ $1 == "true" ]]
	then
		echo -e "\t-o= | --orig= Original source code folder"
		echo -e "\t-m= | --modified= Modified source code folder"
		echo -e "\t-f Runs in file mode (Default is folder mode)"
		echo -e "\t-O= | --output= Save .patch files into a folder (Default is stdout)"
		echo -e "\t--help Shows this help"
		exit
	fi
	echo "Use --help for any other relevant info"
	exit
}

function extract_value() {
	EXTR_RET=$(echo $1 | awk -F'=' '{print$2}')
}

function parse_parms() {	
	while [ "$1" != "" ]
	do
		case $1 in
			--orig=*)		shift
						extract_value $1
						ORIG_FOLDER=$?
						;;
			*)			show_usage
		esac
	done
}

function __do_diff() {
		orig_file=$1
		mod_file=$2
		NC='\e[0m' #No Color format
		red='\e[0;31m'
		green='\e[0;32m'
		yellow='\e[1;33m'
		echo "Checking for file $orig_file against $mod_file"
	
		diff_count=$(diff -rNu $orig_file $mod_file | wc -l)

		if (( $diff_count != 0 ))
		then
			echo -e "${yellow}[INFO]${NC} Generating patch file: $file.patch with $diff_count lines"
			if [[ $OUTPUT_FOLDER != "" ]]
			then
				if [[ ! -d $OUTPUT_FOLDER ]]
				then
					
					echo -e "${red}[ERROR]${NC} Output folder: $OUTPUT_FOLDER not found"
					exit -1
				fi
				diff -rNu $orig_file $mod_file > $OUTPUT_FOLDER/$file.patch	

				if [[ -f $OUTPUT_FOLDER/$file.patch ]]
				then
					echo -e "${green}[OK]${NC}  $OUTPUT_FOLDER/$file.patch created succssfully"
				else
					echo -e "${red}[ERROR]${NC}  cannot create $OUTPUT_FOLDER/$file.patch"
				fi
			else
				diff -rNu $orig_file $mod_file
			fi
		else
			echo -e "${yellow}[INFO]${NC} No differences found between $orig_file and $mod_file ...skipping both..."
		fi

}

function create_patches() {
	if [[ $FILE_MODE == "true" ]]
	then
		__do_diff $1 $2
	fi

	for file in $(ls $1)
	do
		orig_file=$1/$file
		mod_file=$2/$file
	
		__do_diff $orig_file $mod_file
	done
}

if (( $# < 2 )) 
then
	if [[ $1 == "--help" ]]
	then
		show_usage true
	fi
	
	show_usage false
fi

while [ "$1" != "" ]
do
	echo "Param=$1"
	case $1 in
		--orig=* | -o=*)		extract_value $1
						echo "$EXTR_RET"
						ORIG_FOLDER=$EXTR_RET
						shift
						;;
		--modified=* | -m=*)		extract_value $1
						MOD_FOLDER=$EXTR_RET
						shift
						;;
		-f)				FILE_MODE=true
						shift
						;;
		--output=* | -O=*)		extract_value $1
						OUTPUT_FOLDER=$EXTR_RET
						shift
						;;
		*)			show_usage
	esac
done

if [[ "$ORIG_FOLDER" == "" || "$MOD_FOLDER" == "" ]]
then
	echo "You should provide both orig file/folder to continue"
	show_usage false
fi

echo "Code comparer running over $ORIG_FOLDER/$MOD_FOLDER"

create_patches $ORIG_FOLDER $MOD_FOLDER
