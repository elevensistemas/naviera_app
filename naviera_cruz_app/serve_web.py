from http.server import HTTPServer, SimpleHTTPRequestHandler
import sys, os

class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

if __name__ == '__main__':
    web_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web')
    os.chdir(web_dir)
    server = HTTPServer(('0.0.0.0', 8085), NoCacheHandler)
    print(f'Serving {web_dir} on http://0.0.0.0:8085 with No-Cache headers...', flush=True)
    server.serve_forever()

