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

# Set jobtime so dates on different outputs from the job will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

# Set filename of this file so contents can be printed in job output

this_filename='04_call_genotypes.sub.sh'

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

# Set important variables for job

max_procs=16
proc_count=0

# Create variables with paths and names of input and output files

barcodespath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras'
barcodesname='barcodes_CaleighWC_Jun_9_2025_data.txt'

bampath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/sam_bam/2025-Aug-20_07-59-56'
bamname='bam'

genomepath='/home/cwcharle/projects/def-dirwin/cwcharle/gw2022_data/'
genomename='GW2022ref.fa'

genomeindexpath="${genomepath}"
genomeindexname='GW2022ref.fa.fai'

dataname='GBS_Jun_9_2025_clean_'

outlistpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras/'
outlistname="prefix.list.${dataname}.bwa"

outdictpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras/'
outdictname='GW2022ref.dict'

out_dir_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/gvcf/'

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

cp -r ${SLURM_TMPDIR}/${jobtime} ${out_dir_path}

printf "\nScript complete\n"

