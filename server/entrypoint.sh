#!/bin/bash

# Wait until Postgres is ready
sleep 5

echo "Migrating database before starting..."

DIEP_SECRET_KEY_BASE=$(cat secret_key.txt) bin/diep_io eval "DiepIORelease.migrate"

echo "Starting JDISGames 2020 Server...."
DIEP_SECRET_KEY_BASE=$(cat secret_key.txt) bin/diep_io start
