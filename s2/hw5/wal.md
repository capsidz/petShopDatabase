## Изменение LSN и WAL после изменения данных
### LSN и WAL до
``
SELECT pg_current_wal_lsn() AS lsn_before_insert,
       pg_walfile_name(pg_current_wal_lsn()) AS wal_file_before,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0')) AS wal_size_before;
``

<img width="782" height="92" alt="image" src="https://github.com/user-attachments/assets/8e1edf61-a3df-4564-917c-d5c16e4631c5" />

### INSERT операции
``
INSERT INTO animal_type (name) VALUES 
    ('Млекопитающее'),
    ('Птица'),
    ('Рептилия'),
    ('Рыба'),
    ('Земноводное');
``
``
INSERT INTO petshop (address, name, pets_capacity) VALUES
    ('ул. Ленина, 10', 'Зоомир', 100),
    ('пр. Победы, 25', 'Друг', 150),
    ('ул. Гагарина, 5', 'Аквариум', 50);
``
``
INSERT INTO employee (name, surname, profession) VALUES
    ('Иван', 'Петров', 'Ветеринар'),
    ('Мария', 'Иванова', 'Грумер'),
    ('Алексей', 'Сидоров', 'Зоотехник'),
    ('Елена', 'Козлова', 'Администратор');
``
``
INSERT INTO breed (breed_name, animal_type_id, average_weight) VALUES
    ('Шотландская вислоухая', 1, 4.5),
    ('Попугай волнистый', 2, 0.1),
    ('Красноухая черепаха', 3, 1.2);
``

### LSN после
``
SELECT pg_current_wal_lsn() AS lsn_after_insert,
       pg_walfile_name(pg_current_wal_lsn()) AS wal_file_after,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0')) AS wal_size_after;
``

<img width="743" height="121" alt="image" src="https://github.com/user-attachments/assets/1264c480-a436-4053-9fb4-72653220a292" />

## WAL после коммита
``
BEGIN;
INSERT INTO client (name, surname, passport_data, petshop_id) VALUES
    ('Ольга', 'Смирнова', '4510 123456', 1),
    ('Дмитрий', 'Васильев', '4511 789012', 2);
COMMIT;
``

``
SELECT 
    pg_current_wal_lsn() AS lsn_after_commit,
    pg_walfile_name(pg_current_wal_lsn()) AS current_wal_file,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0')) AS total_wal_size;
``

<img width="738" height="95" alt="image" src="https://github.com/user-attachments/assets/aff19b0f-131c-4909-adf5-7137ee8f0ba1" />

## Анализ WAL после массовой операции
### WAL до
``
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0')) AS wal_size_before_massive;
``

<img width="384" height="95" alt="image" src="https://github.com/user-attachments/assets/f7eddfd5-d495-4286-92e2-6a3a7f7597c8" />

### Массовая вставка данных
``
DO $$
DECLARE
    i INTEGER;
BEGIN
    FOR i IN 1..1000 LOOP
        INSERT INTO pet (name, age, petshop_id) VALUES
            ('Питомец_' || i, floor(random() * 15 + 1)::int, floor(random() * 3 + 1)::int);
    END LOOP;
END $$;
``

## WAL после
``
SELECT 
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0')) AS wal_size_after_massive,
    pg_walfile_name(pg_current_wal_lsn()) AS current_wal_file;
``

<img width="718" height="83" alt="image" src="https://github.com/user-attachments/assets/3fb469b3-5670-47d2-86cb-773be1478ee5" />


## Создание дампа
### Полный дамп
``
pg_dump -U postgres -d petShopDb > full_backup.sql
``

### Только структуры
``
pg_dump -U postgres -d petShopDb --schema-only > schema_only.sql
``


### Только одной таблицы - pet
``
pg_dump -U postgres -d petShopDb --table=pet > pet_dump.sql
``

## Восстановление дампа в новую бд
``
createdb -U postgres new_database
``

``
psql -U postgres -d new_database < full_backup.sql
``

<img width="315" height="577" alt="image" src="https://github.com/user-attachments/assets/808d2cd3-4f0e-4083-aca0-9c8bffbab922" />

## Создание нескольких seed
## Идемпотентная вставка в animal_type

``
INSERT INTO animal_type (name) VALUES
    ('Млекопитающее'),
    ('Птица'),
    ('Рептилия'),
    ('Рыба'),
    ('Земноводное')
ON CONFLICT (id) DO NOTHING;
``

