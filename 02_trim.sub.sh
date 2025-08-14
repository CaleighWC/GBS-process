#!/bin/bash

#SBATCH --time=5:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --job-name="02_trim.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL 

# Set jobtime so dates on different outputs from the job will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

# Set filename of this file so contents can be printed in job output

this_filename='02_trim.sub.sh'

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
trimmomatic/0.39

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files

barcodespath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras'
barcodesname='barcodes_CaleighWC_Jun_9_2025_data.txt'

cleandatapath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/clean_data'
cleandataname=''

dataprefix='CWC_Jun_9_2025'

outlistpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras'
outlistname='prefix.list.${dataprefix}.bwa'

out_dir_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/clean_data_trim/'

# Make list of individuals from the barcode file

awk '{print "${dataprefix}"$1}' ${barcodespath}/${barcodesname} > ${outlistpath}/${outlistname}

# Copy input files to temp node local directory as input and make working directory

printf "\nCopying prefix list file to node local storage\n"
cp ${outlistpath}/${outlistname} ${SLURM_TMPDIR} 

printf "\nCopying cleaned data to node local storage\n"
cp ${fq1path}/${fq1name} ${SLURM_TMPDIR}

printf "\nThe files in SLURM_TMPDIR are:\n"
echo $(ls ${SLURM_TMPDIR})

# Make node local output directory to copy back later

mkdir ${SLURM_TMPDIR}/${jobtime}

# Run the trimmomatic tool and write its output to the node local output file

cd ${SLURM_TMPDIR}

printf "\nAttempting to run trimmomatic\n"

while read prefix

do

java -jar $EBROOTTRIMMOMATIC/trimmomatic-0.39.jar \
PE \
-phred33 \
-threads 1 \
${cleandatapath}/"$prefix"_R1.fastq \
${cleandatapath}/"$prefix"_R2.fastq \
${jobtime}/"$prefix"_R1.fastq \
${jobtime}/"$prefix"_R1_unpaired.fastq \
${jobtime}/"$prefix"_R2.fastq \
${jobtime}/"$prefix"_R2_unpaired.fastq \
TRAILING:3 \
SLIDINGWINDOW:4:10 \
MINLEN:30

done < ${outlistpath}/${outlistname}

printf "\nfinished running trimmomatic\n"

printf "\nThe files in SLURM_TMPDIR are now\n"
echo $(ls ${SLURM_TMPDIR})

# Move output back to new output directory in projects directory

printf "\nCopying output files back to projects directory\n"

cp -r ${SLURM_TMPDIR}/${jobtime} ${out_dir_path}

printf "\nScript complete\n"

