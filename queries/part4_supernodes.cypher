// Запит 1. Знайти топ-15 вузлів з найбільшою кількістю зв'язків
MATCH (n)
WITH n, COUNT { (n)--() } AS connections
ORDER BY connections DESC
LIMIT 15
RETURN labels(n)[0] AS NodeType, 
       coalesce(n.title, toString(n.userId), n.name) AS NodeIdentifier, 
       connections;

// Запит 2. Знайти конкретно топ-5 найщільніших жанрів (для аналізу)
MATCH (g:Genre)
RETURN g.name, COUNT { (g)--() } AS connections
ORDER BY connections DESC 
LIMIT 5;

// Запит 3. Знайти конкретно топ-5 фільмів-супервузлів (блокбастерів)
MATCH (m:Movie)
RETURN m.title, COUNT { (m)--() } AS connections
ORDER BY connections DESC 
LIMIT 5;