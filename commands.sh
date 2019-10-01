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
  sql "EXPLAIN (ANALYZE, BUFFERS) $*"
  sql "$@"
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

like(){
  sqla "SELECT * FROM people WHERE name ILIKE '%wisest juxtapositions%'"
}

likel(){
  sqla "SELECT * FROM people WHERE name ILIKE '%wisest juxtapositions%' limit 10"
}

likeol(){
  sqla "SELECT * FROM people WHERE name ILIKE '%some%' order by id limit 10 offset 2"
}

like2(){
	sql "set enable_seqscan=off; EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM people WHERE name ILIKE '%wisest juxtapositions%'"
}
like10(){
	sqla "SELECT * FROM people WHERE name ILIKE '%some%' limit 10"
}

update() {
  sql "UPDATE people SET metaphone=METAPHONE(name, 10)"
}

meta() {
  sql "SELECT METAPHONE('biker recuperating braved stolidest riffs', 10)"
  sql "SELECT METAPHONE('bikes recuperating braved stolidest riffs', 10)"
}

version(){
	sql "SELECT version()"

}

pg_trgm_version(){
	sql "\dx"
}
"$@"
