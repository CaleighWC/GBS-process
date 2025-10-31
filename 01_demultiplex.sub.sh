#!/bin/bash

#SBATCH --time=10:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=48G
#SBATCH --job-name="01_demultiplex.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL 
#SBATCH --array=1-4

# Set filename of this file so contents can be printed in job output

this_filename='01_demultiplex.sub.sh'

# Set filename of prologue script

prologue_filename='tools/array_job_prologue.sh'

# Scratch path for prologue script

scratchpath='/home/cwcharle/scratch/'

# Source prologue script (creates jobtime and prints scripts to log)

source ${prologue_filename}

# Load modules

printf "\nCurrently loaded modules\n"
module list

printf "\nLoading modules for job\n"
module load \
StdEnv/2023 \
perl/5.36.1

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input files

accessionlistpath='/home/cwcharle/scratch/GBS_data/2025-Oct-30_23-24-58/'
accessionlistname='accessionlist.txt'

accession=$(sed -n ${SLURM_ARRAY_TASK_ID}p ${accessionlistpath}/${accessionlistname})

barcodespath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras'
barcodesname="${accession}_barcodes.txt"

fq1path='/home/cwcharle/scratch/GBS_data/2025-Oct-30_23-24-58/'
fq1name="${accession}_1.fastq"

fq2path="${fq1path}"
fq2name="${accession}_2.fastq"

outputname="${accession}"

demultiplexerpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/tools/GBS_demultiplexer_30base.pl'

out_dir_path='/home/cwcharle/scratch/GBS-process/01_demultiplexed_fastqs/'

# Copy input files to temp node local directory as input and make working directory

printf "\nCopying barcode file to node local storage\n"
cp ${barcodespath}/${barcodesname} ${SLURM_TMPDIR} 

printf "\nCopying fastq 1 to node local storage\n"
cp ${fq1path}/${fq1name} ${SLURM_TMPDIR}

printf "\nCopying fastq 2 to node local storage\n"
cp ${fq2path}/${fq2name} ${SLURM_TMPDIR}

printf "\nThe files in SLURM_TMPDIR are:\n"
echo $(ls ${SLURM_TMPDIR})

# Make node local output directory to copy back later

mkdir ${SLURM_TMPDIR}/${jobtime}

# Run the demultiplexer tool and write its output to the node local output

cd ${SLURM_TMPDIR}

printf "\nAttempting to run demultiplexer\n"

perl ${demultiplexerpath} \
${barcodespath}/${barcodesname} \
${fq1path}/${fq1name} \
${fq2path}/${fq2name} \
${jobtime}/${outputname}

printf "\nfinished running demultiplexer\n"

printf "\nThe files in SLURM_TMPDIR are now\n"
echo $(ls ${SLURM_TMPDIR})

# Move output back to new output directory in projects directory

printf "\nCopying output files back to projects directory\n"

mkdir -p ${out_dir_path}/${jobtime}/${accession}

cp -r ${SLURM_TMPDIR}/${jobtime}/* ${out_dir_path}/${jobtime}/${accession}

# Move and copy log file to final locations
cp ${init_wd}/${logfilename} ${init_wd}/saved_logs
mv ${init_wd}/${logfilename} ${out_dir_path}/${jobtime}

printf "\nScript complete\n"