## Идемпотентная вставка с обновлением
``
INSERT INTO petshop (id, address, name, pets_capacity) VALUES
    (1, 'ул. Ленина, 10', 'Зоомир', 100),
    (2, 'пр. Победы, 25', 'Друг', 150),
    (3, 'ул. Гагарина, 5', 'Аквариум', 50)
ON CONFLICT (id) DO UPDATE SET
    address = EXCLUDED.address,
    name = EXCLUDED.name,
    pets_capacity = EXCLUDED.pets_capacity;
``

## Вставка с проверкой существования
``
INSERT INTO employee (name, surname, profession)
SELECT name, surname, profession
FROM (VALUES 
    ('Иван', 'Петров', 'Ветеринар'),
    ('Мария', 'Иванова', 'Грумер'),
    ('Алексей', 'Сидоров', 'Зоотехник')
) AS new_data(name, surname, profession)
WHERE NOT EXISTS (
    SELECT 1 FROM employee e 
    WHERE e.name = new_data.name AND e.surname = new_data.surname
);
``

## Идемпотентная вставка в breed с проверкой внешних ключей
``
INSERT INTO breed (breed_name, animal_type_id, average_weight)
SELECT 
    breed_name,
    animal_type_id,
    average_weight
FROM (VALUES 
    ('Шотландская вислоухая', 1, 4.5),
    ('Персидская', 1, 5.0),
    ('Сиамская', 1, 4.0),
    ('Попугай волнистый', 2, 0.1),
    ('Какаду', 2, 0.8),
    ('Красноухая черепаха', 3, 1.2)
) AS b(breed_name, animal_type_id, average_weight)
WHERE NOT EXISTS (
    SELECT 1 FROM breed 
    WHERE breed_name = b.breed_name
);
``

## Идемпотентный seed 
``
DO $$
DECLARE
    pet_record RECORD;
BEGIN
    FOR pet_record IN(
        SELECT * FROM (VALUES 
            (1, 'Барсик', 3, 1, 1, 1, 1),
            (2, 'Мурка', 2, 1, 2, 1, 1),
            (3, 'Кеша', 1, NULL, 4, 2, 2)
        ) AS t(id, name, age, owner_id, breed_id, food_id, petshop_id)
    )
    LOOP
        IF NOT EXISTS (SELECT 1 FROM pet WHERE id = pet_record.id) THEN
            INSERT INTO pet (id, name, age, owner_id, breed_id, food_id, petshop_id)
            VALUES (
                pet_record.id,
                pet_record.name,
                pet_record.age,
                pet_record.owner_id,
                pet_record.breed_id,
                pet_record.food_id,
                pet_record.petshop_id
            ); 
        END IF;
    END LOOP;
END $$;
``

## Функция для идемпотентного добавления тестовых данных
``
CREATE OR REPLACE FUNCTION add_test_data_if_not_exists()
RETURNS void AS $$
BEGIN
    INSERT INTO client (name, surname, passport_data, petshop_id)
    SELECT 'Тестовый', 'Клиент_' || i, '1234 56789' || i, 1
    FROM generate_series(1, 5) i
    WHERE NOT EXISTS (
        SELECT 1 FROM client 
        WHERE surname = 'Клиент_' || i
    );
    INSERT INTO cage (animal_type_id, petshop_id, current_pet_id)
    SELECT animal_type_id, petshop_id, NULL
    FROM (VALUES 
        (1, 1),
        (1, 1),
        (2, 2),
        (3, 3)
    ) AS c(animal_type_id, petshop_id)
    WHERE NOT EXISTS (
        SELECT 1 FROM cage 
        WHERE animal_type_id = c.animal_type_id 
        AND petshop_id = c.petshop_id
    );
END;
$$ LANGUAGE plpgsql;
``

## Проверка результатов seed
``
SELECT 'animal_type' AS table_name, COUNT(*) AS record_count FROM animal_type
UNION ALL
SELECT 'petshop', COUNT(*) FROM petshop
UNION ALL
SELECT 'employee', COUNT(*) FROM employee
UNION ALL
SELECT 'breed', COUNT(*) FROM breed
UNION ALL
SELECT 'pet', COUNT(*) FROM pet
UNION ALL
SELECT 'client', COUNT(*) FROM client
ORDER BY table_name;
``

<img width="398" height="306" alt="image" src="https://github.com/user-attachments/assets/ada8900a-97b1-46b6-8b45-583238ebf74a" />


