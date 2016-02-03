#docker-aptly

Dockerfile and support scripts to run aptly in a container backed by nginx.

from [aptly.info](http://aptly.info): 
>aptly is a swiss army knife for Debian repository management: it allows you to mirror remote repositories, manage local package repositories, take snapshots, pull new versions of packages along with dependencies, publish as Debian repository.

If you don't plan on customizing the Dockerfile in this repository, simply follow the instructions [here](https://hub.docker.com/r/bryanhong/aptly/) instead.

##Requirements / Dependencies

* Docker 1.6 or higher, we are using the Docker syslog driver in this container and this feature made its debut in 1.6
* ```vars``` needs to be populated with the appropriate variables.

##Commands and variables

* ```vars```: Variables for Docker registry, the application, and aptly repository data location
* ```build.sh```: Build the Docker image locally
* ```run.sh```: Starts the Docker container, it the image hasn't been built locally, it is fetched from the repository set in vars
* ```push.sh```: Pushes the latest locally built image to the repository set in vars
* ```shell.sh```: get a shell within the container

##How this image/container works

####Data
All of aptly's data (including PGP keys and GPG keyrings) is bind mounted outside of the container to preserve it if the container is removed or rebuilt. Set the location for the bind mount in ```vars``` before starting the container. If you're going to host a mirror of Ubuntu's main repository, you'll need upwards of 35GB of free space as of Feb 2016, plan for growth.
####Networking
By default, Docker will map port 80 on the Docker host to port 80 within the container where nginx is configured to listen. You can change the external listening port in ```vars``` to map to any port you like.
####Security
The GPG password you set in ```vars``` is stored in plain text and is visible as an environment variable inside the container. It is set as an enviornment variable to allow for automation of repository updates without user interaction. The GPG password can be removed completely but it is safer to encrypt the GPG keyrings because they are bind mounted outside the container to avoid the necessity of regenerating/redistributing keys if the container is removed or rebuilt.

##Usage

####Configure the container

1. Configure application specific variables in ```vars```

####Build the image

1. Run ```./build.sh```

####Start the container

1. Run ```./run.sh```
2. Wait until the GPG keyrings are created (not 0 bytes) before proceeding (it can take a few minutes). They will be in the bind mount location you chose in ```vars```

####Create a mirror of Ubuntu's main repository
1. The initial download of the repository may take quite some time depending on your bandwidth limits, it may be in your best interest to open a tmux or screen session before proceeding.
2. Attach to the container ```./shell.sh```
3. By default, ```/opt/update_mirror.sh``` will automate the creation of an Ubuntu 14.04 Trusty repository, if you want a different release, modify the variables in the script.
4. Run ```/opt/update_mirror.sh```
5. If the script fails due to network disconnects etc, just re-run it.

When the script completes, you should have a functional mirror that you can point a client to.

####Point a host at the mirror

1. Fetch the public PGP key from your aptly repository and add it to your trusted repositories

 ```
 wget http://FQDN.OF.APTLY/aptly_repo_key.pub
 apt-key add aptly_repo_key.pub
 ```

2. Backup then replace /etc/apt/sources.list

 ```
 cp /etc/apt/sources.list /etc/apt/sources.list.bak
 echo "deb http://FQDN.OF.APTLY/ ubuntu main" > /etc/apt/sources.list
 apt-get update
 ```
 
 You should be able to install packages at this point!
 
Checkout the excellent aptly documentation [here](http://www.aptly.info/doc/overview/)
 
####Pushing your image to the registry

If you're happy with your container and ready to share with others, push your image up to a [Docker registry](https://docs.docker.com/docker-hub/) and save any other changes you've made so the image can be easily changed or rebuilt in the future.

1. Authenticate to the Docker Registry ```docker login```
2. Run ```./push.sh```
3. Log into your Docker hub account and add a description, etc.

> NOTE: If your image will be used FROM other containers you might want to use ```./push.sh flatten``` to consolidate the AUFS layers into a single layer. Keep in mind, you may lose Dockerfile attributes when your image is flattened.
