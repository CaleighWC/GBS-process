#!/bin/bash

#SBATCH --time=0-01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --job-name="07_merge_contig_batch_vcfs.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL 

# Set jobtime so dates on different outputs from the job will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

# Set filename of this file so contents can be printed in job output

this_filename='07_merge_contig_batch_vcfs.sub.sh'

# Set filename of prologue script

prologue_filename='./tools/single_job_prologue.sh'

# Run prologue script for logging and creating useful variables

source ${prologue_filename}

# Load modules for job

printf "\nCurrently loaded modules\n"
module list

printf "\nLoading modules for job\n"
module load \
StdEnv/2023 \
picard/3.1.0

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files

in_vcf_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/combined_vcfs/'
in_vcf_dir='2025-Oct-24_12-31-07'
in_vcf_prefix='all_individuals_section_'

dict_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras/'
dict_name='GW2022ref.dict'

out_vcf_name='all_individuals_all_contigs.vcf.gz'

out_dir_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/merged_vcf'

# Copy input files to temp node local directory

printf "\nCopying input vcfs to node local storage\n"
cp ${in_vcf_path}/${in_vcf_dir}/${in_vcf_prefix}* ${SLURM_TMPDIR}

printf "\nThe files in SLURM_TMPDIR are:\n"
echo $(ls ${SLURM_TMPDIR})

# Make node local output directory to copy back later

mkdir ${SLURM_TMPDIR}/${jobtime}

# Run picard and write its output to the node local output file

cd ${SLURM_TMPDIR}

ls ${in_vcf_prefix}* > vcfs.list

java -jar $EBROOTPICARD/picard.jar \
MergeVcfs \
	I=vcfs.list \
	O=${jobtime}/${out_vcf_name} \
	D=${dict_path}/${dict_name}

# Move output back to new output directory in projects directory

printf "\nCopying output files back to projects directory\n"

mkdir ${out_dir_path}
cp -r ${SLURM_TMPDIR}/${jobtime} ${out_dir_path}

# Move log file to output directory once job is complete

mv ${init_wd}/${log_filename} ${out_dir_path}/${jobtime}

printf "\nScript complete\n"

