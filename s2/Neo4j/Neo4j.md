#### 1. Запустить Neo4j контейнер 
```
docker-compose -up
```

#### 2. Импортировать датасет из README.md
##### Вставка
##### 1) Добавить категорию
```
Cypher
MERGE (c:Category {categoryID: 'Наука', title: 'Наука'})
RETURN c;
```

##### Вывод:
```
+---------------------------------------------------+
| c                                                 |
+---------------------------------------------------+
| (:Category {title: "Наука", categoryID: "Наука"}) |
+---------------------------------------------------+

1 row
ready to start consuming query after 21 ms, results consumed after another 7 ms
```

##### 2) Добавить статью
```
MERGE (a:Article {articleID: 'Квантовая физика для начинающих'})
WITH a
MATCH (c:Category {categoryID: 'Наука'})
MERGE (a)-[:IS_IN]->(c)
RETURN a, c;
```

##### Вывод:
```
+---------------------------------------------------------------------------------------------------------------+
| a                                                         | c                                                 |
+---------------------------------------------------------------------------------------------------------------+
| (:Article {articleID: "Квантовая физика для начинающих"}) | (:Category {title: "Наука", categoryID: "Наука"}) |
+---------------------------------------------------------------------------------------------------------------+

1 row
ready to start consuming query after 180 ms, results consumed after another 71 ms
Added 1 nodes, Created 1 relationships, Set 1 properties, Added 1 labels
```

##### 3) Добавить читателя, добавить связь с 3-5 статьями
```
// Создаем читателя
MERGE (r:Reader {readerID: 'Алексей'})
ON CREATE SET r.nickname = 'alex_cool', r.email = 'alex@example.com'

// Ищем статьи и создаем связи READ
WITH r
MATCH (a1:Article) WHERE a1.articleID = 'Квантовая физика для начинающих'
MATCH (a2:Article) WHERE a2.articleID = 'Введение в базы данных'
MATCH (a3:Article) WHERE a3.articleID = 'Изучаем Python'

MERGE (r)-[:READ]->(a1)
MERGE (r)-[:READ]->(a2)
MERGE (r)-[:READ]->(a3)

RETURN r;
```

## Запросы
##### 1) Отобразить всех пользователей, статьи и связи между ними
```
MATCH (r:Reader)-[rel:READ]->(a:Article)
RETURN r, rel, a;
```

##### 2) Выбрать пользователя и найти категории, которые он читает 
```
MATCH (r:Reader {readerID: 'Алексей'})-[:READ]->(a:Article)-[:IS_IN]->(c:Category)
RETURN DISTINCT c.title AS Считаемые_Категории;
```

##### 3) Найти самых активных читателей (посчитать, кто читает больше всего статей)
```
MATCH (r:Reader)-[:READ]->(a:Article)
RETURN r.readerID AS Имя_Читателя, count(a) AS Всего_Статей
ORDER BY Всего_Статей DESC
LIMIT 5;
```

##### 4) Выбрать статью и найти похожие статьи (статьи, которые читают те же пользователи)
```
MATCH (a:Article {articleID: 'Квантовая физика для начинающих'})<-[:READ]-(r:Reader)-[:READ]->(similar:Article)
RETURN similar.articleID AS Похожая_Статья, count(r) AS Общих_Читателей
ORDER BY Общих_Читателей DESC;
```


#### 5. Рекомендации по категориям
    - найти категории, которые читает пользователь
    - предложить статьи из этих категорий, которые он ещё не читал 
```
MATCH (r:Reader {readerID: 'Алексей'})-[:READ]->(:Article)-[:IS_IN]->(c:Category)
WITH r, collect(DISTINCT c) AS read_categories

// Ищем все статьи из этих категорий
MATCH (recommended:Article)-[:IS_IN]->(cat)
WHERE cat IN read_categories
  // Проверяем, что пользователь ЛИЧНО эту статью еще не читал
  AND NOT (r)-[:READ]->(recommended)

RETURN recommended.articleID AS Рекомендованная_Статья, cat.title AS Категория;
```

##### Вывод:
```
+----------------------------------------------------------------------------------------+
| recommended_article                                                  | category        |
+----------------------------------------------------------------------------------------+
| "Clustering of clients. Analysis of the client's personality"        | "Data analysis" |
| "AI learns your mood or Perception for Autonomous Systems in action" | "Data analysis" |
+----------------------------------------------------------------------------------------+
```