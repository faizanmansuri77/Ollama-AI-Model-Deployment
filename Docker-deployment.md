# 🐳 Dockerizing Your LLaMA 3.2 AI Agent — Complete Guide

Containerize your Streamlit + Ollama + LLaMA 3.2 chatbot using Docker and Docker Compose.

---

## 🚨 Very Important Understanding

You **CANNOT** run Ollama and Streamlit inside the same container properly in production.

**Best practice — two separate containers:**

```
Container 1 → Ollama
Container 2 → Streamlit App
```

**Why?**

- ✅ Separation of concerns
- ✅ Easier scaling
- ✅ Cleaner networking
- ✅ Production standard approach

**Tools used:** Docker + Docker Compose

---

## 🏗️ Final Architecture

```
Browser
   ↓
Port 8501
   ↓
Streamlit Container
   ↓ (internal docker network)
Ollama Container (port 11434)
   ↓
llama3.2 model
```

---

## 🔹 STEP 1 — Install Docker on EC2

Update packages and install Docker:

```bash
sudo apt update
sudo apt install docker.io -y
```

Start and enable Docker:

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

Add the `ubuntu` user to the docker group:

```bash
sudo usermod -aG docker ubuntu
```

> ⚠️ You must logout and reconnect for this to take effect.

Exit the session:

```bash
exit
```

SSH back into your EC2 instance, then verify Docker is working:

```bash
docker --version
```

---

## 🔹 STEP 2 — Install Docker Compose

```bash
sudo apt install docker-compose -y
```

Verify installation:

```bash
docker-compose --version
```

---

## 🔹 STEP 3 — Modify app.py (IMPORTANT)

By default, the Ollama Python library connects to `localhost:11434`. Inside Docker, containers cannot reach each other via `localhost` — they must use the **container name** as the hostname.

### ✏️ Edit app.py

**Replace:**

```python
import ollama
```

**With:**

```python
import ollama
import os

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
client = ollama.Client(host=OLLAMA_HOST)
```

**Then replace:**

```python
stream = ollama.chat(
```

**With:**

```python
stream = client.chat(
```

Save the file.

---

## 🔹 STEP 4 — Create Dockerfile

Inside your project folder, create the Dockerfile:

```bash
nano Dockerfile
```

Paste this exact content:

```dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8501

CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

Save and exit.

---

## 🔹 STEP 5 — Create docker-compose.yml

In the same project folder, create the Compose file:

```bash
nano docker-compose.yml
```

Paste this exact content:

```yaml
version: "3.8"

services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    restart: unless-stopped

  streamlit:
    build: .
    container_name: streamlit_app
    ports:
      - "8501:8501"
    environment:
      - OLLAMA_HOST=http://ollama:11434
    depends_on:
      - ollama
    restart: unless-stopped

volumes:
  ollama_data:
```

Save and exit.

---

## 🔹 STEP 6 — Pull LLaMA Model Inside Container

> ⚠️ This is a very important step. The model must be pulled inside the Ollama container.

First, start only the Ollama container:

```bash
docker-compose up -d ollama
```

Then pull the model inside the running container:

```bash
docker exec -it ollama ollama pull llama3.2:latest
```

Wait until the download is fully complete before moving to the next step.

---

## 🔹 STEP 7 — Build & Start Everything

Now build and start all containers:

```bash
docker-compose up -d --build
```

Check that both containers are running:

```bash
docker ps
```

You should see two containers running:

- `ollama`
- `streamlit_app`

---

## 🔹 STEP 8 — Open in Browser

Navigate to:

```
http://<EC2_PUBLIC_IP>:8501
```

🎉 **Your AI Agent is now running fully containerized!**

---

## 🔹 STEP 9 — Test Container Networking

Check the Streamlit container logs to confirm there are no connection errors:

```bash
docker logs streamlit_app
```

If everything is working correctly, you will see no connection errors in the output.

---

## 🔹 STEP 10 — Stop Containers

To stop all running containers:

```bash
docker-compose down
```

---

## 🔥 Production Improvements (Optional But Recommended)

### Auto Restart on Reboot

Already handled in `docker-compose.yml` with:

```yaml
restart: unless-stopped
```

This ensures your containers automatically restart if the EC2 instance reboots.

### Remove Old Images (Free Up Space)

```bash
docker system prune -a
```

---

## 💡 Important Notes

### Model Persistence

Because the `docker-compose.yml` includes a named volume:

```yaml
volumes:
  - ollama_data:/root/.ollama
```

Your downloaded LLaMA model is **persisted** even if the container is stopped or restarted. You will not need to re-download it.

---

## 📁 Final Project Structure

```
your-project/
├── app.py
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── lily.jpg
```
