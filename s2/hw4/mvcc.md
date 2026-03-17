## Моделирование обновление данных
``
SELECT ctid, xmin, xmax, * FROM pet WHERE name = 'Бобик';
``
<img width="1439" height="321" alt="image" src="https://github.com/user-attachments/assets/1c302bec-ff45-45c3-9d76-dd9ece6d6f36" />

## Транзакция 1
``
BEGIN;
UPDATE pet SET age = 4 WHERE name = 'Бобик';

SELECT ctid, xmin, xmax, * FROM pet WHERE name = 'Бобик';
``
<img width="1409" height="496" alt="image" src="https://github.com/user-attachments/assets/fde2bdac-f040-489e-91f4-efa398b398d6" />

## Транзакция 2
``
BEGIN;
UPDATE pet SET age = 5 WHERE name = 'Бобик';

COMMIT;

SELECT ctid, xmin, xmax, * FROM pet WHERE name = 'Бобик';
``
<img width="1423" height="253" alt="image" src="https://github.com/user-attachments/assets/aa5eed12-6adf-4816-8190-1c20b1358e21" />

## Deadlock
### Транзакция 1
``
BEGIN;
UPDATE cage SET current_pet_id = 1 WHERE id = 1;
``

### Транзакция 2
``
BEGIN;
UPDATE pet SET age = 6 WHERE id = 1;
``

### Транзакция 1
``
UPDATE pet SET age = 7 WHERE id = 1;
``

### Транзакция 2
``
UPDATE cage SET current_pet_id = 2 WHERE id = 1;
``
<img width="681" height="143" alt="image" src="https://github.com/user-attachments/assets/1d44b82c-9448-4bae-9b4a-a3049e5be7fd" />


## Очистка данных
``
VACUUM pet;
``
<img width="825" height="84" alt="image" src="https://github.com/user-attachments/assets/d7d42861-7ba0-43d1-90a8-70a3511099c0" />

