library(dplyr)
library(purrr)
library(ggplot2)

# Read Data ####

list.files('data')
list.files('data', pattern='^Comp_')
list.files('data', pattern='^Comp_', full.names=TRUE)

comps <- list.files('data', pattern='^Comp_', full.names=TRUE) %>% 
    map_df(readr::read_csv)

glimpse(comps)

# Train and Test ####

library(rsample)

set.seed(7615)
data_split <- initial_split(data=comps, prop=0.8, strata='SalaryCY')
data_split

train <- training(data_split)
test <- testing(data_split)

# EDA ####

ggplot(train, aes(x=SalaryCY)) + geom_histogram()
ggplot(train, aes(x=SalaryCY, fill=Title)) + 
    geom_histogram()
ggplot(train, aes(x=SalaryCY, fill=Title)) + 
    geom_histogram() + 
    scale_x_log10()

# Linear Models ####

