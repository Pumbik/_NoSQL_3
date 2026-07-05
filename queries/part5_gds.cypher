// ЧАСТИНА 5.1: PageRank на графі фільмів

// Крок 1: матеріалізуємо ребра фільм-фільм через спільних користувачів
MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(m1) < id(m2)
WITH m1, m2, count(u) AS weight
WHERE count { (m1)<-[:RATED]-() } > 20
  AND count { (m2)<-[:RATED]-() } > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

// Крок 2: створюємо проєкцію на основі матеріалізованих ребер
CALL gds.graph.project(
  'movieGraph',
  'Movie',
  { CO_RATED: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: Запуск алгоритму PageRank
CALL gds.pageRank.stream('movieGraph', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).title AS title, score
ORDER BY score DESC
LIMIT 10;

// Крок 4: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-() DELETE co;

// ========================================================================================

// ЧАСТИНА 5.2: Виявлення спільнот (Louvain)

// Крок 1: матеріалізуємо ребра користувач-користувач через спільні фільми
// MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
// WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(u1) < id(u2)
// WITH u1, u2, count(m) AS weight
// WITH u1, u2, weight
// ORDER BY weight DESC
// LIMIT 50000
// MERGE (u1)-[sim:SIMILAR]-(u2)
// SET sim.weight = weight;

// Крок 1 Спроба оптимізувати
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 AND r2.rating = 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WHERE weight >= 2
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 30000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;


// Крок 2: створюємо проєкцію
CALL gds.graph.project(
  'userSimilarity',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: Запуск алгоритму Louvain та запис результатів (communityId) у вузли User
CALL gds.louvain.write('userSimilarity', {
  relationshipWeightProperty: 'weight',
  writeProperty: 'communityId'
})
YIELD communityCount, modularity;

// Крок 3.1: Вивід розмірів 10 найбільших кластерів
MATCH (u:User)
WHERE u.communityId IS NOT NULL
RETURN u.communityId AS community, count(u) AS size
ORDER BY size DESC
LIMIT 10;

// Крок 4: Аналіз топ-3 жанрів для кожної з 10 найбільших спільнот
MATCH (u:User)
WHERE u.communityId IS NOT NULL
WITH u.communityId AS community, count(u) AS size
ORDER BY size DESC
LIMIT 10
// Знаходимо високі оцінки користувачів із цих спільнот та жанри відповідних фільмів
MATCH (u:User {communityId: community})-[r:RATED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
WHERE r.rating >= 4
WITH community, size, g.name AS genre, count(r) AS genreCount
ORDER BY community, genreCount DESC
// Збираємо топ-3 жанри в масив для кожної спільноти
WITH community, size, collect(genre)[0..3] AS topGenres
RETURN community, size, topGenres
ORDER BY size DESC;

// Крок 5: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('userSimilarity');
MATCH ()-[sim:SIMILAR]-() DELETE sim;


// ========================================================================================

// ЧАСТИНА 5.3: Найкоротший шлях (Дейкстра)

// Крок 1: 
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 AND r2.rating = 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WHERE weight >= 2
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 30000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

// Крок 2: Створюємо проєкцію 
CALL gds.graph.project(
  'userGraph',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;


// Крок 3: Запуск алгоритму Дейкстри для пари користувачів (наприклад, 1 та 100)
MATCH (source:User {userId: 1}), (target:User {userId: 100})
CALL gds.shortestPath.dijkstra.stream('userGraph', {
  sourceNode: source,
  targetNode: target
  // я навмисно не вказую relationshipWeightProperty: 'weight'.
  // Оскільки шукаю кількість "рукостискань", кожен крок (ребро) рахується як 1.
})
YIELD totalCost, nodeIds
RETURN totalCost AS handshakes,
       [nodeId IN nodeIds | gds.util.asNode(nodeId).userId] AS userPath;


// Крок 4: Видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('userGraph');
MATCH ()-[sim:SIMILAR]-() DELETE sim;