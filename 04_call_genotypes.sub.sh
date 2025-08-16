#!/bin/bash

#SBATCH --time=5:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
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
gatk/4.6.1.0

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files

barcodespath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras'
barcodesname='barcodes_CaleighWC_Jun_9_2025_data.txt'

bampath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/sam_bam/2025-Aug-16_12-15-01/'
bamname='bam'

genomepath='/home/cwcharle/projects/def-dirwin/cwcharle/gw2022_data/'
genomename='GW2022ref.fa'

dataname='GBS_Jun_9_2025_clean_'

outlistpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras/'
outlistname="prefix.list.${dataname}.bwa"

outindexpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras/'
outindexname='GW2022ref.dict'

out_dir_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/gvcf/'

# Make index of reference

java -jar $EBROOTPICARD/picard.jar CreateSequenceDictionary \
REFERENCE=${genomepath}/${genomename} \
OUTPUT=${outindexpath}/${outindexname}

# Copy input files to temp node local directory as input

printf "\nCopying prefix list file to node local storage\n"
cp ${outlistpath}/${outlistname} ${SLURM_TMPDIR} 

printf "\nCopying bam files to node local storage\n"
cp -r ${bampath}/${bamname} ${SLURM_TMPDIR}

printf "\nCopying reference genome to node local storage\n"
cp ${genomepath}/${genomename} ${SLURM_TMPDIR}

printf "\nCopying index to node local storage\n"
cp ${outindexpath}/${outindexname} ${SLURM_TMPDIR}

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

gatk \
-T HaplotypeCaller \
-R ${genomename} \
-I ${bamname}/"$prefix".combo.bam \
-ERC GVCF \
-o ${jobtime}/"$prefix".gvcf.vcf \
-variant_index_type LINEAR \
-variant_index_parameter 128000

printf"\Calling genotypes for '$prefix'\n complete"

# Complete loop

done < ${outlistpath}/${outlistname}

printf "\nfinished running tools\n"

printf "\nThe files in SLURM_TMPDIR are now\n"
echo $(ls ${SLURM_TMPDIR})

# Move output back to new output directory in projects directory

printf "\nCopying output files back to projects directory\n"

cp -r ${SLURM_TMPDIR}/${jobtime} ${out_dir_path}

printf "\nScript complete\n"

