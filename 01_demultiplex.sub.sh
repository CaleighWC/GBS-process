#!/bin/bash

#SBATCH --time=1-00:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=48G
#SBATCH --job-name="01_demultiplex.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL 

# Set jobtime so dates on different outputs from the job will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

# Set filename of this file so contents can be printed in job output

this_filename='01_demultiplex.sub.sh'

# Move output file to have jobtime in it

mv job_${SLURM_JOB_ID}.out job_${SLURM_JOB_ID}_${jobtime}.out

printf "The jobtime is ${jobtime}.\n"

printf "\nThe SLURM Job ID is ${SLURM_JOB_ID}\n"

printf "\nThe submit script for the job is printed below:\n"
printf "_______________________________________________\n"

cat ${this_filename}

printf "\n_____________________________________________"
printf "\nThat concludes the submit script for the job.\n"

printf "\nCurrently loaded modules\n"
module list

printf "\nLoading modules for job\n"
module load \
StdEnv/2023 \
perl/5.36.1

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input files

barcodespath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras'
barcodesname='barcodes_CaleighWC_Jun_9_2025_data.txt'

fq1path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS_pool_Jun_9_2025_data/'
fq1name='GBS_Pool_Jun_9_2025_S7_L002_R1_001.fastq'

fq2path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS_pool_Jun_9_2025_data/'
fq2name='GBS_Pool_Jun_9_2025_S7_L002_R2_001.fastq'

outputname='/GBS_Jun_9_2025_clean'

demultiplexerpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/tools/GBS_demultiplexer_30base.pl'

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
out_dir_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/clean_data/'
cp -r ${SLURM_TMPDIR}/${jobtime} ${out_dir_path}

printf "\nScript complete\n"

