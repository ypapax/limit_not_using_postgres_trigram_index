#!/usr/bin/env bash
set -ex
set -o pipefail

run() {
  docker-compose build
  docker-compose up
}

rerun() {
  set +e
  docker kill limit_not_using_postgres_index_fill_1
  docker rm limit_not_using_postgres_index_fill_1
  set -e
  run
}

sql() {
  psql -h localhost -p 5439 -U postgres -d people -c "$@"
}

sqla() {
  sql "set enable_seqscan=on; EXPLAIN (ANALYZE, BUFFERS) $*"
#  sql "$@"
}

sqlano() {
  sql "set enable_seqscan=off; EXPLAIN (ANALYZE, BUFFERS) $*"
#  sql "$@"
}

c() {
  sql "SELECT count(*) FROM people;"
}

last() {
  sql "SELECT * FROM people ORDER BY id DESC limit 5"
}

likeb(){
  sqla "SELECT * FROM people WHERE name ILIKE 'some%'"
}

q="SELECT * FROM people WHERE name ILIKE '%some%' order by id asc limit 10 offset 1"

like(){
  sqla "$q"
}

likeno(){
  sqlano "$q"
}


version(){
	sql "SELECT version()"

}

pg_trgm_version(){
	sql "\dx"
}
"$@"
