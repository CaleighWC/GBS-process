#!/bin/bash

#SBATCH --time=0-05:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --job-name="00_download.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL 
#SBATCH --array=1-4

# Set scratch path for prologue script to use

scratchpath="/home/cwcharle/scratch"

# Set filename of this file so contents can be printed in job output

this_filename='00_download.sub.sh'

# Set filename of prologue file and run it

prologue_filename='./tools/array_job_prologue.sh'

source ${prologue_filename}

# Load modules for job

printf "\nCurrently loaded modules\n"
module list

printf "\nLoading modules for job\n"
module load \
StdEnv/2023 \
sra-toolkit/3.0.9

printf "\nCurrently loaded modules\n"
module list

# Make SLURM node temp directory to copy back at the end and
# change the working directory to the node temp storage

mkdir ${SLURM_TMPDIR}/${jobtime}
cd ${SLURM_TMPDIR}

# Create variables with paths and names of input and output files

echo 'SRR1176844
SRR31958018
SRR31958020
SRR31958019' > tmpaccessionlist.txt

accession=$(sed -n ${SLURM_ARRAY_TASK_ID}p 'tmpaccessionlist.txt')

out_dir_path='/home/cwcharle/scratch/GBS_data/'

# Download and split files at listed accessions

prefetch ${accession} \
	--max-size 100g \
	--progress \
	--heartbeat 2

fasterq-dump ${accession} \
	--split-files \
	--outdir ${jobtime} \
	--threads 8

# Move output back to new output directory in projects directory

printf "\nCopying output files back to projects directory\n"

mkdir ${out_dir_path}/${jobtime}

cp -r ${SLURM_TMPDIR}/${jobtime}/* ${out_dir_path}/${jobtime}

printf "\nScript complete\n"

