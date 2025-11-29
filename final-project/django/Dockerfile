# Django Application Dockerfile
# Multi-stage build for optimized production image

# Stage 1: Builder
FROM python:3.11 as builder

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Stage 2: Production
FROM python:3.11

# Create non-root user for security
RUN groupadd -r django && useradd -r -g django django

WORKDIR /app

# Copy wheels from builder and install
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .
RUN pip install --no-cache /wheels/*

# Copy application code
COPY --chown=django:django . .

# Collect static files
RUN python manage.py collectstatic --noinput || true

# Switch to non-root user
USER django

# Expose application port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

# Run with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "2", "app.wsgi:application"]
