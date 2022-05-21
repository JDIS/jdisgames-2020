#!/bin/bash

# Wait until Postgres is ready
sleep 5

echo "Migrating database before starting..."

SECRET_KEY_BASE=$(cat secret_key.txt) bin/diep_io eval "DiepIORelease.migrate"

echo "Seeding database before starting..."

echo "Starting JDISGames 2020 Server...."
SECRET_KEY_BASE=$(cat secret_key.txt) bin/diep_io start
