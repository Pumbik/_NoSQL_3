
// 1. ЗАВАНТАЖЕННЯ ВУЗЛІВ (NODES)

// 1.1 Завантаження користувачів
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: toInteger(row.userId)})
ON CREATE SET 
    u.gender = row.gender,
    u.age = toInteger(row.age),
    u.occupation = toInteger(row.occupation),
    u.zip = row.zip;

// 1.2 Завантаження фільмів (із витягуванням року з назви)
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MERGE (m:Movie {movieId: toInteger(row.movieId)})
ON CREATE SET 
    // Назва у форматі "Toy Story (1995)", відрізаємо останні 7 символів для чистої назви
    m.title = trim(substring(row.title, 0, size(row.title)-7)),
    // Беремо 4 цифри року з кінця рядка
    m.year = toInteger(substring(row.title, size(row.title)-5, 4));

// 1.3 Завантаження жанрів (унікальних вузлів)
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
UNWIND split(row.genres, '|') AS genreName
MERGE (g:Genre {name: genreName});


// 2. СТВОРЕННЯ ІНДЕКСІВ (INDEXES)

// Виконуємо ДО створення зв'язків для максимального прискорення MATCH

CREATE INDEX user_id_idx FOR (u:User) ON (u.userId);
CREATE INDEX movie_id_idx FOR (m:Movie) ON (m.movieId);
CREATE INDEX genre_name_idx FOR (g:Genre) ON (g.name);


// 3. ЗАВАНТАЖЕННЯ РЕБЕР (RELATIONSHIPS)

// 3.1 Зв'язки між фільмами та жанрами
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MATCH (m:Movie {movieId: toInteger(row.movieId)})
UNWIND split(row.genres, '|') AS genreName
MATCH (g:Genre {name: genreName})
MERGE (m)-[:HAS_GENRE]->(g);

// 3.2 Зв'язки оцінок користувачів (ребра RATED) — батчеве завантаження через APOC
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row RETURN row",
  "MATCH (u:User {userId: toInteger(row.userId)})
   MATCH (m:Movie {movieId: toInteger(row.movieId)})
   MERGE (u)-[r:RATED]->(m)
   ON CREATE SET 
       r.rating = toInteger(row.rating), 
       r.timestamp = toInteger(row.timestamp)",
  {batchSize: 10000, parallel: false}
);


// 4. ПЕРЕВІРКА РЕЗУЛЬТАТІВ

MATCH (u:User) RETURN count(u) AS users;
MATCH (m:Movie) RETURN count(m) AS movies;
MATCH (g:Genre) RETURN count(g) AS genres;
MATCH ()-[r:RATED]->() RETURN count(r) AS ratings;
MATCH ()-[h:HAS_GENRE]->() RETURN count(h) AS genres_rels;