pkill postgres
rm ../../DCSim/Bench/postgres/Release/data/* -rf
rm ../../DCSim/Bench/postgres/Release/data_cpy -rf
../../DCSim/Bench/postgres/Release/bin/initdb -D ../../DCSim/Bench/postgres/Release/data/
sed -i -e 's/max_connections = 100/max_connections = 200/g' ../../DCSim/Bench/postgres/Release/data/postgresql.conf
sed -i -e 's/#max_worker_processes = 8/max_worker_processes = 128/g' ../../DCSim/Bench/postgres/Release/data/postgresql.conf
sed -i -e 's/#max_parallel_workers = 8/max_parallel_workers = 128/g' ../../DCSim/Bench/postgres/Release/data/postgresql.conf
../../DCSim/Bench/postgres/Release/bin/pg_ctl -D ../../DCSim/Bench/postgres/Release/data/ start
LD_LIBRARY_PATH=../../DCSim/Bench/postgres/Release/lib ../../DCSim/Bench/postgres/Release/bin/psql -h localhost -d postgres -f ../setup.sql
./runDatabaseBuild.sh ./dcsim.properties
cp -r ../../DCSim/Bench/postgres/Release/data ../../DCSim/Bench/postgres/Release/data_cpy
./runBenchmark.sh ./dcsim.properties
