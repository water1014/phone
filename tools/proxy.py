#!/usr/bin/env python3
# 小窝 · OpenCode Go 本地中转
# 网页（https）不能直连 opencode.ai，本脚本在手机本机开一个小门，
# 把请求原样转过去，并补上浏览器要的跨域许可。
#
# 用法：python3 /sdcard/xiaowo/proxy.py
# 然后在小窝「设置 → 聊天的接口」里把地址改成 http://127.0.0.1:8790/go

import json
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

UPSTREAM = "https://opencode.ai/inference"
PORT = 8790
HOP_HEADERS = {"host", "content-length", "origin", "referer", "connection", "accept-encoding"}


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Max-Age", "86400")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.send_header("Content-Length", "0")
        self.end_headers()

    def _forward(self, method):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        target = UPSTREAM + self.path

        req = urllib.request.Request(target, data=body, method=method)
        for key, value in self.headers.items():
            if key.lower() in HOP_HEADERS:
                continue
            req.add_header(key, value)

        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                payload = resp.read()
                self.send_response(resp.status)
                self._cors()
                self.send_header("Content-Type", resp.headers.get("Content-Type", "application/json"))
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)
        except urllib.error.HTTPError as err:
            payload = err.read() or b"{}"
            self.send_response(err.code)
            self._cors()
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        except Exception as err:  # noqa: BLE001
            payload = json.dumps({"error": str(err)}).encode()
            self.send_response(502)
            self._cors()
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

    def do_GET(self):
        self._forward("GET")

    def do_POST(self):
        self._forward("POST")

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    print(f"小窝中转已启动 → {UPSTREAM}")
    print(f"网页里把接口地址填成：http://127.0.0.1:{PORT}/go")
    print("关掉这个窗口，中转就停了。")
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
