# set options
options("width" = 150)
# options(table_counter = TRUE)
# options(figure_counter = TRUE)
# options(tibble.print_max = 10, tibble.print_min = 6)

# load packages
suppressWarnings(suppressMessages(library(rmarkdown)))
suppressWarnings(suppressMessages(library(knitcitations)))
suppressWarnings(suppressMessages(library(knitr)))
suppressWarnings(suppressMessages(library(AMMonitor)))
suppressWarnings(suppressMessages(library(RSQLite)))
suppressWarnings(suppressMessages(library(knitr)))
suppressWarnings(suppressMessages(library(AMModels)))
suppressWarnings(suppressMessages(library(rmarkdown)))
suppressWarnings(suppressMessages(library(tidyverse)))
suppressWarnings(suppressMessages(library(taxize)))
suppressWarnings(suppressMessages(library(sp)))
suppressWarnings(suppressMessages(library(raster)))
suppressWarnings(suppressMessages(library(rdrop2)))
suppressWarnings(suppressMessages(library(soundecology)))
suppressWarnings(suppressMessages(library(RPresence)))


# set knit options
opts_knit$set(out.format = 'markdown', fig_caption = TRUE)

opts_knit$set(base.dir = './', out.format = 'markdown', fig_caption = TRUE)


# set default chunk options
opts_chunk$set(prompt = FALSE,  # testing prompt = FALSE & comment = 
               warning = FALSE,
               echo = TRUE,
               eval = TRUE,
               comment = '##', # testing prompt = FALSE & comment = 
               eval = TRUE,
               fig.align = "left",
               dev = 'png',
               dev.args = list(type = "cairo"),
               dpi = 700,
               highlight = TRUE)


# set the font for figures created in R
par(family = "serif")



