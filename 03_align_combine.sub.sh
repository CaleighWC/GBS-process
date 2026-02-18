#!/bin/bash

#SBATCH --time=1-10:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --job-name="03_align_combine.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL 
#SBATCH --array=1-4

# Set jobtime so dates on different outputs from the job will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

# Set filename of this file so contents can be printed in job output

this_filename='03_align_combine.sub.sh'

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
samtools/1.22.1 \
bwa/0.7.18

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files

main_in_out_dir="/home/cwcharle/scratch/GBS-process"

accessionlistpath="${main_in_out_dir}/00_downloads/2025-Oct-30_23-24-58/"
accessionlistname='accessionlist.txt' # Path to list of names / accessions for array to use

accession=$(sed -n ${SLURM_ARRAY_TASK_ID}p ${accessionlistpath}/${accessionlistname})

barcodespath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras/'
barcodesname="${accession}_barcodes.txt"

cleandatatrimpath='/home/cwcharle/scratch/GBS-process/02_trimmed_fastqs/2025-Nov-06_11-36-22'
cleandatatrimname="${accession}"

genomepath='/home/cwcharle/projects/def-dirwin/cwcharle/gw2022_data/'
genomename='GW2022ref.fa'

outlistpath="/home/cwcharle/scratch/GBS-process/02_trimmed_fastqs/2025-Nov-06_11-36-22/${accession}"
outlistname="prefix.list.${accession}_.bwa"

out_dir_path="/home/cwcharle/scratch/GBS-process/03_align_combine/${jobtime}/${accession}"

# Print accession to log
printf "\n The accession for this run is ${accession}\n"

# Create extra variables for scripts

sam="${SLURM_TMPDIR}/${jobtime}/sam"
bam="${SLURM_TMPDIR}/${jobtime}/bam"
lane="${accession}"
runbarcode="${accession}"
log="log"

# Copy input files to temp node local directory as input

printf "\nCopying prefix list file to node local storage\n"
cp ${outlistpath}/${outlistname} ${SLURM_TMPDIR} 

printf "\nCopying cleaned trimmed data to node local storage\n"
cp -r ${cleandatatrimpath}/${cleandatatrimname} ${SLURM_TMPDIR}

printf "\nCopying reference genome to node local storage\n"
cp ${genomepath}/${genomename} ${SLURM_TMPDIR}

printf "\nThe files in SLURM_TMPDIR are:\n"
echo $(ls ${SLURM_TMPDIR})

# Make node local output directory to copy back later

mkdir ${SLURM_TMPDIR}/${jobtime}
mkdir ${SLURM_TMPDIR}/${jobtime}/sam
mkdir ${SLURM_TMPDIR}/${jobtime}/bam

# Index the fasta file

cd ${SLURM_TMPDIR}

printf "\nIndexing the fasta file\n"
bwa index ${genomename}

printf "\nThe files in SLURM_TMPDIR are:\n"

# Run the tools and write their output to the node local output file

printf "\nBeginning loop to run tools\n"

while read prefix

do

# align to reference with bwa

printf "\nAttempting to run bwa on '$prefix'\n"

bwa mem \
-M \
-t 32 \
${genomename} \
${cleandatatrimname}/"$prefix"_R1.fastq \
${cleandatatrimname}/"$prefix"_R2.fastq \
>$sam/"$prefix".sam

bwa mem \
-M \
-t 32 \
${genomename} \
${cleandatatrimname}/"$prefix"_R1_unpaired.fastq \
>$sam/"$prefix".R1.unpaired.sam

bwa mem \
-M \
-t 32 \
${genomename} \
${cleandatatrimname}/"$prefix"_R2_unpaired.fastq \
>$sam/"$prefix".R2.unpaired.sam

printf "\nbwa on '$prefix' complete\n"

# Add read group headers, convert to bam, sort and index with picard
printf "\nattempting to run Picard on '$prefix'"

java -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups \
I=$sam/"$prefix".sam \
O=$bam/"$prefix".bam \
RGID=${lane} \
RGPL=ILLUMINA \
RGLB=LIB."$prefix" \
RGSM="$prefix" \
RGPU="$runbarcode" \
SORT_ORDER=coordinate \
CREATE_INDEX=TRUE

java -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups \
I=$sam/"$prefix".R1.unpaired.sam \
O=$bam/"$prefix".R1.unpaired.bam \
RGID=${lane} \
RGPL=ILLUMINA \
RGLB=LIB."$prefix" \
RGSM="$prefix" \
RGPU="$runbarcode" \
SORT_ORDER=coordinate \
CREATE_INDEX=TRUE

java -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups \
I=$sam/"$prefix".R2.unpaired.sam \
O=$bam/"$prefix".R2.unpaired.bam \
RGID=${lane} \
RGPL=ILLUMINA \
RGLB=LIB."$prefix" \
RGSM="$prefix" \
RGPU="$runbarcode" \
SORT_ORDER=coordinate \
CREATE_INDEX=TRUE

printf "Picard on '$prefix' complete"

# Merge se and pe bam files with samtools and index
printf "\nattempting to run samtools on '$prefix'\n"

samtools merge \
$bam/"$prefix".combo.bam \
$bam/"$prefix".bam \
$bam/"$prefix".R1.unpaired.bam \
$bam/"$prefix".R2.unpaired.bam

samtools index \
$bam/"$prefix".combo.bam

printf "\nSamtools on '$prefix' completed\n"

# complete loop

done < ${outlistpath}/${outlistname}

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

