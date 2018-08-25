MERGE (start:Page { path: "/" })
MERGE (list:Page { path: "/list" })
MERGE (popular:Page { path: "/popular" })
MERGE (about:Page { path: "/about" })
MERGE (exit:Page { exit: true })

// Stale sessions

CREATE
  (start)  -[:SESSION { key: "skey1", count: 1, occurred_at: timestamp() - (3600 * 1000 * 24 * 9) }]->
  (list)   -[:SESSION { key: "skey1", count: 2, occurred_at: timestamp() - (3600 * 1000 * 24 * 8) }]->
  (popular)-[:SESSION { key: "skey1", count: 3, occurred_at: timestamp() - (3600 * 1000 * 24 * 7), expired_at: timestamp() - (3600 * 1000 * 24 * 7) }]->
  (exit)

CREATE
  (start)-[:SESSION { key: "skey2", count: 1, occurred_at: timestamp() - (3600 * 1000 * 24 * 9) }]->
  (list) -[:SESSION { key: "skey2", count: 1, occurred_at: timestamp() - (3600 * 1000  * 24 * 8) }]->
  (popular)-[:SESSION { key: "skey2", count: 1, occurred_at: timestamp() - (3600 * 1000 * 24 * 7), expired_at: timestamp() - (3600 * 1000 * 24 * 7) }]->
  (exit)

// Expired sessions

CREATE
  (start)  -[:SESSION { key: "skey10", count: 1, occurred_at: timestamp() - (3600 * 1000 * 10) }]->
  (list)   -[:SESSION { key: "skey10", count: 3, occurred_at: timestamp() - (3600 * 1000 * 9) }]->
  (popular)-[:SESSION { key: "skey10", count: 1, occurred_at: timestamp() - (3600 * 1000 * 8), expired_at: timestamp() - (3600 * 1000) }]->
  (exit)

CREATE
  (start)-[:SESSION { key: "skey11", count: 1, occurred_at: timestamp() - (3600 * 1000 * 9) }]->
  (list) -[:SESSION { key: "skey11", count: 1, occurred_at: timestamp() - (3600 * 1000 * 8), expired_at: timestamp() - (3600 * 1000) }]->
  (exit)

// Inactive sessions

CREATE
  (start)-[:SESSION { key: "skey20", count: 1, occurred_at: timestamp() - (3600 * 1000 * 4) }]->
  (list) -[:SESSION { key: "skey20", count: 1, occurred_at: timestamp() - (3600 * 1000 * 3) }]->
  (popular)

CREATE
  (start)-[:SESSION { key: "skey21", count: 1, occurred_at: timestamp() - (3600 * 1000 * 3) }]->
  (list) -[:SESSION { key: "skey21", count: 1, occurred_at: timestamp() - (3600 * 1000 * 2) }]->
  (popular)

CREATE
  (start)-[:SESSION { key: "skey22", count: 1, occurred_at: timestamp() - (3600 * 1000 * 4) }]->
  (list) -[:SESSION { key: "skey22", count: 1, occurred_at: timestamp() - (3600 * 1000 * 3) }]->
  (about)

// Short session to be removed
CREATE (start)-[:SESSION { key: "skey23", count: 1, occurred_at: timestamp() - (3600 * 1000 * 2) }]->(list)

// Active sessions

CREATE
  (start)-[:SESSION { key: "skey30", count: 1, occurred_at: timestamp() - (3600 * 1000) }]->
  (list) -[:SESSION { key: "skey30", count: 1, occurred_at: timestamp() - (60 * 1000 * 2) }]->
  (popular)

CREATE
  (start)-[:SESSION { key: "skey31", count: 1, occurred_at: timestamp() - (60 * 1000 * 30) }]->
  (list) -[:SESSION { key: "skey31", count: 1, occurred_at: timestamp() - (60 * 1000 * 5) }]->
  (popular)
