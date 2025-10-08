# Prologue file for QOL improvements on single-job submissions
# This should be sourced from the submit scripts, not run on its own

# Set jobtime (shared time identifier for outputs of job)
printf "\nSetting jobtime so dates on different outputs from job will match\n"

jobtime=$(date "+%Y-%b-%d_%H-%M-%S")

printf "\nJobtime set as ${jobtime}.\n"

# Move log file to contain jobtime
printf "\nMoving log file to contain jobtime\n"

mv job_${SLURM_JOB_ID}.out job_${SLURM_JOB_ID}_${jobtime}.out

printf "\nLog file moved from job_${SLURM_JOB_ID}.out"
printf "\nto job_${SLURM_JOB_ID}_${jobtime}.out\n"

# Print scripts submitted with job

printf "\nThe submit script for this job is called ${this_filename}.\n"
printf "\nThe submit script for the job is printed below:\n"
printf "_______________________________________________\n"

cat ${this_filename}

printf "\n_____________________________________________"
printf "\nThat concludes the submit script for the job.\n"

printf "\nThe prologue script for the job is called ${prologue_filename}.\n"
printf "\nThe prologue script for the job is printed below:\n
"printf "_______________________________________________\n"

cat ${prologue_filename}

printf "\n_____________________________________________"
printf "\nThat concludes the prologue script for the job.\n"

printf "\nThe epilogue script for the job is called ${epilogue_filename}.\n"
printf "\nThe epilogue script for the job is printed below:\n
"printf "_______________________________________________\n"

cat ${epilogue_filename}

printf "\n_____________________________________________"
printf "\nThat concludes the epilogue script for the job.\n"
