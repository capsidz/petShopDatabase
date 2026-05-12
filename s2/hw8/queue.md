#### 1. Проектирование схемы БД (Таблица tasks)
```
-- Создаем перечисление для статусов задачи
CREATE TYPE task_status AS ENUM ('Ready', 'Running', 'Completed', 'Failed');

-- Создаем перечисление для приоритетов (веса)
CREATE TYPE task_priority AS ENUM ('Low', 'Normal', 'Critical');

CREATE TABLE public.tasks (
    id            SERIAL PRIMARY KEY,
    task_type     VARCHAR(100) NOT NULL,    -- Тип задачи (например, 'send_invoice', 'medical_alert')
    payload       JSONB,                    -- Данные по задаче (ID клиента, ID питомца и т.д.)
    priority      task_priority NOT NULL DEFAULT 'Normal',
    status        task_status NOT NULL DEFAULT 'Ready',
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    started_at    TIMESTAMP,
    finished_at   TIMESTAMP,
    error_message TEXT,
    worker_id     VARCHAR(50)               -- Идентификатор воркера, забравшего задачу
);

-- Индекс для супер-быстрого поиска задач воркерами (с учетом приоритета и статуса)
CREATE INDEX idx_tasks_processing ON public.tasks (priority DESC, created_at ASC) 
WHERE status = 'Ready';
```

2. Реализация Продьюсера
Продьюсер должен генерировать задачи, соблюдая пропорцию (80% обычных / 20% критических), объединяя это с фиктивной «бизнес-логикой» (например, симуляция «приема питомца в отель»).
```
BEGIN;

-- 1. Фиктивная бизнес-логика: оформляем клиента и питомца
INSERT INTO public.client (id, name, surname, passport_data, petshop_id)
VALUES (999, 'Иван', 'Тестов', '1234 567890', 1)
ON CONFLICT (id) DO NOTHING;

-- 2. Логика продюсера: Генерируем случайное число от 1 до 100 для распределения веса
-- Если число <= 20 (20% вероятность) -> Critical, иначе -> Normal (80%)
INSERT INTO public.tasks (task_type, payload, priority, status)
VALUES (
    'send_welcome_email', 
    '{"client_id": 999, "email": "test@example.com"}'::jsonb,
    CASE WHEN random() * 100 <= 20 THEN 'Critical'::task_priority ELSE 'Normal'::task_priority END,
    'Ready'::task_status
);

COMMIT;
```

3. Реализация Консьюмеров (Воркеров)
Чтобы два независимых воркера конкурировали за задачи и не перехватывали одну и ту же задачу одновременно, нужно использовать конструкцию SELECT ... FOR UPDATE SKIP LOCKED. Она намертво блокирует выбранную строку для одного воркера, а второй воркер её просто "перепрыгивает" и берет следующую

```
BEGIN;

-- 1. Находим и атомарно блокируем самую старую задачу с наивысшим приоритетом
WITH next_task AS (
    SELECT id 
    FROM public.tasks
    WHERE status = 'Ready'
    ORDER BY priority DESC, created_at ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED
)
-- 2. Переводим её в статус 'Running' и отдаем воркеру
UPDATE public.tasks t
SET 
    status = 'Running',
    started_at = NOW(),
    worker_id = 'worker_node_1' 
FROM next_task
WHERE t.id = next_task.id
RETURNING t.id, t.task_type, t.payload;


UPDATE public.tasks 
SET 
    status = 'Completed', -- или 'Failed' в случае ошибки
    finished_at = NOW()
WHERE id = :task_id; -- id задачи, полученный из прошлого шага

COMMIT;
```

4. Нагрузка и мониторинг Лага
Показывает, сколько времени (в секундах/минутах) самая «несчастная», долго ожидающая задача в статусе Ready висит незапущенной.
```
SELECT 
    COUNT(*) AS total_ready_tasks,
    NOW() - MIN(created_at) AS queue_lag,
    EXTRACT(EPOCH FROM (NOW() - MIN(created_at))) AS queue_lag_in_seconds
FROM public.tasks
WHERE status = 'Ready';
```

5. Пропускная способность (Throughput)
```
SELECT 
    COUNT(*) AS tasks_processed,
    10 AS monitoring_window_seconds,
    ROUND(COUNT(*)::numeric / 10, 2) AS tasks_per_second
FROM public.tasks
WHERE 
    status IN ('Completed', 'Failed') 
    AND finished_at >= NOW() - INTERVAL '10 second';
```