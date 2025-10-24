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

scratchpath="/home/cwcharle/scratch"

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
gatk/4.6.1.0 \
picard/3.1.0

printf "\nCurrently loaded modules\n"
module list

# Create variables with paths and names of input and output files
# This is the last spot where you need to ADD VARIABLES (3/3)

# The path to directory and then the name of directory containing your individual gvcf files
gvcfspath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/gvcf'
gvcfsname='2025-Aug-21_11-57-57'

genomepath='/home/cwcharle/projects/def-dirwin/cwcharle/gw2022_data/'
genomename='GW2022ref.fa'

genomeindexpath="${genomepath}"
genomeindexname='GW2022ref.fa.fai'

# The path to directory containing your .dict file and then name of .dict file
genomedictpath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/extras'
genomedictname='GW2022ref.dict'

# The path to directory containing the interval lists and then filename of manifest
intervallistspath='/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/interval_lists/2025-Oct-02_14-20-40'
intervallistsmanifest='lists_manifest.txt'

# The path where you would like the job output to be placed (ideally something generated unique to this run)
out_dir_path="/home/cwcharle/projects/def-dirwin/cwcharle/GBS-process/combined_vcfs/${jobtime}"

# The name of the genomicsdb workspace
genomicsdb_out_name="genomicsdb_${SLURM_ARRAY_TASK_ID}"

# The name of the genotyped combined vcf, should contain task ID to avoid overwriting
vcf_out_name="all_individuals_section_${SLURM_ARRAY_TASK_ID}.vcf.gz"

# Copy input files to temp node local directory
# This makes reads/writes faster during the job

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

# Change working directory to the temp node local directory
# This is just so we can use smaller file paths and all outputs
# are generated on the node

printf "\nChanging working directory to SLURM_TMPDIR\n"
cd ${SLURM_TMPDIR}

# Make list of individuals for which gvcfs exist
# We are reading all the files ending in vcf in the directory given
# earlier and turning it into a variable with "-V" printed before 
# each one. I like this because it will automatically get the names
# from the headers, whereas when you provide a sample map you are
# providing the names.

printf "\nCreating a variable with the list of all individuals for which gvcf files exist"

gvcflist=$(printf -- " -V %s" "${gvcfsname}"/*vcf)

printf "\nBelow is the list of all individuals for which gvcf files exist\n"
printf "\n----------------------------\n"
echo ${gvcflist}
printf "\n----------------------------\n"
printf "\nThat concludes the list of all individuals for which gvcf files exist\n"

# Run gatk and write output to the output file specified earlier
# The correct interval list file will be chosen by reading the line
# in the manifest corresponding to this task ID in the array. 

printf "\nRunning gatk to create combined genomicsDB database file\n"

interval_file=${intervallistspath}/$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${intervallistspath}/${intervallistsmanifest}")

gatk \
--java-options \
'-DGATK_STACKTRACE_ON_USER_EXCEPTION=true -Xmx60g -Xms60g' \
GenomicsDBImport \
	--tmp-dir ${SLURM_TMPDIR} \
${gvcflist} \
	--genomicsdb-workspace-path ${genomicsdb_out_name} \
	--intervals ${interval_file}

printf "\nfinished running gatk GenomicsDBImport\n"

printf "\nThe files in SLURM_TMPDIR are now\n"
echo $(ls ${SLURM_TMPDIR})

printf "\nRunning gatk to genotype combined genomicsDB database file\n"
gatk \
--java-options \
'-DGATK_STACKTRACE_ON_USER_EXCEPTION=true -Xmx60g -Xms60g' \
GenotypeGVCFs \
	-R ${genomename} \
	-V gendb://${genomicsdb_out_name} \
	-O ${vcf_out_name}.unsorted

printf "\nThe files in SLURM_TMPDIR are now\n"
echo $(ls ${SLURM_TMPDIR})

# Sort output file to prevent downstream problems
printf "\nRunning picard to sort output vcf\n"

java -jar $EBROOTPICARD/picard.jar \
SortVcf \
	I=${vcf_out_name}.unsorted \
	O=${vcf_out_name} \
	SD=${genomedictname}

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
