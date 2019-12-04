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

multiplot(sal3, sal4, sort='magnitude', single=FALSE)
multiplot(sal3, sal4, sort='magnitude', single=TRUE, intercept=FALSE) + 
    facet_wrap(~Model, ncol=2, scales='free_y')

# glmnet ####

library(glmnet)

# lm: data.frame/tibble: lm(y ~ x, data=data.frame)
# glmnet: x/y matrices: glmnet(x=x_matrix, y=y_matrix)

sal_prepped
sal_x <- sal_prepped %>% juice(all_predictors(), composition='matrix')
head(sal_x)
sal_y <- sal_prepped %>% juice(SalaryCY, composition='matrix')
head(sal_y)

sal5 <- glmnet(x=sal_x, y=sal_y, family='gaussian', alpha=1, standardize=FALSE)
sal5 %>% coef() %>% as.matrix() %>% View()

plot(sal5, xvar='lambda')
plot(sal5, xvar='lambda', label=TRUE)

coefpath(sal5)
coefplot(sal5, sort='magnitude', lambda=exp(-6))
coefplot(sal5, sort='magnitude', lambda=exp(-10))
coefplot(sal5, sort='magnitude', lambda=exp(-2))

sal6 <- cv.glmnet(x=sal_x, y=sal_y,
                  family='gaussian', alpha=1,
                  standardize=FALSE,
                  nfolds=10)
plot(sal6)

coefplot(sal6, sort='magnitude', lambda='lambda.min')

sal7 <- cv.glmnet(x=sal_x, y=sal_y,
                  family='gaussian', alpha=0,
                  standardize=FALSE,
                  nfolds=10)
coefpath(sal7)

sal8 <- cv.glmnet(x=sal_x, y=sal_y,
                  family='gaussian', alpha=0.5,
                  standardize=FALSE,
                  nfolds=10)
coefpath(sal8)

test_x <- sal_prepped %>% 
    bake(all_predictors(), new_data=test, composition='matrix')
class(test_x)
head(test_x)

sal_preds_8 <- predict(sal8, newx=test_x, s='lambda.min')
head(sal_preds_8)

# lm(y ~ x, data)
# glmnet(x, y)
# xgb.train(xgb.DMatrix(x, y))

# Model Specifications ####

library(parsnip)

spec_lm <- linear_reg() %>% 
    set_engine('lm')
spec_lm
sal9 <- spec_lm %>% fit(SalaryCY ~ ., data=sal_train)
sal9

spec_glmnet <- linear_reg() %>% 
    set_engine('glmnet')
sal10 <- spec_glmnet %>% fit(SalaryCY ~ ., data=sal_train)
sal10

sal9 <- spec_lm %>% fit(SalaryCY ~ ., data=sal_train)
sal10 <- spec_glmnet %>% fit(SalaryCY ~ ., data=sal_train)

# linear_reg() %>% set_engine('stan') %>% fit(SalaryCY ~ ., data=sal_train)
# linear_reg() %>% set_engine('spark') %>% fit(SalaryCY ~ ., data=sal_train)
# linear_reg() %>% set_engine('keras') %>% fit(SalaryCY ~ ., data=sal_train)
 
logistic_reg() %>% set_engine('glm')
logistic_reg() %>% set_engine('glmnet')

boost_tree(mode='regression') %>% set_engine('xgboost')
boost_tree(mode='classification') %>% set_engine('xgboost')

# Decision Trees ####

library(xgboost)
test_y <- sal_prepped %>% 
    bake(SalaryCY, new_data=test, composition='matrix')
head(test_y)

train_xg <- xgb.DMatrix(data=sal_x, label=sal_y)
# DON'T USE TEST DATA AS VALIDATION DATA
# WE'RE JUST DOING IT OUT OF LAZINESS AND TIME CONSTRAINTS
val_xg <- xgb.DMatrix(data=test_x, label=test_y)

sal11 <- xgb.train(
    data=train_xg,
    objective='reg:squarederror',
    booster='gbtree',
    eval_metric='rmse',
    nrounds=1,
    watchlist=list(train=train_xg)
)

sal8$cvm[which(sal8$lambda == sal8$lambda.min)]


sal12 <- xgb.train(
    data=train_xg,
    objective='reg:squarederror',
    booster='gbtree',
    eval_metric='rmse',
    nrounds=100,
    watchlist=list(train=train_xg)
)

sal13 <- xgb.train(
    data=train_xg,
    objective='reg:squarederror',
    booster='gbtree',
    eval_metric='rmse',
    nrounds=500,
    watchlist=list(train=train_xg)
)

sal14 <- xgb.train(
    data=train_xg,
    objective='reg:squarederror',
    booster='gbtree',
    eval_metric='rmse',
    nrounds=500,
    watchlist=list(train=train_xg, validate=val_xg)
)
sal14$evaluation_log %>% dygraphs::dygraph()


sal15 <- xgb.train(
    data=train_xg,
    objective='reg:squarederror',
    booster='gbtree',
    eval_metric='rmse',
    nrounds=500,
    max_depth=3,
    watchlist=list(train=train_xg, validate=val_xg)
)

sal15$evaluation_log$validate_rmse %>% min
sal14$evaluation_log$validate_rmse %>% min

# workflows ####

# rsample
sal_cv <- vfold_cv(data=train, v=5, strata='SalaryCY')
sal_cv

library(yardstick)
sal_metrics <- metric_set(rmse, mae)
sal_metrics

# recipes
sal_rec <- recipe(SalaryCY ~ Region + Title + Years + Reports + Career + Floor,
                  data=train) %>% 
    step_nzv(all_predictors()) %>% 
    step_BoxCox(all_numeric(), -SalaryCY) %>% 
    step_other(all_nominal(), other='Misc') %>% 
    step_dummy(all_nominal(), one_hot=TRUE)

# parsnip
spec_xg <- boost_tree(
    mode='regression',
    learn_rate=0.3,
    trees=tune(),
    tree_depth=tune()
) %>% 
    set_engine('xgboost')
spec_xg

library(dials)
library(tune)
sal_params <- spec_xg %>% 
    parameters() %>% 
    update(
        trees=trees(range=c(20, 300)),
        tree_depth=tree_depth(range=c(2, 5))
    )
sal_params
sal_param_grid <- grid_max_entropy(sal_params, size=6)
sal_param_grid

library(tictoc)

tic()
1 - 1
toc()

tic()
sal_tune <- tune_grid(
    object=sal_rec,
    model=spec_xg,
    resamples=sal_cv,
    grid=sal_param_grid,
    metrics=sal_metrics,
    control=control_grid(verbose=TRUE)
)
toc()

sal_tune
sal_tune$.metrics[[1]]
sal_tune$.metrics[[2]]
autoplot(sal_tune)

sal_tune %>% collect_metrics()
show_best(sal_tune, metric='mae', maximize=FALSE, n_top=2)

sal_best <- select_best(sal_tune, metric='mae', maximize=FALSE)
sal_best

sal_best_mod <- finalize_model(x=spec_xg, parameters=sal_best)
sal_best_mod
sal_best_rec <- finalize_recipe(x=sal_rec, parameters=sal_best)
sal_best_rec

library(workflows)

sal_flow <- workflow() %>% 
    add_recipe(sal_best_rec) %>% 
    add_model(sal_best_mod)
sal_flow

sal_final <- sal_flow %>% 
    fit(data=train)
sal_final
