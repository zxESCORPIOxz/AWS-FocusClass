import requests

def lambda_handler(event, context):
    query_params = event.get('queryStringParameters', {})
    
    ruta = query_params.get('ruta', None)
    if not ruta:
        return {
            'statusCode': 400,
            'body': 'Falta el parámetro "ruta"'
        }
    
    base_url = "http://108.181.169.248/Ubigeo/api"
    rutas_disponibles = {
        'ubicacion': f"{base_url}/ubicacion",
        'distritos': f"{base_url}/distritos",
        'departamentos': f"{base_url}/departamentos",
        'provincias': f"{base_url}/provincias"
    }
    
    if ruta not in rutas_disponibles:
        return {
            'statusCode': 400,
            'body': f'Ruta "{ruta}" no válida. Rutas permitidas: {", ".join(rutas_disponibles.keys())}'
        }
    
    api_url = rutas_disponibles[ruta]
    
    try:
        response = requests.get(api_url, params=query_params)
        return {
            'statusCode': response.status_code,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': response.text
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error interno: {str(e)}'
        }
