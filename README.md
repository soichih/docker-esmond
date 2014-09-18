esmond (ESnet Monitoring daemon) container (http://software.es.net/esmond) 

This container only provides the esmond app and the Postgresql DB. You have to provide your own cassandra(/cluster) instance.

You can start one from spotify/cassandra if you don't have one.

    mkdir -p /usr/local/cassandra1
    docker run -d -v /usr/local/cassandra1:/var/lib/cassandra -e "CASSANDRA_TOKEN=0" --name cassandra1 spotify/cassandra:cluster

(Using /usr/local/cassandra1 for DB volume)

You are most likely interested in building your own esmond instance that comes with admin user/pass and some esmond users. The
easiest way to do this is simply build your own container using this container as a base image.. like

Dockerfile

```
FROM soichih/esmond

RUN yum -y install expect
ADD superadmin.sh /tmp/superadmin.sh
RUN scl enable python27 "cd /opt/esmond && source bin/activate && /tmp/superadmin.sh"

RUN service postgresql start && \
    scl enable python27 "cd /opt/esmond && source bin/activate && \
        python esmond/manage.py add_ps_metadata_post_user perfsonar && \
        python esmond/manage.py add_timeseries_post_user perfsonar"
```

superadmin.sh script can look like this.

```
#!/usr/bin/expect

set timeout 10
spawn python esmond/manage.py createsuperuser --username=admin --email=email@exmample.com
expect "Password: " { send "xxxxxxxxxxxxxxx\r" }
expect "Password (again): " { send "xxxxxxxxxxxx\r" }
interact

```

esmond/manage.py createsuperuser command is an interactive command, which is why I am using "expect" command. You can then build your 
container with

```
docker build .
```

(Note the API key generated during the build)

Once you build your container, then you can start it up by linking to your cassandra instance.

    docker run -d --name esmond --link cassandra1:cassandra -p 40180:80 soichih/esmond

Link parent name needs to be "cassandra". Adjust port to your liking.

Once it starts up, you can try posting data to it (replace the apikey and url generating during the build)

    curl -X POST --dump-header - -H "Content-Type: application/json" -H "Authorization: ApiKey perfsonar:xxxxxxxxxxxxxxxxxxxxxxx" --data '{"subject-type": "point-to-point", "source": "10.1.1.1", "destination": "10.1.1.2", "tool-name": "bwctl/iperf3", "measurement-agent": "110.1.1.1", "input-source": "host1.example.net","input-destination": "host2.example.net","time-duration": 30,"ip-transport-protocol": "tcp","event-types": [{"event-type": "throughput","summaries":[{"summary-type": "aggregation","summary-window": 3600},{"summary-type": "aggregation","summary-window": 86400}]},{"event-type": "packet-retransmits","summaries":[]}]}' http://localhost:40180/esmond/perfsonar/archive/

You should see the data posted under

    http://localhost:40180/esmond/perfsonar/archive/?format=json

You can also access your admin UI at (using the user/pass you used inside setupsueradmin.sh)

    http://localhost:40180/esmond/admin/
