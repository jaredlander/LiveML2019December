library(dplyr)
library(purrr)
library(ggplot2)

list.files('data')
list.files('data', pattern='^Comp_')
list.files('data', pattern='^Comp_', full.names=TRUE)

comps <- list.files('data', pattern='^Comp_', full.names=TRUE) %>% 
    map_df(readr::read_csv)

glimpse(comps)

library(rsample)

set.seed(7615)
data_split <- initial_split(data=comps, prop=0.8, strata='SalaryCY')
data_split

train <- training(data_split)
test <- testing(data_split)
