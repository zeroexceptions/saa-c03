# Daymark

A small Rails todo app with an open, no-account task list.

## PostgreSQL setup

PostgreSQL is the default adapter. Copy `.env.example` to `.env` and set `PGHOST`, `PGPORT`, `PGUSER`, and `PGPASSWORD` for your server. The app loads `.env` automatically in development and test. Database names default to `daymark_development`, `daymark_test`, and `daymark_production`; set `PGDATABASE` and `PGTESTDATABASE` to override them. You can also provide a `DATABASE_URL`.

Install dependencies, create the databases, and start Rails:

```sh
cp .env.example .env
# Edit .env with your PostgreSQL credentials.
bundle install
bin/rails db:prepare
bin/rails server
```
