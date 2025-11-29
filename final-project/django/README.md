# Django Application

## Local Development

### Prerequisites

- Docker and Docker Compose
- Python 3.11+ (for local development without Docker)

### Running with Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop all services
docker-compose down

# Start with pgAdmin (database management)
docker-compose --profile tools up -d
```

### Running Locally

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export DATABASE_NAME=appdb
export DATABASE_USER=dbadmin
export DATABASE_PASSWORD=yourpassword
export DEBUG=true
export SECRET_KEY=your-secret-key

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver
```

## API Endpoints

| Endpoint           | Method           | Description           |
| ------------------ | ---------------- | --------------------- |
| `/health/`         | GET              | Health check          |
| `/ht/`             | GET              | Detailed health check |
| `/metrics`         | GET              | Prometheus metrics    |
| `/api/`            | GET              | API root              |
| `/api/items/`      | GET, POST        | List/Create items     |
| `/api/items/<id>/` | GET, PUT, DELETE | Item details          |
| `/admin/`          | GET              | Django admin          |

## Building Docker Image

```bash
# Build image
docker build -t django-app .

# Run container
docker run -p 8000:8000 \
  -e DATABASE_HOST=host.docker.internal \
  -e DATABASE_PORT=5432 \
  -e DATABASE_NAME=appdb \
  -e DATABASE_USER=dbadmin \
  -e DATABASE_PASSWORD=password \
  django-app
```

## Testing

```bash
# Run tests
python -m pytest

# Run with coverage
python -m pytest --cov=. --cov-report=html

# Run specific tests
python -m pytest core/tests/
```
