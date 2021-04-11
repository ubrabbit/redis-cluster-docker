#!/bin/bash

. ./common.env

mkdir -p $HOME/redis-cluster
cp -f redis-cluster.conf $HOME/redis-cluster/redis-cluster.conf

systemctl is-active --quiet docker
if [ $? != '0' ];then
    echo "restart docker"
    systemctl restart docker
fi

networt_id=`docker network ls | grep redis-cluster-net | awk '{print $1}'`
if [ -z $networt_id ];then
    echo "create docker subnet"
    docker network create redis-cluster-net --subnet=${SUB_NET_PREFIX}.0/16
fi

echo "make cluster dir"
cd $HOME/redis-cluster
for port in `seq ${START_PORT} ${END_PORT}`; do
    rm -rf ./${port} >/dev/null
    mkdir -p ./${port}/conf && cp -f ./redis-cluster.conf ./${port}/conf/redis.conf
    sed -i "s/HOST_PORT/${port}/g" ./${port}/conf/redis.conf
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    cat ./${port}/conf/redis.conf
    mkdir -p ./${port}/data
done
echo "done"
