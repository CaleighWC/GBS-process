# GBS-process

This is a set of submit scripts created to modernize the Irwin lab GBS processing protocol to use GATK version on the Fir cluster from Digital Research Alliance of Canada. This cluster uses SLURM for job scheduling. 

# Things to Know

- The scripts all produce log files which stay in the original working directory (where the job was submitted from) until the script is completed, at which point they are moved to the output directory.
- Output folders are named with timestamps describing when the job was submitted, to avoid the output from one job overwriting another
