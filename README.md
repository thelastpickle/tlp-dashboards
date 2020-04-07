# tlp-dashboards

Cassandra Dashboards based on Prometheus and Grafana

This should allow you to use a 'TLP Cassandra Overview' dashboard, which is the critical dashboard to detect anomalies for a Cassandra cluster.

**Notes**

* This is a work in progress. We are building more dashboards and improving the existing ones, that should not require any big modification on operators side once dashboards are already set up.
* For now metrics are not filtered out, which on bigger cluster or with a lot of table could be a problem)
* Some charts might be inaccurate or even wrong. Please send a feedback or a pull request with the fix and make it available to everyone. We will handles those request with the highest priority. That being said, we believe the existing charts are probably a good starting point to get an accurate feel for your Cassandra clusters.

## Runbook - How to Use the TLP dashboards in my Cassandra cluster(s)?

### Prerequisite

This tool was tested with:

- Grafana version 6.3
- Prometheus version 2.11.1
- node_exporter version 0.18.1
- jmx_exporter version 0.12.0

Newer (and older) versions of those, might also work well, with no action or minor tweaks.

### Export Cassandra Metrics (through JMX)

For cassandra metrics and when using Prometheus, there is a lot of distinct metrics exporters you could use out there. After distinct attempts with a few distinct exporters, we decided to go with the official one, recommended in Prometheus documentation for collecting JMX metrics (Cassandra, or Kafka are explicitly stated there). This could change in the future but for now we aim at building on top of this exporter, and using default naming (no renaming, yet).

On all the nodes, take the following steps.

* Add jmx_exporter jar file to /usr/share/cassandra/lib/jmx_prometheus_javaagent-0.12.0.jar.

```
$ wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.12.0/jmx_prometheus_javaagent-0.12.0.jar
$ sudo mv jmx_prometheus_javaagent-0.12.0.jar /usr/share/cassandra/lib/jmx_prometheus_javaagent-0.12.0.jar
$ sudo chown cassandra: /usr/share/cassandra/lib/jmx_prometheus_javaagent-0.12.0.jar
```
You can also find it here in tlp-dashboard repository: [jmx_prometheus_javaagent-0.12.0.jar.txt](dashboards/cassandra-environment/jmx_prometheus_javaagent-0.12.0.jar.txt). Rename the file to remove the ending `.txt` in case you downlaod using this source.

* Add the JMX exporter configuration `cassandra_metrics.yml` to `/etc/cassandra`. You can find our version of it here: [config.yaml](dashboards/cassandra-environment/config.yaml). Be sure to rename or/and that the name you use matches with the change in the next step.

* Add a line in `/etc/cassandra/cassandra-env.sh` (default Cassandra configuration folder) as follows to load the library:
```
JVM_OPTS="$JVM_OPTS -javaagent:/usr/share/cassandra/lib/jmx_prometheus_javaagent-0.12.0.jar=9595:/etc/cassandra/cassandra_metrics.yml"
```

* Open the TCP Network (port) 9595 from Prometheus server to each Cassandra server.

### Export Operating System Metrics

For Operating System metrics, the officially recommended exporter is the node_exporter, and that’s what we built our dashboard with.

On all the nodes, take the following steps.

* Add https://github.com/prometheus/node_exporter to the Cassandra nodes. Instructions are in the project readme.

* Open the TCP Network (port) 9100 from Prometheus server to each Cassandra server.

### Configure Prometheus

* Prometheus server scrape configuration needs to be modified depending on your environment and scrape both Cassandra and OS metrics.
```
$ sudo vim /etc/prometheus/prometheus.yml
```

