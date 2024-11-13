# Monitoring using Prometheus and Grafana

## Grafana

Grafana allows us to query, visualize, alert on and understand metrics no matter where they are stored. We can create, explore and share dashboards with teams and foster a data driven culture. It is open platform for analytics and monitoring. It's also leading open source software for time-series analysis. It provides data visualization and monitoring with support for postgres, Graphite, InfluxDB, Prometheus, Cloudwatch and many more dashboards. Grafana has many visualization options to understand data.
Grafana provides features for following.
- Visualization: Fast & flexible client side graphs with multitude options. Panel plugins for many different ways to visualize metrics and logs.
- Dynamic Dashboards: Create dynamic & reusable dashboards with template variables that appear as dropdowns at the top of the dashboard.
- Explore Metrics: Explore data through ad-hoc queries and dynamic drilldown. Split view and compare different time ranges, queries and data sources side by side.
- Explore Logs: Experience the magic of switching from metrics to logs with preserved label filters. Option to search through all logs or streaming them live.
- Alerting: Visually define alert rules for important metrics. Grafana will continuously evaluate and send notifications to systems like Slack, PagerDury, OpsGenie.
- Mixed Data Sources: Mix different data sources in the same graph. We can specify data source on a per-query basis. This is also available for custom data sources.

### Installation:

1. Launch Amazon EC2 instance (ubuntu) with port 3000 open for Grafana UI.
2. Install latest version of Grafana.

```shell
sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list 
sudo apt-get update
sudo apt-get install grafana
```

3. Start the server

```shell
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl status grafana-server
sudo systemctl enable grafana-server.service
```

4. Access `<PUBLIC_IP>:3000` for accessing UI. The default username and password is `admin`.
5. Click *Add Data Source* and search for *CloudWatch*.
6. In Settings, for *Auth Provider* select *Access and Secret Key* and provide those details along with other details for AWS account. Save Settings and it should show that Data source is setup.
7. Click Create Dashboard. Then click on *Add new panel*.
8. In *Query* tab, select *CloudWatch* data source. For Query mode select *Cloudwatch Metrics*. Select Region and for *Namespace* select AWS/EC2. Select Metric Name and other paramters.
9. Click Apply and Save.
10. To change visualization, click on Panel and Visualization and select different kind of visualization.

## Prometheus

It is an open-source system monitoring for machine centric and highly dynamic service-oriented architectures. For this, we write `prometheus.yml` file which helps to configure targets via a static configuration file. It has multi-dimensional data model with time-series data identified by metric name and key/value pairs. It also has flexible query language to leverage this dimensionality and integrates with Grafana since Grafana also offers Prometheus as one of the data sources.

### Installation:

1. Launch EC2 (CentOS) server on AWS with port 9090 open in security group.
2. Install Prometheus

```shell
yum install wget
wget https://github.com/prometheus/prometheus/releases/download/v2.20.0/prometheus-2.20.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
cd prometheus-2.20.0.linux-amd64/
vi prometheus.yml
```

3. Configure Prometheus if needed using file `prometheus.yml` file. By default, it will scrape data for the host where Prometheus is running.
4. Start Prometheus server and check port 9090 on `<PUBLIC_IP>:9090/metrics` address.

```shell
./prometheus --config.file=prometheus.yml
```
5. In the UI, click *Status* and *Targets*, you will see Endpoint for Prometheus.

### Integrating Grafana and Prometheus

Go to DataSource. Search for Prometheus Data source and add it. It will ask for Prometheus URL with port 9090. Save and Test.

Create new dashboard and add new panel. Select Data Source as Prometheus. 
In Metrics, write the counter name from Prometheus.

### Integrate Grafana with Prometheus

1. Enable metric collection in Grafana configuration `/etc/grafana/grafana.ini` file. By default, this is disabled. Uncomment internal metrics and restart Grafana server. Remove semi-colon from `enable = true` line. Restart Grafana using `sudo systemctl restart grafana-server`.
2. Grafana also exposes metrics on `PUBLIC_IP:3000/metrics` URL location. To use this on Prometheus server, go to Prometheus server and open `prometheus.yml` configuration file. Under `scrape_configs`, select complete job including `targets` and create another job using that. 
3. Modify *job_name* as `grafana` and *target* to `PUBLIC_IP:3000` for Grafana public IP address.
4. Restart Prometheus server and check UI. Go to *Status* and click *Targets* to check that we have Grafana endpoint available.
5. Select one of the metric, go to Graph and in the expression browser, just paste that metric and click *Execute*.
6. In Grafana, now we can access this Grafana metrics using same Prometheus Data Source.

### Using Node Exporter

Node exporter can be used to collect metric of host and export them on endpoint which can be used by Prometheus. It allows Prometheus to collect metrics from any generic host which can execute node exporter. Prometheus Node Exporter for hardware and OS metrics exposed by UNIX kernels, is written in Go with pluggable metric collectors. There are different node exporters for Windows, NVIDIA GPU metrics, etc.

1. Launch another EC2 (CentOS) machine with port 8080 and 9100 opened in security group and connect to that machine using SSH.
2. Install Docker on this machine using `yum install docker`
3. Start Flask app using `docker run -d -p 8080:4080 --name flaskapp <username>/flaskapp`. Try connecting to `<PUBLIC_IP>:8080` address.
4. Start a node exporter on this node

```shell
yum install wget
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
ls -l
tar xvfz node_exporter-1.0.1.linux-amd64.tar.gz
cd node_exporter-1.0.1.linux-amd64
./node_exporter
```

5. Verify that you can access Node exporter metrics are accessible on port 9100 (default). Check `<PUBLIC_IP>:9100/metrics` URL.
6. Go to Prometheus server, create another job to scrape metrics from this new *webserver*. Make sure to edit the *targets* section to the IP address of this new webserver with port 9100.
7. Restart Prometheus server using `./prometheus --config.file=prometheus.yml`
8. Verify under *Status* --> *Targets* that new webserver metrics are now being scrapped on Prometheus UI.
9. Create new Dashboard on Grafana UI using Prometheus as Data Source.


### Monitoring Docker using Grafana

1. Configure our *webserver* docker to export metrics. Edit `/etc/docker/daemon.json` file and update as below.

```json
{
  "metrics-addr": "0.0.0.0:9323",
  "experimental": true
}
```

2. Restart Docker service using `sudo systemctl restart docker`.
3. Open port 9323 in security group for *webserver* instance. Access `<PUBLIC_IP>:9323` address on browser. It should display KPIs from docker engine.
4. Configure Prometheus server with configuration for `docker` job. Modify the port and IP address for targets. Restart the service and verify that the target is available in Prometheus UI.
5. Once this target is available for Prometheus, we can use different KPIs for visualization in Grafana.

### Importing Grafana Dashboards

If you want to use already available dashboards, you can visit [https://grafana.com/grafana/dashboards](https://grafana.com/grafana/dashboards) and checkout some of the available dashboards. Import them into your Grafana instance and setup the Data Source according to your needs.