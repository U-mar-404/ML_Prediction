# Dockerfile

# 1) Start from the official Python 3.12 slim image (Debian-based)
FROM python:3.12-slim

# 2) Set the working directory inside the container
WORKDIR /app

# 3) Copy only requirements.txt first (this allows Docker to cache pip installs)
COPY requirements.txt .

# 4) Install OS-level dependencies needed for pip (and building wheels)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       python3-distutils \
       build-essential \
       gcc \
       libc-dev \
       curl \
    && rm -rf /var/lib/apt/lists/*

# 5) Create a virtual environment at /opt/venv
RUN python -m venv /opt/venv

# 6) Upgrade pip and install Python packages inside that venv
RUN /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install -r requirements.txt

# 7) Copy the rest of your application code into /app
COPY . .

# 8) Make sure the venv’s binaries are used first
ENV PATH="/opt/venv/bin:$PATH"

# 9) Expose port 8000 so the container can receive traffic on that port
EXPOSE 8000

# 10) By default, run Uvicorn serving main:app on port 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
