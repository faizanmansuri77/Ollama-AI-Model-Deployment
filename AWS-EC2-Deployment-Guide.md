# 🚀 Deployment Guide: AI Agent on AWS EC2 (Manual Dev Mode)

This guide walks you through running the **FastAPI + React + Ollama** application on an AWS EC2 instance in **Development Mode**. 
This method is best for practicing, debugging, and seeing logs in real-time. We will run the backend and frontend in separate terminal sessions.

## Prerequisites
- AWS Account
- Basic knowledge of terminal/SSH
- EC2 Instance (Ubuntu 24.04 LTS recommended)

---

## Step 1: Launch EC2 Instance
1.  **OS**: Ubuntu Server 24.04 LTS (recommended)
2.  **Instance Type**:
    *   **Recommended**: `c7i-flex.large` (2 vCPU, 4GB RAM) or similar.
    *   **Why**: Needs 4GB+ RAM to run LLaMA 3.2 smoothly.

3.  **Storage**: At least **20GB gp3**.
4.  **Security Group (Firewall)**:
    *   **SSH (22)** - Your IP (for access)
    *   **Custom TCP (5000)** - Anywhere (for Backend API)
    *   **Custom TCP (5173)** - Anywhere (for Frontend Vite Server)

---

## Step 2: Connect and Install Dependencies
SSH into your instance:
```bash
ssh -i "your-key.pem" ubuntu@your-ec2-ip
```

Update system and install required tools:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3-pip python3-venv nodejs npm git
```

*Note: If Node.js is old, install v20:*
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
node -v  # Should be v20.x.x
```

---

## Step 3: Install and Setup Ollama
1.  Install Ollama:
    ```bash
    curl -fsSL https://ollama.com/install.sh | sh
    ```

2.  Start Ollama service:
    ```bash
    sudo systemctl start ollama
    ```

3.  Pull the LLaMA 3.2 model:
    ```bash
    ollama pull llama3.2:latest
    ```

---

## Step 4: Run Backend (Terminal 1)
1.  **Clone the repository**:
    ```bash
    git clone <your-github-repo-url>
    cd AI-Agent-Project
    ```

2.  **Setup Python Virtual Environment**:
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **Install Python Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

4.  **Start the Backend**:
    ```bash
    python3 app.py
    ```
    *You should see "Uvicorn running on http://0.0.0.0:5000".*
    **DO NOT CLOSE THIS TERMINAL.**

---

## Step 5: Run Frontend (Terminal 2)
1.  **Open a NEW Terminal/SSH Session**:
    Connect to the same EC2 instance in a new window.

2.  **Navigate to Frontend**:
    ```bash
    cd AI-Agent-Project/frontend
    ```

3.  **Install Dependencies**:
    ```bash
    npm install
    ```

4.  **Start the Frontend**:
    ```bash
    npm run dev
    ```
    *(We have configured vite.config.js to automatically expose the host)*

---

## Step 6: Access Your App
Open your web browser and enter your EC2 instance's Public IP with port **5173**:

`http://<your-ec2-public-ip>:5173`

---

## 🛠 Troubleshooting
*   **Site not loading?** Check your **Security Group** rules on AWS. Ensure port **5173** is open to "Anywhere" (0.0.0.0/0).
*   **Backend error?** Check the logs in **Terminal 1**.
*   **Frontend error?** Check the logs in **Terminal 2**.
