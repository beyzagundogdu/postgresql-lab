CREATE TABLE IF NOT EXISTS operations (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

INSERT INTO operations (description) VALUES
('GÜVENLİ NOKTA'),
('İLK VERİ');

SELECT * FROM operations ORDER BY id;

-- Bu dosyanın amacı: PITR senaryosunda geri getireceğin test tablosunu oluşturmak
/*
Çalıştırma:

```bash
docker exec -i pg14-pitr psql -U beyza -d testdb < scripts/init.sql
```
*/
