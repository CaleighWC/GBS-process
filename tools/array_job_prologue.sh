# Synchronize jobtime and name logs more clearly for array jobs
# Also print scripts submitted with job to logs

tmp_jobtime_file="setting_${SLURM_ARRAY_JOB_ID}_jobtime.sh"
jobtime_file="${SLURM_ARRAY_JOB_ID}_jobtime.sh"

init_wd=$(pwd)
printf "\nThe initial working directory is ${init_wd}"

# The following should only run for the first job in the array

if [ "$SLURM_ARRAY_TASK_ID" = "$SLURM_ARRAY_TASK_MIN" ]; then

        # Set jobtime so dates on different outputs from the job will match

        jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

        # Write jobtime file
        printf 'jobtime="%s"\n' "${jobtime}" > "${scratchpath}/${tmp_jobtime_file}"
        printf "\n Leader wrote file: ${scratchpath}/${tmp_jobtime_file}"
        ls -l "${scratchpath}"

        printf "\n Leader moving file to final dest: ${scratchpath}/${jobtime_file}"
        mv ${scratchpath}/${tmp_jobtime_file} ${scratchpath}/${jobtime_file}
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

# Move log file to have jobtime and match other array tasks
logfilename="job_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}_${jobtime}.out"
mv job_${SLURM_JOB_ID}.out ${logfilename}

# Print some helpful variables and record state of submit script
printf "The jobtime is ${jobtime}.\n"

printf "\nThe SLURM Job ID is ${SLURM_JOB_ID}\n"

printf "\nThe SLURM Array Job ID is ${SLURM_ARRAY_JOB_ID}"

printf "\nThe SLURM Array Task ID is ${SLURM_ARRAY_TASK_ID}"

printf "\nThe submit script for the job is printed below:\n"
printf "_______________________________________________\n"

cat ${this_filename}

printf "\n_____________________________________________"
printf "\nThat concludes the submit script for the job.\n"

printf "\nThe prologue script for the job is printed below:\n"
printf "_______________________________________________\n"

cat ${prologue_filename}

printf "\n_____________________________________________"
printf "\nThat concludes the prologue script for the job.\n"

