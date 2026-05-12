DROP TABLE operations;

SELECT pg_switch_wal();

/*
DROP TABLE operations; tabloyu siler.
SELECT pg_switch_wal(); ise aktif WAL segmentini değiştirerek bu işlemin WAL archive’a düşmesini kolaylaştırır.

Çalıştırma:
```bash
docker exec -i pg14-pitr psql -U beyza -d testdb < scripts/simulate-disaster.sql
```
*/
