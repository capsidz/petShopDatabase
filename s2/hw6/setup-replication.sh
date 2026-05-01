#!/bin/bash

# Ожидание запуска master
sleep 10

# Перезагрузка конфигурации у мастера
docker exec pg-master psql -U postgres -c "SELECT pg_reload_conf();"

# Настройка Replica 1
echo "Настройка Replica 1..."
docker exec pg-replica1 bash -c "
    rm -rf /var/lib/postgresql/data/*
    PGPASSWORD='replicator_password' pg_basebackup -h pg-master -U replicator -D /var/lib/postgresql/data -P -R
"

# Настройка Replica 2
echo "Настройка Replica 2..."
docker exec pg-replica2 bash -c "
    rm -rf /var/lib/postgresql/data/*
    PGPASSWORD='replicator_password' pg_basebackup -h pg-master -U replicator -D /var/lib/postgresql/data -P -R
"

echo "Репликация настроена!"