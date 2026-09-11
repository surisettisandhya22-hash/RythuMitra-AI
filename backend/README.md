# RythuMitra AI Backend

This is the FastAPI backend foundation for the RythuMitra AI application.

## 1. Requirements
- Python 3.9+
- A virtual environment

## 2. Virtual Environment Creation & Activation (Windows)
Create the virtual environment:
```powershell
python -m venv .venv
```
Activate it:
```powershell
.venv\Scripts\activate
```

## 3. Package Installation
Install dependencies:
```powershell
pip install -r requirements.txt
```

## 4. Environment Configuration
Copy `.env.example` to `.env` and configure as needed:
```powershell
cp .env.example .env
```
Ensure you have set the `HOST`, `PORT`, and `APP_ENV`.

## 5. Backend Start Command
Start the backend server (ensure you are running this from the `backend/` directory):
```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## 6. Endpoints & Documentation
- **Root**: `http://localhost:8000/`
- **Health Check**: `http://localhost:8000/health`
- **Swagger Documentation**: `http://localhost:8000/docs`
- **ReDoc Documentation**: `http://localhost:8000/redoc`

## 7. Physical Android Device Networking
When testing the Flutter app on a physical Android device (like the Vivo Y56) on the same Wi-Fi network:
1. Ensure the backend is listening on `0.0.0.0` (as shown in the start command).
2. The Android phone cannot access your PC's `localhost` directly. 
3. You must find your PC's local network IP address (e.g., by running `ipconfig` on Windows).
4. Point your Flutter app's API base URL to `http://<YOUR_PC_IP>:8000`.

### Firewall Note
Windows Firewall may block incoming connections on port 8000. If your phone cannot connect to your PC, you may need to add an inbound rule in Windows Firewall to allow traffic on TCP port 8000 for Python/Uvicorn. Do NOT disable the firewall globally; only allow the specific port.

## 8. Troubleshooting
- **Cannot import `app.main`**: Ensure you are running the `uvicorn` command from the root `backend/` folder, not from inside the `app/` folder.
- **Port 8000 in use**: Stop other processes using the port or change the `--port` argument (and update your `.env`).
