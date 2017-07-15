library(ncdf4)
library(ggplot2)

args = commandArgs(trailingOnly=TRUE)

targetdir <- args[1]
basename <- args[2]
variable <- args[3]
region <- args[4]

nc <- nc_open(file.path(targetdir, paste0(basename, ".nc4")))
data <- ncvar_get(nc, variable)
regions <- ncvar_get(nc, 'regions')
year <- ncvar_get(nc, 'year')
nc_close(nc)

series <- data[regions == which(regions == region),]

png(filepath(targetdir, "cache", paste0(paste(basename, variable, region, sep='.'), '.nc4')), width=600, height=400)
ggplot(data.frame(year, series), aes(year, series)) +
    geom_smooth(se=F, span=.1) +
    geom_hline(yintercept=0, size=.3) + scale_x_continuous(expand=c(0, 0), limits=c(2005, 2099)) +
    xlab("") + ylab("Heat and cold deaths per 100,000 per year") +
    ggtitle(paste("Comparison of mortality impacts by assumption, ", region)) +
    theme_bw() + theme(legend.justification=c(0,1), legend.position=c(0,1))
dev.off()

