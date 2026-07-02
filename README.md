# SANE XS4ALL Software Lists

This repository contains files that define which software packages are available in KB's XS4ALL SANE environment.

Use this repo to track and update the set of accessible software and packages for the XS4ALL configuration.

## Setting up SANE environment

This is largely based on SURF [instructions](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/96207241/Data+provider+instructions), but specific for this particular use case

1. Follow steps 1-3 from main instructions
2. Add component to install SolrWayback + dependencies following [the components guide](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/17825812/Create+a+catalog+item) (note that this is a different guide from above)
    1. Under Development>Catalog items, expand the XS4ALL SANE Tinker (or similar name) workspace
    2. From the "Available Components" list (at the bottom), selectthe component called `SolrWayback + requirements`
    3. Click continue and fill in all the documentation steps as described in the components guide
    4. In step 6. of the components guide overwrite the value for the python packages using `https://github.com/DaniBodor/SANE_XS4ALL_software_list/blob/main/requirements.txt`
3. Move data into SANE environment using SFTP [as described](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/96207241/Data+provider+instructions#Dataproviderinstructions-UsingSFTP)
   1. This step is not tested yet; we may use a different option than SFTP
   2. I would like to have a script to run the file transfer in this repo as well

## Software and packages

### SolrWayback

The main tool for working with WARC files is [SolrWayback](https://github.com/netarchivesuite/solrwayback). This tool is installed in the environment using the included [powershell script](install_solrwayback.ps1).

The script will install the following requirements as well (see/edit top lines of [script](install_solrwayback.ps1) for version numbers of each):

- Java 11
- Tomcat 9
- Solr 9
- Chrome (latest)

### Python packages

Our list of installed [python packages](requirements.txt) is based on the [default list of python packages in SANE](https://gitlab.com/rsc-surf-nl/co-create-plugins/sane-tinker-python-packages/-/raw/main/requirements.txt). However, we have disabled all packages used exclusively for Deep Learning, as we currently do not allow this application with our dataset.

### R packages

The SANE default R packages are available in the XS4ALL environment, these are:

- data.table
- dplyr
- ggplot2
- readr
- tidyr
- stringr
- lubridate
- tibble
- purrr
- jsonlite
- httr
- DBI
- RSQLite
