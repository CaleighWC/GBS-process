#!/bin/bash

#SBATCH --time=0-1:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --job-name="02_trim.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL 
#SBATCH --array=1-4

# Set jobtime so dates on different outputs from the job will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

# Set filename of this file so contents can be printed in job output

this_filename='02_trim.sub.sh'

# Set filename of prologue script

prologue_filename='tools/array_job_prologue.sh'

# Scratch path for prologue script

scratchpath='/home/cwcharle/scratch/'

# Source prologue script (creates jobtime and prints scripts to log)

source ${prologue_filename}

# Load modules for analysis

printf "\nCurrently loaded modules\n"
module list

printf "\nLoading modules for job\n"
module load \
StdEnv/2023 \
trimmomatic/0.39

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files
# This is the only spot you should have to change any paths on runs
# Except for the "scratchpath" above

main_in_out_dir='/home/cwcharle/scratch/GBS-process/'

accessionlistpath="${main_in_out_dir}/00_downloads/2025-Oct-30_23-24-58/"
accessionlistname='accessionlist.txt' # Path to list of names / accessions for array to use

accession=$(sed -n ${SLURM_ARRAY_TASK_ID}p ${accessionlistpath}/${accessionlistname})

barcodespath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras/'
barcodesname="${accession}_barcodes.txt"

infastqpath="${main_in_out_dir}/01_demultiplexed_fastqs/2025-Oct-31_11-55-01"
infastqdir="${accession}" # Path to input fastqs

indatanamestart="${accession}_"

out_dir_stem="${main_in_out_dir}/02_trimmed_fastqs/${jobtime}"
out_dir_leaf="/${accession}"

out_prefix_list_name="prefix.list.${indatanamestart}.bwa"

# Print accession to log

printf "\n The accession is ${accession}\n"

# Make list of individuals from the indatanamestart variable and barcode file

printf "\nMaking list of individuals from the barcode file\n"

mkdir -p ${out_dir_stem}/${out_dir_leaf}

awk -v dataname="${dataname}" '{print dataname $1}' ${barcodespath}/${barcodesname} > ${out_dir_stem}/${out_dir_leaf}/${out_prefix_list_name}

# Copy input files to temp node local directory as input and make working directory

printf "\nCopying prefix list file to node local storage\n"
cp ${out_dir_stem}/${out_dir_leaf}/${out_prefix_list_name} ${SLURM_TMPDIR} 

printf "\nCopying input fastqs to node local storage\n"
cp -r ${infastqpath}/${infastqdir} ${SLURM_TMPDIR}

printf "\nThe files in SLURM_TMPDIR are:\n"
echo $(ls ${SLURM_TMPDIR})

# Make node local output directory to copy back later

mkdir ${SLURM_TMPDIR}/outfastq

# Run the trimmomatic tool and write its output to the node local output file

cd ${SLURM_TMPDIR}

printf "\nAttempting to run trimmomatic\n"

while read prefix

do

java -jar $EBROOTTRIMMOMATIC/trimmomatic-0.39.jar \
PE \
-phred33 \
-threads 8 \
${infastqdir}/${indatanamestart}${prefix}_R1.fastq \
${infastqdir}/${indatanamestart}${prefix}_R2.fastq \
outfastq/"$prefix"_R1.fastq \
outfastq/"$prefix"_R1_unpaired.fastq \
outfastq/"$prefix"_R2.fastq \
outfastq/"$prefix"_R2_unpaired.fastq \
TRAILING:3 \
SLIDINGWINDOW:4:10 \
MINLEN:30

done < ${SLURM_TMPDIR}/${out_prefix_list_name}

printf "\nfinished running trimmomatic\n"

printf "\nThe files in SLURM_TMPDIR are now\n"
echo $(ls ${SLURM_TMPDIR})

# Move output back to new output directory in projects directory

printf "\nCopying output files back to projects directory\n"

cp -r ${SLURM_TMPDIR}/outfastq/* ${out_dir_stem}/${out_dir_leaf}

printf "\nScript complete\n"

# Move and copy log file to output directory and log archive

cp ${init_wd}/${logfilename} ${init_wd}/saved_logs
mv ${init_wd}/${logfilename} ${out_dir_stem}/${logfilename}

