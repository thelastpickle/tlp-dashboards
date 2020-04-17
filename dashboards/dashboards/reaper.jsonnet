local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local graphPanel = grafana.graphPanel;
local tablePanel = grafana.tablePanel;
local singleStatPanel = grafana.singlestat;

local textPanel = grafana.text;
local prometheus = grafana.prometheus;
local template = grafana.template;

dashboard.new(
  'Cassandra Reaper',
  schemaVersion=14,
  refresh='10s',
  time_from='now-15m',
  editable=true,
  tags=['Cassandra', 'Reaper', 'Repair'],
)
.addTemplate(
  grafana.template.datasource(
    'PROMETHEUS_DS',
    'prometheus',
    'Prometheus',
    hide='label',
  )
)
.addRow(
  row.new(title='Repair Performance')
  .addPanel(
    graphPanel.new(
      'Segment duration (p50)',
      description='Time it took to repair an average segment. Ideally, this is somewhere around 10 minutes.',
      format='seconds',
      datasource='$PROMETHEUS_DS',
      transparent=true,
      fill=0,
      legend_show=true,
      legend_values=true,
      legend_current=true,
      legend_alignAsTable=true,
      legend_sort='current',
      legend_sortDesc=true,
      shared_tooltip=false,
      min=0,
    )
    .addTarget(
      prometheus.target(
        'io_cassandrareaper_service_SegmentRunner_repairing{quantile="0.5"}',
        legendFormat='{{cluster}}.{{keyspace}}',
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'Repair Progress',
      description='How the repairs progressed over time. A curve that flattens indicates a repair stalled.',
      format='percentunit',
      datasource='$PROMETHEUS_DS',
      transparent=true,
      fill=0,
      legend_show=true,
      legend_values=true,
      legend_current=true,
      legend_alignAsTable=true,
      legend_sort='current',
      legend_sortDesc=true,
      shared_tooltip=false,
      min=0,
    )
    .addTarget(
      prometheus.target(
        'io_cassandrareaper_service_RepairRunner_repairProgress',
        legendFormat='{{cluster}}.{{keyspace}}',
      )
    )
  )
  .addPanel(
    tablePanel.new(
      'Most Recent Repair Progress',
      description='The current state of repair for each cluster.table pair',
      datasource='$PROMETHEUS_DS',
      transform='timeseries_aggregations',
      transparent=true,
      styles=[
        {
          "alias": "Cluster.Keyspace",
          "colorMode": null,
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "mappingType": 1,
          "pattern": "Metric",
          "preserveFormat": true,
          "sanitize": true,
          "thresholds": [],
          "type": "string",
          "unit": "short"
        },
        {
          "alias": "Progress",
          "colorMode": null,
          "dateFormat": "YYYY-MM-DD HH:mm:ss",
          "decimals": 2,
          "link": false,
          "mappingType": 1,
          "pattern": "Current",
          "type": "number",
          "unit": "percentunit"
        }
      ],
      columns=[
        {
          "text": "Current",
          "value": "current"
        }
      ],
      sort={
        "col": 1,
        "desc": true
      }
    )
    .addTarget(
      prometheus.target(
        'io_cassandrareaper_service_RepairRunner_repairProgress',
        legendFormat='{{cluster}}.{{keyspace}}',
        instant=true
      )
    )
  )
)
