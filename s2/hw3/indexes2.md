## GIN индексы
### 1. По названиям лекарств
``
CREATE INDEX idx_medication_description_gin ON medication USING gin(to_tsvector('russian', description));
``

``
SELECT * FROM medication 
WHERE to_tsvector('russian', description) @@ to_tsquery('russian', 'противовоспалительное & антибиотик');
``
<img width="1013" height="241" alt="image" src="https://github.com/user-attachments/assets/35a3bfe1-43ce-4589-b98a-8b6cd203e06a" />

``
EXPLAIN ANALYZE
SELECT * FROM medication 
WHERE description ILIKE '%противовоспалительное%' AND description ILIKE '%антибиотик%';
``
<img width="1008" height="260" alt="image" src="https://github.com/user-attachments/assets/bc844f41-e6f0-44cc-a84b-a15db612d53b" />


### 2. По названиям пород
``
CREATE INDEX idx_breed_name_gin ON breed USING gin(to_tsvector('russian', breed_name));
``

``
SELECT * FROM breed 
WHERE to_tsvector('russian', breed_name) @@ to_tsquery('russian', 'овчарка | терьер');
``
<img width="973" height="248" alt="image" src="https://github.com/user-attachments/assets/2bbf18ed-20fd-457a-a0f0-98901935faee" />

``
EXPLAIN ANALYZE
SELECT * FROM breed WHERE breed_name IN ('Немецкая овчарка', 'Йоркширский терьер');
``
<img width="955" height="267" alt="image" src="https://github.com/user-attachments/assets/9384010b-80e0-4c6f-857a-c752ef3c32f3" />


### 3. По названиям аксессуаров
``
CREATE INDEX idx_accessorie_name_gin ON accessorie USING gin(to_tsvector('russian', name));
``

``
SELECT * FROM accessorie 
WHERE to_tsvector('russian', name) @@ to_tsquery('russian', 'игрушка & мяч');
``
<img width="1051" height="260" alt="image" src="https://github.com/user-attachments/assets/b4f7b782-6ad0-47ba-b0af-956ac8df2027" />

``
EXPLAIN ANALYZE
SELECT * FROM accessorie WHERE name ~ 'мяч|игрушка';
``
<img width="1019" height="247" alt="image" src="https://github.com/user-attachments/assets/1f61d188-5a7f-444b-abd6-9a0635a1f9bf" />


### 4. По кличкам
``
CREATE INDEX idx_pet_name_gin ON pet USING gin(to_tsvector('russian', name));
``

``
SELECT * FROM pet 
WHERE to_tsvector('russian', name) @@ to_tsquery('russian', 'рекс | мухтар');
``
<img width="1173" height="370" alt="image" src="https://github.com/user-attachments/assets/befec454-5926-448e-b8f6-98321d0da3a2" />

``
EXPLAIN ANALYZE
SELECT * FROM pet WHERE name LIKE 'Рекс%' OR name LIKE 'Мухтар%';
``
<img width="1110" height="359" alt="image" src="https://github.com/user-attachments/assets/eef277e4-54a6-467e-b5ad-8c5259ee8fd6" />


### 5. По виду животных
``
CREATE INDEX idx_animal_type_name_gin ON animal_type USING gin(to_tsvector('russian', name));
``

``
SELECT * FROM animal_type 
WHERE to_tsvector('russian', name) @@ to_tsquery('russian', 'собака & кошка');
``
<img width="989" height="241" alt="image" src="https://github.com/user-attachments/assets/ab572e9b-97d5-4565-a479-0d8d635d0a72" />

``
EXPLAIN ANALYZE
SELECT * FROM animal_type WHERE name IN ('Собака', 'Кошка');
``
<img width="1021" height="253" alt="image" src="https://github.com/user-attachments/assets/015ba367-be62-449a-a18f-bfcda11b182c" />


