#!/bin/bash

#SBATCH --time=0-01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --job-name="08_merge_vcfs.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL 

# Set jobtime so dates on different outputs from the job will match

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

# Set filename of this file so contents can be printed in job output

this_filename='08_merge_vcfs.sub.sh'

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
picard/3.1.0

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files

in_vcf_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/filtered_vcfs/'
in_vcf_dir='2025-Oct-09_11-19-15'
in_vcf_prefix='comb_vcf_filtered'

dict_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras/'
dict_name='GW2022ref.dict'

out_vcf_name='all_individuals_all_sections_filtered.vcf.gz'

out_dir_path='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/merged_vcf'

# Copy input files to temp node local directory

printf "\nCopying input vcfs to node local storage\n"
cp ${in_vcf_path}/${in_vcf_dir}/${in_vcf_prefix}* ${SLURM_TMPDIR}

printf "\nThe files in SLURM_TMPDIR are:\n"
echo $(ls ${SLURM_TMPDIR})

# Make node local output directory to copy back later

mkdir ${SLURM_TMPDIR}/${jobtime}

# Run picard and write its output to the node local output file

cd ${SLURM_TMPDIR}

ls ${in_vcf_prefix}* > vcfs.list

java -jar $EBROOTPICARD/picard.jar \
MergeVcfs \
	I=vcfs.list \
	O=${jobtime}/${out_vcf_name} \
	D=${dict_path}/${dict_name}

# Move output back to new output directory in projects directory

printf "\nCopying output files back to projects directory\n"

mkdir ${out_dir_path}
cp -r ${SLURM_TMPDIR}/${jobtime} ${out_dir_path}

printf "\nScript complete\n"

