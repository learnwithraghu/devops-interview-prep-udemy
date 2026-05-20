import os
import sys
import time
import threading
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler

LISTEN_PORT = int(os.getenv("LISTEN_PORT", "8080"))
FAIL_START = os.getenv("FAIL_START", "false").lower() == "true"
READINESS_DELAY = int(os.getenv("READINESS_DELAY", "0"))
LIVENESS_FAIL_AFTER = int(os.getenv("LIVENESS_FAIL_AFTER", "0"))
OOM_ALLOCATE_MB = int(os.getenv("OOM_ALLOCATE_MB", "0"))
RESPONSE_CODE = int(os.getenv("RESPONSE_CODE", "200"))
LOG_SPIKE = os.getenv("LOG_SPIKE", "false").lower() == "true"

big_memory = []

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

ready_event = threading.Event()
health_ok_event = threading.Event()
health_ok_event.set()


def allocate_memory():
    if OOM_ALLOCATE_MB > 0:
        try:
            chunk = bytearray(1024 * 1024 * OOM_ALLOCATE_MB)
            big_memory.append(chunk)
            logger.info(f"Allocated {OOM_ALLOCATE_MB} MB of memory")
        except MemoryError:
            logger.error(f"Failed to allocate {OOM_ALLOCATE_MB} MB of memory")
            sys.exit(1)


def log_spike():
    counter = 0
    while True:
        logger.info(f"LOG SPIKE line {counter}")
        counter += 1
        time.sleep(0.01)


def update_ready():
    if READINESS_DELAY > 0:
        time.sleep(READINESS_DELAY)
    ready_event.set()
    logger.info(f"Readiness probe now returning 200 (delayed by {READINESS_DELAY}s)")


def update_health():
    if LIVENESS_FAIL_AFTER > 0:
        time.sleep(LIVENESS_FAIL_AFTER)
        health_ok_event.clear()
        logger.info(
            f"Liveness probe now returning 500 (failed after {LIVENESS_FAIL_AFTER}s)"
        )


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        logger.info("%s - %s" % (self.client_address[0], format % args))

    def do_GET(self):
        if self.path == "/ready":
            if ready_event.is_set():
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"OK\n")
            else:
                self.send_response(503)
                self.end_headers()
                self.wfile.write(b"Not Ready\n")
        elif self.path == "/health":
            if health_ok_event.is_set():
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"OK\n")
            else:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b"UNHEALTHY\n")
        else:
            self.send_response(RESPONSE_CODE)
            self.end_headers()
            self.wfile.write(f"Response code: {RESPONSE_CODE}\n".encode())


def main():
    if FAIL_START:
        logger.error("FAIL_START is true, exiting immediately with code 1")
        sys.exit(1)

    allocate_memory()

    threading.Thread(target=update_ready, daemon=True).start()
    threading.Thread(target=update_health, daemon=True).start()

    if LOG_SPIKE:
        threading.Thread(target=log_spike, daemon=True).start()

    server = HTTPServer(("0.0.0.0", LISTEN_PORT), Handler)
    logger.info(f"Server starting on 0.0.0.0:{LISTEN_PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        logger.info("Server stopped")


if __name__ == "__main__":
    main()
