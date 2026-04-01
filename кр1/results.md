## Задание 1. Оптимизация простого запроса
``
SELECT id, shop_id, total_sum, sold_at FROM store_checks WHERE shop_id = 77
  AND sold_at >= TIMESTAMP '2025-02-14 00:00:00'
  AND sold_at < TIMESTAMP '2025-02-15 00:00:00';
``
1. План выполнения запроса до изменений.
<img width="2310" height="445" alt="image" src="https://github.com/user-attachments/assets/fdf938f8-54be-407d-95b8-0e1beeccec7e" />

                                                                            QUERY PLAN                                  
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Seq Scan on store_checks  (cost=0.00..1880.07 rows=1 width=26) (actual time=7.953..7.957 rows=3 loops=1)
   Filter: ((sold_at >= '2025-02-14 00:00:00'::timestamp without time zone) AND (sold_at < '2025-02-15 00:00:00'::timestamp without time zone) AND (shop_id = 77))
   Rows Removed by Filter: 70001
 Planning Time: 0.659 ms
 Execution Time: 8.066 ms
(5 rows)

2. Укажите:

   - тип сканирования: Seq Scan

   - из уже созданных индексов не помогают этому запросу: idx_store_checks_payment_type, idx_store_checks_sum_hash

   - почему планировщик выбирает именно такой план.

3. Индекс, который лучше подходит под этот запрос.
``
CREATE INDEX idx_store_checks_shop_id ON store_checks(shop_id);
``

4. Повторно постройте план выполнения.
<img width="2302" height="664" alt="image" src="https://github.com/user-attachments/assets/0781a503-96c0-4b6c-aab2-c8ddd694de0e" />

                                                                   QUERY PLAN                                           
------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on store_checks  (cost=5.15..301.02 rows=1 width=26) (actual time=0.250..0.251 rows=3 loops=1)
   Recheck Cond: (shop_id = 77)
   Filter: ((sold_at >= '2025-02-14 00:00:00'::timestamp without time zone) AND (sold_at < '2025-02-15 00:00:00'::timestamp without time zone))
   Rows Removed by Filter: 89
   Heap Blocks: exact=89
   ->  Bitmap Index Scan on idx_store_checks_shop_id  (cost=0.00..5.15 rows=114 width=0) (actual time=0.081..0.081 rows=92 loops=1)
         Index Cond: (shop_id = 77)
 Planning Time: 36.310 ms
 Execution Time: 0.926 ms
(9 rows)

5. Был создан индекс по айди магазина, что ускорило запрос с where. Использовался Bitmap Heap Scan, то есть было обращение к индексам. Execution Time уменьшилось. 

6. Ответьте, нужно ли после создания индекса выполнять ANALYZE, и зачем. !!!!!!!

## Задание 2. Анализ и улучшение JOIN-запроса
``
SELECT m.id, m.member_level, v.spend, v.visit_at
FROM club_members m
JOIN club_visits v ON v.member_id = m.id
WHERE m.member_level = 'premium'
  AND v.visit_at >= TIMESTAMP '2025-02-01 00:00:00'
  AND v.visit_at < TIMESTAMP '2025-02-10 00:00:00';
``

Что нужно сделать:

1. План выполнения запроса до изменений.
<img width="2294" height="945" alt="image" src="https://github.com/user-attachments/assets/33c29a14-c17d-4dfc-9873-6bacc0c94fa7" />

                                                                            QUERY PLAN                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Hash Join  (cost=690.33..1800.92 rows=732 width=27) (actual time=13.803..57.333 rows=819 loops=1)
   Hash Cond: (v.member_id = m.id)
   ->  Bitmap Heap Scan on club_visits v  (cost=233.00..1314.76 rows=10984 width=22) (actual time=5.321..46.466 rows=10998 loops=1)
         Recheck Cond: ((visit_at >= '2025-02-01 00:00:00'::timestamp without time zone) AND (visit_at < '2025-02-10 00:00:00'::timestamp without time zone))
         Heap Blocks: exact=917
         ->  Bitmap Index Scan on idx_club_visits_visit_at  (cost=0.00..230.26 rows=10984 width=0) (actual time=4.584..4.585 rows=10998 loops=1)
               Index Cond: ((visit_at >= '2025-02-01 00:00:00'::timestamp without time zone) AND (visit_at < '2025-02-10 00:00:00'::timestamp without time zone))
   ->  Hash  (cost=439.00..439.00 rows=1466 width=13) (actual time=8.435..8.436 rows=1466 loops=1)
         Buckets: 2048  Batches: 1  Memory Usage: 85kB
         ->  Seq Scan on club_members m  (cost=0.00..439.00 rows=1466 width=13) (actual time=1.148..8.030 rows=1466 loops=1)
               Filter: (member_level = 'premium'::text)
               Rows Removed by Filter: 20534
 Planning Time: 7.182 ms
 Execution Time: 57.504 ms
(14 rows)

2. Использован Hash join

