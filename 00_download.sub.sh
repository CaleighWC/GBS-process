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

# Set jobtime so dates on different outputs from the job will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

# Set filename of this file so contents can be printed in job output

this_filename='00_download.sub.sh'

# Set filename of prologue file and run it

prologue_filename='/tools/single_job_prologue.sh'

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
SRR31958019
' > tmpaccessionlist.txt

accessionlist='tmpaccessionlist.txt'

out_dir_path='/home/cwcharle/scratch/GBS_data/'

# Download and split files at listed accessions, then delete
# the archive download to make space for others

while read accession; do
	prefetch "$accession" \
		--max-size 100g
	fasterq-dump "$accession" \
		--split-files \
		--outdir ${jobtime}
	rm -r "$accession"
done < ${accessionlist}

# Move output back to new output directory in projects directory

printf "\nCopying output files back to projects directory\n"

cp -r ${SLURM_TMPDIR}/${jobtime} ${out_dir_path}

printf "\nScript complete\n"

