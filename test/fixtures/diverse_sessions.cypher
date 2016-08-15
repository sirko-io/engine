MERGE (start:Page { start: true })
MERGE (list:Page { path: "/list" })
MERGE (popular:Page { path: "/popular" })
MERGE (exit:Page { exit: true })

// Expired sessions

CREATE
  (start)  -[:SESSION { key: "skey10", created_at: timestamp() - (60 * 60 * 10) }]->
  (list)   -[:SESSION { key: "skey10", created_at: timestamp() - (60 * 60 * 10) }]->
  (popular)-[:SESSION { key: "skey10", created_at: timestamp() - (60 * 60 * 10), expired_at: timestamp() - (60 * 60) }]->
  (exit)

CREATE
  (start)-[:SESSION { key: "skey11", created_at: timestamp() - (60 * 60 * 8) }]->
  (list) -[:SESSION { key: "skey11", created_at: timestamp() - (60 * 60 * 8), expired_at: timestamp() - (60 * 60) }]->
  (exit)

// Inactive sessions

CREATE
  (start)-[:SESSION { key: "skey20", created_at: timestamp() - (60 * 30 * 4) }]->
  (list) -[:SESSION { key: "skey20", created_at: timestamp() - (60 * 30 * 3) }]->
  (popular)

CREATE
  (start)-[:SESSION { key: "skey21", created_at: timestamp() - (60 * 30 * 3) }]->
  (list) -[:SESSION { key: "skey21", created_at: timestamp() - (60 * 30 * 2) }]->
  (popular)

// Active sessions

CREATE
  (start)-[:SESSION { key: "skey30", created_at: timestamp() - (60 * 60) }]->
  (list) -[:SESSION { key: "skey30", created_at: timestamp() - (60 * 2) }]->
  (popular)

CREATE
  (start)-[:SESSION { key: "skey31", created_at: timestamp() - (60 * 30) }]->
  (list) -[:SESSION { key: "skey31", created_at: timestamp() - (60 * 5) }]->
  (popular)
