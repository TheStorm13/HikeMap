# HikeMap
# **Проект: Интерактивная карта с туристическими маршрутами**

## Описание

**Цель**: Платформа для планирования, поиска и взаимодействия с походами на основе интерактивной карты.

### **1. Функционал**

**Для всех пользователей**:

- **Интерактивная карта**:
    - Отображение треков походов в виде линий.
    - Поиск по: названию, району, дате, сложности.
    - Фильтры: категория сложности, вид похода (пеший, вело)
    - Группировка маркеров (кластеризация).
    - Взаимодействие: клик на маркер → открытие описания похода.
- **Список походов**
    - Отображение всех походов в виде списка с превью (название, фото, район, сложность, дата).
    - **Сортировка**:
        - По дате добавления, сложности, популярности (количеству лайков).
    - **Фильтрация**:
        - Аналогично фильтрам на карте (вид похода, район).
    - Переключение между картой и списком без перезагрузки страницы.
- **Описание похода**:
    - Поля: название, описание, фото, даты начала/завершения, район, категория сложности, вид, трек (можно скачать), отчет по походу (PDF файл, можно скачать).
    - Кнопки: "Лайк"

**Для гостя:**

- Фильтровать и сортировать походы

**Для участников**:

- Права гостя
- Регистрация/авторизация
- Лайки походов

**Для организаторов**:

- Права участника
- Добавление походов через форму с загрузкой трека (GPX) и отчета (PDF).
- Поля формы:
    - Название, описание, фото, даты начала/завершения, категория сложности, вид похода.

## **Стек**

- **Backend**: Spring, Hibernate, PostgreSQL/PostGIS.
- **Frontend**: React, Leaflet
- **Инфраструктура**: Docker

## Сущности

### **Сущности**

### 1. **Пользователь (User)**

- **Поля**:
    - `id` (PK)
    - `username` (уникальный)
    - `email` (уникальный)
    - `password_hash`
    - `role`
    - `created_at`
    - `updated_at`
    - **Внешние ключи**:
        - `role_id` → `Role.id`

### 2. Роли

- **Поля:**
    - `id` (PK)
    - `name` (уникальный, например: "Альпы", "Кавказ")

### **3. Район (Area)**

- **Поля**:
    - `id` (PK)
    - `name` (уникальный, например: member, organizer)

### 4. **Категория сложности (DifficultyCategory)**

- **Поля**:
    - `id` (PK)
    - `name` (ENUM: например: "Легкий", "Средний", "Сложный")

### 5. **Тип похода (HikeType)**

- **Поля**:
    - `id` (PK)
    - `name` (ENUM: "Пеший", "Велосипедный", "Горный")

### 6. **Поход (Hike)**

- **Поля**:
    - `id` (PK)
    - `title`
    - `description`
    - `photo_path` (путь к изображению)
    - `start_date` (дата начала похода)
    - `end_date` (дата завершения похода)
    - `track_gpx_path` (путь к GPX-файлу)
    - `track_geometry` (PostGIS геометрия `LineString`)
    - `report_pdf_path` (путь к PDF-отчету)
    - `created_at`
    - `updated_at`
    - **Внешние ключи**:
        - `organizer_id` → `User.id` (организатор)
        - `area_id` → `Area.id`
        - `difficulty_id` → `DifficultyCategory.id`
        - `hike_type_id` → `HikeType.id`

### 7. **Лайк (Like)**

- **Поля**:
    - `user_id` (PK, FK → `User.id`)
    - `hike_id` (PK, FK → `Hike.id`)
    - `created_at`

---

### **Схема связей**

1. **User** (1) → (N) **Hike**
    
    Организатор (`organizer_id`) создает походы.
    
2. **User** (N) → (1) **Role**
    
    Пользователь имеет одну роль
    
3. **Hike** (N) → (1) **Area**
    
    Поход относится к одному району.
    
4. **Hike** (N) → (1) **DifficultyCategory**
    
    Поход имеет одну категорию сложности.
    
5. **Hike** (N) → (1) **HikeType**
    
    Поход относится к одному типу (пеший, вело).
    
6. **User** (N) ↔ (N) **Hike** через **Like**
    
    Участники ставят лайки походам.
    

## API

### **1. Аутентификация и пользователи**

- **POST /api/auth/signup**
    
    Регистрация нового пользователя.
    
    **Тело запроса**:
    
    ```json
    {
      "username": "string",
      "email": "string",
      "password": "string"
    }
    ```
    
    **Ответ**: JWT токен.
    
- **POST /api/auth/login**
    
    Вход в систему.
    
    **Тело запроса**:
    
    ```json
    {
      "email": "string",
      "password": "string"
    }
    ```
    
    **Ответ**: JWT токен.
    
