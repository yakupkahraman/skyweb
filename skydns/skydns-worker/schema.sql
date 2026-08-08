CREATE TABLE domains (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  domain TEXT NOT NULL,
  tld TEXT NOT NULL,
  repo TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  UNIQUE(domain, tld)
);