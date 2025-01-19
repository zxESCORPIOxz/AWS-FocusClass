from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
from datetime import date

# Nombre del procedimiento almacenado
OBTENER_NIVELES_PROC = "ObtenerNivelesGradosSecciones"

def convert_date(value):
    if isinstance(value, date):
        return value.strftime('%Y-%m-%d')
    return value

def build_cascade_structure(data):
    """
    Construye la estructura en cascada: Nivel > Grado > Sección.
    """
    niveles = {}
    for row in data:
        id_nivel, nombre_nivel, id_grado, nombre_grado, id_seccion, nombre_seccion, limite_cupo, turno = row
        
        if id_nivel not in niveles:
            niveles[id_nivel] = {
                "id_nivel": id_nivel,
                "nombre": nombre_nivel,
                "grados": {}
            }
        
        if id_grado not in niveles[id_nivel]["grados"]:
            niveles[id_nivel]["grados"][id_grado] = {
                "id_grado": id_grado,
                "nombre": nombre_grado,
                "secciones": []
            }
        
        niveles[id_nivel]["grados"][id_grado]["secciones"].append({
            "id_seccion": id_seccion,
            "nombre": nombre_seccion,
            "limite_cupo": limite_cupo,
            "turno": turno
        })
    
    # Convertir grados de diccionario a lista
    for nivel in niveles.values():
        nivel["grados"] = list(nivel["grados"].values())
    
    return list(niveles.values())

def lambda_handler(event, context):
    connection = None
    cursor = None
    response = None

    try:
        # Parsear los datos de entrada
        body = json.loads(event['body']) if 'body' in event else {}
        token = body.get('token')
        id_institucion = body.get('id_institucion')

        print("Validando token recibido:", token)
        token_result = validate_token(token)

        if token_result['status'] != SUCCESS:
            print("Token no válido:", token_result['message'])
            return {
                "statusCode": 401,
                "body": json.dumps({
                    "status": LOGOUT,
                    "message": "Tu sesión ha expirado o es inválida. Por favor, inicia sesión nuevamente para continuar."
                })
            }

        print("Token válido, obteniendo niveles, grados y secciones de la institución:", id_institucion)

        # Conexión a la base de datos
        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        cursor.callproc(OBTENER_NIVELES_PROC, [id_institucion])

        niveles_data = []
        for result in cursor.stored_results():
            niveles_data.extend(result.fetchall())

        if niveles_data:
            # Construir estructura en cascada
            cascade_data = build_cascade_structure(niveles_data)
            
            response = {
                "statusCode": 200,
                "body": json.dumps({
                    "status": SUCCESS,
                    "message": "Datos de niveles, grados y secciones obtenidos correctamente.",
                    "data": cascade_data
                })
            }
        else:
            response = {
                "statusCode": 404,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "No se encontraron datos para la institución proporcionada."
                })
            }

        connection.commit()
        return response

    except Error as e:
        print("Error al obtener niveles, grados y secciones:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al obtener los datos."
            })
        }
        return response

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
