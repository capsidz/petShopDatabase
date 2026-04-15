#### 1. Секционирование: RANGE 
Создание партиционированную таблицу 
```
CREATE TABLE cleaning_assignments (
    cleaner_id     INT NOT NULL REFERENCES employee(id),
    cage_id        INT NOT NULL REFERENCES cage(id),
    cleaning_date  DATE NOT NULL,
    is_completed   BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (cleaner_id, cage_id, cleaning_date)
) PARTITION BY RANGE (cleaning_date);
```

Создание партиции
```
CREATE TABLE cleaning_june2026 PARTITION OF cleaning_assignments
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
```

```
CREATE TABLE cleaning_july2026 PARTITION OF cleaning_assignments
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
```

Индекс на колонку секционирования внутри партиций
```
CREATE INDEX idx_cleaning_date ON cleaning_assignments(cleaning_date);
```

План
```
EXPLAIN ANALYZE SELECT * FROM cleaning_assignments WHERE cleaning_date = '2026-06-15';
```

```
                                                                 QUERY PLAN                                             
---------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on cleaning_june2026 cleaning_assignments  (cost=4.23..14.79 rows=10 width=13) (actual time=0.044..0.046 rows=1 loops=1)
   Recheck Cond: (cleaning_date = '2026-06-15'::date)
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on cleaning_june2026_cleaning_date_idx  (cost=0.00..4.23 rows=10 width=0) (actual time=0.005..0.006 rows=1 loops=1)
         Index Cond: (cleaning_date = '2026-06-15'::date)
 Planning Time: 0.458 ms
 Execution Time: 0.084 ms
(7 rows)
```

1) есть ли partition pruning - Да
2) сколько партиций участвует в плане - 1 партиция (cleaning_june2026)
3) используется ли индекс - Да

#### Секционирование: LIST 
Секционируем породы по типу животного. Кошки - 1, Собаки - 2, остальные
```
CREATE TABLE breed (
    id              SERIAL,
    breed_name      VARCHAR(100) NOT NULL,
    animal_type_id  INT NOT NULL,
    average_weight  NUMERIC(5,2),
    PRIMARY KEY (id, animal_type_id) 
) PARTITION BY LIST (animal_type_id);
```

Партиции
```
CREATE TABLE breed_cats PARTITION OF breed FOR VALUES IN (1);
CREATE TABLE breed_dogs PARTITION OF breed FOR VALUES IN (2);
CREATE TABLE breed_other PARTITION OF breed DEFAULT; 
```

Индекс
```
CREATE INDEX idx_breed_type ON breed(animal_type_id);
```

План
```
EXPLAIN ANALYZE 
SELECT * FROM breed WHERE animal_type_id = 1;
```

```
                                                              QUERY PLAN                                                
--------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on breed_cats breed  (cost=4.16..9.50 rows=2 width=238) (actual time=0.014..0.015 rows=0 loops=1)
   Recheck Cond: (animal_type_id = 1)
   ->  Bitmap Index Scan on breed_cats_animal_type_id_idx  (cost=0.00..4.16 rows=2 width=0) (actual time=0.004..0.005 rows=0 loops=1)
         Index Cond: (animal_type_id = 1)
 Planning Time: 0.657 ms
 Execution Time: 0.050 ms
```

1) есть ли partition pruning - Да
2) сколько партиций участвует в плане - 1 партиция (breed_cats)
3) используется ли индекс - Да


#### Секционирование: HASH 
Секционируем клиентов на 3 партиции по хэшу от их id
```
CREATE TABLE client (
    id              INT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    surname         VARCHAR(100) NOT NULL,
    passport_data   VARCHAR(100) NOT NULL,
    petshop_id      INT NOT NULL,
    PRIMARY KEY (id)
) PARTITION BY HASH (id);
```

Партиции
```
CREATE TABLE client_hash_0 PARTITION OF client FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE client_hash_1 PARTITION OF client FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE client_hash_2 PARTITION OF client FOR VALUES WITH (MODULUS 3, REMAINDER 2);
```

План
```
EXPLAIN ANALYZE 
SELECT * FROM client WHERE id = 42;
```

```
                                                                QUERY PLAN                                              
-------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using client_hash_0_pkey on client_hash_0 client  (cost=0.14..8.16 rows=1 width=662) (actual time=0.003..0.004 rows=0 loops=1)
   Index Cond: (id = 42)
 Planning Time: 0.378 ms
 Execution Time: 0.019 ms
(4 rows)
```

1) есть ли partition pruning - Да
2) сколько партиций участвует в плане - 1 партиция (client_hash_0)
3) используется ли индекс - Да, Index Scan 


#### 2. Секционирование и физическая репликация
1. Проверить что секционирование есть на репликах
```
\d client
```
Точно такая же структура таблиц

2. Почему репликация “не знает” про секции?
Физическая репликация работает на уровне WAL. Она работает с физическими блоками данных на диске. Для него партиции — это просто набор разных файлов на диске, в которые вносятся изменения. Она не знает, что такое PARTITION BY RANGE, она просто синхронизирует файлы


#### 3. Логическая репликация и секционирование publish_via_partition_root = on / off
1. publish_via_partition_root = off (По умолчанию)
Когда этот параметр отключен, Postgres транслирует изменения так, будто реплицируются сами дочерние партиции, а не их родительская таблица.
На приемнике реплике обязаны существовать точно такие же таблицы-партиции и структура должна полностью совпадать. Изменения публикуются от имени дочерних таблиц

