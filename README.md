esmond (ESnet Monitoring daemon) container (http://software.es.net/esmond) 

This container only provides the esmond app and the Postgresql DB. You have to provide your own cassandra(/cluster) instance.

You can start one from spotify/cassandra if you don't have one.

    mkdir -p /usr/local/cassandra1
    docker run -d -v /usr/local/cassandra1:/var/lib/cassandra -e "CASSANDRA_TOKEN=0" --name cassandra1 spotify/cassandra:cluster

(Using /usr/local/cassandra1 for DB volume)

Then start up esmond by linking to it.

    docker run -d --name esmond --link cassandra1:cassandra -p 40180:80 soichih/esmond

Link parent name needs to be "cassandra". Adjust port to your liking.

Once it starts up, you can test it by downloading an empty json.

    http://localhost:40180/esmond/perfsonar/archive/?format=json

# Administration

This contains comes with sshd running, so you can ssh to it. The default root password is 'esmond'.

    ssh root@<container ip>

(check docker logs for the ip address)

When you login, you will need to setup your bash to use python27

    bash-4.1# scl enable python27 bash
    bash-4.1# cd /opt/esmond
    bash-4.1# . bin/activate

(don't ask me what these things are..)

Anyway, you can then start setting up admin password, etc.

    (esmond)bash-4.1# python esmond/manage.py createsuperuser
    Username (leave blank to use 'root'): admin
    Email address: admin@example.com
    Password:
    Password (again):
    Superuser created successfully.

Once you setup your admin password, you can try accessing the admin UI

    http://localhost:40180/esmond/admin/

Or setup user access..

    python esmond/manage.py add_ps_metadata_post_user perfsonar
    python esmond/manage.py add_timeseries_post_user perfsonar

(Note the API key generated)

Once you set up your api key, you can then post data to it (replace the apikey and url)

    curl -X POST --dump-header - -H "Content-Type: application/json" -H "Authorization: ApiKey perfsonar:xxxxxxxxxxxxxxxxxxxxxxx" --data '{"subject-type": "point-to-point", "source": "10.1.1.1", "destination": "10.1.1.2", "tool-name": "bwctl/iperf3", "measurement-agent": "110.1.1.1", "input-source": "host1.example.net","input-destination": "host2.example.net","time-duration": 30,"ip-transport-protocol": "tcp","event-types": [{"event-type": "throughput","summaries":[{"summary-type": "aggregation","summary-window": 3600},{"summary-type": "aggregation","summary-window": 86400}]},{"event-type": "packet-retransmits","summaries":[]}]}' http://localhost:40180/esmond/perfsonar/archive/

You should see the data posted under

    http://localhost:40180/esmond/perfsonar/archive/?format=json

