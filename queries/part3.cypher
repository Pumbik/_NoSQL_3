// Базові запити

// Запит 1. Знайти всі фільми жанру «Thriller» із середнім рейтингом вище 4.0
MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre {name: 'Thriller'})
MATCH (u:User)-[r:RATED]->(m)
WITH m, avg(r.rating) AS avgRating, count(r) AS totalRatings
WHERE avgRating > 4.0 AND totalRatings > 10 //  мінімальна кількість оцінок для релевантності
RETURN m.title, avgRating, totalRatings
ORDER BY avgRating DESC
LIMIT 10;

// Запит 2. Знайти користувачів, які поставили оцінку 5 більш ніж 50 фільмам
MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE r.rating = 5
WITH u, count(m) AS fiveStarMovies
WHERE fiveStarMovies > 50
RETURN u.userId, fiveStarMovies
ORDER BY fiveStarMovies DESC
LIMIT 10;


// Запити середнього рівня

// Запит 3. Знайти фільми, які обидва користувачі (userId=1 і userId=2) оцінили високо (рейтинг >= 4)
MATCH (u1:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: 2})
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN m.title, r1.rating AS ratingUser1, r2.rating AS ratingUser2;

// Запит 4. Знайти жанри, чиї фільми стабільно отримують високі оцінки — середній рейтинг і кількість оцінок
MATCH (g:Genre)<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-(u:User)
WITH g, avg(r.rating) AS avgGenreRating, count(r) AS totalRatings
WHERE totalRatings > 1000 // відсікаємо рідкісні жанри
RETURN g.name, avgGenreRating, totalRatings
ORDER BY avgGenreRating DESC;


// Складні запити

// Запит 5.  Рекомендація «користувачі зі схожими смаками також дивилися»: для заданого користувача
//  знайти фільми, які він ще не дивився, але високо оцінили користувачі з подібними смаками
MATCH (target:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(similar:User)
WHERE r1.rating >= 4 AND r2.rating >= 4
WITH target, similar, count(m) AS similarityScore
ORDER BY similarityScore DESC LIMIT 50 // Беремо 50 найбільш схожих користувачів

MATCH (similar)-[r3:RATED]->(recMovie:Movie)
WHERE r3.rating >= 4
  AND NOT EXISTS {
    MATCH (target)-[:RATED]->(recMovie) // Відсікаємо фільми, які цільовий користувач вже бачив
  }
WITH recMovie, count(similar) AS timesRecommended, sum(similarityScore) AS recommendationScore
RETURN recMovie.title, recMovie.year, timesRecommended, recommendationScore
ORDER BY recommendationScore DESC
LIMIT 10;

// Запит 6. Знайти найкоротший ланцюжок зв’язку між двома користувачами через спільні фільми
MATCH path = shortestPath((u1:User {userId: 1})-[:RATED*..6]-(u2:User {userId: 100}))
RETURN path;