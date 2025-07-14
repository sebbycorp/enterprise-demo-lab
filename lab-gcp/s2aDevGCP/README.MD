# Demo Reote engings for GCP

If you are running S2A in kind in GCP follow the following rules

## Build the remote engine

### Set the base URL
You can set the base URL for the remote engines by exporting the `S2_BASE_URL` environment variable. This is useful if you want to use a custom domain or if you are running S2A in a different environment.

```bash
export S2_BASE_URL="your-custom-domain.com"
```

### Deploy the remote engines 

You can deploy the remote engines by running the following command. This will download the necessary scripts and set up the remote engines.

```bash
chmod +x ./deploy-engines.sh
./deploy-engines.sh
```


## S2 Kind Important things to concider.

Make sure you do the following 

1. ./s2ctl.sh install 
2. ./s2ctl.sh gets2mspecs

## Import the following metastore and inventory

2. Import the metastore schema 
    - This file is located in the `lab-gcp/s2aDevGCP/metastore/metastore-schema-gcp.json` directory.
3. Import the metastore2 inventory
    - This file is located in the `lab-gcp/s2aDevGCP/metastore/metastore2-inv.zip` directory.
4. Import the SNMP configuration for Arista, haproxy and vyos
5. Import the restpull to pull customer inventory into s2_inventory
6. Edit the s2ml.manifest.yaml file to include the new engines
  - ssh into your server /opt/s2/deployments/config/default/s2ml
  - Edit the `s2ml.manifest.yaml` file to include the new engines.

```yaml
# s2ml.manifest.yaml
manifests:
  include:
     - ../../base/s2ml-common/s2ml-infra.manifest
     - ../../base/s2ml-common/snmptrap/s2ml.snmptrap-manifest
     - ../../base/s2ml-common/pingmesh/s2ml.pingmesh-manifest
     - ../../base/s2ml-common/snmp/s2ml.snmp-solutions-manifest
     - ../../base/s2ml-common/gnmi/s2ml.gnmi-manifest
     - ../../base/s2ml-common/snmp/vendor/arista/s2ml-snmp-arista.manifest
     - ../../base/s2ml-common/arista_cue/s2ml_arista_cue.manifest
     - ../../base/s2ml-common/logs/s2ml-syslog.manifest
     - ../../base/s2ml-common/engine2_manager/s2ml.engine2-manager-manifest
```

## Set the context for s2ctl (If you havent)

You need to set the context for `s2ctl` to work with your deployment. You can do this by running the following command:

```bash
s2ctl set-context
```

Example output:
```yaml
Set s2ctl context
-------------------
Config File "s2ctl.conf" Not Found in "[/root/.s2ctl]"
+ Select/Create s2ctl context [* is current pick]
  [1] Create new context

  Enter number: 1

+ Pick kubernetes context
  [1] kind-kind

  Enter number: 1
  Enter path of deployment directory? []: /opt/s2/deployments/config/default
  Enter context config name? []: default
  Set current-context kind-kind
  Set namespace to s2 for kind-kind
  - Save context to [/root/.s2ctl/s2ctl.conf]
    [name:       default]
    [k8s:        kind-kind]
    [deployment: /opt/s2/deployments/config/default]
```

## Apply the S2ML manifest
You can apply the S2ML manifest by running the following command:

```bash

1. Start proxy and apply> s2ctl apply s2ml -u http://localhost:8000/s2mlmanager/manifest
2. kubectl port-forward svc/s2-s2mlmanager 8000:80 & s2ctl apply s2ml -u http://localhost:8000/manifest
```

