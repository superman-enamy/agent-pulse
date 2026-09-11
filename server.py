#!/data/data/com.termux/files/usr/bin/python3
import http.server
import json
import os
import socketserver
import subprocess
import sys
import traceback
import urllib.parse

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(BASE_DIR, "config.json")
WEB_DIR = os.path.join(BASE_DIR, "web")
LOG_PATH = os.path.join(BASE_DIR, "logs", "activity.log")
OPEN_SCRIPT = os.path.join(BASE_DIR, "open.sh")
NOTIFY_SCRIPT = os.path.join(BASE_DIR, "notify.sh")

def load_config():
    try:
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        return {"error": str(e)}

def save_config(new_config):
    try:
        with open(CONFIG_PATH, "w", encoding="utf-8") as f:
            json.dump(new_config, f, indent=2)
        return True, "Config updated successfully"
    except Exception as e:
        return False, str(e)

class AgentPulseHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def _send_json(self, data, status=200):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        try:
            parsed = urllib.parse.urlparse(self.path)
            path = parsed.path

            if path == "/api/config":
                self._send_json(load_config())
                return
            elif path == "/api/status":
                # Pure status - NEVER trigger any activity launch!
                self._send_json({
                    "status": "online",
                    "config_loaded": True
                })
                return
            elif path == "/api/logs":
                lines = []
                if os.path.exists(LOG_PATH):
                    try:
                        with open(LOG_PATH, "r", encoding="utf-8") as f:
                            lines = [line.strip() for line in f.readlines()[-40:]]
                    except Exception:
                        pass
                self._send_json({"logs": lines})
                return

            return super().do_GET()
        except Exception as e:
            self._send_json({"error": str(e), "trace": traceback.format_exc()}, status=500)

    def do_POST(self):
        try:
            parsed = urllib.parse.urlparse(self.path)
            path = parsed.path
            length = int(self.headers.get("Content-Length", 0))
            post_data = {}
            if length > 0:
                try:
                    post_data = json.loads(self.rfile.read(length).decode("utf-8"))
                except Exception:
                    pass

            if path == "/api/config":
                ok, msg = save_config(post_data)
                self._send_json({"success": ok, "message": msg}, status=200 if ok else 400)
                return

            elif path == "/api/test/notification":
                title = post_data.get("title", "Agent Pulse Live Test")
                content = post_data.get("content", "Testing notification from Web Portal!")
                subprocess.Popen([NOTIFY_SCRIPT, "test_notify", title, content])
                self._send_json({"success": True, "message": "Notification dispatched"})
                return

            elif path == "/api/test/voice":
                text = post_data.get("text", "Agent Pulse voice test is working successfully.")
                subprocess.Popen([NOTIFY_SCRIPT, "test_voice", text])
                self._send_json({"success": True, "message": "Voice test dispatched"})
                return

            elif path == "/api/test/open":
                subprocess.Popen([OPEN_SCRIPT])
                self._send_json({"success": True, "message": "Open Termux dispatched"})
                return

            self._send_json({"error": "Endpoint not found"}, status=404)
        except Exception as e:
            self._send_json({"error": str(e), "trace": traceback.format_exc()}, status=500)

def run():
    socketserver.TCPServer.allow_reuse_address = True
    cfg = load_config()
    port = cfg.get("server", {}).get("port", 8899)
    host = "0.0.0.0"
    
    server_address = (host, port)
    httpd = http.server.ThreadingHTTPServer(server_address, AgentPulseHandler)
    print(f"Agent-Pulse Server running at http://localhost:{port}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()

if __name__ == "__main__":
    run()
