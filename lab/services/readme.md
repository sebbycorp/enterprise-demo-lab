

## DB

docker run -d -p 1521:1521 \
  --name service-2 \
  -e LISTEN_ADDR=0.0.0.0:1521 \
  -e MESSAGE="Hello from Oracle DB " \
  -e NAME="Oracle DB (Port 1521)" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1


## API
docker run -d -p 9090:9090 \
  --name service-api \
  -e LISTEN_ADDR=0.0.0.0:9090 \
  -e UPSTREAM_URIS="http://10.1.11.104:1521" \
  -e MESSAGE="Hello from API Payments" \
  -e NAME="API Payments (Port 9090)" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1


## Web Front
docker run -d -p 9091:9091 \
  --name service-web2 \
  -e LISTEN_ADDR=0.0.0.0:9091 \
  -e UPSTREAM_URIS="http://10.1.11.102:8080" \
  -e MESSAGE="Hello from Web Front" \
  -e NAME="Web Front (Port 9091)" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1




## Client 1
docker run -d -p 9001:9001 \
  --name service-client1 \
  -e LISTEN_ADDR=0.0.0.0:9001 \
  -e UPSTREAM_URIS="http://10.1.10.103:8080" \
  -e MESSAGE="Hello from Client 1" \
  -e NAME="Client 1" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1

## Client 4
docker run -d -p 9004:9004 \
  --name service-client4 \
  -e LISTEN_ADDR=0.0.0.0:9004 \
  -e UPSTREAM_URIS="http://10.1.10.103:8080" \
  -e MESSAGE="Hello from Client 4" \
  -e NAME="Client 4" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1