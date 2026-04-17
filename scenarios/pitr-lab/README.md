# PostgreSQL Point-in-Time Recovery (PITR) Lab

## Genel Bakış

PITR, PostgreSQL’i belirli bir saniyeye geri döndürmemizi sağlayan bir felaket kurtarma mekanizmasıdır. 
Full backup + WAL arşivleme sayesinde, yanlışlıkla veri silme, bozulma veya hata anında veriyi hatanın yaşandığı andan önceki bir zaman noktasına geri yükleyebiliriz.
 Bu finans, e-ticaret ve kritik sistemlerde veri kaybını neredeyse sıfıra indirir.


> Bu lab çalışmasında PostgreSQL üzerinde **Point-in-Time Recovery (PITR)** mekanizmasını uçtan uca uyguladım.

---

##  Amaç

Veritabanı bozulduğunda, yanlışlıkla silindiğinde istediğimiz o ana dönebilir miyiz sorusuna cevap olarak pitr sistemini kurdum. 
Bunun için temel iki şeye ihtiyacımız vardı: 
- ***base backup*** 
- ***wal arşivi***


Senaryo:
- Bir tablo oluşturuldu ve veri eklendi
- Base backup alındı
- Bilerek tablo silindi (felaket senaryosu)
- WAL replay kullanılarak veritabanı istenilen zamana geri alındı

---

## ️ Mimari

- PostgreSQL bir Docker container içinde çalışır
- Veriler Docker volume içinde tutulur
- WAL dosyaları host makineye arşivlenir
- Base backup host makinede saklanır

```
PostgreSQL (Container)
│
├── PGDATA (Docker Volume)
├── WAL → Host’a arşivlenir
└── Base Backup → Host’ta saklanır
```

---

## Kullanılan Teknolojiler

- PostgreSQL 14
- Docker & Docker Compose
- WAL Archiving
- pg_basebackup
- PITR (Point-in-Time Recovery)

---

## Proje Yapısı
```
pitr-lab/
├── docker-compose.yml
├── scripts/
│   ├── init.sql
│   ├── create-base-backup.sh
│   ├── simulate-disaster.sql
│   └── restore.sh
└── images/
```

---

## ADIM ADIM

### PostgreSQL'i Baslat

```bash
docker compose up -d 
```

Container kontrolü:

```bash
docker ps
```

### Test Tablosu Olustur

```bash
docker exec -it pg14-pitr psql -U beyza -d testdb
```

```sql
CREATE TABLE operations (
    id SERIAL PRIMARY KEY,
    description TEXT,
    created_at TIMESTAMP DEFAULT now()
);

INSERT INTO operations (description) VALUES
('GÜVENLİ NOKTA'),
('İLK VERİ');
```
### Base Backup Al

````bash
docker exec -it pg14-pitr bash

PGUSER=beyza PGPASSWORD=password \
pg_basebackup -h localhost -D /backups/base_1 -F plain -X fetch -P
```

Bu adımda:
. Veritabanının fiziksel kopyası alındı

. Gerekli WAL segmentleri de dahil edildi

### Felaket Senaryosu

```sql
DROP TABLE operations;  
SELECT pg_switch_wal(); 
```

. Tablo silindi

. WAL segmenti archive a gönderildi

### Restore Hazırlıgı

```bash
docker stop pg14-pitr
```

Volume erisimi:

```bash
docker run --rm -it \
  -v pg-pitr-lab_postgres-data:/var/lib/postgresql/data \
  -v "$(pwd)/backups:/backups" \
  -v "$(pwd)/wal-archive:/wal-archive" \
  postgres:14 bash
```

Veriyi sıfırla:

```bash
rm -rf /var/lib/postgresql/data/*
cp -a /backups/base_1/* /var/lib/postgresql/data/
touch /var/lib/postgresql/data/recovery.signal
```

### Recovery Ayarları

docker-compose.yaml icine 

```bash 
restore_command='cp /wal-archive/%f %p'
recovery_target_time='YYYY-MM-DD HH:MM:SS'
recovery_target_action=promote
```

### Recovery Baslat

```bash
docker compose up -d
```

PostgreSQL:
. Recovery modunda baslar

. WAL replay yapar

. Hedef zamana geldiginde durur

### Sonuc Konrolü

```bash
docker exec -it pg14-pitr psql -U beyza -d testdb

SELECT * FROM operations;
```

. Tablo geri geldi

. Veriler korundu

. DROP işlemi hiç olmamış gibi


Öğrendiklerim
. WAL, veritabanında zaman içinde geri gidebilmemizi sağlar

. Base backup tek başına yeterli değildir

. WAL + Base Backup birlikte çalışır

. recovery_target_time ile hassas kontrol sağlanır

. pg_switch_wal test senaryolarında kritiktir

. Docker volume veri kalıcılığı için gereklidir
