
<!-- README.md is generated from README.Rmd. Please edit that file -->

# R Class

This is an empty repo to initialize an R project for class at by
[O’Reilly](https://www.oreilly.com/live-training/courses/machine-learning-with-the-tidyverse-in-r/0636920326045/).

Please **follow all instructions** to set up your environment for the
training.

# Install R and RStudio

This is just like installing any other program.

  - [R](https://cloud.r-project.org/)
  - [RStudio](https://www.rstudio.com/products/rstudio/download/#download)

# Getting the Repo

In order to get the most out of class you have to be working in this
project.

## `usethis` Package

Run these commands in the R console.

``` r
# install usethis package
install.packages('usethis')

# get the repo
usethis::use_course('https://github.com/jaredlander/LiveML2019December/archive/master.zip')
```

Be sure to select the positive prompts such as `yes`, `yeah`, etc.

This will open the project in a new RStudio window.

You should have a new RStudio project called `LiveML2019December` or
`LiveML2019December-master`. You can see this in the top right of
RStudio (the name in the image may be different).

![](images/ProjectCorner.png)<!-- -->

# Install Packages

Setting up all of the needed packages\[1\] will be handled by running
the following line of code in the R console.

``` r
source('prep/install_packages.r')
```

Answer `y` to any questions asked in the terminal.

If that fails, installing `{tidyverse}` and `{tidmodels}` with the
following code will suffice to get started.

``` r
install.packages(c('tidyverse', 'tidymodels'))
```

# Getting Data

The data are stored in a [GitHub
repo](https://github.com/jaredlander/coursedata) and can be downloaded
automatically with the following line of code, assuming all of the
packages installed successfully and you are using the RStudio project
created earlier.

``` r
source('prep/download_data.r')
```

# All Done

That’s everything. You should now do all of your work for this class in
this project.

# Footnotes

1.  Linux users might need to install `libxml2-dev` and `zlib1g-dev`
