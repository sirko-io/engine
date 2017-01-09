MERGE (start:Page { start: true })
MERGE (list:Page { path: "/list" })
MERGE (popular:Page { path: "/popular" })
MERGE (details:Page { path: "/details" })
MERGE (about:Page { path: "/about" })
MERGE (exit:Page { exit: true })

CREATE
  (start)-[:TRANSITION { count: 14, updated_at: timestamp() }]->(list),
  (list)-[:TRANSITION { count: 4, updated_at: timestamp() - 3600 * 1000 * 15 }]->(popular),
  (list)-[:TRANSITION { count: 6, updated_at: timestamp() }]->(details),
  (list)-[:TRANSITION { count: 4, updated_at: timestamp() }]->(about),
  (details)-[:TRANSITION { count: 4, updated_at: timestamp() - 1000 }]->(popular),
  (details)-[:TRANSITION { count: 4, updated_at: timestamp() }]->(exit),
  (popular)-[:TRANSITION { count: 6}]->(exit),
  (about)-[:TRANSITION { count: 2, updated_at: timestamp() }]->(popular),
  (about)-[:TRANSITION { count: 2, updated_at: timestamp() - 1000 }]->(details)
