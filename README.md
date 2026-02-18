# GBS-process

This is a set of submit scripts created by Caleigh Charlebois to streamline
Darren Irwin's GBS processing protocol to use GATK version on the Fir cluster
from Digital Research Alliance of Canada. This cluster uses SLURM for job
scheduling. 

# How to Use

1. Modify the SLURM parameters at the beginning of the script as appropriate.
You may need to change the walltime if your dataset is larger or smaller than
mine and you will definitely need to change the number of array jobs in most
steps to match the number of source files in your data.
3. Put the correct paths to your data in the "# Create variables with paths and
names of input files" section of the script. Often, the input path will be in
the output directory of a prior step. Don't forget to also make sure your
output directory is correct. Having the output directory in scratch is a good
idea to avoid accidentally taking up a lot of space. 

# What You Should Know

- The scripts all produce log files which stay in the original working
directory (where the job was submitted from) until the script is completed, at
which point the log files are moved to the output directory.
- Output folders are named with timestamps describing when the job was
submitted, to avoid the output from one run overwriting another
- The scripts work by copying input files to temporary storage on the compute
nodes, which has some advantages and is recommended by the Digital Research
Alliance of Canada. However, this does mean that incomplete jobs sometimes
don't copy any results back, and it can make troubleshooting more challenging.

-------------------------------------------------------------------------------
