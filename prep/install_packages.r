# make sure all packages are installed
install.packages(c(
    'dplyr', 
    'tidyr', 
    'ggplot2', 
    'purrr', 
    'stringr', 
    'jsonlite', 
    'readr', 
    'readxl', 
    'rvest', 
    'ggthemes', 
    'ggridges', 
    'rmarkdown', 
    'usethis', 
    'piggyback', 
    'here',
    'rsample', 
    'dials',
    'parsnip',
    'yardstick',
    'remotes',
    'devtools',
    'glmnet', 'xgboost', 
    'coefplot', 'DiagrammeR', 'dygraphs',
    'shiny', 'shinythemes', 'flexdashboard', 'shinyjs'
))

remotes::install_github("r-lib/cli")
remotes::install_github("tidymodels/tune")
remotes::install_github("tidymodels/recipes")
remotes::install_github("tidymodels/dials")
remotes::install_github("tidymodels/workflows")
remotes::install_github("koalaverse/vip")
