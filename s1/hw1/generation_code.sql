INSERT INTO animal_type (name) VALUES 
('Собака'), ('Кошка'), ('Птица'), ('Рыбка'), ('Грызун');

INSERT INTO petshop (address, name, pets_capacity) VALUES 
('ул. Ленина, 1', 'Зоомир', 500),
('пр. Мира, 25', 'Друг человека', 300),
('ул. Гагарина, 10', 'Аквариум', 200),
('пр. Победы, 5', 'ЗооCity', 400);

INSERT INTO breed (breed_name, animal_type_id, average_weight)
SELECT 
    'Порода ' || i,
    (random() * 4 + 1)::int,
    round((random() * 50 + 1)::numeric, 2)
FROM generate_series(1, 100) AS i;

INSERT INTO food (brand_name, food_type) VALUES 
('Royal Canin', 'Сухой'), ('Royal Canin', 'Влажный'),
('Purina', 'Сухой'), ('Purina', 'Влажный'),
('Hills', 'Лечебный'), ('Hills', 'Сухой'),
('Acana', 'Беззерновой'), ('Orijen', 'Беззерновой'),
('Whiskas', 'Для кошек'), ('Pedigree', 'Для собак');


INSERT INTO client (name, surname, passport_data, petshop_id)
SELECT 
    CASE WHEN random() < 0.7 THEN 
        CASE floor(random() * 2)::int 
            WHEN 0 THEN 'Иван' ELSE 'Мария' END
    ELSE 
        CASE floor(random() * 8)::int
            WHEN 0 THEN 'Алексей' WHEN 1 THEN 'Ольга'
            WHEN 2 THEN 'Дмитрий' WHEN 3 THEN 'Елена'
            WHEN 4 THEN 'Сергей' WHEN 5 THEN 'Анна'
            ELSE 'Михаил' END
    END || ' ' || floor(random() * 1000)::text,
    
    CASE WHEN random() < 0.7 THEN 
        CASE floor(random() * 2)::int 
            WHEN 0 THEN 'Иванов' ELSE 'Петров' END
    ELSE 
        CASE floor(random() * 5)::int
            WHEN 0 THEN 'Сидоров' WHEN 1 THEN 'Смирнов'
            WHEN 2 THEN 'Кузнецов' WHEN 3 THEN 'Попов'
            ELSE 'Васильев' END
    END || floor(random() * 100)::text,
    
    'PA' || lpad(floor(random() * 1000000)::text, 6, '0'),
    
    CASE 
        WHEN random() < 0.35 THEN 1  -- 35% в магазин 1
        WHEN random() < 0.65 THEN 2  -- 30% в магазин 2
        WHEN random() < 0.85 THEN 3  -- 20% в магазин 3
        ELSE 4                        -- 15% в магазин 4
    END
FROM generate_series(1, 250000) AS i;

INSERT INTO pet (name, age, owner_id, breed_id, food_id, petshop_id)
SELECT 
    CASE floor(power(random(), 2) * 10)::int  -- квадрат дает перекос
        WHEN 0 THEN 'Бобик' WHEN 1 THEN 'Мурка'
        WHEN 2 THEN 'Шарик' WHEN 3 THEN 'Рыжик'
        WHEN 4 THEN 'Тузик' WHEN 5 THEN 'Барсик'
        ELSE 'Питомец ' || floor(random() * 1000)::text
    END,
    
    CASE WHEN random() < 0.2 THEN NULL 
         ELSE floor(random() * 15 + 1)::int END,
    
    floor(random() * 250000 + 1)::int,
    
    CASE 
        WHEN random() < 0.4 THEN floor(random() * 10 + 1)::int     -- 40% первые 10 пород
        WHEN random() < 0.7 THEN floor(random() * 30 + 11)::int    -- 30% следующие 30
        ELSE floor(random() * 60 + 41)::int                         -- 30% остальные
    END,
    
    CASE WHEN random() < 0.15 THEN NULL
         ELSE floor(random() * 10 + 1)::int END,
    
    CASE 
        WHEN random() < 0.8 THEN (SELECT petshop_id FROM client WHERE id = floor(random() * 250000 + 1)::int)
        ELSE floor(random() * 4 + 1)::int
    END
FROM generate_series(1, 250000) AS i;

INSERT INTO cleaning_assignments (cleaner_id, cage_id, cleaning_date, is_completed)
SELECT
    CASE 
        WHEN random() < 0.7 THEN 
            (SELECT id FROM employee WHERE profession IN ('уборщик', 'кипер') ORDER BY random() LIMIT 1)
        ELSE 
            (SELECT id FROM employee WHERE profession = 'уборщик' ORDER BY random() LIMIT 1)
    END,
    
    floor(random() * 1000 + 1)::int,
    
    (DATE '2024-01-01' +
     (CASE
        WHEN random() < 0.3 THEN floor(random() * 90)::int
        WHEN random() < 0.6 THEN floor(random() * 90 + 90)::int
        ELSE floor(random() * 185 + 180)::int
     END) * interval '1 day'
    )::DATE,
    
    random() < 0.95
FROM generate_series(1, 300000) AS i
ON CONFLICT (cleaner_id, cage_id, cleaning_date) DO NOTHING;

INSERT INTO keeper_assignments (keeper_id, pet_id, assignment_date)
SELECT
    floor(random() * 100 + 1)::int,
    (SELECT id FROM pet ORDER BY random() LIMIT 1),
    (CURRENT_DATE - (floor(random() * 180)::int * interval '1 day'))::DATE
FROM generate_series(1, 200000) AS i
ON CONFLICT (keeper_id, pet_id, assignment_date) DO NOTHING;