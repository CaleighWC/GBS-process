#!/bin/bash

#SBATCH --time=0-05:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --job-name="09_convert_to_012minus1.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL

# Setting initial variables

scratchpath="/home/cwcharle/scratch"

this_filename="09_convert_to_012minus1.sub.sh"

prologue_filename="tools/single_job_prologue.sh"

# Run prologue script to take care of some logging and synchronize jobtimes
source ${prologue_filename}

# Load modules
printf "\nCurrently loaded modules\n"
module list

printf "\nLoading modules for job\n"
module load \
StdEnv/2023 \
vcftools/0.1.16

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files
# This is the last spot where you need to ADD VARIABLES (3/3)

# The path where you would like the job output to be placed (ideally something generated unique to this run)
out_dir_path="/home/cwcharle/scratch/GBS-process/09_convert_to_012minus1.sub.sh/"

# The path and name of the genotyped vcf to use as input
vcf_in_path="/home/cwcharle/scratch/GBS-process/08_filter_sites/2025-Dec-11_10-42-50"
vcf_in_name="all_individuals_all_contigs_filtered.vcf"

# The name of the output file
out_name="all_individuals_all_contigs_filtered_for_julia.012minus1"

# Copy input files to temp node local directory
# This makes reads/writes faster during the job

cp ${vcf_in_path}/${vcf_in_name}* ${SLURM_TMPDIR}

printf "\nThe files in SLURM_TMPDIR are:\n"
echo $(ls ${SLURM_TMPDIR})

# Change working directory to the temp node local directory
# This is just so we can use smaller file paths and all outputs
# are generated on the node

printf "\nChanging working directory to SLURM_TMPDIR\n"
cd ${SLURM_TMPDIR}

mkdir ${jobtime}

# Unzip vcf
gunzip ${vcf_in_name}.gz

# Convert file format
vcftools \
	--vcf ${vcf_in_name} \
	--012 \
	--out ${jobtime}/${out_name}

printf "\nThe files in SLURM_TMPDIR are now\n"
echo $(ls ${SLURM_TMPDIR})

# Move output back to output directory in projects directory

printf "\nCopying final output file back to projects directory in ${out_dir_path}\n"

mkdir -p ${out_dir_path}

cp -r ${SLURM_TMPDIR}/${jobtime} ${out_dir_path}/

printf "\n These are the files in the output directory\n"
ls ${out_dir_path}

printf "\n Moving logfile to the output folder \n"
mv ${init_wd}/${log_filename} ${out_dir_path}/${jobtime}

printf "\nScript complete\n"
