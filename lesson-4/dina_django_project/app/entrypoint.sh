#!/bin/bash

echo "Waiting for PostgreSQL to be ready..."
timeout 30 bash -c 'until nc -z db 5432; do sleep 1; done'

if [ $? -eq 0 ]; then
    echo "PostgreSQL is ready!"
else
    echo "Failed to connect to PostgreSQL after 30 seconds"
    exit 1
fi

echo "Running database migrations..."
python manage.py migrate --noinput

echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Starting Gunicorn server..."
exec gunicorn dina_app.wsgi:application --bind 0.0.0.0:8000 --workers 3
