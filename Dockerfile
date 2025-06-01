# Dockerfile

# ────────────────────────────────────────────────────────────────────────────────
# 1) Start from the official Python 3.12 slim image (Debian‐based)
# ────────────────────────────────────────────────────────────────────────────────
FROM python:3.12-slim

# ────────────────────────────────────────────────────────────────────────────────
# 2) Set the working directory inside the container
# ────────────────────────────────────────────────────────────────────────────────
WORKDIR /app

# ────────────────────────────────────────────────────────────────────────────────
# 3) Copy only requirements.txt first (so Docker can cache pip install layer)
# ────────────────────────────────────────────────────────────────────────────────
COPY requirements.txt .

# ────────────────────────────────────────────────────────────────────────────────
# 4) Install OS‐level build dependencies BEFORE pip:
#    - python3‐distutils: required by pip for some wheels
#    - build‐essential / gcc / gfortran / libc‐dev: required to compile 
#      NumPy and SciPy if a prebuilt wheel isn’t available
#    - libatlas‐base‐dev: BLAS/LAPACK libraries for NumPy/SciPy
#    - curl: optional (remove if you don’t need it)
# ────────────────────────────────────────────────────────────────────────────────
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         python3-distutils \
         build-essential \
         gcc \
         gfortran \
         libc-dev \
         libatlas-base-dev \
         curl \
    && rm -rf /var/lib/apt/lists/*

# ────────────────────────────────────────────────────────────────────────────────
# 5) Create a Python virtual environment at /opt/venv
# ────────────────────────────────────────────────────────────────────────────────
RUN python -m venv /opt/venv

# ────────────────────────────────────────────────────────────────────────────────
# 6) Upgrade pip in the venv and install Python dependencies from requirements.txt
# ────────────────────────────────────────────────────────────────────────────────
RUN /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install -r requirements.txt

# ────────────────────────────────────────────────────────────────────────────────
# 7) Copy the rest of the application code into /app
# ────────────────────────────────────────────────────────────────────────────────
COPY . .

# ────────────────────────────────────────────────────────────────────────────────
# 8) Add the venv’s bin directory to PATH so that uvicorn, etc. run from venv
# ────────────────────────────────────────────────────────────────────────────────
ENV PATH="/opt/venv/bin:$PATH"

# ────────────────────────────────────────────────────────────────────────────────
# 9) Expose port 8000 so the container will listen there
# ────────────────────────────────────────────────────────────────────────────────
EXPOSE 8000

# ────────────────────────────────────────────────────────────────────────────────
# 10) Default command: run Uvicorn serving main:app
# ────────────────────────────────────────────────────────────────────────────────
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
