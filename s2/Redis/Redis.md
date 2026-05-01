#### 1. Запуск Redis
```
pip install qdrant-client sentence-transformers datetime
```

#### 2. Подключение к Redis CLI
```
docker exec -it redis-homework redis-cli
```

#### Часть 2. Счётчик просмотров
```
# 1. Увеличиваем счетчик для статьи №10 несколько раз
INCR article:10:views
INCR article:10:views
INCR article:10:views

# Можно увеличить сразу на определенное число (например, еще на 5 просмотров)
INCRBY article:10:views 5

# 2. Получаем текущее значение счетчика
GET article:10:views
```

##### Вывод:
```
GET: "8"
```

#### Часть 3. Рейтинг статей (Leaderboard)
```
# 1. Создаем leaderboard и добавляем статьи с разным количеством просмотров
# Формат: ZADD key score member
ZADD article_leaderboard 150 article:1
ZADD article_leaderboard 420 article:2
ZADD article_leaderboard 90 article:3
ZADD article_leaderboard 310 article:4

# 2. Получаем ТОП-3 статьи без количества просмотров
# Команда ZREVRANGE выводит элементы по убыванию score (от большего к меньшему)
ZREVRANGE article_leaderboard 0 2

# 3. Получаем ТОП-3 статьи С количеством просмотров
ZREVRANGE article_leaderboard 0 2 WITHSCORES

# 4. Добавляем статье №3 большое количество просмотров (вырвется в топ)
# Используем ZINCRBY, чтобы прибавить просмотры, либо ZADD, чтобы перезаписать
ZINCRBY article_leaderboard 1000 article:3

# 5. Выводим новый ТОП-3 со значениями, чтобы убедиться в изменениях
ZREVRANGE article_leaderboard 0 2 WITHSCORES
```

##### Вывод:
```
1) "article:3"
2) "1090"
3) "article:2"
4) "420"
5) "article:4"
6) "310"
```

#### Часть 4. Ограничение действий (Rate Limiting)
```
# 1. Инициализируем или увеличиваем счетчик лайков
INCR user:42:likes
INCR user:42:likes

# 2. Задаем время жизни ключа (60 секунд)
EXPIRE user:42:likes 60

# 3. Эмулируем дальнейшие лайки (допустим, пользователь нажал еще 3 раза)
INCR user:42:likes
INCR user:42:likes
INCR user:42:likes

# 4. Проверяем текущее значение счетчика
GET user:42:likes

# 5. Проверяем, сколько секунд осталось до удаления ключа
TTL user:42:likes
```

##### Вывод:
```
TTL user:42:likes
(integer) 58
```


