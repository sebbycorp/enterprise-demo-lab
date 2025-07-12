docker run -d \
  --name=kasm \
  --network=ceos_clab \
  -p 6901:6901 \
  -e VNC_PW=mypassword \
  --shm-size=512m \
  kasmweb/desktop:1.15.0

