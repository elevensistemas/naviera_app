"""
Local development proxy for Naviera Cruz del Sur (CORS & SSL bridge for Flutter Web)
Port: 8086
"""
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.request
import urllib.error
import ssl
import json
import time
import sys

INTRANET_BASE = "https://navieracruzdelsur.dyndns.org:6570"
CENTINELA_BASE = "https://centinela.dyndns.org:5073"
MASTER_TOKEN = "Token f910e860cb94c3ebeccc0e1a4b16cb1ae641d69b"

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

# Cache en memoria del token CAT para respuestas instantáneas
_cached_cat_bytes = None
_cached_cat_time = 0
_cached_cat_token = ""

def _fetch_intranet_cat():
    global _cached_cat_bytes, _cached_cat_time, _cached_cat_token
    req = urllib.request.Request(
        f"{INTRANET_BASE}/api/v1/centinela/camera-token/",
        data=b'{}',
        method='POST',
        headers={
            'Content-Type': 'application/json',
            'Authorization': MASTER_TOKEN,
            'Accept': 'application/json',
        }
    )
    with urllib.request.urlopen(req, context=ctx, timeout=8) as resp:
        data = resp.read()
        try:
            parsed = json.loads(data.decode('utf-8'))
            _cached_cat_token = parsed.get('camera_access_token', '')
        except Exception:
            pass
        _cached_cat_bytes = data
        _cached_cat_time = time.time()
        # Absorber desfase NTP en el momento de emisión
        time.sleep(1.8)
        return data

class ProxyHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE')
        self.send_header('Access-Control-Allow-Headers', 'Authorization, Content-Type, Accept, X-Requested-With, Cache-Control, Pragma')

    def do_OPTIONS(self):
        self.send_response(204)
        self._send_cors_headers()
        self.end_headers()

    def do_POST(self):
        global _cached_cat_bytes, _cached_cat_time, _cached_cat_token
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else b'{}'

        # Endpoint de token CAT con caché activo y auto-recuperación
        if 'camera-token' in self.path:
            now = time.time()
            if _cached_cat_bytes and (now - _cached_cat_time < 480):
                self.send_response(200)
                self._send_cors_headers()
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(_cached_cat_bytes)
                return

            # Intentar obtener CAT fresco
            try:
                # 1. Probar con las cabeceras provistas por el cliente
                target_url = INTRANET_BASE + self.path
                req = urllib.request.Request(target_url, data=body, method='POST')
                has_auth = False
                for k, v in self.headers.items():
                    if k.lower() in ('authorization', 'content-type', 'accept'):
                        if k.lower() == 'authorization' and v.strip():
                            has_auth = True
                        req.add_header(k, v)

                if not has_auth:
                    req.add_header('Authorization', MASTER_TOKEN)

                with urllib.request.urlopen(req, context=ctx, timeout=8) as resp:
                    data = resp.read()
                    try:
                        parsed = json.loads(data.decode('utf-8'))
                        _cached_cat_token = parsed.get('camera_access_token', '')
                    except Exception:
                        pass
                    _cached_cat_bytes = data
                    _cached_cat_time = time.time()
                    time.sleep(1.8)
                    self.send_response(resp.status)
                    self._send_cors_headers()
                    self.send_header('Content-Type', resp.headers.get('Content-Type', 'application/json'))
                    self.end_headers()
                    self.wfile.write(data)
                    return
            except urllib.error.HTTPError as e:
                # Si falló con 401 (token de usuario revocado o expirado), recurrir inmediatamente a MASTER_TOKEN
                if e.code == 401:
                    try:
                        data = _fetch_intranet_cat()
                        self.send_response(200)
                        self._send_cors_headers()
                        self.send_header('Content-Type', 'application/json')
                        self.end_headers()
                        self.wfile.write(data)
                        return
                    except Exception as err2:
                        print(f"[Proxy] Fallback con token maestro falló: {err2}", flush=True)

                err_data = e.read()
                self.send_response(e.code)
                self._send_cors_headers()
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(err_data)
                return
            except Exception as e:
                # Fallback final a MASTER_TOKEN si hay excepción de red
                try:
                    data = _fetch_intranet_cat()
                    self.send_response(200)
                    self._send_cors_headers()
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(data)
                    return
                except Exception:
                    self.send_response(500)
                    self._send_cors_headers()
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'error': str(e)}).encode())
                    return

        # Para cualquier otro POST a la Intranet
        target_url = INTRANET_BASE + self.path
        req = urllib.request.Request(target_url, data=body, method='POST')
        is_login = 'login' in self.path
        for k, v in self.headers.items():
            if k.lower() in ('authorization', 'content-type', 'accept'):
                if is_login and k.lower() == 'authorization':
                    continue
                req.add_header(k, v)
        try:
            with urllib.request.urlopen(req, context=ctx, timeout=8) as resp:
                data = resp.read()
                self.send_response(resp.status)
                self._send_cors_headers()
                self.send_header('Content-Type', resp.headers.get('Content-Type', 'application/json'))
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            err_data = e.read()
            self.send_response(e.code)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(err_data)
        except Exception as e:
            self.send_response(500)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def do_GET(self):
        global _cached_cat_token
        is_centinela = '/external/' in self.path
        target_url = (CENTINELA_BASE if is_centinela else INTRANET_BASE) + self.path

        req = urllib.request.Request(target_url, method='GET')
        has_auth = False
        for k, v in self.headers.items():
            if k.lower() in ('authorization', 'content-type', 'accept'):
                if k.lower() == 'authorization' and v.strip():
                    has_auth = True
                req.add_header(k, v)

        if is_centinela and not has_auth and _cached_cat_token:
            req.add_header('Authorization', f'Bearer {_cached_cat_token}')

        try:
            with urllib.request.urlopen(req, context=ctx, timeout=8) as resp:
                data = resp.read()
                self.send_response(resp.status)
                self._send_cors_headers()
                self.send_header('Content-Type', resp.headers.get('Content-Type', 'application/json'))
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            # Reintento si es Intranet y devolvió 401 (token de sesión del navegador expirado)
            if not is_centinela and e.code == 401:
                try:
                    req_master = urllib.request.Request(target_url, method='GET')
                    req_master.add_header('Authorization', MASTER_TOKEN)
                    req_master.add_header('Accept', 'application/json')
                    with urllib.request.urlopen(req_master, context=ctx, timeout=8) as resp_m:
                        data_m = resp_m.read()
                        self.send_response(resp_m.status)
                        self._send_cors_headers()
                        self.send_header('Content-Type', resp_m.headers.get('Content-Type', 'application/json'))
                        self.end_headers()
                        self.wfile.write(data_m)
                        return
                except Exception as em:
                    pass

            # Reintento si es Centinela y devolvió 401
            if is_centinela and e.code == 401:
                # Renovar CAT si es posible
                try:
                    _fetch_intranet_cat()
                    if _cached_cat_token:
                        req2 = urllib.request.Request(target_url, method='GET')
                        for k, v in self.headers.items():
                            if k.lower() in ('content-type', 'accept'):
                                req2.add_header(k, v)
                        req2.add_header('Authorization', f'Bearer {_cached_cat_token}')
                        with urllib.request.urlopen(req2, context=ctx, timeout=8) as resp2:
                            data2 = resp2.read()
                            self.send_response(resp2.status)
                            self._send_cors_headers()
                            self.send_header('Content-Type', resp2.headers.get('Content-Type', 'application/json'))
                            self.end_headers()
                            self.wfile.write(data2)
                            return
                except Exception as err2:
                    print(f"[Proxy] Reintento con CAT renovado falló: {err2}", flush=True)

            err_data = e.read()
            self.send_response(e.code)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(err_data)
        except Exception as e:
            self.send_response(500)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def log_message(self, format, *args):
        print(f"[Proxy] {self.command} {self.path} - {format % args}", flush=True)

def run():
    # Pre-calentar token CAT al inicio para disponibilidad instantánea
    try:
        print("[Proxy] Pre-calentando token CAT desde Intranet...", flush=True)
        _fetch_intranet_cat()
        print("[Proxy] Token CAT listo.", flush=True)
    except Exception as e:
        print(f"[Proxy] Advertencia en pre-calentamiento: {e}", flush=True)

    server = HTTPServer(('127.0.0.1', 8086), ProxyHandler)
    print("Local Camera Proxy running on http://127.0.0.1:8086", flush=True)
    server.serve_forever()

if __name__ == '__main__':
    run()
