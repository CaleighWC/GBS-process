#!/bin/bash

#SBATCH --time=10:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --job-name="03_align_combine.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL 

# Set jobtime so dates on different outputs from the job will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

# Set filename of this file so contents can be printed in job output

this_filename='03_align_combine.sub.sh'

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
picard/3.1.0 \
samtools/1.22.1 \
bwa/0.7.18

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files

barcodespath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras'
barcodesname='barcodes_CaleighWC_Jun_9_2025_data.txt'

cleandatatrimpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/clean_data_trim'
cleandatatrimname='2025-Aug-15_14-04-40'

genomepath='/home/cwcharle/projects/def-dirwin/cwcharle/gw2022_data/'
genomename='GW2022ref.fa'

dataname='GBS_Jun_9_2025_clean_'

outlistpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras'
outlistname="prefix.list.${dataname}.bwa"

out_dir_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/sam_bam/'

# Create extra variables for scripts

sam="${SLURM_TMPDIR}/${jobtime}/sam"
bam="${SLURM_TMPDIR}/${jobtime}/bam"
lane="GBS_Jun_9_2025"
runbarcode="GBS_Jun_9_2025"
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
-t 16 \
${genomename} \
${cleandatatrimname}/"$prefix"_R1.fastq \
${cleandatatrimname}/"$prefix"_R2.fastq \
>$sam/"$prefix".sam

bwa mem \
-M \
-t 16 \
${genomename} \
${cleandatatrimname}/"$prefix"_R1_unpaired.fastq \
>$sam/"$prefix".R1.unpaired.sam

bwa mem \
-M \
-t 16 \
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

cp -r ${SLURM_TMPDIR}/${jobtime} ${out_dir_path}

printf "\nScript complete\n"

