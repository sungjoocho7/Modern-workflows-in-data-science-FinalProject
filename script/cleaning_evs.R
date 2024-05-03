## library
library(dplyr)
library(tidyr)
library(haven)
library(knitr)
library(ggplot2)
library(summarytools)
library(ggExtra)
library(texreg)
library(plotly)

## 1. Data Cleaning

# read data file (original dataset)
evs_origin <- read_sav("data/ZA7500_v5-0-0.sav")

# select variables of interest
evs_vars <- c("v72", "v80", "age", "v243_r", "v225", "country")
evs <- evs_origin[evs_vars]

# change variable names
names(evs)[names(evs) == "v243_r"] <- "edu"
names(evs)[names(evs) == "v225"] <- "sex"
names(evs)[names(evs) == "v72"] <- "child_suffer"
names(evs)[names(evs) == "v80"] <- "job_national"
nrow(evs)

# create country name variable
cntry_labels <- attributes(evs$country)$labels
evs$cntry <- names(cntry_labels)[match(evs$country, cntry_labels)]

# Clean sex
evs$sex <- factor(evs$sex, levels = c(1, 2), labels = c("Male", "Female"))

# Clean edu
evs$edu[evs$edu == 66] <- NA
evs$edu <- factor(evs$edu, levels = c(1, 2, 3), labels = c("lower", "medium", "higher"))

# outcome variables
evs$child_suffer <- as.numeric(evs$child_suffer)
evs$job_national <- as.numeric(evs$job_national)

# save cleaned data locally
saveRDS(evs, file = "data/evs.rds")







  