# Use the latest Ubuntu as the base image
FROM ubuntu:latest

# Объявляем аргументы сборки с значениями по умолчанию
ARG GEOGRAPHIC_AREA="Europe"

# Устанавливаем значение переменной окружения
ENV DEBIAN_FRONTEND=noninteractive
ENV GEOGRAPHIC_AREA=${GEOGRAPHIC_AREA}

# Update package list and install necessary packages
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    wget \
    unzip \
    vim \
    ufw \
    make

# Download and install Nagios 
WORKDIR /tmp
RUN wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.6.tar.gz
RUN tar -xvzf nagios-4.4.6.tar.gz
WORKDIR /tmp/nagios-4.4.6

# Продолжаем сборку
RUN make all
RUN make install-groups-users
RUN usermod -a -G nagios www-data
RUN make install
RUN make install-daemoninit
RUN make install-commandmode
RUN make install-config
RUN make install-webconf
RUN a2enmod cgi

# Используем значение переменной внутри команды или конфигурации
RUN echo "Geographic area: $GEOGRAPHIC_AREA"

# Install Nagios Plugins
WORKDIR /tmp
RUN wget https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz
RUN tar -xvzf nagios-plugins-2.3.3.tar.gz
WORKDIR /tmp/nagios-plugins-2.3.3
RUN ./configure --with-nagios-user=nagios --with-nagios-group=nagios
RUN make
RUN make install

# Clean up downloaded files
WORKDIR /
RUN rm -rf /tmp/nagios-4.4.6* /tmp/nagios-plugins-2.3.3*

# Copy configurations file (make sure your configuration files are in the same directory as your Dockerfile)
COPY . /usr/local/nagios/etc/

# Expose port 80 for Apache
EXPOSE 80

# Start Apache and Nagios
CMD ["/usr/local/nagios/bin/nagios", "/usr/local/nagios/etc/nagios.cfg"]
