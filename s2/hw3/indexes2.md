## GIN индексы
### 1. По названиям лекарств
``
CREATE INDEX idx_medication_description_gin ON medication USING gin(to_tsvector('russian', description));
``
``
SELECT * FROM medication 
WHERE to_tsvector('russian', description) @@ to_tsquery('russian', 'противовоспалительное & антибиотик');
``

``
EXPLAIN ANALYZE
SELECT * FROM medication 
WHERE description ILIKE '%противовоспалительное%' AND description ILIKE '%антибиотик%';
``

### 2. По названиям пород
``
CREATE INDEX idx_breed_name_gin ON breed USING gin(to_tsvector('russian', breed_name));
``

``
SELECT * FROM breed 
WHERE to_tsvector('russian', breed_name) @@ to_tsquery('russian', 'овчарка | терьер');
``

``
EXPLAIN ANALYZE
SELECT * FROM breed WHERE breed_name IN ('Немецкая овчарка', 'Йоркширский терьер');
``

### 3. По названиям аксессуаров
``
CREATE INDEX idx_accessorie_name_gin ON accessorie USING gin(to_tsvector('russian', name));
``

``
SELECT * FROM accessorie 
WHERE to_tsvector('russian', name) @@ to_tsquery('russian', 'игрушка & мяч');
``

``
EXPLAIN ANALYZE
SELECT * FROM accessorie WHERE name ~ 'мяч|игрушка';
``

### 4. По кличкам
``
CREATE INDEX idx_pet_name_gin ON pet USING gin(to_tsvector('russian', name));
``

``
SELECT * FROM pet 
WHERE to_tsvector('russian', name) @@ to_tsquery('russian', 'рекс | мухтар');
``

``
EXPLAIN ANALYZE
SELECT * FROM pet WHERE name LIKE 'Рекс%' OR name LIKE 'Мухтар%';
``

### 4. По виду животных
``
CREATE INDEX idx_animal_type_name_gin ON animal_type USING gin(to_tsvector('russian', name));
``

``
SELECT * FROM animal_type 
WHERE to_tsvector('russian', name) @@ to_tsquery('russian', 'собака & кошка');
``

``
EXPLAIN ANALYZE
SELECT * FROM animal_type WHERE name IN ('Собака', 'Кошка');
``


## GIST индексы
### 1. По диапазону дат уборки
``
CREATE INDEX idx_cleaning_date_gist ON cleaning_assignments USING gist(cleaning_date);
``
``
SELECT * FROM cleaning_assignments 
WHERE cleaning_date BETWEEN '2024-01-01' AND '2024-01-31';
``

``
EXPLAIN ANALYZE
SELECT * FROM cleaning_assignments 
WHERE EXTRACT(MONTH FROM cleaning_date) = 1 AND EXTRACT(YEAR FROM cleaning_date) = 2024;
``

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

``
EXPLAIN ANALYZE
SELECT ca1.cage_id, ca1.cleaning_date
FROM cleaning_assignments ca1
JOIN cleaning_assignments ca2 ON ca1.cleaning_date = ca2.cleaning_date
WHERE ca1.cage_id != ca2.cage_id AND ca1.is_completed = false;
``

### 3. По диапазону веса пород
``
CREATE INDEX idx_breed_weight_gist ON breed USING gist(average_weight);
``

``
SELECT * FROM breed 
WHERE average_weight BETWEEN 5.0 AND 15.0;
``

``
EXPLAIN ANALYZE
SELECT * FROM breed WHERE average_weight > 5.0 AND average_weight < 15.0;
``

### 4. По возрасту питомцев
``
CREATE INDEX idx_pet_age_gist ON pet USING gist(age);
``

``
SELECT * FROM pet 
WHERE age BETWEEN 1 AND 3;
``

``
EXPLAIN ANALYZE
SELECT * FROM pet WHERE age >= 1 AND age <= 3;
``

### 5. По датам назначений
``
CREATE INDEX idx_keeper_assignments_date_gist ON keeper_assignments USING gist(assignment_date);
``

``
SELECT * FROM keeper_assignments 
WHERE assignment_date BETWEEN '2024-01-01' AND '2024-03-31';
``

``
EXPLAIN ANALYZE
SELECT * FROM keeper_assignments 
WHERE assignment_date >= '2024-01-01' AND assignment_date <= '2024-03-31';
``

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
