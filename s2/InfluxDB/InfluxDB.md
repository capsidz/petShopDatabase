#### 1. Создать bucket mydb

```
$headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer apiv3_al86UeW3iUzL8grREot-Uc_lKQLMxydFmiLeHD1RHPvz22IBJ6m1KrisA0ZcFTc33LTCb4g-hZmt9x7-TUNPRw"
}

$body = @{
    "db" = "mydb"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "http://localhost:8181/api/v3/configure/database" -Headers $headers -Body $body
```

#### 2. Вставить несколько записей

##### Запись 1: комната 1, температура 23.5
```
Invoke-RestMethod -Method Post -Uri "http://localhost:8181/api/v3/write_lp?db=mydb" -Headers $headers -Body "temperature,location=room1 value=23.5"
```

##### Запись 2: комната 2, температура 21.0
```
Invoke-RestMethod -Method Post -Uri "http://localhost:8181/api/v3/write_lp?db=mydb" -Headers $headers -Body "temperature,location=room2 value=21.0"
```

##### Запись 3: комната 1, температура 24.2 (новая точка)
```
Invoke-RestMethod -Method Post -Uri "http://localhost:8181/api/v3/write_lp?db=mydb" -Headers $headers -Body "temperature,location=room1 value=24.2"
```

#### 3. Выбрать все данные за последние 5 минут
```
$headers = @{
    "Authorization" = "Bearer apiv3_al86UeW3iUzL8grREot-Uc_lKQLMxydFmiLeHD1RHPvz22IBJ6m1KrisA0ZcFTc33LTCb4g-hZmt9x7-TUNPRw"
    "Accept"        = "text/csv"
}

$db = [System.Web.HttpUtility]::UrlEncode("mydb")
$q  = [System.Web.HttpUtility]::UrlEncode("SELECT * FROM temperature WHERE time >= now() - interval '5 minutes'")

# Выполняем GET-запрос на правильный эндпоинт
$response = Invoke-RestMethod -Method Get -Uri "http://localhost:8181/api/v3/query_sql?db=$db&q=$q" -Headers $headers
$response
```

##### Консоль:
```
location,time,value
room1,2026-06-02T20:06:43.413618316,24.2
room2,2026-06-02T20:06:25.075744191,21.0
```

#### 5. Сгруппировать SELECT по тегу location
```
$headers = @{
    "Authorization" = "Bearer apiv3_al86UeW3iUzL8grREot-Uc_lKQLMxydFmiLeHD1RHPvz22IBJ6m1KrisA0ZcFTc33LTCb4g-hZmt9x7-TUNPRw"
    "Accept"        = "text/csv"
}

$sqlQuery = "SELECT location, AVG(value) AS avg_temperature FROM temperature WHERE time >= now() - interval '5 minutes' GROUP BY location"

$db = [System.Web.HttpUtility]::UrlEncode("mydb")
$q  = [System.Web.HttpUtility]::UrlEncode($sqlQuery)

$responseGroup = Invoke-RestMethod -Method Get -Uri "http://localhost:8181/api/v3/query_sql?db=$db&q=$q" -Headers $headers
$responseGroup
```
##### Консоль:
```
location,avg_temperature
room2,21.0
room1,23.85
```