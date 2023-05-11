# Shiny server notes

## Details
| Field  | Detail |
| ------------- | ------------- |
| Host  | icb-epi1  |
| Username  | heinig  |
| Password  | ICB@test |
| Environment | rshiny40 |
| App path    | /srv/shiny-server/scpower |
| Configuration file path | /etc/init/shiny-server.conf |
| scPower path (also linked with git) | /home/heinig/scpower_git |

## Notes

### Server update procedure
1. Update scPower. Be aware that dependencies may cause trouble such as "stringi". Currently skipping to update "stringi".
    ```
    conda activate rshiny40
    R -e "devtools::install('~/scpower_git')"
    ```
2. Pull most uptodate codes from github for ui.R and server.R. 
    ```
    There is a shell script able to handle the job specifically.
        ./update_server.sh
    ```
3. Restart the server. See ``/srv/shiny-server/scpower/restart.txt``
    ```
    Firstly, simply running below command should be enough.
        touch ~/scPower/restart.txt
    
    If this does not work, please try:
        sudo service apache2 stop
        sudo service apache2 restart
        sudo start shiny-server
    ```

### Initial installation has been like this:

Repository is cloned and removed all the RData files not needed for the shiny server, then installed with:<br />
``devtools::install("~/scpower_git")`` <br />
``git clone -b dev https://github.com/heiniglab/scPower scpower_git``<br />
``R -e "devtools::install('~/scpower_git')"``<br />
``ln -s scpower_git/inst/shinyApp scPower``
