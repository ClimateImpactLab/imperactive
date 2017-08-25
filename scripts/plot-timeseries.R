.libPaths(c(.libPaths(), "/home/jrising/R/x86_64-pc-linux-gnu-library/3.4"))

library(ncdf4)
library(ggplot2)

args = commandArgs(trailingOnly=TRUE)

directory_root <- '/shares/gcp/outputs'
destination <- args[1]
targetdir <- args[2]
region <- args[3]

if (region == 'global') {
  my.region <- ''
} else
  my.region <- region

df <- data.frame(year=c(), series=c(), label=c())
current.years <- NULL
current.series <- 0

for (term in args[4:length(args)]) {
    parts = strsplit(term, ':')[[1]]
    if ((parts[1] == 'STOP' || parts[1] == 'CONT') && !is.null(current.years)) {
        df <- rbind(df, data.frame(year=current.year, series=current.series, label=parts[2]))
        if (parts[1] == 'STOP') {
            current.years = NULL
	    current.series = 0
        }
    }

    basename <- parts[1]
    variable <- parts[2]

    nc <- nc_open(file.path(directory_root, targetdir, paste0(basename, ".nc4")))
    regions <- ncvar_get(nc, 'regions')
    years <- ncvar_get(nc, 'year')

    if (substr(variable, 1, 1) == '-') {
        data <- ncvar_get(nc, substr(variable, 2, nchar(variable)))
        series <- -data[which(regions == my.region),]
    } else {
        data <- ncvar_get(nc, variable)
        series <- data[which(regions == my.region),]
    }
    nc_close(nc)

    if (is.null(current.years) || all.equal(years, current.years) == T) {
        current.series <- current.series + series
        current.years = years
    }
}

if (!is.null(current.years))
    df <- rbind(df, data.frame(year=current.years, series=current.series, label="result"))

png(destination, width=600, height=400)
ggplot(df, aes(year, series, colour=label)) +
    geom_smooth(se=F, span=.1) +
    geom_hline(yintercept=0, size=.3) + scale_x_continuous(expand=c(0, 0), limits=c(2005, 2099)) +
    xlab("") + ylab("Heat and cold deaths per person per year") +
    ggtitle(paste("Mortality impacts for ", region)) +
    theme_bw() + theme(legend.justification=c(0,1), legend.position=c(0,1))
dev.off()