**Examples:**
* Here is an example of static configuration that can be used on-premise or for small clusters:
```
[...]
static_configs:
  - targets: ['<node1_ip_or_fqdn>:9595', '<node1_ip_or_fqdn>:9100']
    labels:
      environment: '<myEnvironment>'
      cluster: '<myCluster>'
      datacenter: '<myDatacenter>'
      rack: '<myRack>'
  - targets: ['<node2_ip_or_fqdn>:9595', '<node2_ip_or_fqdn>:9100']
    labels:
      environment: '<myEnvironment>'
      cluster: '<myCluster>'
      datacenter: '<myDatacenter>'
      rack: '<myRack>
  - targets: ['<node3_ip_or_fqdn>:9595', '<node3_ip_or_fqdn>:9100']
      labels:
      environment: '<myEnvironment>'
      cluster: '<myCluster>'
      datacenter: '<myDatacenter>'
      rack: '<myRack>
relabel_configs:
  - source_labels: [instance]
    regex: '^([0-9.]+).*$'
    replacement: $1
    target_label: node


# [...Other jobs configurations]
```

**OR**

* For bigger AWS cluster you might want to use `tags` feature and a dynamical prometheus configuration like:
```
[...]
scrape_configs:
  - job_name: 'cassandra'
    scrape_interval: 15s

    ec2_sd_configs:
      - port: 9595
        # Filters are more performant than relabel_configs but require Prometheus 2.3+
        #filters:
        #  - name: tag:PrometheusDiscovery
        #    values:
        #      - <tagValue>
      - port: 9100
        #filters:
        #  - name: tag:PrometheusDiscovery
        #    values:
        #      - <tagValue>
    relabel_configs:
      - source_labels: [__meta_ec2_tag_PrometheusDiscovery]
        regex: '^<tagValue>$'
        action: keep
      - source_labels: [__meta_ec2_tag_Name]
        regex: '^(.*)$'
        replacement: '<myEnvironment>'
        target_label: environment
      - source_labels: [__meta_ec2_tag_Name]
        regex: '^(.*)$'
        replacement: '<tagValue>'
        target_label: cluster
      - source_labels: [__meta_ec2_availability_zone]
        regex: '^(.+-.+-[0-9]*).+$'
        replacement: '${1}' # Add datacenter suffix if any
        target_label: datacenter
      - source_labels: [__meta_ec2_availability_zone]
        regex: '^.+-.+-(.+)$'
        replacement: '${1}'
        target_label: rack
      - source_labels: [__meta_ec2_private_ip]
        target_label: node

  - job_name: 'prometheus'
    # [...Other jobs configurations]

```

**OR**

* Other configurations of prometheus are possible, as described in [Prometheus documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)

At this stage, you should be able to see Operating System and Cassandra metrics querying the prometheus expression Browser. It should available at <prometheus_fqdb_or_ip>:9090.
This expression browser allows you to see what Prometheus exposes. It is very handy to build dashboards or to debug a setup that is not working as expected.

### Configure Grafana

Grafana dashboards in JSON format are [here](dashboards/build/distributions/) or [here](dashboards/build/dashboards/com/thelastpickle/dashboards).

* Download and import the JSON files from the Grafana UI.
* Then choose the name of the dashboard and folder where it should be stored.

At this stage, the dashboard should be available and you should have been redirected to it.


Any problem raises? Don't hesitate to create an issue or a pull request to fix the documentation.


## Run locally for development or tests purposes

* Clone the repository
* Run `./gradlew assemble`
* Run `./gradlew preview` to run the entire monitoring stack. This allows to create a docker stack with all the containers needed for local testing/development like grafana, cassandra, promethus, tlp-stress, ... The entire stack is started, see the [docker-compose.yml](dashboards/docker-compose.yml) and [build.gradle](dashboards/build.gradle) files for more details.
* When done with dev/testing, run `./gradlew stopPreview` to stop the monitoring stack.

**Rebuild Dashboards Automatically**
* When working on the grafonnet version of the dashboards, it might be useful to run this in the background or another tab, to detect changes and automatically update json (and thus what you'll see in Grafana): `./gradlew generateDashboards -i -t`
