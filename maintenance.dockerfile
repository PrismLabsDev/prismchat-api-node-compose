FROM alpine:3.17.2

RUN apk add --update python3 py3-pip
RUN apk add certbot

# Copy cron file to the container
COPY maintenance/cron.d/cron /etc/cron.d/cron

# Give the permission
RUN chmod 0644 /etc/cron.d/cron

# Add the cron job
RUN crontab /etc/cron.d/cron

# Link cron log file to stdout
RUN ln -s /dev/stdout /var/log/cron

# Run the cron service in the foreground
CMD [ "crond", "-l", "2", "-f" ]