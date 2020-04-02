# tlp-dashboards

Cassandra Dashboards based on Prometheus and Grafana

## Run locally for development or tests purposes

* Clone the repository
* Run `./gradlew assemble`
* Run `./gradlew preview` to run the entire monitoring stack.
* When done, run `./gradlew stopPreview` to stop the monitoring stack

**Rebuild Dashboards Automatically**
* When working on the grafonnet version of the dashboards, it might be useful to run this in the background or another tab, to detect changes and automatically update json (and thus what you'll see in Grafana): `./gradlew generateDashboards -i -t`

## Use the dashboards for production clusters

WIP

### Prerequisite

WIP

- Grafana 6.3+ server installed
- Prometheus 2.11.1 server installed
- node_exporter installed on the nodes
- ..

### Prometheus server and jmx_exporter configuration

WIP

### TODO

### Get the dashboards JSON

The JSON version of the dashboards, ready for import in Grafana are available in `dashboards/build/distribution/`
