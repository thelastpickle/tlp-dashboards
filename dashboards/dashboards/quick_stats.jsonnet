local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local template = grafana.template;

local singleStatPanel = grafana.singlestat;

local smallGrid = {
  'w': 4,
  'h': 4
};

dashboard.new(
  'Cassandra Quick Stats',
  schemaVersion=14,
  refresh='1m',
  time_from='now-15m',
  editable=true,
  tags=['Cassandra', 'Stats'],
)
.addTemplate(
  grafana.template.datasource(
    'PROMETHEUS_DS',
    'prometheus',
    'Prometheus',
    hide='label',
  )
)
.addTemplate(
  template.new(
    'environment',
    '$PROMETHEUS_DS',
    'label_values(org_apache_cassandra_metrics_clientrequest_oneminuterate, environment)',
    label='Environment',
    refresh='time',
  )
)
.addTemplate(
  template.new(
    'cluster',
    '$PROMETHEUS_DS',
    'label_values(org_apache_cassandra_metrics_clientrequest_oneminuterate{environment="$environment"}, cluster)',
    label='Cluster',
    refresh='time',
  )
)
.addTemplate(
  template.new(
    'datacenter',
    '$PROMETHEUS_DS',
    'label_values(org_apache_cassandra_metrics_clientrequest_oneminuterate{environment="$environment", cluster="$cluster"}, datacenter)',
    label='Datacenter',
    refresh='time',
    includeAll=true,
    multi=true,
  )
)
.addTemplate(
  template.new(
    'rack',
    '$PROMETHEUS_DS',
    'label_values(org_apache_cassandra_metrics_clientrequest_oneminuterate{environment="$environment", cluster="$cluster", datacenter=~"$datacenter"}, rack)',
    label='Rack',
    refresh='time',
    includeAll=true,
    multi=true,
  )
)
.addTemplate(
  template.new(
    'node',
    '$PROMETHEUS_DS',
    'label_values(org_apache_cassandra_metrics_clientrequest_oneminuterate{environment="$environment", cluster="$cluster", datacenter=~"$datacenter", rack=~"$rack"}, node)',
    label='Node',
    refresh='time',
    current='all',
    includeAll=true,
    multi=true,
  )
)
.addRow(
  row.new(title='Quick Stats')
  .addPanel(
    singleStatPanel.new(
      'Avg CPU',
      description='Average of CPU usage',
      transparent=true,
      timeFrom='',
      gaugeShow=true,
      datasource='$PROMETHEUS_DS',
      span=2,
      format='percentunit',
      decimals=0,
      thresholds='0.50,0.75',
      gaugeMaxValue=1,

    ).addTarget(
        prometheus.target(
        'avg by (environment, cluster) (1 - avg by (environment, cluster, datacenter, rack, node) (irate(node_cpu_seconds_total{mode="idle", environment="$environment", cluster="$cluster", datacenter=~"$datacenter", rack=~"$rack"}[1m])))'
        )
    ), smallGrid
  )
  .addPanel(
    singleStatPanel.new(
      'Avg Network Throughput',
      description='Average of network throughput (in + out)',
      transparent=true,
      timeFrom='',
      datasource='$PROMETHEUS_DS',
      sparklineShow=true,
      format='bps',
      span=2,
    ).addTarget(
        prometheus.target(
        'avg by (environment, cluster) (irate(node_network_receive_bytes_total{environment="$environment", cluster="$cluster", datacenter=~"$datacenter", rack=~"$rack"}[1m]))
        + avg by (environment, cluster) (irate(node_network_transmit_bytes_total{environment="$environment", cluster="$cluster", datacenter=~"$datacenter", rack=~"$rack"}[1m]))'
        )
    ), smallGrid
  )
  .addPanel(
    singleStatPanel.new(
      'Average Disk Throughput',
      description='Average of disk throughput (reads + writes)',
      transparent=true,
      timeFrom='',
      datasource='$PROMETHEUS_DS',
      sparklineShow=true,
      format='bps',
      span=2,
    ).addTarget(
        prometheus.target(
        'avg by (environment, cluster) (irate(node_disk_read_bytes_total{environment="$environment", cluster="$cluster", datacenter=~"$datacenter", rack=~"$rack"}[1m]))'
        )
    ), smallGrid
  )
  .addPanel(
    singleStatPanel.new(
        'Requests per Second',
        description='Request throughput, "RF * numberOfClientRequests"',
        transparent=true,
        timeFrom='',
        datasource='$PROMETHEUS_DS',
        span=2,
        decimals=0,
        format='rps',
        sparklineShow=true,
    )
    .addTarget(
        prometheus.target(
            'sum by (environment, cluster) (irate(org_apache_cassandra_metrics_threadpools_value{scope="Native-Transport-Requests", name="CompletedTasks", environment="$environment", cluster="$cluster", datacenter=~"$datacenter", rack=~"$rack",}[1m]))'
        )
    ), smallGrid
  )
  .addPanel(
    singleStatPanel.new(
        'Blocked Tasks',
        datasource='$PROMETHEUS_DS',
        description='Sum of blocked tasks',
        timeFrom='',
        transparent=true,
        format='short',
        span=2,
    )
    .addTarget(
        prometheus.target(
          'sum by (environment, cluster) (irate(org_apache_cassandra_metrics_threadpools_count{name="TotalBlockedTasks", environment="$environment", cluster="$cluster", datacenter=~"$datacenter", rack=~"$rack"}[1m]))'
        )
    ), smallGrid
  )
)
