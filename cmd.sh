#!/bin/bash

. ./common.env

function stop_container() {
    tmp_pkg="redis-cluster"
    echo "ready stop "${tmp_pkg}
    docker ps | grep ${tmp_pkg} | awk '{print $1}' | while read line;
    do
        if [ -z "$line" ];
        then
            continue
        fi
        docker stop ${line} >/dev/null 2>&1
        echo "stop "${line}" success"
    done
    echo "stop all "${tmp_pkg}" finish"
    return 0
}

function start_container() {
    IP_CUNTER="1"
    for port in `seq ${START_PORT} ${END_PORT}`; do
        let "IP_CUNTER=$IP_CUNTER+1"
        IP="${SUB_NET_PREFIX}.${IP_CUNTER}"
        echo "node ${port} USE IP: ${IP}"
        docker run -d -ti -v $HOME/redis-cluster/${port}/conf/redis.conf:/usr/local/etc/redis/redis.conf \
        -v $HOME/redis-cluster/${port}/data:/data \
        -p 127.0.0.1:${port}:${port} \
        --restart always \
        --network redis-cluster-net \
        --ip $IP \
        --sysctl net.core.somaxconn=10240 redis-cluster /usr/local/bin/redis-server /usr/local/etc/redis/redis.conf
    done
}

function rm_all_images() {
    docker stop $(docker ps -q) >/dev/null 2>&1
    docker rm $(docker ps -aq) >/dev/null 2>&1
    echo "remove all container finish"

    hangout_images=`docker images -aq -f "dangling=true"`
    if [ ! -z "${hangout_images}" ]; then
        echo "remove hangout images"
        docker rmi $hangout_images
        echo "remove all images finish"
    fi
    return 0
}

function init_cluster() {
    echo "init_cluster"
    CONTAINER_ID=`docker container ls | grep redis | head -n 1 | awk '{print $1}'`
    if [ -z $CONTAINER_ID ];then
        echo "找不到容器ID"
        exit 1
    fi

    IP_LIST=""
    IP_CUNTER="1"
    for port in `seq ${START_PORT} ${END_PORT}`; do
        let "IP_CUNTER=$IP_CUNTER+1"
        IP="${SUB_NET_PREFIX}.${IP_CUNTER}"
        IP_LIST="${IP_LIST} ${IP}:${port}"
    done
    echo ${IP_LIST}
    redis-cli --cluster create $IP_LIST --cluster-replicas 1
}

function list_cluster() {
    echo "list_cluster"
    redis-cli -c -p ${START_PORT} cluster info
}

function test_cluster() {
    echo "test_cluster"
    redis-cli -c -p ${START_PORT}
}

function build(){
    docker build -t "redis-cluster" -f "Dockerfile" .
}


CMD=$1
case ${CMD} in
    build) build;;
    stop)  stop_container;;
    start) start_container;;
    init) init_cluster;;
    list) list_cluster;;
    test) test_cluster;;
    rmi)  rm_all_images;;
    *)
        echo "invalid CMD"
        echo "example: ./cmd.sh [build|stop|start|init|list|test|rmi]"
        ;;
esac
