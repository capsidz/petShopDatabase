#### Запуск
```
docker run -d --name clickhouse-server 
-p 8123:8123 -p 9000:9000 
--ulimit nofile=262144:262144 
clickhouse/clickhouse-server
```

```
docker exec -it clickhouse-server clickhouse-client
```

#### 2. Создание таблицы
```
CREATE TABLE trips
(
    trip_id UInt32,
    start_time DateTime,
    end_time DateTime,
    distance_km Float32,
    city String
)
ENGINE = MergeTree()
ORDER BY (city, start_time);
```

Query id: 26a2ec78-b019-4e37-8788-97075baf52da
Ok.
0 rows in set. Elapsed: 0.066 sec.


#### 3. Наполнение данными
```
INSERT INTO trips
SELECT
    number AS trip_id,
    now() - randUniform(0, 30 * 24 * 3600) AS start_time,
    start_time + randUniform(300, 7200) AS end_time,
    round(randUniform(1, 50), 2) AS distance_km,
    arrayRandomSample(['Москва', 'Санкт-Петербург', 'Новосибирск', 'Екатеринбург', 'Казань'], 1)[1] AS city
FROM numbers(1000000);
```

Query id: 1b86ec43-f186-42a2-9bb0-9588f04ebf36
Ok.
1000000 rows in set. Elapsed: 1.227 sec. Processed 1.00 million rows, 8.00 MB (815.14 thousand rows/s., 6.52 MB/s.)
Peak memory usage: 97.78 MiB.

```
SELECT count() FROM trips;
```

Данные заполнились:

Query id: bc2d8404-571e-4fb2-b5a9-5971a134eb94
   ┌─count()─┐
1. │ 1000000 │
   └─────────┘
1 row in set. Elapsed: 0.006 sec.


#### 4. Написание аналитического запроса
```
SELECT
    city,
    round(avg(distance_km), 2) AS avg_distance,
    count() AS trip_count,
    max(toUnixTimestamp(end_time) - toUnixTimestamp(start_time)) AS max_duration_sec
FROM trips
GROUP BY city
ORDER BY trip_count DESC;
```

Query id: 4b3ea88e-833d-414f-9f75-6e84e873e436
   ┌─city────────────┬─avg_distance─┬─trip_count─┬─max_duration_sec─┐
1. │ Екатеринбург    │        25.58 │     200376 │             7199 │
2. │ Москва          │        25.46 │     200076 │             7199 │
3. │ Санкт-Петербург │        25.48 │     199971 │             7199 │
4. │ Новосибирск     │        25.54 │     199914 │             7199 │
5. │ Казань          │        25.54 │     199663 │             7199 │
   └─────────────────┴──────────────┴────────────┴──────────────────┘
5 rows in set. Elapsed: 0.042 sec. Processed 1.00 million rows, 34.80 MB (23.86 million rows/s., 830.45 MB/s.)
Peak memory usage: 23.91 MiB.

