#!/bin/bash

sleep 10

# Перечитываем конфиг мастера
docker exec pg_master psql -U postgres -c "SELECT pg_reload_conf();"

# Настройка replica1
echo "Настройка replica1..."
docker exec pg_replica1 bash -c "
    rm -rf /var/lib/postgresql/data/*
    PGPASSWORD='replicator_password' pg_basebackup -h pg_master -U replicator -D /var/lib/postgresql/data -R
"

# Настройка replica2
echo "Настройка replica2..."
docker exec pg_replica2 bash -c "
    rm -rf /var/lib/postgresql/data/*
    PGPASSWORD='replicator_password' pg_basebackup -h pg_master -U replicator -D /var/lib/postgresql/data -R
"

echo "Готово!"