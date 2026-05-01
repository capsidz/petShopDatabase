## Кластер Cassandra из 3 нод
```
docker exec -it cassandra-1 nodetool status
```

Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack
UN  172.22.0.2  114.68 KiB  16      100.0%            f73e2c39-eba0-48b5-9450-5db255a2ad59  rack1

## Создание Keyspace и таблиц
```
docker exec -it cassandra-1 cqlsh
```

ATTENTION: All commands will be saved to history file: /root/.cassandra/cqlsh_history
This may include sensitive information such as passwords.
To disable history, use --disable-history or set 'disabled = true' in the [history] section of cqlshrc.
See https://cassandra.apache.org/doc/latest/tools/cqlsh.html for more information.

Connected to PetshopCluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.8 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.

### Создание Keyspace
```
CREATE KEYSPACE petshop_keyspace 
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};
```

```
USE petshop_keyspace;
```

### Создание таблиц
#### 1. Поиск питомца по его уникальному id
```
CREATE TABLE pets_by_id (
    pet_id int,
    petshop_id int,
    name text,
    breed_name text,
    age int,
    PRIMARY KEY (pet_id)
);
```

#### 2. Поиск всех питомцев в конкретном магазине (petshop_id), отсортированных по возрасту
```
CREATE TABLE pets_by_shop (
    petshop_id int,
    age int,
    pet_id int,
    name text,
    breed_name text,
    PRIMARY KEY (petshop_id, age, pet_id)
) WITH CLUSTERING ORDER BY (age DESC, pet_id ASC);
```


#### 3. Заполнение одинаковыми данными
```
INSERT INTO pets_by_id (pet_id, petshop_id, name, breed_name, age) VALUES (1, 101, 'Шарик', 'Корги', 3);
INSERT INTO pets_by_id (pet_id, petshop_id, name, breed_name, age) VALUES (2, 101, 'Барсик', 'Сиамский', 5);
```

```
INSERT INTO pets_by_shop (pet_id, petshop_id, name, breed_name, age) VALUES (1, 101, 'Шарик', 'Корги', 3);
INSERT INTO pets_by_shop (pet_id, petshop_id, name, breed_name, age) VALUES (2, 101, 'Барсик', 'Сиамский', 5);
```

#### 4. CRUD-операции и проверка ограничения ключей
##### Запросы SELECT
```
SELECT * FROM pets_by_id WHERE pet_id = 1;
```
 pet_id | age | breed_name | name  | petshop_id
--------+-----+------------+-------+------------
      1 |   3 |      Корги | Шарик |        101

(1 rows)


```
SELECT * FROM pets_by_shop WHERE petshop_id = 101;
```
 petshop_id | age | pet_id | breed_name | name
------------+-----+--------+------------+--------
        101 |   5 |      2 |   Сиамский | Барсик
        101 |   3 |      1 |      Корги |  Шарик

(2 rows)

Поиск по не-ключевому  полю
```
SELECT * FROM pets_by_id WHERE name = 'Шарик';
```
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"


##### Запросы UPDATE
```
UPDATE pets_by_id SET breed_name = 'Пемброк-корги' WHERE pet_id = 1;
```

```
UPDATE pets_by_shop SET breed_name = 'Пемброк-корги' WHERE petshop_id = 101 AND age = 3 AND pet_id = 1;
```


##### Запросы DELETE
```
DELETE FROM pets_by_id WHERE pet_id = 2;
```

```
DELETE FROM pets_by_shop WHERE petshop_id = 101 AND age = 5 AND pet_id = 2;
```


### 5. Остановика одного из нод кластера 
```
docker stop cassandra-3
```

```
docker exec -it cassandra-1 nodetool status
```
Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack
UN  172.22.0.2  119.03 KiB  16      100.0%            f73e2c39-eba0-48b5-9450-5db255a2ad59  rack1
UN  172.22.0.4  120.49 KiB  16      100.0%            dde0181a-df4d-4018-8189-f4c0f5ce15a9  rack1
DN  172.22.0.3  120.2 KiB   16      ?                 b7fa8c34-e5bc-42d2-b2c9-e2e7d3bb9259  rack1

#### Проверка чтения и записи при упавшей ноде
```
SELECT * FROM petshop_keyspace.pets_by_id WHERE pet_id = 1;
```

 pet_id | age | breed_name    | name  | petshop_id
--------+-----+---------------+-------+------------
      1 |   3 | Пемброк-корги | Шарик |        101

(1 rows)
Сработало

```
INSERT INTO petshop_keyspace.pets_by_id (pet_id, petshop_id, name, breed_name, age) 
VALUES (3, 101, 'Рекс', 'Овчарка', 2);
```
Сработало
   
```
SELECT * FROM petshop_keyspace.pets_by_id WHERE pet_id = 3;
```
 pet_id | age | breed_name | name | petshop_id
--------+-----+------------+------+------------
      3 |   2 |    Овчарка | Рекс |        101

(1 rows)
Сработало


