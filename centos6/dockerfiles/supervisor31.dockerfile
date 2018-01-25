
#
#    CentOS 6 (centos6) Supervisor31 System (dockerfile)
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

ARG app_supervisor_loglevel="warn"

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

# Refresh the package manager
# Install the selected packages
#   Install the python packages
#    - python-pip: for pip, the alternative Python package installer
#    - python-setuptools: extensions to the python-distutils for large or complex distributions
#    - python-meld3: HTML/XML templating system for Python
# Cleanup the package manager
# Install the python modules
#  - supervisor: for supervisord, to launch and manage processes
#  - supervisor-stdout: a simple supervisord event listener to relay process output to supervisor’s stdout
RUN printf "Installing repositories and packages...\n" && \
    \
    printf "Refresh the package manager...\n" && \
    rpm --rebuilddb && yum makecache && \
    \
    printf "Install the selected packages...\n" && \
    yum install -y \
      python-pip python-setuptools python-meld3 && \
    \
    printf "Cleanup the package manager...\n" && \
    yum clean all && rm -Rf /var/lib/yum/* && rm -Rf /var/cache/yum/* && \
    \
    printf "Instal the python modules...\n" && \
    pip install "supervisor>=3.1.0,<3.2.0" supervisor-stdout && \
    \
    printf "Finished installing repositories and packages...\n";

#
# Configuration
#

# Update daemon configuration
# - Supervisor
RUN printf "Updading Daemon configuration...\n" && \
    \
    printf "Updading Supervisor configuration...\n" && \
    \
    # ignoring /etc/sysconfig/supervisor \
    \
    # /etc/supervisord.conf \
    file="/etc/supervisord.conf" && \
    echo_supervisord_conf > ${file} && \
    printf "\n# Applying configuration for ${file}...\n" && \
    perl -0p -i -e "s>logfile=/var/log/supervisor/supervisord.log>logfile=/dev/null>" ${file} && \
    perl -0p -i -e "s>loglevel=info>loglevel=${app_supervisor_loglevel}>" ${file} && \
    perl -0p -i -e "s>nodaemon=false>nodaemon=true>" ${file} && \
    perl -0p -i -e "s>\[unix_http_server\]\nfile=.*>\[unix_http_server\]\nfile=/dev/shm/supervisor.sock>" ${file} && \
    perl -0p -i -e "s>\[supervisorctl\]\nserverurl=.*>\[supervisorctl\]\nserverurl=unix:///dev/shm/supervisor.sock>" ${file} && \
    printf "\n\
[include]\n\
files = supervisord.d/*.ini\n\
files = supervisord.d/*.conf\n\
\n" >> ${file} && \
    perl -0p -i -e "s>\[supervisord\]>\[supervisord\]\n\
# send logs to stdout and stderr\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0>" ${file} && \
    \
    # /etc/supervisord.d/ \
    mkdir -p /etc/supervisord.d/ && \
    \
    # /etc/supervisord.d/stdout.conf \
    file="/etc/supervisord.d/stdout.conf" && \
    printf "\n# Applying configuration for ${file}...\n" && \
    printf "# stdout\n\
[eventlistener:stdout]\n\
command=supervisor_stdout\n\
buffer_size=100\n\
events=PROCESS_LOG\n\
result_handler=supervisor_stdout:event_handler\n\
\n" > ${file} && \
    printf "Done patching ${file}...\n" && \
    \
    # /etc/supervisord.d/init.conf \
    file="/etc/supervisord.d/init.conf" && \
    printf "\n# Applying configuration for ${file}...\n" && \
    printf "# init\n\
[program:init]\n\
command=/bin/bash -c \"supervisorctl start rclocal;\"\n\
autostart=true\n\
autorestart=false\n\
startsecs=0\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
stdout_events_enabled=true\n\
stderr_events_enabled=true\n\
\n" > ${file} && \
    printf "Done patching ${file}...\n" && \
    \
    # /etc/supervisord.d/rclocal.conf \
    file="/etc/supervisord.d/rclocal.conf" && \
    printf "\n# Applying configuration for ${file}...\n" && \
    printf "# rclocal\n\
[program:rclocal]\n\
command=/bin/bash -c \"/etc/rc.local\"\n\
autostart=false\n\
autorestart=false\n\
startsecs=0\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
stdout_events_enabled=true\n\
stderr_events_enabled=true\n\
\n" > ${file} && \
    printf "Done patching ${file}...\n" && \
    \
    # /etc/rc.local \
    file="/etc/rc.local" && \
    touch ${file} && chown root ${file} && chmod 755 ${file} && \
    \
    printf "\n# Testing configuration...\n" && \
    echo "Testing $(which supervisord):" && $(which supervisord) -v && \
    printf "Done testing configuration...\n" && \
    \
    printf "Finished Daemon configuration...\n";

#
# Run
#

# Command to execute
# Defaults to /bin/bash.
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf", "--nodaemon"]

# Ports to expose
# Defaults to none.
#EXPOSE ...

