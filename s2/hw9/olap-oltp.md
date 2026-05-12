#### 1. Выбрать 2-3 аналитических вопроса по своему проекту.

1. Какая динамика активности сотрудников по дням? (Как часто убираются клетки и закрепляются смотрители за питомцами в разрезе магазинов?)
2. Какие типы и породы животных самые популярные? (Кого чаще всего приводят клиенты и какие питомцы занимают больше всего места?)
3. Какая нагрузка на персонал? (Сколько действий/заданий выполняет каждый сотрудник за определенный период?)


#### 2. Определить один главный факт. 
- Главный факт: fact_pet_care_actions (Факт действий по уходу за питомцами). Объединим логику назначений на уборку (cleaning_assignments) и уход (keeper_assignments) в одну общую таблицу фактов для комплексного анализа активности.
- Зерно факта: 1 строка = одно действие/назначение сотрудника на задачу в конкретный день.

#### 3. Проектирование OLAP-схемы (Звезда)
##### Таблицы измерений (Dimensions)
Денормализуем OLTP-таблицы, чтобы аналитическим инструментам не приходилось делать сложные JOIN
- dim_date — измерение времени (день, месяц, квартал, год, день недели)
- dim_employee — данные о сотрудниках (id, имя, фамилия, профессия)
- dim_petshop — данные о точках (id, название, адрес, вместимость)
- dim_pet — полная информация о питомце (id, имя, возраст, порода, тип животного, бренд корма, имя владельца)
- dim_action_type — тип действия (уборка клетки, уход за питомцем)

##### Таблица фактов (Fact Table)
- fact_pet_care_actions — содержит внешние ключи на измерения и метрики


#### 4. SQL-скрипт для создания схемы OLAP
```
-- Создаем отдельную схему для аналитики
CREATE SCHEMA IF NOT EXISTS olap;
```


```
-- 1. Измерение: Календарь
CREATE TABLE olap.dim_date (
    date_id         DATE PRIMARY KEY,
    day_of_week     INT NOT NULL,
    day_name        VARCHAR(20) NOT NULL,
    month_number    INT NOT NULL,
    month_name      VARCHAR(20) NOT NULL,
    quarter         INT NOT NULL,
    year            INT NOT NULL
);
```

```
-- 2. Измерение: Магазины
CREATE TABLE olap.dim_petshop (
    petshop_id      INT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    address         VARCHAR(255) NOT NULL,
    pets_capacity   INT NOT NULL
);
```


```
-- 3. Измерение: Сотрудники
CREATE TABLE olap.dim_employee (
    employee_id     INT PRIMARY KEY,
    full_name       VARCHAR(200) NOT NULL,
    profession      VARCHAR(100) NOT NULL
);
```

```
-- 4. Измерение: Питомцы (Денормализованное)
CREATE TABLE olap.dim_pet (
    pet_id          INT PRIMARY KEY,
    pet_name        VARCHAR(100) NOT NULL,
    age             INT,
    breed_name      VARCHAR(100),
    animal_type     VARCHAR(100),
    food_brand      VARCHAR(100),
    food_type       VARCHAR(100),
    owner_full_name VARCHAR(200)
);
```

```
-- 5. Измерение: Тип действия
CREATE TABLE olap.dim_action_type (
    action_type_id  SERIAL PRIMARY KEY,
    action_name     VARCHAR(50) NOT NULL -- 'Уборка клетки', 'Уход за питомцем'
);
```

```
-- 6. Таблица фактов: Действия по уходу
CREATE TABLE olap.fact_pet_care_actions (
    fact_id         SERIAL PRIMARY KEY,
    date_key        DATE NOT NULL REFERENCES olap.dim_date(date_id),
    petshop_key     INT NOT NULL REFERENCES olap.dim_petshop(petshop_id),
    employee_key    INT NOT NULL REFERENCES olap.dim_employee(employee_id),
    pet_key         INT REFERENCES olap.dim_pet(pet_id), -- Может быть NULL, если это просто уборка пустой клетки
    action_type_key INT NOT NULL REFERENCES olap.dim_action_type(action_type_id),
    
    -- Метрики
    action_count    INT DEFAULT 1,          -- Всегда 1 для удобства суммирования
    is_completed    BOOLEAN NOT NULL DEFAULT TRUE -- Для уборки берем из OLTP, для ухода ставим TRUE
);
```

#### 5. Аналитические запросы
1. Проверка динамики активности по дням
```
SELECT 
    d.date_id AS action_date,
    d.day_name AS day_of_week,
    p.name AS petshop_name,
    SUM(f.action_count) AS total_actions_completed
FROM olap.fact_pet_care_actions f
JOIN olap.dim_date d ON f.date_key = d.date_id
JOIN olap.dim_petshop p ON f.petshop_key = p.petshop_id
WHERE f.is_completed = TRUE
GROUP BY d.date_id, d.day_name, p.name
ORDER BY d.date_id ASC;
```

Вывод:
```
 action_date | day_of_week |   petshop_name   | total_actions_completed
-------------+-------------+------------------+-------------------------
 2026-06-01  | Monday      | Хвостики и Лапки |                       1
 2026-06-02  | Tuesday     | ЗооПланета       |                       1
 2026-06-15  | Monday      | Хвостики и Лапки |                       1
(3 rows)
```


2. Нагрузка персонала
```
SELECT 
    e.full_name AS employee_name,
    e.profession,
    SUM(f.action_count) AS total_assigned_tasks,
    ROUND(100.0 * SUM(CASE WHEN f.is_completed THEN f.action_count ELSE 0 END) / SUM(f.action_count), 2) AS completion_rate_pct
FROM olap.fact_pet_care_actions f
JOIN olap.dim_employee e ON f.employee_key = e.employee_id
GROUP BY e.employee_id, e.full_name, e.profession
ORDER BY total_assigned_tasks DESC;
```

Вывод:
```
 employee_name | profession | total_assigned_tasks | completion_rate_pct
---------------+------------+----------------------+---------------------
 Иванов Иван   | Уборщик    |                    3 |              100.00
 Сидорова Анна | Смотритель |                    1 |                0.00
(2 rows)
```

3. Проверка распределения по типам действий
```
SELECT 
    t.action_name,
    COUNT(f.fact_id) AS actions_count,
    ROUND(100.0 * COUNT(f.fact_id) / SUM(COUNT(f.fact_id)) OVER(), 2) AS share_pct
FROM olap.fact_pet_care_actions f
JOIN olap.dim_action_type t ON f.action_type_key = t.action_type_id
GROUP BY t.action_name;
```

Вывод:
```
  action_name  | actions_count | share_pct
---------------+---------------+-----------
 Уборка клетки |             4 |    100.00
(1 row)
```