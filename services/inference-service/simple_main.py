#!/usr/bin/env python3
"""
简化的推理服务
"""
import json
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
import time

# 设置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class InferenceServiceHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                "status": "healthy",
                "service": "inference-service",
                "version": "1.0.0"
            }
            self.wfile.write(json.dumps(response).encode())
        elif self.path == '/ready':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {"status": "ready"}
            self.wfile.write(json.dumps(response).encode())
        elif self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                "message": "Inference Service API",
                "version": "1.0.0"
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        logger.info(f"{self.address_string()} - {format % args}")

def run_server():
    server_address = ('0.0.0.0', 8084)
    httpd = HTTPServer(server_address, InferenceServiceHandler)
    logger.info(f"Inference Service starting on port 8084")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down Inference Service...")
        httpd.shutdown()

if __name__ == '__main__':
    run_server()
