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






## 2. Descriptive Analysis

# 1) table for continuous variables
sum_v72 <- summary(evs$child_suffer)
sum_v80 <- summary(evs$job_national)
sum_age <- summary(evs$age)

tab_continuous <- tibble("Variables" = c("child_suffer", "job_national", "age"),
                         "Mininum" = c(sum_v72["Min."], sum_v80["Min."], sum_age["Min."]),
                         "1st Qu." = c(sum_v72["1st Qu."], sum_v80["1st Qu."], sum_age["1st Qu."]),
                         "Median" = c(sum_v72["Median"], sum_v80["Median"], sum_age["Median"]),
                         "Mean" = c(round(sum_v72["Mean"], 3), round(sum_v80["Mean"], 3), sum_age["Mean"]),
                         "3rd Qu." = c(sum_v72["3rd Qu."], sum_v80["3rd Qu."], sum_age["3rd Qu."]),
                         "Maximum" = c(sum_v72["Max."], sum_v80["Max."], sum_age["Max."]))

kable(tab_continuous, caption = "Summary Statistics for child_suffer and job_national")




evs_sex <- evs %>%
  group_by(sex) %>%
  summarise(frequency = n(),
            proportion = round(n()/nrow(evs), 4)) %>%
  mutate(variable = "sex",
         value = sex) %>%
  select(variable, value, frequency, proportion)

evs_edu <- evs %>%
  group_by(edu) %>%
  summarise(frequency = n(),
            proportion = round(n()/nrow(evs), 4)) %>%
  mutate(variable = "education",
         value = edu) %>%
  select(variable, value, frequency, proportion)

tab_categorical <- bind_rows(evs_sex, evs_edu)
kable(tab_categorical, caption = "Summary Statistics for sex and education")



## 3. Graphs

# table of average v72 and v80 by age
tab_ave_age <- evs %>%
  select(v72, v80, age) %>%
  group_by(age) %>%
  summarise(v72 = mean(v72, na.rm = TRUE),
            v80 = mean(v80, na.rm = TRUE))
tab_ave_age

# grraph for v72
chart_ave_v72 <- ggplot(tab_ave_age, aes(x=age, y=v72)) +
  geom_line(color = "blue") +
  labs(title = "Average Disagreement of v72 by Age", 
       x = "Age", 
       y = "Average Disagreement")
ggplotly(chart_ave_v72)

# save
ggsave("figs/chart_ave_v72.png", plot = chart_ave_v72)


# grraph for v80
chart_ave_v80 <- ggplot(tab_ave_age, aes(x=age, y=v80)) +
  geom_line(color = "blue") +
  labs(title = "Average Disagreement of v80 by Age", 
       x = "Age", 
       y = "Average Disagreement")
ggplotly(chart_ave_v80)

# save
ggsave("figs/chart_ave_v80.png", plot = chart_ave_v80)



## 4. Regression models

evs$edu <- as.factor(evs$edu)
evs$sex <- as.factor(evs$sex)

# regression model of v72
reg_v72 <- lm(v72 ~ age + I(age^2) + sex + edu, data = evs)

# regression model of v80
reg_v80 <- lm(v80 ~ age + I(age^2) + sex + edu, data = evs)

# present outputs from stats model texreg (texreg: pdf, htmlreg: html)
htmlreg(list(reg_v72, reg_v80), caption = "Outputs from Regression Models", type = "html")














  