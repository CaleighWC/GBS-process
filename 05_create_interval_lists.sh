#!/bin/bash

# Redirect stdout and stderr to from console to a log file

LOGFILE="create_interval_lists_log.txt"

exec &> $LOGFILE

# Set jobtime so timestamps on different outputs from this script will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

printf "The jobtime is ${jobtime}.\n"

# Set filename of this script so contents can be printed to output

this_filename='05_create_interval_lists.sh'

# Print contents to output

printf "\nThe submit script for the job is printed below:\n"
printf "_______________________________________________\n"

cat ${this_filename}

printf "\n_____________________________________________"
printf "\nThat concludes the submit script for the job.\n"

# Load modules for job

printf "\nCurrently loaded modules\n"
module list

printf "\nLoading modules for job\n"
module load \
StdEnv/2023 \
julia/1.11.3

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files
printf "\nCreating variables\n"

genomedictpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras'
genomedictname='GW2022ref.dict'

out_dir_path="/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/interval_lists/${jobtime}/"

# Enter julia shell and run script
# The first argument passed to julia should be the path to the dict file, and
# the second should be the output directory path

printf "Running Julia script\n"

julia tools/create_interval_lists.jl \
"${genomedictpath}/${genomedictname}" \
"${out_dir_path}"

printf "\nMove logfile to contain jobtime"

mv ${LOGFILE} "create_interval_lists_log_${jobtime}.txt"

printf "\nScript completed"

