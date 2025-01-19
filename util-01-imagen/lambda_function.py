import requests
import base64

def lambda_handler(event, context):
    image_id = event['queryStringParameters'].get('img', None)
    
    if not image_id:
        return {
            'statusCode': 400,
            'body': 'Falta el parámetro img'
        }
    
    image_url = f"http://108.181.169.248/IMG-FOCUSCLASS/IMG/{image_id}.png"
    
    try:
        response = requests.get(image_url)
        if response.status_code == 200:
            image_base64 = base64.b64encode(response.content).decode('utf-8')
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'image/png'
                },
                'body': image_base64,
                'isBase64Encoded': True
            }
        else:
            return {
                'statusCode': response.status_code,
                'body': 'Error al obtener la imagen'
            }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error interno: {str(e)}'
        }
