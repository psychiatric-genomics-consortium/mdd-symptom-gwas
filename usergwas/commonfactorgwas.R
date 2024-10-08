# Common factor GWAS

library(GenomicSEM)

# get task number and max task number
k <- as.numeric(Sys.getenv("SGE_TASK_ID"))
max_tasks <- as.numeric(Sys.getenv("SGE_TASK_LAST"))

cat(paste("Running task", k, " of ", max_tasks, "\n"))

args <- commandArgs(TRUE)

prefix <- args[1]

covstruct_prefix <- paste(prefix, 'covstruct', sep='.')
sumstats_prefix <- paste(prefix, 'sumstats', sep='.')
gwas_prefix <- paste(prefix, 'sumstats', sep='.')

covstruct_r <- here::here('ldsc', paste(covstruct_prefix, 'deparse.R', sep='.'))
covstruct_rds <- here::here('ldsc', paste(covstruct_prefix, 'rds', sep='.'))
sumstats_rds <- here::here('sumstats', paste(sumstats_prefix, 'rds', sep='.'))
gwas_rds <- here::here('meta', 'usergwas', gwas_prefix, paste(gwas_prefix, k, 'rds', sep='.'))

dir.create(dirname(gwas_rds), showWarnings=FALSE)

symptoms_covstruct <- dget(covstruct_r)

symptoms_sumstats <- readRDS(sumstats_rds)

# get subset of SNPs to analyze in this task
nsnps <- nrow(symptoms_sumstats)
snps_per_task <- ceiling(nsnps / max_tasks)

# index of task IDs repeated for number of SNPs per ask, clip the last task
# to the actual number of snps

task_allocations <- rep(1:max_tasks, each=snps_per_task)[seq.int(nsnps)]

SNPs <- symptoms_sumstats[which(task_allocations == k),]

rm(symptoms_sumstats)

symptoms_gwas <- commonfactorGWAS(covstruc=symptoms_covstruct,
						 SNPs=SNPs,
						 smooth_check=TRUE,
                         parallel=TRUE,
						 cores=8)
				 
saveRDS(symptoms_gwas, gwas_rds)