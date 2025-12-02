#!/bin/bash

#SBATCH --time=1-00:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --job-name="04_call_genotypes.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL 
#SBATCH --array=1-4

# Set jobtime so dates on different outputs from the job will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

# Set filename of this file so contents can be printed in job output

this_filename='04_call_genotypes.sub.sh'

# Set filename of prologue script

prologue_filename='tools/array_job_prologue.sh'

# Scratch path for prologue script

scratchpath='/home/cwcharle/scratch/'

# Source prologue script (creates jobtime and prints scripts to log)

source ${prologue_filename}

# Load modules for job

printf "\nCurrently loaded modules\n"
module list

printf "\nLoading modules for job\n"
module load \
StdEnv/2023 \
picard/3.1.0 \
gatk/4.6.1.0

printf "\nCurrently loaded modules\n"
module list

# Set important variables for job

max_procs=16
proc_count=0

# Create variables with paths and names of input and output files

main_in_out_dir="/home/cwcharle/scratch/GBS-process"

accessionlistpath="${main_in_out_dir}/00_downloads/2025-Oct-30_23-24-58/"
accessionlistname='accessionlist.txt' # Path to list of names / accessions for array to use

accession=$(sed -n ${SLURM_ARRAY_TASK_ID}p ${accessionlistpath}/${accessionlistname})

barcodespath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras/'
barcodesname="${accession}_barcodes.txt"

bampath="${main_in_out_dir}/03_align_combine/2025-Nov-13_10-21-30/${accession}/"
bamname='bam'

genomepath='/home/cwcharle/projects/def-dirwin/cwcharle/gw2022_data/'
genomename='GW2022ref.fa'

genomeindexpath="${genomepath}"
genomeindexname='GW2022ref.fa.fai'

outlistpath="/home/cwcharle/scratch/GBS-process/02_trimmed_fastqs/2025-Nov-06_11-36-22/${accession}"
outlistname="prefix.list.${accession}_.bwa"

outdictpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras/'
outdictname='GW2022ref.dict'

out_dir_path="${main_in_out_dir}/04_call_genotypes/${jobtime}/${accession}"

# Print accession to log
printf "\n The accession for this run is ${accession}\n"

# Make dict of reference

java -jar $EBROOTPICARD/picard.jar CreateSequenceDictionary \
REFERENCE=${genomepath}/${genomename} \
OUTPUT=${outdictpath}/${outdictname}

# Copy input files to temp node local directory

printf "\nCopying prefix list file to node local storage\n"
cp ${outlistpath}/${outlistname} ${SLURM_TMPDIR} 

printf "\nCopying bam files to node local storage\n"
cp -r ${bampath}/${bamname} ${SLURM_TMPDIR}

printf "\nCopying reference genome to node local storage\n"
cp ${genomepath}/${genomename} ${SLURM_TMPDIR}

printf "\nCopying reference genome index to node local storage\n"
cp ${genomeindexpath}/${genomeindexname} ${SLURM_TMPDIR}

printf "\nCopying dict to node local storage\n"
cp ${outdictpath}/${outdictname} ${SLURM_TMPDIR}

printf "\nThe files in SLURM_TMPDIR are:\n"
echo $(ls ${SLURM_TMPDIR})

# Make node local output directory to copy back later

mkdir ${SLURM_TMPDIR}/${jobtime}

# Run the tools and write their output to the node local output file

cd ${SLURM_TMPDIR}

printf "\nBeginning loop to run tools\n"

while read prefix

do

# Call genotypes with GATK

printf "\nAttempting to call genotypes for '$prefix'\n"

gatk HaplotypeCaller \
-R ${genomename} \
-I ${bamname}/"$prefix".combo.bam \
-ERC GVCF \
-O ${jobtime}/"$prefix".gvcf.vcf &

proc_count=$((proc_count+1))

# Check whether we've reached the maximum process limit and wait
if [[ $proc_count -ge $max_procs ]]; then
	wait
	proc_count=0
fi

printf "\nCalling genotypes for '$prefix' complete\n"

# Complete loop

done < ${outlistpath}/${outlistname}

# Make sure all processes finish
wait

printf "\nfinished running tools\n"

printf "\nThe files in SLURM_TMPDIR are now\n"
echo $(ls ${SLURM_TMPDIR})

# Move output back to new output directory in projects directory

printf "\nCopying output files back to projects directory\n"

mkdir -p ${out_dir_path}

cp -r ${SLURM_TMPDIR}/${jobtime}/* ${out_dir_path}

# Move and copy log file to output directory and log archive

cp ${init_wd}/${logfilename} ${init_wd}/saved_logs
mv ${init_wd}/${logfilename} ${out_dir_path}/${logfilename}

printf "\nScript complete\n"

