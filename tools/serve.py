"""
Godot 4 Web Local Server with COOP/COEP Headers
-----------------------------------------------
ให้การรัน Godot Web บน localhost รองรับ WebGL2, AudioWorklet และ WebAssembly ได้สมบูรณ์แบบ
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

PORT = 8060
WEB_DIR = Path(__file__).resolve().parents[1] / "build" / "web"


class GodotWebHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Header ที่จำเป็นสำหรับ Godot 4 WebAssembly & AudioWorklet
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def guess_type(self, path):
        if str(path).endswith(".wasm"):
            return "application/wasm"
        if str(path).endswith(".pck"):
            return "application/octet-stream"
        if str(path).endswith(".js"):
            return "text/javascript"
        return super().guess_type(path)


def run_server(port=PORT):
    os.chdir(WEB_DIR)
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", port), GodotWebHandler) as httpd:
        print(f"=== Blood Gambit Web Server Started ===")
        print(f"Serving from: {WEB_DIR}")
        print(f"URL: http://localhost:{port}/")
        print(f"URL: http://127.0.0.1:{port}/")
        sys.stdout.flush()
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("Server shutting down.")


if __name__ == "__main__":
    p = int(sys.argv[1]) if len(sys.argv) > 1 else PORT
    run_server(p)
