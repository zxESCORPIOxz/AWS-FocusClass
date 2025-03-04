from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
from decimal import Decimal

MODIFICAR_ASISTENCIA_PROC = "ModificarAsistencia"

def convert_date(value):
    from datetime import date, datetime
    if isinstance(value, (date, datetime)):
        return value.strftime('%Y-%m-%d %H:%M:%S')
    elif isinstance(value, Decimal):
        return float(value)
    return value

def lambda_handler(event, context):
    connection = None
    cursor = None
    response = None

    print("Evento recibido:", json.dumps(event, indent=2))  # Imprimir evento completo para depuración

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        token = body.get('token')
        asistencias = body.get('asistencias') 

        print("Token recibido:", token)
        print("Lista de asistencias recibidas:", asistencias)

        token_result = validate_token(token)
        print("Resultado de validación del token:", token_result)

        if token_result['status'] != SUCCESS:
            print("Token inválido:", token_result['message'])
            return {
                "statusCode": 401,
                "body": json.dumps({
                    "status": LOGOUT,
                    "message": "Tu sesión ha expirado o es inválida. Por favor, inicia sesión nuevamente para continuar."
                })
            }

        print("Token válido, procediendo con la actualización de asistencias...")

        if not asistencias:
            print("Error: No se proporcionaron asistencias en la solicitud.")
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "No se proporcionaron registros de asistencia para modificar."
                })
            }

        print("Intentando conectar a la base de datos...")
        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()
        print("Conexión establecida con éxito.")

        for asistencia in asistencias:
            p_id_asistencia = asistencia.get('id_asistencia')
            p_estado = asistencia.get('estado')
            p_observaciones = asistencia.get('observaciones')

            print(f"Procesando asistencia: ID={p_id_asistencia}, Estado={p_estado}, Observaciones={p_observaciones}")

            if not p_id_asistencia or not p_estado:
                print("Error: Falta ID de asistencia o estado en uno de los registros.")
                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "Faltan parámetros requeridos en una de las asistencias."
                    })
                }

            print("Ejecutando procedimiento almacenado:", MODIFICAR_ASISTENCIA_PROC)
            cursor.callproc(MODIFICAR_ASISTENCIA_PROC, [p_id_asistencia, p_estado, p_observaciones])
            print("Procedimiento ejecutado correctamente para ID:", p_id_asistencia)

        print("Confirmando cambios en la base de datos...")
        connection.commit()
        print("Cambios confirmados correctamente.")

        response = {
            "statusCode": 200,
            "body": json.dumps({
                "status": SUCCESS,
                "message": "Asistencias actualizadas correctamente."
            })
        }
        print("Respuesta enviada:", response)
        return response

    except Error as e:
        print("Error al modificar asistencia:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al modificar las asistencias."
            })
        }
        return response

    finally:
        if cursor:
            print("Cerrando cursor...")
            cursor.close()
        if connection:
            print("Cerrando conexión con la base de datos...")
            connection.close()
        print("Lambda finalizada.")
