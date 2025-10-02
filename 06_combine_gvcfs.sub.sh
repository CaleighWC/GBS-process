#!/bin/bash

#SBATCH --time=00:05:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=64G
#SBATCH --job-name="05_combine_gcfs.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL 

# Set jobtime so dates on different outputs from the job will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

# Set filename of this file so contents can be printed in job output

this_filename='05_combine_gvcfs.sub.sh'

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
gatk/4.6.1.0

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files

gvcfspath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/gvcf'
gvcfsname='2025-Aug-21_11-57-57'

genomepath='/home/cwcharle/projects/def-dirwin/cwcharle/gw2022_data/'
genomename='GW2022ref.fa'

genomeindexpath="${genomepath}"
genomeindexname='GW2022ref.fa.fai'

genomedictpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras'
genomedictname='GW2022ref.dict'

dataname='GBS_Jun_9_2025_clean_'

out_dir_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/combined_vcfs/'

# Copy input files to temp node local directory

printf "\nCopying gvcfs to node local storage\n"
cp -r ${gvcfspath}/${gvcfsname} ${SLURM_TMPDIR}

printf "\nCopying reference genome to node local storage\n"
cp ${genomepath}/${genomename} ${SLURM_TMPDIR}

printf "\nCopying reference genome index to node local storage\n"
cp ${genomeindexpath}/${genomeindexname} ${SLURM_TMPDIR}

printf "\nCopying reference genome dict to node local storage\n"
cp ${genomedictpath}/${genomedictname} ${SLURM_TMPDIR}

printf "\nThe files in SLURM_TMPDIR are:\n"
echo $(ls ${SLURM_TMPDIR})

# Make node local output directory to copy back later

mkdir ${SLURM_TMPDIR}/${jobtime}
mkdir ${SLURM_TMPDIR}/${jobtime}/combined_vcfs
mkdir ${SLURM_TMPDIR}/${jobtime}/combined_vcfs_logs

printf "\nThe files in SLURM_TMPDIR are:\n"

printf "\nChanging working directory to SLURM_TMPDIR\n"
cd ${SLURM_TMPDIR}

# Make list of individuals for which gvcfs exist

printf "\nCreating a variable with the list of all individuals for which gvcf files exist"

ls -1 "${gvcfsname}"/*vcf > gvcflist.list

printf "\nBelow is the list of all individuals for which gvcf files exist\n"
printf "\n----------------------------\n"
cat gvcflist.list
printf "\n----------------------------\n"
printf "\nThat concludes the list of all individuals for which gvcf files exist\n"

# Run the tools and write their output to the node local output file

printf "\nAttempting to begin running gatk to create combined vcf file\n"

gatk \
--java-options '-DGATK_STACKTRACE_ON_USER_EXCEPTION=true' \
CombineGVCFs \
-R ${genomename} \
--verbosity INFO \
-V gvcflist.list \
-O ${jobtime}/combined_vcfs/${dataname}.whole_genome.vcf

printf "\nCopying output file from the first step back to projects directory\n"
cp ${SLURM_TMPDIR}/${jobtime}/combined_vcfs/${dataname}.whole_genome.vcf ${out_dir_path}

printf "\nAttempting to begin running gatk to genotype combined vcf\n"
gatk \
--java-options '-DGATK_STACKTRACE_ON_USER_EXCEPTION=true' \
CombineGVCFs \
-R ${genomename} \
--verbosity INFO \
-V ${jobtime}/combined_vcfs/${dataname}.whole_genome.vcf \
-O ${jobtime}/combined_vcfs/${dataname}.genotypes.SNPs_only.whole_genome.vcf

printf "\nfinished running gatk\n"

printf "\nThe files in SLURM_TMPDIR are now\n"
echo $(ls ${SLURM_TMPDIR})

# Move output back to new output directory in projects directory

printf "\nCopying final output file back to projects directory\n"

cp -r ${SLURM_TMPDIR}/${jobtime}/combined_vcfs/${dataname}.genotypes.SNPs_only.whole_genome.vcf ${out_dir_path}

printf "\nScript complete\n"

