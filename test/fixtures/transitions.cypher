CREATE (start:Page {start: true}),
  (list:Page {path: "/list"}),
  (popular:Page {path: "/popular"}),
  (details:Page {path: "/details"}),
  (exit:Page {exit: true})

CREATE
  (start)-[:TRANSITION {count: 10}]->(list),
  (list)-[:TRANSITION {count: 4}]->(popular),
  (list)-[:TRANSITION {count: 6}]->(details),
  (details)-[:TRANSITION {count: 4}]->(popular),
  (details)-[:TRANSITION {count: 2}]->(exit),
  (popular)-[:TRANSITION {count: 4}]->(exit)