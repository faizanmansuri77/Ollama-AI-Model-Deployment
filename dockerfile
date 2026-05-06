FROM python:3.10-slim

WORKDIR /app

# Copy dependency file first (better caching)
COPY requirements.txt .

# Install dependencies (include streamlit explicitly)
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir streamlit

# Copy app code
COPY . .

# Expose Streamlit port
EXPOSE 8501

# Run Streamlit
CMD ["python", "-m", "streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
