1. Без индексов
```
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM pet WHERE age > 8;
```

<img width="991" height="428" alt="image" src="https://github.com/user-attachments/assets/91fd71d8-a22f-4f16-ab28-f3d480caf66a" />

С индексами
```
CREATE INDEX idx_pets_age ON pet(age);
```

```
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM pet WHERE age > 8;
```

<img width="1142" height="406" alt="image" src="https://github.com/user-attachments/assets/97710701-714a-439b-80ba-ccc357514a3f" />


2. Без индексов
```
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM pet WHERE age < 5;
```

<img width="995" height="373" alt="image" src="https://github.com/user-attachments/assets/da0a27ad-80ea-4f55-ac6f-4326e08dff5d" />

С индексами
```
CREATE INDEX idx_pets_age ON pet(age);
```

```
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM pet WHERE age < 5;
```

<img width="1149" height="487" alt="image" src="https://github.com/user-attachments/assets/d5920386-5402-4ffa-918d-aa167e8a3a4b" />


3. Без индексов
```
SELECT * FROM pet WHERE breed_id = 6;
```

<img width="982" height="379" alt="image" src="https://github.com/user-attachments/assets/4c4a3a9b-f36d-41db-b1a0-2b0349cdaf5a" />

С индексами
```
CREATE INDEX idx_pets_breed_hash ON pet USING HASH(breed_id);
```

```
SELECT * FROM pet WHERE breed_id = 6;
```

<img width="1249" height="490" alt="image" src="https://github.com/user-attachments/assets/131c1034-2de2-47f3-97f1-7b8f05655e43" />


4. Без индексов
```
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM client WHERE name LIKE 'Мария%';
```
<img width="1069" height="372" alt="image" src="https://github.com/user-attachments/assets/6355aae2-ceb6-43a3-92c3-d5a767c1ca81" />

С индексами
```
CREATE INDEX idx_clients_name ON client(name);
```

```
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM client WHERE name LIKE 'Мария%';
```
<img width="1087" height="453" alt="image" src="https://github.com/user-attachments/assets/d5854a6e-6940-45ef-ae3f-0f5915d9f235" />


5. Без индексов
```
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM pet WHERE petshop_id IN (3, 4);
```
<img width="980" height="288" alt="image" src="https://github.com/user-attachments/assets/67eb5d52-1899-47bf-a2ee-c94de947d593" />

С индексами
```
CREATE INDEX idx_pets_petshop ON pet(petshop_id);
```

```
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM pet WHERE petshop_id IN (3, 4);
```
<img width="1161" height="493" alt="image" src="https://github.com/user-attachments/assets/98406037-e4dc-4c7a-a765-c0aba9a05435" />
