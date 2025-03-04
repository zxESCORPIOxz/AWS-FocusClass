from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json

# Nombre del procedimiento almacenado
MODIFICAR_NOTAS_PROC = "ModificarNotas"

def lambda_handler(event, context):
    connection = None
    cursor = None

    try:
        # Parsear los datos de entrada
        body = json.loads(event['body']) if 'body' in event else {}
        token = body.get('token')
        notas = body.get('notas', [])  # Array de notas a actualizar

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

        print("Token válido. Actualizando notas...")

        # Validar que el array de notas no esté vacío
        if not notas:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "El arreglo de notas está vacío."
                })
            }

        # Conexión a la base de datos
        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        # Iterar sobre las notas y llamar al procedimiento almacenado
        for nota in notas:
            id_nota_alumno_curso = nota.get('id_nota_alumno_curso')
            nueva_nota = nota.get('nueva_nota')

            if id_nota_alumno_curso is None or nueva_nota is None:
                print("Nota inválida:", nota)
                continue

            print(f"Actualizando nota: ID={id_nota_alumno_curso}, Nueva Nota={nueva_nota}")
            cursor.callproc(MODIFICAR_NOTAS_PROC, [id_nota_alumno_curso, nueva_nota])

        connection.commit()

        return {
            "statusCode": 200,
            "body": json.dumps({
                "status": SUCCESS,
                "message": "Las notas se actualizaron correctamente."
            })
        }

    except Error as e:
        print("Error al actualizar notas:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al actualizar las notas."
            })
        }

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
