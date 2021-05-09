# OTRS with Let's Encrypt in a Docker Compose

Install the Docker Engine by following the official guide: https://docs.docker.com/engine/install/

Install the Docker Compose by following the official guide: https://docs.docker.com/compose/install/

Deploy OTRS server with a Docker Compose using the command:

`docker-compose -f otrs-traefik-letsencrypt-docker-compose.yml -p otrs up -d`

### Administration Interface
https://otrs.heyvaldemar.net/otrs/index.pl

### Customer Interface
https://otrs.heyvaldemar.net/otrs/customer.pl
