# PrismChat API Node Compose

We have created this docker compose configuration so you can deploy docker to a VPS as easily as possible. 

``` bash
docker exec prismchat-api-node-compose-prismchat-1 node /app/build/app/scripts/generateKeys.js # set keys in compose file.
docker-compose up -d
```

## Base Configuration

Before we can start the project it requires some very basic configuration. Mainly to allow our domain to be routed to the server.

1. Open ```docker/config/nginx/conf.d/sites.conf``` and replace every ```api1.prism.chat``` to your actual domain.
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
    docker exec prismchat-api-node-compose-nginx-1 nginx -s reload

    # Reset environment
    rm -rf ./docker/volumes
    docker system prune -a
    ```

## SSL Configuration

This project uses CertBot to easily install and configure SSL certificates. You can obtain ssl certificates using the "maintenance" container, and will automatically manage certificate renewal. Run the certbot commands replacing ```api1.prism.chat``` with your actual domain.

``` bash
# Test certbot obtaining SSL certificate
docker exec -i prismchat-api-node-compose-maintenance-1 certbot certonly --webroot --webroot-path /var/certbot/ -d api1.prism.chat --dry-run -v

## Actually obtain certificate
docker exec -i prismchat-api-node-compose-maintenance-1 certbot certonly --webroot --webroot-path /var/certbot/ -d api1.prism.chat
```

After SSL certificates have been obtained you will need to change the Nginx configuration files to take advantage of HTTPS. Follow the instructions in the configuration files located at ```docker/config/nginx/conf.d```. Then reload Nginx.

``` bash
docker exec prismchat-api-node-compose-nginx-1 nginx -s reload
```

## Graceful update

To update this application while running on the server and minimize downtime we utilize dockers scale functionality, commonly referred to as the "rolling update strategy". Basically we create a duplicate of our PrismChat container and reload Nginx to direct traffic to the newly created container. Then we update our original PrismChat container to the latest version. Finally we take down the outdated PrismChat container and redirect traffic back to our now updated PrismChat container by reloading Nginx. This does not result in ZERO downtime but does limit downtime as much as possible while using compose. To guarantee ZERO downtime you must use a container orchestration system like [Kubernetes](https://kubernetes.io/) or [SWARM](https://docs.docker.com/engine/swarm/).

``` bash
# Scale the service to run 2 containers
docker-compose up -d --scale prismchat=2

# Reload Nginx, this will redirect traffic to the latest container running the prismchat service
docker exec prismchat-api-node-compose-nginx-1 nginx -s reload

# Update original container
docker-compose up -d --build --no-deps prismchat

# Scale down to 1 container, by default removes the oldest versioned container
docker-compose up -d --scale prismchat=1

# Reload Nginx to switch back to original container
docker exec prismchat-api-node-compose-nginx-1 nginx -s reload
```
