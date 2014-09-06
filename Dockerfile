FROM centos:centos6
MAINTAINER Soichi Hayashi <hayashis@iu.edu>
#instruction from http://software.es.net/esmond/rpm_install.html

RUN yum -y localinstall http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum -y localinstall http://software.internet2.edu/branches/release-3.4/rpms/el6/x86_64/main/RPMS/Internet2-repo-0.5-2.noarch.rpm 

#we don't actually run cassandra on this container, but we need it to install esmond
ADD datastax.repo /etc/yum.repos.d/datastax.repo

#let esmond install everything
RUN yum -y install esmond

#init psql
RUN service postgresql initdb 
RUN service postgresql start && \
    su postgres -c "psql -c \"CREATE USER esmond WITH PASSWORD 'default_password'\"" && \
    su postgres -c "psql -c \"CREATE DATABASE esmond\"" && \
    su postgres -c "psql -c \"GRANT ALL ON DATABASE esmond to esmond\""

#install default config
ADD conf/pg_hda.conf /var/lib/pgsql/data/pg_hba.conf
ADD conf/esmond.conf /opt/esmond/esmond.conf 

#this is needed to run managa.py
ENV ESMOND_ROOT /opt/esmond

#initialize esmond/psql
RUN service postgresql start && \
    scl enable python27 "cd /opt/esmond && source bin/activate && echo no | python esmond/manage.py syncdb"

#setup superuser
#RUN yum -y install expect
#ADD conf/superadmin.sh /superadmin.sh
#RUN scl enable python27 "cd /opt/esmond && source bin/activate && expect /superadmin.sh"
#RUN rm /superadmin.sh

#RUN yum -y install supervisor openssh-server
#ADD conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#RUN mkdir /var/run/sshd
#RUN echo 'root:esmond' | chpasswd
#CMD ["/usr/bin/supervisord"]

#install sshd.. out of desperation.
RUN yum -y install openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:esmond' | chpasswd
#disable PAM or sshd won't let user in
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config

EXPOSE 80 22

CMD service postgresql start && \
    service httpd start && \
    service sshd start && \
    sleep 3 && \
    tail -f /var/log/httpd/error_log.log /var/log/esmond/esmond.log /var/log/esmond/django.log