3. Планировщик выбрал именно этот тип JOIN, поскольку обе таблицы большие

4. Данный индекс полезен: CREATE INDEX idx_club_visits_visit_at ON club_visits (visit_at);

5. Индекс на member_level
``
CREATE INDEX idx_club_members_idx_member_level ON club_members(member_level);
``

6. Повторно постройте план выполнения.
<img width="2313" height="1028" alt="image" src="https://github.com/user-attachments/assets/6cfca0bf-8400-4c9b-8e97-ded79ec5b53a" />


                                                                            QUERY PLAN                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Hash Join  (cost=453.30..1563.90 rows=732 width=27) (actual time=1.781..5.565 rows=819 loops=1)
   Hash Cond: (v.member_id = m.id)
   ->  Bitmap Heap Scan on club_visits v  (cost=233.00..1314.76 rows=10984 width=22) (actual time=0.803..3.351 rows=10998 loops=1)
         Recheck Cond: ((visit_at >= '2025-02-01 00:00:00'::timestamp without time zone) AND (visit_at < '2025-02-10 00:00:00'::timestamp without time zone))
         Heap Blocks: exact=917
         ->  Bitmap Index Scan on idx_club_visits_visit_at  (cost=0.00..230.26 rows=10984 width=0) (actual time=0.702..0.703 rows=10998 loops=1)
               Index Cond: ((visit_at >= '2025-02-01 00:00:00'::timestamp without time zone) AND (visit_at < '2025-02-10 00:00:00'::timestamp without time zone))
   ->  Hash  (cost=201.97..201.97 rows=1466 width=13) (actual time=0.959..0.960 rows=1466 loops=1)
         Buckets: 2048  Batches: 1  Memory Usage: 85kB
         ->  Bitmap Heap Scan on club_members m  (cost=19.65..201.97 rows=1466 width=13) (actual time=0.156..0.734 rows=1466 loops=1)
               Recheck Cond: (member_level = 'premium'::text)
               Heap Blocks: exact=164
               ->  Bitmap Index Scan on idx_club_members_idx_member_level  (cost=0.00..19.28 rows=1466 width=0) (actual time=0.128..0.128 rows=1466 loops=1)
                     Index Cond: (member_level = 'premium'::text)
 Planning Time: 0.708 ms
 Execution Time: 5.657 ms
(16 rows)

7. План улучшился, join остался тот же, но уменьшилось Execution Time: 57.504 ms -> Execution Time: 5.657 ms

8. Преобладание shared hit - значит, большая часть страниц была прочитана из кеша, read - непостредственно обратились к бд

## Задание 3. MVCC и очистка
``
SELECT xmin, xmax, ctid, id, title, stock
FROM warehouse_items
ORDER BY id;
``
<img width="1475" height="557" alt="image" src="https://github.com/user-attachments/assets/461f79a5-b1e6-4703-a8e5-15c3183791ec" />

 xmin | xmax | ctid  | id |  title  | stock
------+------+-------+----+---------+-------
  766 |    0 | (0,1) |  1 | Cable   |    40
  766 |    0 | (0,2) |  2 | Adapter |    25
  766 |    0 | (0,3) |  3 | Hub     |    12
(3 rows)

``
UPDATE warehouse_items
SET stock = stock - 2
WHERE id = 1;
``
<img width="701" height="157" alt="image" src="https://github.com/user-attachments/assets/79ee7108-be4d-4836-aa1f-298bdf583e36" />

UPDATE 1

``
SELECT xmin, xmax, ctid, id, title, stock
FROM warehouse_items
ORDER BY id;
``


 xmin | xmax | ctid  | id |  title  | stock
------+------+-------+----+---------+-------
  828 |    0 | (0,4) |  1 | Cable   |    38
  766 |    0 | (0,2) |  2 | Adapter |    25
  766 |    0 | (0,3) |  3 | Hub     |    12
(3 rows)

``
DELETE FROM warehouse_items
WHERE id = 3;
``

``
SELECT xmin, xmax, ctid, id, title, stock
FROM warehouse_items
ORDER BY id;
``
 xmin | xmax | ctid  | id |  title  | stock
------+------+-------+----+---------+-------
  828 |    0 | (0,4) |  1 | Cable   |    38
  766 |    0 | (0,2) |  2 | Adapter |    25
(2 rows)

Что нужно сделать:

1. после UPDATE xmin изменился, ctid изменился

2. потому что по факту это delete+update

3. после DELETE xmin и ctid изменились, строка изчезла из select так как ее xmax получил значение

4. Кратко сравните:

   - VACUUM - не блокирует, освобождает память для перезаписывания, не освобождает полностью память

   - autovacuum - не блокирует, освобождает память для перезаписывания, не освобождает полностью память, происходит автоматически

   - VACUUM FULL - блокирует, освобождает память для перезаписывания, освобождает полностью память

5. Отдельно укажите, какой из этих механизмов может полностью блокировать таблицу.
VACUUM FULL

