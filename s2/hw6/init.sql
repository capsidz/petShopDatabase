CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator_password';

-- Создание тестовой таблицы
CREATE TABLE IF NOT EXISTS test_data (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW()
);