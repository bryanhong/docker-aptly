docker-aptly
==

aptly in a container backed by nginx

>aptly is a swiss army knife for Debian repository management: it allows you to mirror remote repositories, manage local package repositories, take snapshots, pull new versions of packages along with dependencies, publish as Debian repository. [aptly.info](http://aptly.info)

>nginx [engine x] is an HTTP and reverse proxy server, a mail proxy server, and a generic TCP proxy server, originally written by Igor Sysoev [nginx.org](http://nginx.org/en/)

**NOTE:** This container and the scripts within are written to make hosting an Ubuntu mirror "as-close-to-turnkey" as possible. If there is enough demand or I end up building it for my own purposes, I'll publish a branch or separate repo to support a "turnkey" Aptly Docker image for Debian.

Quickstart
--

The following command will run aptly and nginx in a container, if you want to customize or build the container locally, skip to [Building the Container](#building-the-container) below

```
docker run                                               \
  --detach=true                                          \
  --log-driver=syslog                                    \
  --name="aptly"                                         \
  --restart=always                                       \
  --env FULL_NAME="First Last"                           \
  --env EMAIL_ADDRESS="youremail@example.com"            \
  --env GPG_PASSWORD="PickAPassword"                     \
  --env HOSTNAME=aptly.example.com                       \
  --volume /dockerhost/dir/with/lots/of/space:/opt/aptly \
  --publish 80:80                                        \
  bryanhong/aptly:latest
```

### Runtime flags explained

```
--detach=true
```  
run the container in the background  
```
--log-driver=syslog
```  
send nginx logs to syslog on the Docker host  (requires Docker 1.6 or higher)  
```
--name="aptly"
```  
name of the container  
```
--restart=always
```  
automatically start the container when the Docker daemon starts  
```
--env FULL_NAME="First Last"
```  
the first and last name that will be associated with the GPG apt signing key  
```
--env EMAIL_ADDRESS="youremail@example.com"
```  
the email address that will be associated with the GPG apt signing key  
```
--env GPG_PASSWORD="PickAPassword"
```  
the password that will be used to encrypt the GPG apt signing key  
```
--env HOSTNAME=aptly.example.com
```  
the hostname of the Docker host that this container is running on  
```
--volume /dockerhost/dir/with/lots/of/space:/opt/aptly
```  
path that aptly will use to store its data : mapped path in the container  
```
--publish 80:80
```  
Docker host port : mapped port in the container

Create a mirror of Ubuntu's main repository
--
1. The initial download of the repository may take quite some time depending on your bandwidth limits, it may be in your best interest to open a screen or tmux session before proceeding.
2. Attach to the container ```docker exec -it aptly /bin/bash```
3. By default, ```/opt/update_mirror.sh``` will automate the creation of an Ubuntu 14.04 Trusty repository with the main and universe components, you can adjust the variables in the script to suit your needs.
4. Run ```/opt/update_mirror.sh```
5. If the script fails due to network disconnects etc, just re-run it.

When the script completes, you should have a functional mirror that you can point a client to.

Point a host at the mirror
--

1. Fetch the public PGP key from your aptly repository and add it to your trusted repositories

 ```
 wget http://FQDN.OF.APTLY/aptly_repo_signing.key
 apt-key add aptly_repo_signing.key
 ```

2. Backup then replace /etc/apt/sources.list

 ```
 cp /etc/apt/sources.list /etc/apt/sources.list.bak
 echo "deb http://FQDN.OF.APTLY/ ubuntu main" > /etc/apt/sources.list
 apt-get update
 ```
 
 You should be able to install packages at this point!
 
Checkout the excellent aptly documentation [here](http://www.aptly.info/doc/overview/)

Building the container
--

If you want to make modifications to the image or simply see how things work, check out this repository:

```
git clone https://github.com/bryanhong/docker-aptly.git
```

### Commands and variables

* ```vars```: Variables for Docker registry, the application, and aptly repository data location
* ```build.sh```: Build the Docker image locally
* ```run.sh```: Starts the Docker container, it the image hasn't been built locally, it is fetched from the repository set in vars
* ```push.sh```: Pushes the latest locally built image to the repository set in vars
* ```shell.sh```: get a shell within the container

### How this image/container works

**Data**  
All of aptly's data (including PGP keys and GPG keyrings) is bind mounted outside of the container to preserve it if the container is removed or rebuilt. Set the location for the bind mount in ```vars``` before starting the container. If you're going to host a mirror of Ubuntu's main repository, you'll need upwards of 80GB+ (x86_64 only) of free space as of Feb 2016, plan for growth.

**Networking**  
By default, Docker will map port 80 on the Docker host to port 80 within the container where nginx is configured to listen. You can change the external listening port in ```vars``` to map to any port you like.

**Security**  
The GPG password you set in ```vars``` is stored in plain text and is visible as an environment variable inside the container. It is set as an enviornment variable to allow for automation of repository updates without user interaction. The GPG password can be removed completely but it is safer to encrypt the GPG keyrings because they are bind mounted outside the container to avoid the necessity of regenerating/redistributing keys if the container is removed or rebuilt.

### Usage

#### Configure the container

1. Configure application specific variables in ```vars```

#### Build the image

1. Run ```./build.sh```

#### Start the container

1. Run ```./run.sh```
2. Wait until the GPG keyrings are created (not 0 bytes) before proceeding (it can take a few minutes). They will be in the bind mount location you chose in ```vars```
 
#### Pushing your image to the registry

If you're happy with your container and ready to share with others, push your image up to a [Docker registry](https://docs.docker.com/docker-hub/) and save any other changes you've made so the image can be easily changed or rebuilt in the future.

1. Authenticate to the Docker Registry ```docker login```
2. Run ```./push.sh```
3. Log into your Docker hub account and add a description, etc.

> NOTE: If your image will be used FROM other containers you might want to use ```./push.sh flatten``` to consolidate the AUFS layers into a single layer. Keep in mind, you may lose Dockerfile attributes when your image is flattened.
