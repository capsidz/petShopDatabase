from datetime import datetime
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from sentence_transformers import SentenceTransformer

# 1. Инициализация клиента (в памяти для теста или localhost)
client = QdrantClient(":memory:")  # Для локального докера используйте QdrantClient("http://localhost:6333")
model = SentenceTransformer('all-MiniLM-L6-v2')  # Размерность эмбеддингов — 384

# 2. Создание коллекции
collection_name = "articles"
client.create_collection(
    collection_name=collection_name,
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
)

# 3. Подготовка 7 тестовых статей
articles_data = [
    {"title": "Новый процессор от Intel", "content": "Архитектура и тесты производительности нового чипа.",
     "author": "Иванов", "category": "tech", "published_at": "2024-02-15T12:00:00Z", "views": 1500, "rating": 4.5},
    {"title": "Как начать бегать по утрам",
     "content": "Советы для новичков: правильная обувь, техника бега и разминка.", "author": "Петров",
     "category": "sport", "published_at": "2023-11-10T08:30:00Z", "views": 2500, "rating": 4.8},
    {"title": "Итоги чемпионата мира", "content": "Обзор финального матча и статистика игроков.", "author": "Сидоров",
     "category": "sport", "published_at": "2024-03-01T21:00:00Z", "views": 5000, "rating": 3.9},
    {"title": "Революция в AI: GPT-5", "content": "Обсуждение будущих возможностей больших языковых моделей.",
     "author": "Иванов", "category": "tech", "published_at": "2024-05-20T10:15:00Z", "views": 8000, "rating": 4.9},
    {"title": "Смартфоны будущего", "content": "Гибкие экраны и новые аккумуляторы изменят индустрию.",
     "author": "Смирнов", "category": "tech", "published_at": "2023-05-12T14:00:00Z", "views": 1200, "rating": 3.2},
    {"title": "Главные новости недели", "content": "Коротко о важных событиях в мире политики и экономики.",
     "author": "Васильев", "category": "news", "published_at": "2024-06-01T09:00:00Z", "views": 300, "rating": 4.0},
    {"title": "Спортивное питание", "content": "Что нужно есть до и после тренировок для максимального результата.",
     "author": "Петров", "category": "sport", "published_at": "2024-01-10T16:45:00Z", "views": 600, "rating": 3.7},
]

# 4. Вставка данных в Qdrant
points = []
for idx, doc in enumerate(articles_data):
    # Кодируем комбинацию заголовка и контента для лучшего контекста
    text_to_vector = f"{doc['title']}. {doc['content']}"
    vector = model.encode(text_to_vector).tolist()

    points.append(
        PointStruct(
            id=idx,
            vector=vector,
            payload=doc
        )
    )

client.upsert(collection_name=collection_name, points=points)
print("Данные успешно импортированы!")

from qdrant_client.models import Filter, FieldCondition, MatchValue, Range, DatetimeRange

def print_results(title, response):
    print(f"\n=== {title} ===")
    for res in response.points:
        print(f"[{res.score:.3f}] {res.payload['title']} | Кат: {res.payload['category']} | Рейтинг: {res.payload['rating']} | Просмотры: {res.payload['views']}")


# --- 1. Простой поиск ---
query_vector = model.encode("бег и спорт").tolist()
res_simple = client.query_points(
    collection_name=collection_name,
    query=query_vector,
    limit=3
)
print_results("Простой поиск ('бег и спорт')", res_simple)


# --- 2. Фильтр по категории и рейтингу ---
res_filter_tech = client.query_points(
    collection_name=collection_name,
    query=model.encode("инновации").tolist(),
    query_filter=Filter(
        must=[
            FieldCondition(key="category", match=MatchValue(value="tech")),
            FieldCondition(key="rating", range=Range(gte=4.0))
        ]
    ),
    limit=3
)
print_results("Tech статьи с рейтингом >= 4.0", res_filter_tech)


# --- 3. Поиск с диапазоном дат ---
res_date_range = client.query_points(
    collection_name=collection_name,
    query=model.encode("актуальные события").tolist(),
    query_filter=Filter(
        must=[
            # ИСПОЛЬЗУЕМ DatetimeRange ВМЕСТО Range ДЛЯ СТРОКОВЫХ ДАТ
            FieldCondition(key="published_at", range=DatetimeRange(gt="2024-01-01T00:00:00Z")),
            # Здесь оставляем Range, так как просмотры — это числа
            FieldCondition(key="views", range=Range(gt=1000))
        ]
    ),
    limit=3
)
print_results("Опубликовано после 2024-01-01 и просмотры > 1000", res_date_range)


# --- 4. Сложный фильтр ---
res_complex = client.query_points(
    collection_name=collection_name,
    query=model.encode("что почитать интересного").tolist(),
    query_filter=Filter(
        must=[
            FieldCondition(key="rating", range=Range(gte=3.5)),
            FieldCondition(key="views", range=Range(gte=500, lte=5000)),
            Filter(
                should=[
                    FieldCondition(key="category", match=MatchValue(value="sport")),
                    FieldCondition(key="category", match=MatchValue(value="tech"))
                ]
            )
        ]
    ),
    limit=5
)
print_results("Сложный фильтр (sport/tech, рейтинг >= 3.5, просмотры 500-5000)", res_complex)

from qdrant_client.models import PayloadSchemaType

# Создаем индексы для полей
client.create_payload_index(collection_name=collection_name, field_name="category", field_schema=PayloadSchemaType.KEYWORD)
client.create_payload_index(collection_name=collection_name, field_name="rating", field_schema=PayloadSchemaType.FLOAT)
client.create_payload_index(collection_name=collection_name, field_name="published_at", field_schema=PayloadSchemaType.DATETIME)
client.create_payload_index(collection_name=collection_name, field_name="views", field_schema=PayloadSchemaType.INTEGER)

print("Payload-индексы успешно созданы!")

def get_paginated_search(query_text, page=1, page_size=2):
    print(f"\n--- Пагинация: Страница {page} (размер {page_size}) ---")
    vector = model.encode(query_text).tolist()

    # Вычисляем смещение
    offset = (page - 1) * page_size

    results = client.query_points(
        collection_name=collection_name,
        query=vector,
        limit=page_size,
        offset=offset
    )


    for i, res in enumerate(results.points):
        print(f"Позиция {offset + i + 1}: {res.payload['title']} (Score: {res.score:.3f})")


get_paginated_search("технологии", page=1, page_size=2)
get_paginated_search("технологии", page=2, page_size=2)
