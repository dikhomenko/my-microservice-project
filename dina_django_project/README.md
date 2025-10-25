# Dina Django Project - Django + PostgreSQL + Nginx

## Prerequisites

- Docker
- Docker Compose

## Quick Start

### 1. Build and Start All Services

```bash
cd dina_django_project
docker-compose up --build
```

### 2. Access the Application

Open your browser and navigate to:

- **Main Application**: http://localhost:8080
- **Django Admin**: http://localhost:8080/admin

## Docker Commands

### Start Services

```bash
docker-compose up
```

### Stop Services

```bash
docker-compose down
```

## Database Configuration

The PostgreSQL database is configured with the following credentials (defined in `docker-compose.yml`):

- **Database Name**: dinadb
- **Username**: dinauser
- **Password**: dinapassword
- **Host**: db
- **Port**: 5432

These are automatically used by Django through environment variables in `app/dina_app/settings.py`.

## How It Works

**Request Flow**:

- Client → Nginx (port 8080 on host, port 80 in container) → Django (port 8000) → PostgreSQL (port 5432)
