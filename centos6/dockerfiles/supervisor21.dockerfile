
#
#    CentOS 6 (centos6) Supervisor21 System (dockerfile)
#    Copyright (C) 2016-2017 Stafli
#    Luís Pedro Algarvio
#    This file is part of the Stafli Application Stack.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#
# Build
#

# Base image to use
FROM stafli/stafli.system.minimal:minimal10_centos6

# Labels to apply
LABEL description="Stafli Supervisor Init (stafli/stafli.init.supervisor), Based on Stafli Minimal System (stafli/stafli.system.minimal)" \
      maintainer="lp@algarvio.org" \
      org.label-schema.schema-version="1.0.0-rc.1" \
      org.label-schema.name="Stafli Supervisor Init (stafli/stafli.init.supervisor)" \
      org.label-schema.description="Based on Stafli Minimal System (stafli/stafli.system.minimal)" \
      org.label-schema.keywords="stafli, supervisor, init, debian, centos" \
      org.label-schema.url="https://stafli.org/" \
      org.label-schema.license="GPLv3" \
      org.label-schema.vendor-name="Stafli" \
      org.label-schema.vendor-email="info@stafli.org" \
      org.label-schema.vendor-website="https://www.stafli.org" \
      org.label-schema.authors.lpalgarvio.name="Luis Pedro Algarvio" \
      org.label-schema.authors.lpalgarvio.email="lp@algarvio.org" \
      org.label-schema.authors.lpalgarvio.homepage="https://lp.algarvio.org" \
      org.label-schema.authors.lpalgarvio.role="Maintainer" \
      org.label-schema.registry-url="https://hub.docker.com/r/stafli/stafli.init.supervisor" \
      org.label-schema.vcs-url="https://github.com/stafli-org/stafli.init.supervisor" \
      org.label-schema.vcs-branch="master" \
      org.label-schema.os-id="centos" \
      org.label-schema.os-version-id="6" \
      org.label-schema.os-architecture="amd64" \
      org.label-schema.version="1.0"

#
# Arguments
#

#
# Environment
#

# Working directory to use when executing build and run instructions
# Defaults to /.
#WORKDIR /

# User and group to use when executing build and run instructions
# Defaults to root.
#USER root:root

#
# Packages
#

# Install Package Manager related packages
#  - yum-utils: to provide additional utilities such as package-cleanup in yum
#  - yum-plugin-keys: to provide key signing capabilities to yum
# Install crypto packages
#  - openssl: for openssl, the OpenSSL cryptographic utility required for many packages
#  - ca-certificates: adds trusted PEM files of CA certificates to the system
# Install base packages
#  - mailcap: to provide mime support
# Install administration packages
#  - htop: for htop, an interactive process viewer
#  - iotop: for iotop, a simple top-like I/O monitor
#  - iftop: for iftop, a simple top-like network monitor
# Install programming packages
#  - bc: for bc, the GNU bc arbitrary precision calculator language
#  - mawk: for awk, a faster interpreter for the AWK Programming Language
# Install find and revision control packages
#  - file: for file. retrieves information about files
#  - tree: for tree, displays directory tree, in color
#  - diffutils: for diff, the file comparison utility
# Install archive and compression packages
#  - bzip2: for bzip2, a compression utility, which uses the Burrows–Wheeler algorithm
#  - zip: for zip, the InfoZip compression utility which uses various ZIP algorithms
#  - unzip: for unzip, the InfoZip decompression utility which uses various ZIP algorithms
#  - xz: for xz, the XZ compression utility, which uses Lempel-Ziv/Markov-chain algorithm
# Install network diagnosis packages
#  - iproute: for ip and others, the newer tools for routing and network configuration
#  - traceroute: for traceroute/6, tools to trace the network path to a remote host
#  - bind-utils: for nslookup and dig, the BIND DNS client programs
# Install network transfer packages
#  - wget: for wget, a network utility to download via FTP and HTTP protocols
#  - httpie: for HTTPie, a CLI HTTP utility that makes CLI interaction with HTTP-based services as human-friendly as possible
#  - rsync: for rsync, a fast and versatile remote (and local) file-copying tool
#  - openssh-clients: for ssh, a free client implementation of the Secure Shell protocol
# Install misc packages
#  - bash-completion: to add programmable completion for the bash shell
#  - pwgen: for pwgen, the automatic password generation tool
#  - dialog: for dialog, to provide prompts for the bash shell
#  - screen: for screen, the terminal multiplexer with VT100/ANSI terminal emulation
#  - byobu: for byobu, a text window manager, shell multiplexer and integrated DevOps environment
# Install daemon and utilities packages
#  - supervisor: for supervisord, to launch and manage processes
RUN printf "Installing repositories and packages...\n" && \
    \
    printf "Install the Package Manager related packages...\n" && \
    yum makecache && yum install -y \
      openssl ca-certificates \
      yum-utils yum-plugin-keys && \
    \
    printf "Install the required packages...\n" && \
    rpm --rebuilddb && \
    yum makecache && yum install -y \
      mailcap \
      htop iotop iftop \
      bc mawk \
      file tree diffutils \
      bzip2 zip unzip xz \
      iproute traceroute bind-utils \
      wget httpie rsync openssh-clients \
      bash-completion pwgen dialog screen byobu \
      supervisor && \
    \
    printf "Cleanup the Package Manager...\n" && \
    yum clean all && rm -Rf /var/lib/yum/* && \
    \
    printf "Finished installing repositories and packages...\n";

#
# Configuration
#

# Update daemon configuration
# - Supervisor
RUN printf "Updading Daemon configuration...\n"; \
    \
    printf "Updading Supervisor configuration...\n"; \
    mkdir -p /var/log/supervisor; \
    \
    # ignoring /etc/sysconfig/supervisor \
    \
    # /etc/supervisord.conf \
    file="/etc/supervisord.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    perl -0p -i -e "s>nodaemon=false>nodaemon=true>" ${file}; \
    perl -0p -i -e "s>\[unix_http_server\]\nhttp_port=.*>\[unix_http_server\]\nhttp_port=/dev/shm/supervisor.sock>" ${file}; \
    perl -0p -i -e "s>\[supervisorctl\]\nserverurl=.*>\[supervisorctl\]\nserverurl=unix:///dev/shm/supervisor.sock>" ${file}; \
    # includes available only on v3.x+ \
    printf "Done patching ${file}...\n"; \
    \
    # init is not working at this point \
    \
    # /etc/supervisord.conf \
    file="/etc/supervisord.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    printf "# rclocal\n\
[program:rclocal]\n\
command=/bin/bash -c \"/etc/rc.local\"\n\
autostart=true\n\
autorestart=false\n\
startsecs=0\n\
\n" >> ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # /etc/rc.local \
    file="/etc/rc.local"; \
    touch ${file} && chown root ${file} && chmod 755 ${file}; \
    \
    printf "\n# Testing configuration...\n"; \
    printf "Done testing configuration...\n"; \
    \
    printf "Finished Daemon configuration...\n";

#
# Run
#

# Command to execute
# Defaults to /bin/bash.
#CMD ["/bin/bash"]

