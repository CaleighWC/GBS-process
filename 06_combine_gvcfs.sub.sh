#!/bin/bash

#SBATCH --time=0-01:00:00
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

# Setting initial variables

scratchpath="/home/cwcharle/scratch"

jobtime_file="${SLURM_ARRAY_JOB_ID}_jobtime.sh"

# The following should only run for the first job in the array

if [ "$SLURM_ARRAY_TASK_ID" = "$SLURM_ARRAY_TASK_MIN" ]; then
	
	# Set jobtime so dates on different outputs from the job will match

	jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

	# Move output file to have jobtime in it
	mv job_${SLURM_JOB_ID}.out job_${SLURM_JOB_ID}_${jobtime}.out

	# Write jobtime file
	printf 'jobtime="%s"\n' "${jobtime}" > "${scratchpath}/${jobtime_file}"
	printf "\n Leader writing file: ${scratchpath}/${jobtime_file}"
	ls -l "${scratchpath}"

fi

# The rest of the script which runs for all jobs waits until the file is created
# This means in the other jobs created by the array, nothing will
# happen until the first job has made the jobtime available

printf "Waiting for shared jobtime file to exist\n"

printf "Follower checking: ${scratchpath}/${jobtime_file}" 
ls -l ${scratchpath}

until [ -f "${scratchpath}/${jobtime_file}" ]; do

	echo "Still waiting..."

	sleep 10

done

# Get jobtime from file created by first so all jobs agree on the jobtime

source ${scratchpath}/${jobtime_file}

printf "The jobtime is ${jobtime}\n"

# Set filename of this file so contents can be printed in job output

this_filename='06_combine_gvcfs.sub.sh'

# Move output file to have jobtime in it

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

intervallistspath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/interval_lists/2025-Oct-02_14-20-40'
intervallistsmanifest='lists_manifest.txt'

dataname='GBS_Jun_9_2025_clean_'

out_dir_path="/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/combined_vcfs/combined_vcfs/${jobtime}"

genomicsdb_out_name="genomicsdb_${SLURM_ARRAY_TASK_ID}"

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

# Change working directory to the temporary directory on the node

printf "\nChanging working directory to SLURM_TMPDIR\n"
cd ${SLURM_TMPDIR}

# Make list of individuals for which gvcfs exist

printf "\nCreating a variable with the list of all individuals for which gvcf files exist"

gvcflist=$(printf -- " -V %s" "${gvcfsname}"/*vcf)

printf "\nBelow is the list of all individuals for which gvcf files exist\n"
printf "\n----------------------------\n"
echo ${gvcflist}
printf "\n----------------------------\n"
printf "\nThat concludes the list of all individuals for which gvcf files exist\n"

# Run the tools and write their output to the node local output file

printf "\nAttempting to begin running gatk to create combined vcf file\n"

interval_file=${intervallistspath}/$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${intervallistspath}/${intervallistsmanifest}")

gatk \
--java-options \
'-DGATK_STACKTRACE_ON_USER_EXCEPTION=true -Xmx60g -Xms60g' \
GenomicsDBImport \
--tmp-dir ${SLURM_TMPDIR} \
${gvcflist} \
--genomicsdb-workspace-path ${genomicsdb_out_name} \
--intervals ${interval_file}

printf "\nfinished running gatk\n"

printf "\nThe files in SLURM_TMPDIR are now\n"
echo $(ls ${SLURM_TMPDIR})

# Move output back to new output directory in projects directory

printf "\nCopying final output file back to projects directory\n"

cp -r ${SLURM_TMPDIR}/${genomicsdb_out_name} ${out_dir_path}

printf "\nScript complete\n"

