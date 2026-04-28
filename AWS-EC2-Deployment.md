# 🦙 LLaMA 3.2 Chatbot — AWS Deployment Guide

Deploy a Streamlit + Ollama + LLaMA 3.2 chatbot on AWS EC2.

---

## 🏗️ Architecture

```
User → Public IP → EC2 → Streamlit App → Ollama → LLaMA Model
```

---

## ⚠️ Before You Start

Ollama + LLaMA 3.2 requires:

- Minimum **8GB RAM** (16GB recommended)
- Good CPU (GPU optional, but improves performance)

> ❌ Do **NOT** use `t2.micro` — it won't work.  
> ✅ Use `t3.large` (8GB RAM) or `t3.xlarge` (16GB RAM)

---

## 🔹 STEP 1 — Launch EC2 Instance

Go to: **AWS Console → EC2 → Launch Instance**

### Basic Settings

| Setting | Value |
|---|---|
| Name | `llama-chatbot` |
| AMI | Ubuntu 22.04 LTS |
| Instance Type | `t3.large` (min) / `t3.xlarge` (recommended) |

### Key Pair

Select your existing key **OR** create a new key pair and download the `.pem` file.

### Security Group (VERY IMPORTANT)

Create a new Security Group with the following inbound rules:

| Type | Port | Source |
|---|---|---|
| SSH | 22 | My IP |
| Custom TCP | 8501 | Anywhere (0.0.0.0/0) |

> Port **8501** is used by Streamlit.

### Storage

| Setting | Value |
|---|---|
| Minimum | 20 GB |
| Recommended | 30 GB |

> The LLaMA model download is large — allocate sufficient storage.

Click **Launch Instance**.

---

## 🔹 STEP 2 — Connect to EC2

From your local terminal:

```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>
```

---

## 🔹 STEP 3 — Update Server

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 🔹 STEP 4 — Install Python

Ubuntu 22.04 comes with Python 3.10. Confirm it's available:

```bash
python3 --version
```

Install pip and venv:

```bash
sudo apt install python3-pip python3-venv -y
```

---

## 🔹 STEP 5 — Install Ollama on EC2

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Verify installation:

```bash
ollama --version
```

---

## 🔹 STEP 6 — Pull LLaMA Model

> ⚠️ This will take some time depending on your connection.

```bash
ollama pull llama3.2:latest
```

Wait until the download completes, then test it:

```bash
ollama run llama3.2:latest
```

Type something to confirm it works. Press `Ctrl + D` to exit.

---

## 🔹 STEP 7 — Clone Your GitHub Repo

Install Git:

```bash
sudo apt install git -y
```

Clone the repository:

```bash
git clone https://github.com/Rohit-1920/zzzzz.git
cd zzzzz
```

---

## 🔹 STEP 8 — Fix Image File Name (IMPORTANT)

Your code references:

```python
set_bg("lily.jpg")
```

Check what image files are present:

```bash
ls
```

If the image is named differently (e.g., `flowers.jpg`), either rename it:

```bash
mv flowers.jpg lily.jpg
```

Or update the filename in `app.py` to match the actual file.

---

## 🔹 STEP 9 — Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate
```

---

## 🔹 STEP 10 — Install Requirements

If your requirements file is named `requirement.txt`, rename it first:

```bash
mv requirement.txt requirements.txt
```

Then install dependencies:

```bash
pip install -r requirements.txt
```

---

## 🔹 STEP 11 — Allow Ollama Remote Access (CRITICAL)

By default, Ollama only listens on `localhost:11434`. To allow Streamlit to communicate with it, you need to expose it on all interfaces.

Edit the Ollama service file:

```bash
sudo nano /etc/systemd/system/ollama.service
```

Add the following line inside the `[Service]` section:

```ini
Environment="OLLAMA_HOST=0.0.0.0"
```

Save and exit, then reload and restart the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

Verify it's running:

```bash
sudo systemctl status ollama
```

---

## 🔹 STEP 12 — Run Streamlit

From inside your project folder:

```bash
streamlit run app.py --server.port 8501 --server.address 0.0.0.0
```

---

## 🔹 STEP 13 — Access in Browser

Open your browser and navigate to:

```
http://<EC2_PUBLIC_IP>:8501
```

🎉 **Your AI Agent is LIVE!**

---

## 🔹 STEP 14 — Run in Background (Production Ready)

Install screen:

```bash
sudo apt install screen -y
```

Start a screen session and run the app:

```bash
screen -S chatbot
streamlit run app.py --server.port 8501 --server.address 0.0.0.0
```

Detach from the session (app keeps running):

```
CTRL + A + D
```

---

## 🔐 OPTIONAL — Nginx Reverse Proxy (Highly Recommended)

Add an Nginx reverse proxy so users can access the app without specifying a port:

```
http://yourdomain.com
```

> Open an issue or reach out if you'd like a full Nginx setup guide.

---

## 💰 Cost Warning

| Instance | Approx. Cost |
|---|---|
| `t3.large` | ~₹6–8 per hour |
| Running 24/7 | ~₹5,000–6,000 per month |

> ⚠️ **Stop your EC2 instance when not in use to avoid unnecessary charges.**
