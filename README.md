# Logistics API — Geliştirici Rehberi (Docker + Flyway + Spring Boot)

Bu repo, **Docker’lı PostgreSQL**, **Flyway migration’ları** ve **Spring Boot** ile lokal geliştirme için hazır bir iskelet sunar. Amaç: ekibe yeni katılan biri **tek seferde** ortamını kurup projeyi çalıştırabilsin.

---

## İçindekiler

* [Gereksinimler](#gereksinimler)
* [Hızlı Başlangıç](#hızlı-başlangıç)
* [Proje Yapısı](#proje-yapısı)
* [Docker Compose Servisleri](#docker-compose-servisleri)
* [Veritabanı Şeması ve Roller](#veritabanı-şeması-ve-roller)
* [Uygulamayı Çalıştırma](#uygulamayı-çalıştırma)
* [Makefile Hedefleri](#makefile-hedefleri)
* [Migration Ekleme Rehberi](#migration-ekleme-rehberi)
* [DBeaver ile Bağlantı](#dbeaver-ile-bağlantı)
* [Konfigürasyon Notları](#konfigürasyon-notları)
* [Kod Stili ve Git Ayarları](#kod-stili-ve-git-ayarları)
* [Sorun Giderme](#sorun-giderme)
* [Yol Haritası](#yol-haritası)

---

## Gereksinimler

* **Docker Desktop** (Docker Compose ile)
* **JDK 21** (`java -version` ile doğrula)
* **Git**
* (İsteğe bağlı) **IntelliJ IDEA** ve **DBeaver**

> Mac/Linux/WSL hepsinde çalışır. Windows’ta da Docker Desktop + Git Bash ile aynı komutlar geçerlidir.

---

## Hızlı Başlangıç

Aşağıdaki komutlar yeni katılan birinin sıfırdan kurulum yapmasını sağlar.

```bash
# 1) Kodu al
git clone git@github.com:eraytutal/logistics-api.git
cd logistics-api

# 2) Ortam değişkenleri (kişisel dosya)
cp ops/.env.example ops/.env

# 3) Postgres'i Docker'da başlat (port 55432)
make -C ops up

# 4) Migration'ları çalıştır (Flyway container)
make -C ops migrate

# 5) Uygulamayı Docker'daki Postgres'e karşı çalıştır
./ops/run-local.sh

# 6) Sağlık kontrolü (ayrı terminalde)
curl -sS http://localhost:8080/actuator/health
# {"status":"UP"} beklenir
```

> **Dikkat:** `ops/.env` kişiseldir, commit edilmez.

---

## Proje Yapısı

```
ops/
  docker-compose.yml   # Postgres ve Flyway servisleri
  .env.example         # Ortak env şablonu → kopyala: ops/.env
  .env                 # Kişisel dosya (git ignore)
  Makefile             # up / down / clean / logs / psql / migrate
  run-local.sh         # Spring'i 55432 portundaki DB'ye yönlendirip çalıştırır
src/
  main/resources/
    application.properties
    db/migration/      # Flyway SQL dosyaları (V1__..., V2__...)
.editorconfig          # IDE’lerde tutarlı kod stili
.gitattributes         # Satır sonu & SQL diff ayarları
pom.xml                # Maven yapılandırması
README.md              # Bu dosya
```

---

## Docker Compose Servisleri

Compose dosyamız `ops/docker-compose.yml` içinde.

* **db (postgres:17)**

  * Host portu: **55432** → Container portu **5432**
  * Varsayılan DB: `logistics_dev`
  * Volume: `logistics_pgdata` (veri kalıcı)
  * Healthcheck: `pg_isready`

* **flyway (flyway/flyway:10)**

  * `src/main/resources/db/migration` klasörünü container içinde `/flyway/sql` olarak mount eder.
  * Komut: `migrate`
  * `make -C ops migrate` ile tetiklenir.

> Compose “project name” `logistics` olarak ayarlı; oluşturulan network `logistics_default`, volume `logistics_pgdata` adlarıyla görünür.

---

## Veritabanı Şeması ve Roller

* **Şema:** `logistics` (sahip: `logistics_owner`)
* **Roller / Kullanıcılar:**

  * `logistics_owner / owner` → DDL & Flyway (migration uygular)
  * `logistics_app / app` → Uygulama (DML: SELECT/INSERT/UPDATE/DELETE)

> İlk kurulumda bu roller ve yetkiler oluşturulmuştur; yeni ekip üyesinin ayrıca işlem yapmasına gerek yoktur.

---

## Uygulamayı Çalıştırma

### Önerilen: script ile

```bash
./ops/run-local.sh
```

Bu script, Spring Boot’u **Docker’daki Postgres (localhost:55432)**’e yönlendiren ortam değişkenlerini geçici olarak set eder ve `./mvnw spring-boot:run` başlatır.

### IntelliJ’den çalıştırma

**Run/Debug Configuration > Environment variables** kısmına şunları ekle:

```
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:55432/logistics_dev
SPRING_DATASOURCE_USERNAME=logistics_app
SPRING_DATASOURCE_PASSWORD=app
SPRING_FLYWAY_URL=jdbc:postgresql://localhost:55432/logistics_dev
SPRING_FLYWAY_USER=logistics_owner
SPRING_FLYWAY_PASSWORD=owner
```

### Sağlık kontrolü

```
curl -sS http://localhost:8080/actuator/health
# {"status":"UP"}
```

---

## Makefile Hedefleri

`ops` klasörü içinde bulunur. Proje kökünden çalıştırırken `-C ops` kullanın.

```bash
make -C ops up       # Postgres'i başlatır (port 55432)
make -C ops migrate  # Flyway ile SQL migration'larını uygular
make -C ops psql     # Container içinden psql açar
make -C ops logs     # Postgres loglarını izler
make -C ops down     # Container'ları durdurur
make -C ops clean    # Container + volume'ları siler (TÜM VERİ GİDER)
```

`make -C ops psql` komutundan sonra örnek sorgular:

```sql
\conninfo;
\dn;         -- şema listesi
\du;         -- rol listesi
\dt logistics.*; -- logistics şemasındaki tablolar
```

---

## Migration Ekleme Rehberi

* Dosya yolu: `src/main/resources/db/migration`
* Adlandırma: `V7__açıklama.sql`, `V8__...sql` (V numarası **artımsal** tam sayı)
* Örnek:

  ```sql
  -- V7__add_order_indexes.sql
  CREATE INDEX IF NOT EXISTS idx_orders_created_at
    ON logistics.orders (created_at DESC);
  ```
* Çalıştırma:

  ```bash
  make -C ops migrate
  ```
* İpuçları:

  * DDL (CREATE/ALTER) varsa **owner** rolüne ihtiyaç olur; Flyway zaten `logistics_owner` ile çalışır.
  * DML/data-seed için de normal migration yazılabilir, ancak veri büyüklüğüne dikkat edin.

> Repeatable migration (R\_\_\*.sql) şimdilik kullanmıyoruz; ihtiyaç olursa kuralları ekleriz.

---

## DBeaver ile Bağlantı

* Host: `localhost`
* Port: `55432`
* Database: `logistics_dev`
* Kullanıcılar:

  * Yönetici: `postgres / postgres` (container default)
  * Uygulama: `logistics_app / app`

Bağlandıktan sonra isterseniz **Connection Initialization** kısmına:

```sql
SET search_path TO logistics, public;
SET application_name = 'dbeaver';
```

ekleyebilirsiniz.

---

## Konfigürasyon Notları

* `application.properties` içinde DB URL’si 5432 olabilir; **run-local.sh** bunu **55432** ile **override** eder.
* Uygulama tarafında `spring.jpa.open-in-view=false` ayarlıdır (en iyi pratikler için önerilir).
* Zaman damgası/saat dilimi için `hibernate.jdbc.time_zone=UTC` kullanıyoruz.

**Örnek** `application.properties` (özet):

```properties
spring.application.name=logistics-api
server.port=8080

# App datasource (DML)
spring.datasource.url=jdbc:postgresql://localhost:5432/logistics_dev
spring.datasource.username=logistics_app
spring.datasource.password=app
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.properties.hibernate.default_schema=logistics
spring.jpa.properties.hibernate.jdbc.time_zone=UTC

# Flyway (DDL)
spring.flyway.enabled=true
spring.flyway.url=jdbc:postgresql://localhost:5432/logistics_dev
spring.flyway.user=logistics_owner
spring.flyway.password=owner
spring.flyway.schemas=logistics
spring.flyway.default-schema=logistics
```

> Lokal çalışmada `./ops/run-local.sh` bu bağlantıları 55432’ye çevirir.

---

## Kod Stili ve Git Ayarları

* **.editorconfig**: Tüm IDE’lerde aynı satır sonu, boşluk/indent ve final newline kurallarını uygular.
* **.gitattributes**: `*.sql` için `diff=sql`, satır sonu `eol=lf` olarak ayarlı.
* **ops/.env**: **Commit ETME!** (repo’da `.gitignore` ile korumalı)

Branch/Commit önerileri:

* Ana dal: `main`
* Örnek isimler: `feat/orders-api`, `fix/shipment-null`, `chore/ops-upgrade`
* Commit mesajları kısa ve anlamlı: `feat: add order status enum`

---

## Sorun Giderme

**1) Uygulama ayakta ama ****`/actuator/health`**** boş**
Yeni terminalde çalıştır:

```bash
curl -sS http://localhost:8080/actuator/health
```

Eğer boşsa, uygulama gerçekten çalışıyor mu? `./ops/run-local.sh` ile başlat.

**2) Postgres ‘healthy’ değil**

```bash
docker ps
make -C ops logs
```

Port çakışması olabilir. Kontrol:

```bash
lsof -nP -iTCP:55432 -sTCP:LISTEN
```

Çakışma varsa `ops/docker-compose.yml` içinde host portunu değiştir (ör. 55433) ve yeniden `make -C ops up`.

\*\*3) \*\***`permission denied: ./ops/run-local.sh`**

```bash
chmod +x ops/run-local.sh
```

**4) Flyway ‘up to date’**
Bu normal; yeni migration yok demektir. Yeni SQL dosyası ekledikten sonra `make -C ops migrate`.

**5) psql içine girdim, çıkamıyorum**
`\q` yazıp Enter’a bas.

---

## Yol Haritası

