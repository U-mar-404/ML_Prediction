# ────────────────────────────────────────────────────────────────────────────────
# Use an official Python 3.12 "slim" image (Debian‐based)
# ────────────────────────────────────────────────────────────────────────────────
FROM python:3.12-slim

# ────────────────────────────────────────────────────────────────────────────────
# Set the working directory for subsequent commands
# ────────────────────────────────────────────────────────────────────────────────
WORKDIR /app

# ────────────────────────────────────────────────────────────────────────────────
# Copy only requirements.txt first so Docker can cache the pip install layer
# ────────────────────────────────────────────────────────────────────────────────
COPY requirements.txt .

# ────────────────────────────────────────────────────────────────────────────────
# Install system‐level build dependencies needed for compiling NumPy, pandas, etc.
#   • python3‐distutils: needed by pip for some wheels
#   • python3‐dev: headers & static libraries for Python C extensions
#   • build‐essential: gcc, g++, make, etc.
#   • gfortran: Fortran compiler (used by NumPy/Sci-Kit-Learn)
#   • libatlas‐base‐dev: BLAS/LAPACK for linear algebra
#   • ca-certificates, curl (optional)
# After installing, clean up apt lists to reduce image size.
# ────────────────────────────────────────────────────────────────────────────────
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       python3-distutils \
       python3-dev \
       build-essential \
       gfortran \
       libc-dev \
       libatlas-base-dev \
       ca-certificates \
       curl \
    && rm -rf /var/lib/apt/lists/*

# ────────────────────────────────────────────────────────────────────────────────
# Create a Python virtual environment in /opt/venv
# ────────────────────────────────────────────────────────────────────────────────
RUN python -m venv /opt/venv

# ────────────────────────────────────────────────────────────────────────────────
# Upgrade pip in the venv, then install Python dependencies from requirements.txt
# ────────────────────────────────────────────────────────────────────────────────
RUN /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install -r requirements.txt

# ────────────────────────────────────────────────────────────────────────────────
# Copy the rest of the application code into /app
# ────────────────────────────────────────────────────────────────────────────────
COPY . .

# ────────────────────────────────────────────────────────────────────────────────
# Ensure the venv’s bin folder is first in PATH, so "uvicorn", etc. resolve correctly
# ────────────────────────────────────────────────────────────────────────────────
ENV PATH="/opt/venv/bin:$PATH"

# ────────────────────────────────────────────────────────────────────────────────
# Expose port 8000 to allow external access
# ────────────────────────────────────────────────────────────────────────────────
EXPOSE 8000

# ────────────────────────────────────────────────────────────────────────────────
# Default command: launch Uvicorn to serve main:app on 0.0.0.0:8000
# ────────────────────────────────────────────────────────────────────────────────
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
