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

# y ~ x
# outcome ~ input
# response ~ predictor
# label ~ data

# Output: outcome, y, response, label, target
# Input: x, features, data, covariates, predictors
sal1 <- lm(SalaryCY ~ Region + Title + Years + Reports + Career + Floor,
           data=train)
sal1
summary(sal1)

library(coefplot)
coefplot(sal1, sort='magnitude')
plotly::ggplotly(coefplot(sal1, sort='magnitude'))


sal2 <- lm(SalaryCY ~ Region + Title + Years + Reports + Career + Floor,
           data=train,
           subset=Title != 'MD')
coefplot(sal2, sort='magnitude')


sal3 <- lm(log10(SalaryCY) ~ Region + Title + scale(Years) + scale(Reports) + 
               Career + scale(Floor),
           data=train)
coefplot(sal3, sort='magnitude')

ggplot(train, aes(x=Years, fill=Title)) + 
    geom_histogram()

ggplot(train, aes(x=Reports, fill=Title)) + 
    geom_histogram()

ggplot(train, aes(x=Floor, fill=Title)) + 
    geom_histogram()

# Feature Engineering ####

library(recipes)

sal_rec <- recipe(SalaryCY ~ Region + Title + Years + Reports + Career + Floor, 
       data=train) %>% 
    step_log(SalaryCY, base=10) %>% 
    step_zv(all_predictors()) %>% 
    step_nzv(all_predictors()) %>% 
    step_knnimpute(all_predictors()) %>% 
    step_BoxCox(all_numeric(), -SalaryCY) %>% 
    # step_center(all_numeric(), -SalaryCY) %>% 
    # step_scale(all_numeric(), -SalaryCY) %>% 
    step_normalize(all_numeric(), -SalaryCY) %>% 
    step_other(all_nominal(), other='Misc') %>% 
    step_dummy(all_nominal())

sal_prepped <- sal_rec %>% prep()
sal_prepped

sal_train <- sal_prepped %>% juice()
sal_train

sal4 <- lm(SalaryCY ~ ., data=sal_train)
coefplot(sal4, sort='magnitude')
