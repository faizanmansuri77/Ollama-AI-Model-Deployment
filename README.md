# 🤖 AI Agent Project - LLaMA 3.2 Chatbot

A professional, offline AI chatbot that runs entirely on your local machine using **Ollama** (for the AI brain), **FastAPI** (for the backend logic), and **React** (for the beautiful user interface).

---

## 🧐 What is this project?

This project is a **Local AI Chat Application**.
*   **"Local"** means it runs on your computer, not in the cloud. No data leaves your device.
*   **"AI Chat"** means you can talk to it like ChatGPT, ask coding questions, or get help with writing.

It is built with three main parts working together:

### 1. 🧠 The Brain: Ollama
*   **What it does:** This is the engine that runs the AI model (LLaMA 3.2). It reads your text and generates the intelligent response.
*   **How we use it:** We use the `ollama` command-line tool to download and run the model. Our Python code talks to Ollama to get answers.

### 2. ⚙️ The Backend: FastAPI (`app.py`)
*   **What it does:** This is the bridge between the user interface and the AI brain.
*   **Key File:** `app.py`
*   **How it works:**
    *   It receives your message from the React website.
    *   It sends that message to Ollama.
    *   It receives the AI's response piece-by-piece (streaming) and sends it back to the website instantly.
    *   It handles the API logic to make sure messages flow correctly.

### 3. 🎨 The Frontend: React (`frontend/`)
*   **What it does:** This is what you see and interact with in your browser.
*   **Key Files:**
    *   `src/App.jsx`: Handles the chat logic (sending messages, displaying history).
    *   `src/index.css`: Contains all the styling for the professional, modern UI.
*   **How it works:**
    *   It displays the chat window, input box, and sidebar.
    *   It sends your typed message to our Backend (`app.py`).
    *   It renders the AI's response beautifully with Markdown (bold text, code blocks, etc.).

---

## 🚀 How to Run (Step-by-Step)

Follow these steps exactly to get the project running.

### Prerequisite: Install Ollama
You must have Ollama installed to run the AI model.
1.  Download from [ollama.com](https://ollama.com).
2.  Install it.
3.  Open your terminal and run:
    ```bash
    ollama pull llama3.2
    ```
    *This downloads the brain.*

### Step 1: Start the Backend (The Logic)
This starts the server that talks to the AI.

1.  Open a terminal in the project folder.
2.  Create a virtual environment (optional but recommended):
    ```bash
    python -m venv venv
    # Windows:
    venv\Scripts\activate
    # Mac/Linux:
    source venv/bin/activate
    ```
3.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```
4.  **Run the Backend Server:**
    ```bash
    uvicorn app:app --reload --port 5000
    ```
    *You will see a message saying "Application startup complete". Keep this terminal open!*

### Step 2: Start the Frontend (The UI)
This starts the website you can see.

1.  Open a **NEW** terminal window (do not close the first one).
2.  Go to the frontend folder:
    ```bash
    cd frontend
    ```
3.  Install Node packages (only needed the first time):
    ```bash
    npm install
    ```
4.  **Run the Frontend Website:**
    ```bash
    npm run dev
    ```
    *You will see a link like `http://localhost:5173`. Click it or copy it to your browser.*

---

## 📂 Project Structure Explained

```text
AI-Agent-Project/
├── app.py                 # BACKEND: The Python code that talks to Ollama
├── requirements.txt       # List of Python tools we need (FastAPI, uvicorn, ollama)
├── frontend/              # FRONTEND: The React website folder
│   ├── src/
│   │   ├── App.jsx        # The main React code (chat logic)
│   │   └── index.css      # The styling (colors, layout, design)
│   ├── package.json       # List of frontend tools (React, Markdown, etc.)
│   └── vite.config.js     # Configuration to connect Frontend to Backend
└── README.md              # This instruction file
```

---

## 🛠 Features
*   **Professional UI**: Modern messenger-style design with formal colors.
*   **Real-time Streaming**: Text appears as it is being generated.
*   **Markdown Support**: Code blocks and formatting render perfectly.
*   **Responsive**: Works on Mobile, Tablet, and Desktop.
*   **Secure & Private**: Runs 100% locally on your machine.
