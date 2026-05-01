#### 1.Поднять Elasticsearch через Docker
```
docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -e "xpack.security.enabled=false" docker.elastic.co/elasticsearch/elasticsearch:8.12.0
```

```
curl http://localhost:9200
```
StatusCode        : 200
StatusDescription : OK
Content           : {
                      "name" : "376eeaf8a318",
                      "cluster_name" : "docker-cluster",
                      "cluster_uuid" : "BJ1L2I6sRr-RKMzSEJumVQ",
                      "version" : {
                        "number" : "8.12.0",
                        "build_flavor" : "default",
                        "build_type"...
RawContent        : HTTP/1.1 200 OK
                    X-elastic-product: Elasticsearch
                    Content-Length: 540
                    Content-Type: application/json

                    {
                      "name" : "376eeaf8a318",
                      "cluster_name" : "docker-cluster",
                      "cluster_uuid" : "BJ1L2I6s...
Forms             : {}
Headers           : {[X-elastic-product, Elasticsearch], [Content-Length, 540], [Content-Type, application/json]}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 540

#### 2-3. Создать индекс products и наполнение данными
```
$headers = @{ "Content-Type" = "application/json" }
$body = @"
{ "index" : { "_id" : "1" } }
{ "name": "Сухой корм для кошек Royal Canin", "category": "food", "price": 1200, "in_stock": true, "tags": ["cat", "dry"] }
{ "index" : { "_id" : "2" } }
{ "name": "Влажный корм для собак Pedigree говядина", "category": "food", "price": 150, "in_stock": true, "tags": ["dog", "wet"] }
{ "index" : { "_id" : "3" } }
{ "name": "Игрушка Мячик для собак резиновый", "category": "accessories", "price": 450, "in_stock": false, "tags": ["dog", "toy"] }
{ "index" : { "_id" : "4" } }
{ "name": "Когтеточка для кошек деревянная", "category": "accessories", "price": 2300, "in_stock": true, "tags": ["cat", "furniture"] }

"@

Invoke-RestMethod -Method Post -Uri "http://localhost:9200/products/_bulk?pretty" -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
```

errors took items
------ ---- -----
 False  607 {@{index=}, @{index=}, @{index=}, @{index=}}


#### 4. Операции с документами
##### 4.1. Создать документ (с автогенерацией ID)
```
$headers = @{ "Content-Type" = "application/json" }
$body = @'
{
  "name": "Поводок-рулетка для собак",
  "category": "accessories",
  "price": 1800,
  "in_stock": true,
  "tags": ["dog", "leash"]
}
'@

Invoke-RestMethod -Method Post -Uri "http://localhost:9200/products/_doc?pretty" -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
```

_index        : products
_id           : EVlRMZ4BSvqhz6wibWGn
_version      : 1
result        : created
_shards       : @{total=2; successful=1; failed=0}
_seq_no       : 4
_primary_term : 1


##### 4.2. Документы с указанным ID
```
$headers = @{ "Content-Type" = "application/json" }
$body = @'
{
  "name": "Шампунь для лошадей гипоаллергенный",
  "category": "medication",
  "price": 850,
  "in_stock": true,
  "tags": ["horse", "shampoo"]
}
'@

Invoke-RestMethod -Method Put -Uri "http://localhost:9200/products/_doc/5?pretty" -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
```

_index        : products
_id           : 5
_version      : 1
result        : created
_shards       : @{total=2; successful=1; failed=0}
_seq_no       : 5
_primary_term : 1


##### 4.3. Обновление документа
```
$headers = @{ "Content-Type" = "application/json" }
$body = @'
{
  "doc": {
    "price": 990,
    "in_stock": false
  }
}
'@

Invoke-RestMethod -Method Post -Uri "http://localhost:9200/products/_update/5?pretty" -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
```

_index        : products
_id           : 5
_version      : 2
result        : updated
_shards       : @{total=2; successful=1; failed=0}
_seq_no       : 6
_primary_term : 1


##### 4.3. Удаление документа
```
Invoke-RestMethod -Method Delete -Uri "http://localhost:9200/products/_doc/5?pretty"
```

_index        : products
_id           : 5
_version      : 3
result        : deleted
_shards       : @{total=2; successful=1; failed=0}
_seq_no       : 7
_primary_term : 1


#### 5. Поисковые запросы
##### 5.1. Поиск по названию товара (match)
```
$headers = @{ "Content-Type" = "application/json" }
$body = @'
{
  "query": {
    "match": {
      "name": "кошек"
    }
  }
}
'@

Invoke-RestMethod -Method Post -Uri "http://localhost:9200/products/_search?pretty" -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
```

took timed_out _shards                                       hits
---- --------- -------                                       ----
 145     False @{total=1; successful=1; skipped=0; failed=0} @{total=; max_score=0,9534807; hits=System.Object[]}


##### 5.2. Запрос с использованием match (полнотекстовый поиск)
```
$headers = @{ "Content-Type" = "application/json" }
$body = @'
{
  "query": {
    "match": {
      "name": "сухой корм собак"
    }
  }
}
'@

Invoke-RestMethod -Method Post -Uri "http://localhost:9200/products/_search?pretty" -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
```

took timed_out _shards                                       hits
---- --------- -------                                       ----
  57     False @{total=1; successful=1; skipped=0; failed=0} @{total=; max_score=2,0907054; hits=System.Object[]}


##### 5.3. Запрос с использованием term (точное совпадение)
```
$headers = @{ "Content-Type" = "application/json" }
$body = @'
{
  "query": {
    "term": {
      "category.keyword": "food"
    }
  }
}
'@

Invoke-RestMethod -Method Post -Uri "http://localhost:9200/products/_search?pretty" -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
```

took timed_out _shards                                       hits
---- --------- -------                                       ----
  12     False @{total=1; successful=1; skipped=0; failed=0} @{total=; max_score=0,87546873; hits=System.Object[]}


##### 5.4. Запрос с использованием range (диапазоны)
```
$headers = @{ "Content-Type" = "application/json" }
$body = @'
{
  "query": {
    "range": {
      "price": {
        "gte": 200,
        "lt": 1500
      }
    }
  }
}
'@

Invoke-RestMethod -Method Post -Uri "http://localhost:9200/products/_search?pretty" -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
```
took timed_out _shards                                       hits
---- --------- -------                                       ----
  15     False @{total=1; successful=1; skipped=0; failed=0} @{total=; max_score=1,0; hits=System.Object[]}


##### 5.5. Сложный запрос с использованием bool (комбинация условий)
```
$headers = @{ "Content-Type" = "application/json" }
$body = @'
{
  "query": {
    "bool": {
      "must": [
        { "match": { "name": "для кошек" } }
      ],
      "filter": [
        { "range": { "price": { "gte": 500, "lte": 3000 } } },
        { "term": { "in_stock": true } }
      ]
    }
  }
}
'@

Invoke-RestMethod -Method Post -Uri "http://localhost:9200/products/_search?pretty" -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
```
took timed_out _shards                                       hits
---- --------- -------                                       ----
  22     False @{total=1; successful=1; skipped=0; failed=0} @{total=; max_score=1,0482455; hits=System.Object[]}