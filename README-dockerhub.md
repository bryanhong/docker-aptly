aptly
=====

aptly in a container backed by nginx

from [aptly.info](http://aptly.info): 
>aptly is a swiss army knife for Debian repository management: it allows you to mirror remote repositories, manage local package repositories, take snapshots, pull new versions of packages along with dependencies, publish as Debian repository.

Requirements / Dependencies
---------------------------
* Docker 1.6 or higher, we are using the Docker syslog driver in this container and this feature made its debut in 1.6

Start the container
---------------------
1. Run (adjust to suit your environment)

  ```
  docker run \
  --detach=true \
  --log-driver=syslog \
  --name="aptly" \
  --restart=always \
  -e FULL_NAME="First Last" \
  -e EMAIL_ADDRESS="youremail@example.com" \
  -e GPG_PASSWORD="PickAPassword" \
  -e HOSTNAME=aptly.example.com \
  -v /dockerhost/directory/with/lots/of/space:/opt/aptly \
  -p 80:80 \
  bryanhong/aptly:latest
```

2. Wait until the GPG keyrings are created (not 0 bytes) before proceeding (it can take a few minutes). They will be in the bind mount location you chose in above.

Create a mirror of Ubuntu's main repository
-------------------------------------------
1. The initial download of the repository may take quite some time depending on your bandwidth limits, it may be in your best interest to open a tmux or screen session before proceeding.
2. Attach to the container ```docker exec -it aptly /bin/bash```
3. By default, ```/opt/update_mirror.sh``` will automate the creation of an Ubuntu 14.04 Trusty repository, if you want a different release, modify the variables in the script.
4. Run ```/opt/update_mirror.sh```
5. If the script fails due to network disconnects etc, just re-run it.

When the script completes, you should have a functional mirror that you can point a client to.

Point a host at the mirror
--------------------------
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
 
 You should be able to install packages from your mirror at this point!
 
Checkout the excellent aptly documentation [here](http://www.aptly.info/doc/overview/)
