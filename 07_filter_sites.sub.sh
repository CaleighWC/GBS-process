#!/bin/bash

#SBATCH --time=0-05:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=64G
#SBATCH --job-name="06_combine_gvcfs.sub.sh"
#SBATCH --account=def-dirwin
#SBATCH --output=job_%j.out
#SBATCH --mail-user=cwc@zoology.ubc.ca
#SBATCH --mail-type=ALL
#SBATCH --array=1-9

# NOTE: The array parameter must be manually set above to the correct
# number matching the number of interval lists for the dataset!
# Above is one of 3 spots you need to add variables if you are running
# the script. ADD VARIABLES (1/3)

# Setting initial variables
# Below is the second spot you need to ADD VARIABLES (2/3)
# Scratchpath is just any directory on the shared filesystem where it's okay for
# the script to create a small temporary file that sets the same jobtime
# across the different jobs created by the array. The scratch directory
# on the cluster is fine. This file can be deleted safely after all
# members of the array are done running.

scratchpath="~/scratch"

this_filename="06_combine_gvcfs.sub.sh"

prologue_filename="tools/array_job_prologue.sh"

# Run prologue script to take care of some logging and synchronize jobtimes
# between members of the array
source ${prologue_filename}

# Load modules
printf "\nCurrently loaded modules\n"
module list

printf "\nLoading modules for job\n"
module load \
StdEnv/2023 \
gatk/4.6.1.0

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files
# This is the last spot where you need to ADD VARIABLES (3/3)

# The path where you would like the job output to be placed (ideally something generated unique to this run)
out_dir_path="/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/combined_vcfs/${jobtime}"

# The path and name of the genotyped vcf to use as input
vcf_in_path="/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/combined_vcfs/2025-Oct-07_19-09-41"
vcf_in_name="comb_vcf_${SLURM_ARRAY_TASK_ID}.vcf.gz"

# The name of the output filtered vcf
vcf_out_name="comb_vcf_filtered_${SLURM_ARRAY_TASK_ID}.vcf.gz"

# Copy input files to temp node local directory
# This makes reads/writes faster during the job

cp ${vcf_in_path}/${vcf_in_name} ${SLURM_TMPDIR}

printf "\nThe files in SLURM_TMPDIR are:\n"
echo $(ls ${SLURM_TMPDIR})

# Change working directory to the temp node local directory
# This is just so we can use smaller file paths and all outputs
# are generated on the node

printf "\nChanging working directory to SLURM_TMPDIR\n"
cd ${SLURM_TMPDIR}

# Remove indels and SNPs with more than two alleles

printf "\nRunning vcftools to remove indels and SNPs with more than two alleles\n"



printf "\nThe files in SLURM_TMPDIR are now\n"
echo $(ls ${SLURM_TMPDIR})

# Move output back to output directory in projects directory

printf "\nCopying final output file back to projects directory in ${out_dir_path}\n"

mkdir ${out_dir_path}

cp -r ${SLURM_TMPDIR}/${vcf_out_name} ${out_dir_path}/

printf "\n These are the files in the output directory\n"
ls ${out_dir_path}

printf "\n Moving logfile to the output folder \n"
${init_wd}
mv ${init_wd}/${logfilename} ${out_dir_path}

printf "\nScript complete\n"
