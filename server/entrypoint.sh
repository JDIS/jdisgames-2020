#!/bin/bash

# Wait until Postgres is ready
sleep 5	

echo "Migrating database before starting..."

SECRET_KEY_BASE=$(cat secret_key.txt) bin/diep_io eval "Diep.Io.Release.migrate"

echo "Starting JDISGames 2020 Server...."
SECRET_KEY_BASE=$(cat secret_key.txt) bin/diep_io start