## GIST индексы
### 1. По диапазону дат уборки
``
CREATE INDEX idx_cleaning_date_gist ON cleaning_assignments USING gist(cleaning_date);
``
``
SELECT * FROM cleaning_assignments 
WHERE cleaning_date BETWEEN '2024-01-01' AND '2024-01-31';
``
<img width="1230" height="359" alt="image" src="https://github.com/user-attachments/assets/237fe5b2-25b2-41e9-b54f-7e1955df2249" />

``
EXPLAIN ANALYZE
SELECT * FROM cleaning_assignments 
WHERE EXTRACT(MONTH FROM cleaning_date) = 1 AND EXTRACT(YEAR FROM cleaning_date) = 2024;
``
<img width="1255" height="349" alt="image" src="https://github.com/user-attachments/assets/6c4b1dde-509f-42f2-8172-e415239d9055" />


### 2. Поиск пересечений графиков уборки
``
SELECT DISTINCT ca1.cage_id, ca1.cleaning_date
FROM cleaning_assignments ca1
WHERE EXISTS (
    SELECT 1 FROM cleaning_assignments ca2
    WHERE ca2.cage_id != ca1.cage_id
    AND ca2.cleaning_date = ca1.cleaning_date
    AND ca2.is_completed = false
);
``
<img width="1165" height="353" alt="image" src="https://github.com/user-attachments/assets/56861a88-e3df-4276-bfb6-358a00428e14" />


``
EXPLAIN ANALYZE
SELECT ca1.cage_id, ca1.cleaning_date
FROM cleaning_assignments ca1
JOIN cleaning_assignments ca2 ON ca1.cleaning_date = ca2.cleaning_date
WHERE ca1.cage_id != ca2.cage_id AND ca1.is_completed = false;
``
<img width="1067" height="360" alt="image" src="https://github.com/user-attachments/assets/38c83a38-14b8-4a2c-909d-2e41bc31b796" />


### 3. По диапазону веса пород
``
CREATE INDEX idx_breed_weight_gist ON breed USING gist(average_weight);
``

``
SELECT * FROM breed 
WHERE average_weight BETWEEN 5.0 AND 15.0;
``
<img width="1140" height="261" alt="image" src="https://github.com/user-attachments/assets/2510e0f7-d6f3-41c0-bac5-19f699569427" />

``
EXPLAIN ANALYZE
SELECT * FROM breed WHERE average_weight > 5.0 AND average_weight < 15.0;
``
<img width="1016" height="243" alt="image" src="https://github.com/user-attachments/assets/b280ba60-3a3c-454c-88f0-524aa2908049" />


### 4. По возрасту питомцев
``
CREATE INDEX idx_pet_age_gist ON pet USING gist(age);
``

``
SELECT * FROM pet 
WHERE age BETWEEN 1 AND 3;
``
<img width="1268" height="252" alt="image" src="https://github.com/user-attachments/assets/1f6ea4b9-5077-476d-9fe6-d58ddf99a54e" />


``
EXPLAIN ANALYZE
SELECT * FROM pet WHERE age >= 1 AND age <= 3;
``
<img width="1227" height="338" alt="image" src="https://github.com/user-attachments/assets/055cb48f-2c55-4f86-b2e3-c435f18877b7" />


### 5. По датам назначений
``
CREATE INDEX idx_keeper_assignments_date_gist ON keeper_assignments USING gist(assignment_date);
``

``
SELECT * FROM keeper_assignments 
WHERE assignment_date BETWEEN '2024-01-01' AND '2024-03-31';
``
<img width="1049" height="269" alt="image" src="https://github.com/user-attachments/assets/f9a5be82-e4e9-4c1e-9a8a-3742247b0571" />


``
EXPLAIN ANALYZE
SELECT * FROM keeper_assignments 
WHERE assignment_date >= '2024-01-01' AND assignment_date <= '2024-03-31';
``
<img width="1310" height="231" alt="image" src="https://github.com/user-attachments/assets/9fbe986a-2d04-44d2-a171-1dcdc0935d91" />


## JOIN запросы
### 1. Информация о питомцах (порода, тип)
``
SELECT 
    p.name as pet_name,
    p.age,
    b.breed_name,
    at.name as animal_type,
    f.brand_name as food_brand
