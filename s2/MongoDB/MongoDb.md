#### 1. Создание коллекции и добавление одной книги
```
use library;

db.books.insertOne({
  title: "Грокаем алгоритмы",
  genre: "programming",
  price: 1200,
  available: true,
  tags: ["algorithms", "education", "beginners"],
  author: {
    name: "Адитья Бхаргава",
    country: "USA"
  }
});
```

##### Консоль:
```
{
  acknowledged: true,
  insertedId: ObjectId('6a1f3c419d8c46f0b39df8a3')
}
```

#### 2. Простой поиск по одному условию
```
db.books.find({ available: true });
```

##### Консоль:
```
[
  {
    _id: ObjectId('6a1f3c419d8c46f0b39df8a3'),
    title: 'Грокаем алгоритмы',
    genre: 'programming',
    price: 1200,
    available: true,
    tags: [ 'algorithms', 'education', 'beginners' ],
    author: { name: 'Адитья Бхаргава', country: 'USA' }
  }
]
```

#### 3. Добавление нескольких документов
```
// 3. Добавление еще 4-х книг с разной структурой данных
db.books.insertMany([
  {
    title: "Чистый код",
    genre: "programming",
    price: 2500,
    available: true,
    tags: ["clean code", "architecture", "development"],
    author: {
      name: "Роберт Мартин",
      country: "USA"
    }
  },
  {
    title: "CLR via C#",
    genre: "programming",
    price: 3800,
    available: false, // Нет в наличии
    tags: [".net", "c#", "advanced"],
    author: {
      name: "Джеффри Рихтер",
      country: "USA"
    }
  },
  {
    title: "Властелин Колец",
    genre: "fantasy",
    price: 1500,
    available: true,
    tags: ["classic", "adventure", "trilogy"],
    author: {
      name: "Джон Р. Р. Толкин",
      country: "UK"
    }
  },
  {
    title: "Дюна",
    genre: "sci-fi",
    price: 950,
    available: false, // Нет в наличии
    tags: ["space", "empire", "classic"],
    author: {
      name: "Фрэнк Герберт",
      country: "USA"
    }
  }
]);
```

##### Консоль:
```
{
  acknowledged: true,
  insertedIds: {
    '0': ObjectId('6a1f3cd39d8c46f0b39df8a4'),
    '1': ObjectId('6a1f3cd39d8c46f0b39df8a5'),
    '2': ObjectId('6a1f3cd39d8c46f0b39df8a6'),
    '3': ObjectId('6a1f3cd39d8c46f0b39df8a7')
  }
}
```


#### 4. Запрос посложнее (Фильтрация + Проекция)
```
// 4. Сложный поиск с ограничением выводимых полей (фильтрация по цене > 1400)
db.books.find(
  { 
    genre: "programming", 
    price: { $gt: 1400 }, 
    available: true 
  },
  { 
    title: 1, 
    price: 1, 
    _id: 0 
  }
);
```

##### Консоль:
```
[ { title: 'Чистый код', price: 2500 } ]
```