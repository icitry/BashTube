# BashTube

[Link to the YouTube video](https://youtu.be/b_WGoPaNPMY)

I have decided that, in an effort of making the world know that Bash is still everything you need in this day and age, to remake YouTube from scratch using only that. That's right, from the Back-End to the Front-End, from the storage to the retrieval of files, including the actual process of transmitting data, I decided to implement everything a Full Stack app needs without allowing myself to step outside of the Bash bubble, no exceptions.

So, do you still think you need fancy frameworks like Django, Spring, React, Angular and many others that have burdened the web development sphere, when the proverbial golden goose is right there?

## Setting up
Prerequisites:
```shell
# use apt or apt-get depending on distro
sudo apt install sqlite3
sudo apt install jq
sudo apt install ncat
```
To run the program you need to first grant the appropriate permissions:
```shell
cd path/to/BashTube
chmod +x src/rest/http/http_orchestrator.sh
```
Then, to start the app:
```shell
cd path/to/BashTube
cd src/app
source main.sh
```