FROM pet p
JOIN breed b ON p.breed_id = b.id
JOIN animal_type at ON b.animal_type_id = at.id
LEFT JOIN food f ON p.food_id = f.id
WHERE p.age < 5;
``

### 2. Информация о назначениях с доп инф
``
SELECT 
    e.name || ' ' || e.surname as employee_name,
    e.profession,
    p.name as pet_name,
    ka.assignment_date,
    ps.name as petshop_name
FROM keeper_assignments ka
JOIN employee e ON ka.keeper_id = e.id
JOIN pet p ON ka.pet_id = p.id
JOIN petshop ps ON p.petshop_id = ps.id
WHERE ka.assignment_date >= CURRENT_DATE - INTERVAL '30 days';
``

### 3. Информация о клетках и кто там живет
``
SELECT 
    c.id as cage_id,
    at.name as animal_type,
    p.name as current_pet,
    p.age as pet_age,
    b.breed_name,
    ps.name as petshop_name
FROM cage c
LEFT JOIN animal_type at ON c.animal_type_id = at.id
LEFT JOIN pet p ON c.current_pet_id = p.id
LEFT JOIN breed b ON p.breed_id = b.id
JOIN petshop ps ON c.petshop_id = ps.id
ORDER BY ps.name, c.id;
``

### 4. Информация о клиентах и их питомцах с аксессуарами
``
SELECT 
    cl.name || ' ' || cl.surname as client_name,
    p.name as pet_name,
    b.breed_name,
    STRING_AGG(DISTINCT a.name, ', ') as accessories,
    COUNT(DISTINCT pa.accessorie_id) as accessories_count
FROM client cl
JOIN pet p ON cl.id = p.owner_id
JOIN breed b ON p.breed_id = b.id
LEFT JOIN pet_accessorie pa ON p.id = pa.pet_id
LEFT JOIN accessorie a ON pa.accessorie_id = a.id
GROUP BY cl.id, p.id, b.breed_name
HAVING COUNT(DISTINCT pa.accessorie_id) > 0;
``

### 5. Информация о медикаментах и питомцах, которые их получают
``
SELECT 
    m.name as medication_name,
    m.description,
    COUNT(DISTINCT pm.pet_id) as pets_count,
    STRING_AGG(DISTINCT p.name, ', ') as pet_names
FROM medication m
JOIN pet_medication pm ON m.id = pm.medication_id
JOIN pet p ON pm.pet_id = p.id
GROUP BY m.id
ORDER BY pets_count DESC;
``

## Запросы для мониторинга
Версия PostgreSQL
``
SELECT version();
``

Активные сессии
``
SELECT 
    pid,
    usename as user_name,
    application_name,
    client_addr,
    state,
    query,
    age(now(), query_start) as query_duration
FROM pg_stat_activity 
WHERE state = 'active' 
AND query NOT LIKE '%pg_stat_activity%';
``

График SELECT
``
SELECT 
    date_trunc('minute', query_start) as time_minute,
    COUNT(*) as select_count
FROM pg_stat_activity 
WHERE query ILIKE 'SELECT%' 
AND query NOT ILIKE '%pg_stat_activity%'
AND query_start > NOW() - INTERVAL '1 hour'
GROUP BY time_minute
ORDER BY time_minute;
``

График INSERT
``
SELECT 
    date_trunc('minute', query_start) as time_minute,
    COUNT(*) as insert_count,
    SUM(CASE WHEN query ILIKE '%INSERT%' THEN 1 ELSE 0 END) as inserts
FROM pg_stat_activity 
WHERE query ILIKE 'INSERT%'
AND query_start > NOW() - INTERVAL '1 hour'
GROUP BY time_minute
ORDER BY time_minute;
``

График DELETE 
``
SELECT 
    date_trunc('minute', query_start) as time_minute,
    COUNT(*) as delete_count
FROM pg_stat_activity 
WHERE query ILIKE 'DELETE%'
AND query_start > NOW() - INTERVAL '1 hour'
GROUP BY time_minute
ORDER BY time_minute;
``

