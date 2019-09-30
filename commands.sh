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
  sql "EXPLAIN (ANALYZE true, FORMAT yaml) $*"
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
  sqla "SELECT * FROM people WHERE name ILIKE '%juxtapositions%'"
}

like10(){
	sqla "SELECT * FROM people WHERE name ILIKE '%some%' limit 10"
}

fuz() {
  #  sqla "SELECT * FROM people WHERE name % '1100011'"
  #  sqla "SELECT * FROM people WHERE name % '120000085000008500000RN3SGD19HYZXYEK9TM0WQW1W1F62PMI6ZDP5GH5M5VAUZKUIWL'"
  # Planning Time: 0.947 ms
  # Execution Time: 243752.916 ms
  #    sqla "SELECT * FROM people WHERE name % '1200000'"
  # Planning Time: 1.091 ms
  # Execution Time: 928.161 ms
  #  sqla "SELECT * FROM people WHERE '1200000' % ANY(STRING_TO_ARRAY(name,' '))"
  #Planning Time: 0.505 ms
  # Execution Time: 23787.588 ms
  #  sqla "SELECT * FROM people WHERE name % 'amnesties Wilder ledge perception falconer'"
  #   Gather  (cost=1000.00..137105.65 rows=8501 width=55) (actual time=14847.954..36051.803 rows=2 loops=1)
  #   Workers Planned: 2
  #   Workers Launched: 2
  #   ->  Parallel Seq Scan on people  (cost=0.00..135255.55 rows=3542 width=55) (actual time=28980.157..36047.508 rows=1 loops=3)
  #         Filter: (name % 'amnesties Wilder ledge perception falconer'::text)
  #         Rows Removed by Filter: 2833333
  # Planning Time: 2.657 ms
  # Execution Time: 36051.986 ms
  #    sqla "SELECT * FROM people WHERE SIMILARITY(name, 'amnesties Wilder ledge perception falconer') > 0.4"
  #----------------------------------------------------------------------------------------------------------------------
  # Seq Scan on people  (cost=0.00..218491.70 rows=2833571 width=55) (actual time=105761.464..105761.509 rows=1 loops=1)
  #   Filter: (similarity(name, 'amnesties Wilder ledge perception falconer'::text) > '0.4'::double precision)
  #   Rows Removed by Filter: 8499999
  # Planning Time: 1.407 ms
  # Execution Time: 105762.077 ms
  #(5 rows)
  #  sqla "SELECT * FROM people WHERE SIMILARITY(name, 'amnesties Wilder ledge perception falconer') > 0.1"
  # Seq Scan on people  (cost=0.00..218491.70 rows=2833571 width=55) (actual time=0.792..108442.755 rows=138062 loops=1)
  #   Filter: (similarity(name, 'amnesties Wilder ledge perception falconer'::text) > '0.1'::double precision)
  #   Rows Removed by Filter: 8361938
  # Planning Time: 0.353 ms
  # Execution Time: 109291.338 ms
  #  sqla "SELECT * FROM people WHERE LEVENSHTEIN(name, 'amnesties Wilder ledge perception falconer') < 5"
  #   Seq Scan on people  (cost=0.00..218491.70 rows=2833571 width=55) (actual time=9036.638..35391.910 rows=1 loops=1)
  #   Filter: (levenshtein(name, 'amnesties Wilder ledge perception falconer'::text) < 5)
  #   Rows Removed by Filter: 8499999
  # Planning Time: 0.290 ms
  # Execution Time: 35392.373 ms
  #(5 rows)
  #
  #+(./commands.sh:24): sqla():  myMac $ sql 'SELECT * FROM people WHERE LEVENSHTEIN(name, '\''amnesties Wilder ledge perception falconer'\'') < 5'
  #+(./commands.sh:19): sql():  myMac $ psql -h localhost -p 5439 -U postgres -d people -c 'SELECT * FROM people WHERE LEVENSHTEIN(name, '\''amnesties Wilder ledge perception falconer'\'') < 5'
  #   id    |                    name
  #---------+---------------------------------------------
  # 8499997 | amnesties Wilder ledge perceptions falconer
  #(1 row)

  #  sqla "SELECT count(*) FROM people WHERE SOUNDEX(name) = SOUNDEX('amnesties Wilder ledge perception falconer')"
  #  sqla "SELECT * FROM people WHERE SOUNDEX(name) = SOUNDEX('amnesties Wilder ledge perception falconer')"
  #   count
  #-------
  #  5605
  # Gather  (cost=1000.00..149360.86 rows=42504 width=55) (actual time=0.492..766.034 rows=5605 loops=1)
  #   Workers Planned: 2
  #   Workers Launched: 2
  #   ->  Parallel Seq Scan on people  (cost=0.00..144110.46 rows=17710 width=55) (actual time=0.764..759.717 rows=1868 loops=3)
  #         Filter: (soundex(name) = 'A523'::text)
  #         Rows Removed by Filter: 2831465
  # Planning Time: 0.688 ms
  # Execution Time: 799.429 ms
  #  sqla "SELECT * FROM people WHERE METAPHONE(name, 10) = METAPHONE('amnesties Wilder ledge perception falconer', 10)"
  #-----------------------------------------------------------------------------------------------------------------------------
  # Gather  (cost=1000.00..149360.86 rows=42504 width=55) (actual time=1170.171..1171.998 rows=1 loops=1)
  #   Workers Planned: 2
  #   Workers Launched: 2
  #   ->  Parallel Seq Scan on people  (cost=0.00..144110.46 rows=17710 width=55) (actual time=879.601..1167.020 rows=0 loops=3)
  #         Filter: (metaphone(name, 10) = 'AMNSTSWLTR'::text)
  #         Rows Removed by Filter: 2833333
  # Planning Time: 0.745 ms
  # Execution Time: 1172.109 ms
  #(8 rows)
  #
  #+(./commands.sh:24): sqla():  myMac $ sql 'SELECT * FROM people WHERE METAPHONE(name, 10) = METAPHONE('\''amnesties Wilder ledge perception falconer'\'', 10)'
  #+(./commands.sh:19): sql():  myMac $ psql -h localhost -p 5439 -U postgres -d people -c 'SELECT * FROM people WHERE METAPHONE(name, 10) = METAPHONE('\''amnesties Wilder ledge perception falconer'\'', 10)'
  #   id    |                    name
  #---------+---------------------------------------------
  # 8499997 | amnesties Wilder ledge perceptions falconer
  #(1 row)
  #  sqla "SELECT * FROM people WHERE METAPHONE(name, 8) = METAPHONE('amnesties Wilder ledge perception falconer', 8)"
  #   Gather  (cost=1000.00..149360.86 rows=42504 width=55) (actual time=83.806..1051.563 rows=3 loops=1)
  #   Workers Planned: 2
  #   Workers Launched: 2
  #   ->  Parallel Seq Scan on people  (cost=0.00..144110.46 rows=17710 width=55) (actual time=425.120..1044.081 rows=1 loops=3)
  #         Filter: (metaphone(name, 8) = 'AMNSTSWL'::text)
  #         Rows Removed by Filter: 2833332
  # Planning Time: 1.460 ms
  # Execution Time: 1051.703 ms
  #(8 rows)
  #
  #+(./commands.sh:24): sqla():  myMac $ sql 'SELECT * FROM people WHERE METAPHONE(name, 8) = METAPHONE('\''amnesties Wilder ledge perception falconer'\'', 8)'
  #+(./commands.sh:19): sql():  myMac $ psql -h localhost -p 5439 -U postgres -d people -c 'SELECT * FROM people WHERE METAPHONE(name, 8) = METAPHONE('\''amnesties Wilder ledge perception falconer'\'', 8)'
  #   id    |                    name
  #---------+---------------------------------------------
  # 8499997 | amnesties Wilder ledge perceptions falconer
  # 6914400 | amnesty's wail's douched bombshell's blue's
  # 5395167 | amnesty's Wilhelm martyrdom's Olaf's Hus's
  #(3 rows)
  #  sqla "SELECT * FROM people WHERE DMETAPHONE(name) = DMETAPHONE('amnesties Wilder ledge perception falconer')"
  #                                                          QUERY PLAN
  #-------------------------------------------------------------------------------------------------------------------------------
  # Gather  (cost=1000.00..149360.86 rows=42504 width=55) (actual time=4.187..1909.798 rows=4928 loops=1)
  #   Workers Planned: 2
  #   Workers Launched: 2
  #   ->  Parallel Seq Scan on people  (cost=0.00..144110.46 rows=17710 width=55) (actual time=3.506..1902.885 rows=1643 loops=3)
  #         Filter: (dmetaphone(name) = 'AMNS'::text)
  #         Rows Removed by Filter: 2831691
  # Planning Time: 1.313 ms
  # Execution Time: 1938.173 ms
  #(8 rows)
  #
  #+(./commands.sh:24): sqla():  myMac $ sql 'SELECT * FROM people WHERE DMETAPHONE(name) = DMETAPHONE('\''amnesties Wilder ledge perception falconer'\'')'
  #+(./commands.sh:19): sql():  myMac $ psql -h localhost -p 5439 -U postgres -d people -c 'SELECT * FROM people WHERE DMETAPHONE(name) = DMETAPHONE('\''amnesties Wilder ledge perception falconer'\'')'
  #   id    |                                 name
  #---------+-----------------------------------------------------------------------
  # 6334323 | amniocentesis credo freight seething oarsman
  # 6331645 | amnesty's moisture downswing chattel's angling's
  # 6376625 | immunizing correcter voicemails mango Karla's
  # 6337984 | omen's fillies dungaree's tightwad's tent's
  # 6338806 | amnesia acquiescent characterizations construes feeler
  #  sqla "SELECT * FROM people WHERE metaphone=METAPHONE('bikes recuperating braved stolidest riffs', 10)"
#  sqla "SELECT * FROM people WHERE metaphone % METAPHONE('bikes recuperating braved stolidest riffs', 10)"
  #   Bitmap Heap Scan on people  (cost=2014.36..33407.35 rows=9595 width=87) (actual time=196.519..1434.978 rows=74 loops=1)
  #   Recheck Cond: (metaphone % 'BKSRKPRTNK'::text)
  #   Rows Removed by Index Recheck: 5653
  #   Heap Blocks: exact=5572
  #   ->  Bitmap Index Scan on metaphone_trigram_idx  (cost=0.00..2011.96 rows=9595 width=0) (actual time=195.275..195.280 rows=5727 loops=1)
  #         Index Cond: (metaphone % 'BKSRKPRTNK'::text)
  # Planning Time: 19.024 ms
  # Execution Time: 1436.955 ms
#  sqla "SELECT * FROM people WHERE metaphone %> METAPHONE('bikes recuperating braved stolidest riffs', 10)"
#                                                               QUERY PLAN
#--------------------------------------------------------------------------------------------------------------------------------------
# Bitmap Heap Scan on people  (cost=2014.36..33407.35 rows=9595 width=87) (actual time=80.547..80.659 rows=5 loops=1)
#   Recheck Cond: (metaphone %> 'BKSRKPRTNK'::text)
#   Rows Removed by Index Recheck: 4
#   Heap Blocks: exact=9
#   ->  Bitmap Index Scan on metaphone_trigram_idx  (cost=0.00..2011.96 rows=9595 width=0) (actual time=80.513..80.518 rows=9 loops=1)
#         Index Cond: (metaphone %> 'BKSRKPRTNK'::text)
# Planning Time: 1.269 ms
# Execution Time: 80.876 ms
#(8 rows)
#
#+(./commands.sh:24): sqla():  myMac $ sql 'SELECT * FROM people WHERE metaphone %> METAPHONE('\''bikes recuperating braved stolidest riffs'\'', 10)'
#+(./commands.sh:19): sql():  myMac $ psql -h localhost -p 5439 -U postgres -d people -c 'SELECT * FROM people WHERE metaphone %> METAPHONE('\''bikes recuperating braved stolidest riffs'\'', 10)'
#   id    |                         name                         | metaphone
#---------+------------------------------------------------------+------------
#  436327 | crease recuperating clearest predisposing Freemasons | KRSRKPRTNK
# 2171175 | Zuni's recuperating vaulter daggers prisoner         | SNSRKPRTNK
# 3599114 | house's recuperating dangerous Kalashnikov lashing   | HSSRKPRTNK
# 4604075 | pup's recuperating portables flip's reschedules      | PPSRKPRTNK
# 7804322 | mess's recuperating drunker espies Enif's            | MSSRKPRTNK
#(5 rows)
#  sqla "SELECT * FROM people WHERE name %> 'destination vituperating diphthong miracles undivided'"
#Bitmap Heap Scan on people  (cost=1690.36..33083.35 rows=9595 width=87) (actual time=3257.574..3257.586 rows=1 loops=1)
#   Recheck Cond: (name %> 'destination vituperating diphthong miracles undivided'::text)
#   Heap Blocks: exact=2
#   ->  Bitmap Index Scan on name_trigram_idx  (cost=0.00..1687.96 rows=9595 width=0) (actual time=3257.524..3257.529 rows=2 loops=1)
#         Index Cond: (name %> 'destination vituperating diphthong miracles undivided'::text)
# Planning Time: 1.326 ms
# Execution Time: 3257.799 ms
#(7 rows)
#
#+(./commands.sh:24): sqla():  myMac $ sql 'SELECT * FROM people WHERE name %> '\''destination vituperating diphthong miracles undivided'\'''
#+(./commands.sh:19): sql():  myMac $ psql -h localhost -p 5439 -U postgres -d people -c 'SELECT * FROM people WHERE name %> '\''destination vituperating diphthong miracles undivided'\'''
#  id  |                         name                          | metaphone
#------+-------------------------------------------------------+------------
# 5082 | destination vituperating diphthong miracles undivided | TSTNXNFTPR
#(1 row)
  sqla "SELECT * FROM people WHERE name %>> 'destination vituperating diphthong miracles undivided'"
#                                                             QUERY PLAN
#-------------------------------------------------------------------------------------------------------------------------------------
# Bitmap Heap Scan on people  (cost=1690.36..33083.35 rows=9595 width=87) (actual time=3251.577..3251.588 rows=1 loops=1)
#   Recheck Cond: (name %>> 'destination vituperating diphthong miracles undivided'::text)
#   Heap Blocks: exact=1
#   ->  Bitmap Index Scan on name_trigram_idx  (cost=0.00..1687.96 rows=9595 width=0) (actual time=3251.527..3251.533 rows=1 loops=1)
#         Index Cond: (name %>> 'destination vituperating diphthong miracles undivided'::text)
# Planning Time: 1.777 ms
# Execution Time: 3251.887 ms
#(7 rows)
#
#+(./commands.sh:24): sqla():  myMac $ sql 'SELECT * FROM people WHERE name %>> '\''destination vituperating diphthong miracles undivided'\'''
#+(./commands.sh:19): sql():  myMac $ psql -h localhost -p 5439 -U postgres -d people -c 'SELECT * FROM people WHERE name %>> '\''destination vituperating diphthong miracles undivided'\'''
#  id  |                         name                          | metaphone
#------+-------------------------------------------------------+------------
# 5082 | destination vituperating diphthong miracles undivided | TSTNXNFTPR
#(1 row)
}

update() {
  sql "UPDATE people SET metaphone=METAPHONE(name, 10)"
}

meta() {
  sql "SELECT METAPHONE('biker recuperating braved stolidest riffs', 10)"
  sql "SELECT METAPHONE('bikes recuperating braved stolidest riffs', 10)"
}

"$@"
