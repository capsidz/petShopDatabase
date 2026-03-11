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

### 3. По возрасту питомцев
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
