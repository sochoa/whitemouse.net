#!/bin/bash -x
echo "Stopping and removing containers"
for CONTAINER in wordpress{,_db}; do 
  docker kill "${CONTAINER}" 2>&1
  docker rm -f "${CONTAINER}" 2>&1
done

echo "Removing stopped contianers"
docker ps -a                       \
  | tail -n +2                     \
  | awk '{print $1}'               \
  | xargs docker rm -f 2>/dev/null
