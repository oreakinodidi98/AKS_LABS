# For more information, please refer to https://aka.ms/vscode-docker-python
FROM python:3.11-slim

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

# Avoid cached wheels/layers from growing image size unnecessarily.
ENV PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install pip requirements
COPY requirements.txt /app/
RUN python -m pip install --upgrade pip && python -m pip install -r requirements.txt

COPY . /app

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-python-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# Run the sample script entrypoint.
CMD ["python", "main.py"]