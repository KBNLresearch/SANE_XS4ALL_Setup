# SANE XS4ALL Software Lists

This repository contains files that define which software packages are available in KB's XS4ALL SANE environment.

Use this repo to track and update the set of accessible software and packages for the XS4ALL configuration.

## Setting up SANE environment

This is largely based on SURF [instructions](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/96207241/Data+provider+instructions), but specific for this particular use case

### 1 Create and prepare SANE collaboration

Follow steps 1-3 from main instructions linked above.

:bangbang: Does this need additional instructions?

### 2 Add component to install SolrWayback + dependencies

Follow [the components guide](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/17825812/Create+a+catalog+item) (note that this is a different guide from above):

1. Under Development>Catalog items, expand the XS4ALL SANE Tinker (or similar name) workspace
2. From the "Available Components" list (at the bottom), selectthe component called `SolrWayback + requirements`
3. Click continue and fill in all the documentation steps as described in the components guide
4. In step 6. of the components guide overwrite the value for the python packages using `https://github.com/DaniBodor/SANE_XS4ALL_software_list/blob/main/requirements.txt`

### 3. Move data into SANE environment

Data can be moved directly from the webarchive server to SANE servers using. We can largely follow step 5 (rsync option) from the [main setup guide](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/96207241/Data+provider+instructions#Dataproviderinstructions-Usingrsync(recommendedforlargetransfers)) with some additions/specifics below.

1. Create a list of files you want to transfer, called e.g. `transfer_list.txt`. The file path should be relative to the `<source location>` used in step 3.3 below.
    - A sample file that shows the expected format is given at [dummy_transfer_list.txt](dummy_transfer_list.txt)
2. Create access credentials for the server (in principle only once per environment) following [these steps](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/195854434/Workspace+access+with+SSH)
   1. Step 1 from the guide is only necessary if have never set up an SSH key yet for your system or if you want a specific key for this environment.
   2. Step 2 adds the key to the environment (needs to be done once per SANE environment) on [your profile page](https://sram.surf.nl/profile)
   3. Test whether you have access.
      - Find your username on the profile page
      - Find the IP address from the SANE Data Provider Portal, listed on your [dashboard](https://portal.live.surfresearchcloud.nl/dashboard/workspaces) (use the "IP address", not the "Local IP address").
      - Try logging in to the data portal using the command `ssh <username>@<IP address>`.
      - You should now see some generic information about the server and the bottom line should look something like `<username>@sanedataprovide:~$`
      - close the connection to the server by entering `exit`
3. Preferably, use `rsync` to copy large amounts of data, as this allows for synchronization and resuming of interupted transfers. Use the command below from a terminal that has rsync (most Unix-like terminals, but not git bash).
   - the guide says to use `rsync -avP`, but the archive (`-a`) flag makes the transfer fail. Instead, we will use `rsync -vPrlgoD`, which does the same except not preserving modification times or permissions (neither of which are relevant for us).
   -

```sh
rsync -vPrlgoD --files-from=</path/transfer_list> <source file location> <username>@<IP address>:/data/sane-data/source/
```

## Available software and packages

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
