# Revisa que la alerta ServicioCaido coincida con el estado real de la API
import json
import subprocess
import sys
import urllib.request


def api_responde():
    try:
        with urllib.request.urlopen('http://localhost:8080/api/salud', timeout=5) as r:
            return r.status == 200
    except OSError:
        return False


def alerta_disparada():
    salida = subprocess.run(
        ['docker', 'compose', 'exec', '-T', 'prometheus', 'wget', '-qO-',
         'http://localhost:9090/api/v1/alerts'],
        capture_output=True, text=True, check=True,
    ).stdout
    for alerta in json.loads(salida)['data']['alerts']:
        etiquetas = alerta['labels']
        if (etiquetas.get('alertname') == 'ServicioCaido'
                and etiquetas.get('servicio') == 'API'
                and alerta['state'] == 'firing'):
            return True
    return False


arriba = api_responde()
alerta = alerta_disparada()
print(f'API responde: {arriba}, alerta ServicioCaido disparada: {alerta}')
sys.exit(0 if arriba != alerta else 1)