- **GET /api/auth/me**
    
    Получение данных текущего пользователя.
    
    **Ответ**:
    
    ```json
    {
      "id": "number",
      "username": "string",
      "email": "string",
      "role": "string"
    }
    ```
    

---

### **2. Походы (Hikes)**

- **GET /api/hikes**
    
    Получение списка походов с фильтрами и сортировкой.
    
    **Параметры запроса**:
    
    - `search` (string): Поиск по названию и описанию.
    - `areaIds[]` (number[]): Фильтр по районам.
    - `difficultyIds[]` (number[]): Фильтр по сложности.
    - `hikeTypeIds[]` (number[]): Фильтр по типу похода.
    - `startDate` (date): Дата начала похода (>=).
    - `endDate` (date): Дата окончания похода (<=).
    - `sortBy` (string): Поле для сортировки (`createdAt`, `difficulty`, `popularity`).
    - `order` (string): Порядок сортировки (`asc`/`desc`).
    
    **Ответ**:
    
    ```json
    {
      "content": [
        {
          "id": "number",
          "title": "string",
          "photoPath": "string",
          "area": "string",
          "difficulty": "string",
          "startDate": "date",
          "endDate": "date",
          "likesCount": "number",
          "isLiked": "boolean" // Только для аутентифицированных пользователей
        }
      ],
      "totalPages": "number",
      "currentPage": "number"
    }
    ```
    
- **GET /api/hikes/{id}**
    
    Получение деталей похода.
    
    **Ответ**:
    
    ```json
    {
      "id": "number",
      "title": "string",
      "description": "string",
      "photoPath": "string",
      "startDate": "date",
      "endDate": "date",
      "area": "string",
      "difficulty": "string",
      "hikeType": "string",
      "trackGpxPath": "string",
      "reportPdfPath": "string",
      "likesCount": "number",
      "isLiked": "boolean", // Только для аутентифицированных пользователей
    }
    ```
    
- **POST /api/hikes** (multipart/form-data, требуется роль организатора)
    
    Создание похода.
    
    **Поля формы**:
    
    - `title` (string)
    - `description` (string)
    - `photo` (file)
    - `startDate` (date)
    - `endDate` (date)
    - `areaId` (number)
    - `difficultyId` (number)
    - `hikeTypeId` (number)
    - `trackGpx` (file)
    - `reportPdf` (file)
- **PUT /api/hikes/{id}** (требуется роль организатора)
    
    Обновление похода. Аналогично POST.
    
- **DELETE /api/hikes/{id}** (требуется роль организатора или администратора)

---

### **3. Работа с картой**

- **GET /api/hikes/geojson**
    
    Получение данных для карты в формате GeoJSON.
    
    Чтобы избежать перегрузки данными, добавим параметры для фильтрации по границам карты (**bbox**) и уровню зума (**zoom**).
    
    Почитать про **Geohash** или **Группировка по областям**
    
    **Параметры**: аналогично `GET /api/hikes`.
    
    **Ответ**:
    
    ```json
    {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "LineString",
            "coordinates": [[lon, lat], ...]
          },
          "properties": {
            "id": "number",
            "title": "string",
            "difficulty": "string"
          }
        }
      ]
    }
    ```
    

---

### **4. Лайки**

- **POST /api/hikes/{hikeId}/likes** (требуется аутентификация)
    
    Поставить лайк.
    
- **DELETE /api/hikes/{hikeId}/likes** (требуется аутентификация)
    
    Удалить лайк.
    

---

### **5. Справочники**

- **GET /api/areas**
    
    Список районов.
    
    **Ответ**:
    
    ```json
    [
      { "id": "number", "name": "string" }
    ]
    ```
    
- **GET /api/difficulties**
    
    Категории сложности.
    
    **Ответ**:
    
    ```json
    [
      { "id": "number", "name": "string" }
    ]
    ```
    
- **GET /api/hike-types**
    
    Типы походов.
    
    **Ответ**:
    
    ```json
    [
      { "id": "number", "name": "string" }
    ]
    ```
    

---

### **6. Файлы**

- **GET /uploads/{filename}**
    
    Скачивание файлов (GPX, PDF).
    

## **Будущие идеи (Roadmap)**

1. **Коллекции походов** ("Прошел", "Планирую пройти").
2. **Точки интереса** на треках (достопримечательности, кемпинги).
3. **Модерация** походов перед публикацией.
4. **Календарь** с датами походов и уведомлениями.
5. **Статистика** для организаторов (лайки, просмотры, активность).
6. **Для администраторов**: управление пользователями и походами
