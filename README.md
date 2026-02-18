# GBS-process

This is a set of submit scripts created by Caleigh Charlebois to streamline
Darren Irwin's GBS processing protocol to use GATK version on the Fir cluster
from Digital Research Alliance of Canada. This cluster uses SLURM for job
scheduling. 

These scripts are based on those prepared by Darren Irwin and used in this 
publication: Irwin D, Bensch S, Charlebois C, David G, Geraldes A, Gupta SK, 
Harr B, Holt P, Irwin JH, Ivanitskii VV, Marova IM, Niu Y, Seneviratne S, 
Singh A, Wu Y, Zhang S, Price TD. The Distribution and Dispersal of Large 
Haploblocks in a Superspecies. Mol Ecol. 2025 Nov;34(21):e17731. doi: 
10.1111/mec.17731. Epub 2025 Mar 17. PMID: 40091860; PMCID: PMC12573742.

The version of the scripts from that publication can be found in the file
"GW_haploblocks_processing_scripts_Irwinetal2025.txt" which can be downloaded
from Dryad at https://datadryad.org/dataset/doi:10.5061/dryad.8w9ghx3xr.

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
submitted, to avoid the output from one run overwriting another.
- The scripts work by copying input files to temporary storage on the compute
nodes, which has some advantages and is recommended by the Digital Research
Alliance of Canada. However, this does mean that incomplete jobs sometimes
don't copy any results back, and it can make troubleshooting more challenging.
- In array jobs, all of the jobs will wait for the job with the lowest array
ID to begin because tools/array_job_prologue.sh programs the lowest array
to generate a shared jobtime variable that is constant across the outputs. 

# Script Descriptions

## 00_download.sub.sh 
This script uses SRA toolkit to download data from the Sequence Read Archive
directly to your chosen output directory. It is an array job with one
member of the array for each accession, so the downloads happen concurrently.
The "#SBATCH --array=" SLURM parameter should be set 1-N, with N being the
number of accessions you list to download. The accessions at the "# Create 
variables with paths and names of input and output files" section should be
replaced with the ones you want to download. 

## 01_demultiplex.sub.sh
This script demultiplexes raw read data using the script located at 
tools/GBS_demultiplexer_30base.pl, which is a demultiplexer script originally 
designed by Greg Baute. Inputs are the barcodes, a list of accession 
directories to run the array members on, a forward read fastq file, and a 
reverse read fastq file. Like in the prior step, "#SBATCH --array=" should be
equal to 1-N, with N being the number of accessions you want to demultiplex 
data from. This is so that you can run a single submit script to simultaneously
demultiplex multiple plates downloaded with "00_download.sub.sh". If you only 
need to run it on a single plate, you can just make that list of accessions
have a single member and include "#SBATCH --array=1". 

## 02_trim.sub.sh
-------------------------------------------------------------------------------

## 03_align_combine.sub.sh


## 04_call_genotypes.sub.sh


## 05_create_interval_lists.sh

## 06_combine_individual_gvcfs.sub.sh

## 07_merge_contig_batch_vcfs.sub.sh

## 08_filter_sites.sub.sh

# Other File Descriptions

## tools/GBS_demultiplexer_30base.pl

## tools/array_job_prologue.sh

## tools/create_interval_lists.jl

## tools/vcf2maxhet.pl

## tools/vcf2minmq.pl

