# PrismChat API Node Compose

We have created this docker compose configuration so you can deploy docker to a VPS as easily as possible. 

``` bash
docker-compose up -d
docker exec prismchat-api-node-compose-prismchat-1 node /app/build/app/scripts/generateKeys.js # set keys in compose file.
docker-compose restart
```

## Base Configuration

**NOTE: All configuration examples use the domain ```api1.prism.chat```, change this to the domain of the server you are deploying to!**

Before we can start the project it requires some very basic configuration. Mainly to allow our domain to be routed to the server. All containers are named in the compose file except for the prismchat container as it would interfere with manual updates.

1. Open ```nginx/conf.d/sites.conf``` and replace every ```api1.prism.chat``` to your actual domain.
2. Add the following DNS records to make everything work:

  | Type  | Name  |   Content   |
  | :---: | :---: | :---------: |
  |   A   | api1  | \<ServerIP> |

3. Start the docker environment! This will make the api available on port 80 (HTTP, NOT HTTPS).

  ``` bash
  # Start and Stop docker compose
  docker-compose up -d
  docker-compose down

  # View status of docker containers
  docker ps -a
  docker logs <container name>

  # Reload Nginx configuration wth zero downtime (Useful for SSL config)
  docker exec nginx nginx -s reload

  # Reset environment
  rm -rf ./volumes/mongo # Remove ./volumes to also remove SSL Certificates
  docker system prune -a
  ```

## SSL Configuration

This project uses CertBot to easily install and configure SSL certificates. You can obtain ssl certificates using the "maintenance" container, and will automatically manage certificate renewal. Run the certbot commands replacing ```api1.prism.chat``` with your actual domain.

``` bash
# Test certbot obtaining SSL certificate
docker exec -i maintenance certbot certonly --webroot --webroot-path /var/certbot/ -d api1.prism.chat --dry-run -v

## Actually obtain certificate
docker exec -i maintenance certbot certonly --webroot --webroot-path /var/certbot/ -d api1.prism.chat
```

After SSL certificates have been obtained you will need to change the Nginx configuration files to take advantage of HTTPS. Follow the instructions in the configuration files located at ```./nginx/conf.d/sites.conf```. Then reload Nginx.

``` bash
docker exec nginx nginx -s reload
```

## Updates

We utilize [containrrr/watchtower](https://hub.docker.com/r/containrrr/watchtower) to automatically update the prismchat container to the latest image. Every other container is hard versioned to prevent any unexpected versioning errors. This environment will remain in sync with the latest stable version of PrismChat which can be found by tag or the latest commit to the main branch. Seeing as the watchtower container will automatically update the prismchat container to the latest version automatically this could lead to the other, hard versioned, containers becoming out of date. If you wish to manually update instead simply comment out the watchtower container and remove the label "com.centurylinklabs.watchtower.enable=true" from the prismchat container in the docker-compose file and follow the steps below.

### Manual Updates

To manually update this application while running on the server and minimize downtime we utilize dockers scale functionality, commonly referred to as the "rolling update strategy". Basically we create a new PrismChat container which will check if there is a new image to pull. When using the scale functionality docker will automatically distribute traffic between the two containers. Next we scale down the PrismChat containers which by default will keep the newest container and remove the oldest. Finally we reload Nginx in case of any issues. This does not result in ZERO downtime but does limit downtime as much as possible while using compose. To guarantee ZERO downtime you must use a container orchestration system like [Kubernetes](https://kubernetes.io/) or [SWARM](https://docs.docker.com/engine/swarm/).

``` bash
# Scale the service to run 2 containers (new image will be pulled for second container).
docker-compose up -d --build --scale prismchat=2

# Scale down to 1 container, by default removes the oldest versioned container.
docker-compose up -d --scale prismchat=1

# Reload Nginx to switch all traffic back to original container.
docker exec nginx nginx -s reload
```