2. publish_via_partition_root = on
```
CREATE PUBLICATION my_partition_pub FOR TABLE client WITH (publish_via_partition_root = true);
```
Все операции INSERT/UPDATE/DELETE над партициями будут фиксироваться в потоке репликации так, будто они произошли с самой таблицей.
На реплике таблица client может быть не секционированной. 


#### 4. Шардирование через postgres_fdw
1. Настройка Шардов (Shard 1 и Shard 2)
На первом шарде мы будем хранить клиентов с четными ID, на втором — с нечетными

На shard1 
```
CREATE TABLE client_shard_1 (
    id              INT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    surname         VARCHAR(100) NOT NULL,
    passport_data   VARCHAR(100) NOT NULL,
    petshop_id      INT NOT NULL
);
```

На shard2
```
CREATE TABLE client_shard_2 (
    id              INT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    surname         VARCHAR(100) NOT NULL,
    passport_data   VARCHAR(100) NOT NULL,
    petshop_id      INT NOT NULL
);
```

2. Настройка роутера
Расширение для работы с удаленными серверами
```
CREATE EXTENSION postgres_fdw;
```

Регистрация удаленных серверов (шарды)
```
CREATE SERVER shard1_server FOREIGN DATA WRAPPER postgres_fdw 
OPTIONS (host 'pg-shard1-host', port '5432', dbname 'homework');
```
```
CREATE SERVER shard2_server FOREIGN DATA WRAPPER postgres_fdw 
OPTIONS (host 'pg-shard2-host', port '5432', dbname 'homework');
```

Маппинг пользователей (чтобы роутер мог авторизоваться на шардах)
```
CREATE USER MAPPING FOR postgres SERVER shard1_server 
OPTIONS (user 'postgres', password 'superpassword');
```
```
CREATE USER MAPPING FOR postgres SERVER shard2_server 
OPTIONS (user 'postgres', password 'superpassword');
```

Внешние таблицы, указывающие на шарды
```
CREATE FOREIGN TABLE foreign_client_1 (
    id              INT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    surname         VARCHAR(100) NOT NULL,
    passport_data   VARCHAR(100) NOT NULL,
    petshop_id      INT NOT NULL
) SERVER shard1_server OPTIONS (table_name 'client_shard_1');
```
```
CREATE FOREIGN TABLE foreign_client_2 (
    id              INT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    surname         VARCHAR(100) NOT NULL,
    passport_data   VARCHAR(100) NOT NULL,
    petshop_id      INT NOT NULL
) SERVER shard2_server OPTIONS (table_name 'client_shard_2');
```

Объединяем шарды через партиционирование на роутере
```
CREATE TABLE client_sharded (
    id              INT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    surname         VARCHAR(100) NOT NULL,
    passport_data   VARCHAR(100) NOT NULL,
    petshop_id      INT NOT NULL,
    PRIMARY KEY (id)
) PARTITION BY HASH (id);
```

```
-- Вместо обычных таблиц привязываем FOREIGN таблицы как партиции
ALTER TABLE client_sharded ATTACH PARTITION foreign_client_1 FOR VALUES WITH (MODULUS 2, REMAINDER 0);
ALTER TABLE client_sharded ATTACH PARTITION foreign_client_2 FOR VALUES WITH (MODULUS 2, REMAINDER 1);
```
при вставке в client_sharded, роутер сам посчитает хэш и отправит строку на нужный физический сервер

3. Запросы и анализ планов (EXPLAIN)
```
INSERT INTO client_sharded VALUES (2, 'Иван', 'Иванов', '1111', 1); -- уйдет на Shard 1 (т.к. id=2)
INSERT INTO client_sharded VALUES (3, 'Петр', 'Петров', '2222', 1); -- уйдет на Shard 2 (т.к. id=3)
```

3.1. Простой запрос на ВСЕ данные (Сканирование всех шардов)
```
EXPLAIN ANALYZE SELECT * FROM client_sharded;
```

Вывод:
```
                                                                 QUERY PLAN                                             
---------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=100.00..228.33 rows=238 width=662) (actual time=4.981..9.308 rows=2 loops=1)
   ->  Foreign Scan on foreign_client_1 client_sharded_1  (cost=100.00..113.57 rows=119 width=662) (actual time=4.978..4.980 rows=1 loops=1)
   ->  Foreign Scan on foreign_client_2 client_sharded_2  (cost=100.00..113.57 rows=119 width=662) (actual time=4.311..4.313 rows=1 loops=1)
 Planning Time: 1.249 ms
 Execution Time: 11.837 ms
(5 rows)
```
Используется Append
Внутри него будут находиться узлы Foreign Scan on foreign_client_1 и Foreign Scan on foreign_client_2
Роутер выполнит два параллельных или последовательных сетевых запроса к обоим шардам, соберет результаты вместе

3.2. Простой запрос на конкретный Шард 
```
EXPLAIN ANALYZE SELECT * FROM client_sharded WHERE id = 2;
```

Вывод:
```
                                                            QUERY PLAN                                                  
-----------------------------------------------------------------------------------------------------------------------------------
 Foreign Scan on foreign_client_1 client_sharded  (cost=100.00..111.51 rows=1 width=662) (actual time=8.869..8.872 rows=1 loops=1)
 Planning Time: 3.377 ms
 Execution Time: 10.201 ms
(3 rows)
```
Благодаря partition pruning, postgres поймет, что id = 2 соответствует условию первой партиции
В плане запроса останется только один узел: Foreign Scan on foreign_client_1
Второй шард опрашиваться по сети вообще не будет

