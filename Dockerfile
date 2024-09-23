# Use termux/termux-docker image
FROM termux/termux-docker

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Set work directory
WORKDIR /app

# Copy your scripts to the container
COPY src/scripts/setup.sh /app/setup.sh
COPY src/scripts/scrapper.py /app/scrapper.py
