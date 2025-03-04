import mysql.connector
from mysql.connector import Error
import json
import resend
from constants import DB_CONFIG, SUCCESS, FAILED

RECOVERY_PROC = "GenerarCodigoRecuperacion"

resend.api_key = "re_GFjFpLT7_AEumKvm1WQHzz79UwANDyikW"

import resend

def send_email_via_resend(email, code):
    try:
        response = resend.Emails.send({
            "from": "no-reply@focusclass.xyz",
            "to": email if isinstance(email, list) else [email],
            "subject": "Código de Recuperación de Cuenta - FocusClass",
            "html": f"""
                <div style="font-family: Arial, sans-serif; padding: 20px; background-color: #D9D9D9; border: 1px solid #ccc; border-radius: 10px; max-width: 600px; margin: 0 auto;">
                    <div style="background: linear-gradient(to right, #5155A6, #4B7DBF); 
                        text-align: center; 
                        border-radius: 10px; 
                        padding: 20px;">
                        
                        <table align="center" style="margin: 0 auto;">
                            <tr>
                                <td style="text-align: center; padding: 10px;">
                                    <img src="https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=icon_focusclass" 
                                         alt="FocusClass Logo" 
                                         style="height: 55px; display: inline-block; vertical-align: middle; margin-right: 10px;">
                                    <h1 style="color: #fff; font-size: 2em; display: inline-block; vertical-align: middle; margin: 0;">FocusClass</h1>
                                </td>
                            </tr>
                        </table>
                        
                        <h2 style="color: #fff; margin: 0; padding: 10px;">Recuperación de Cuenta</h2>
                    </div>
                    
                    <p style="font-size: 16px; color: #333;">Hola,</p>
                    <p style="font-size: 16px; color: #333;">Hemos recibido una solicitud para recuperar tu cuenta en <strong>FocusClass</strong>. Aquí tienes tu código de recuperación:</p>
                    
                    <div style="text-align: center; margin: 20px 0;">
                        <span style="display: inline-block; background-color: #4B7DBF; color: #fff; padding: 10px 20px; border-radius: 5px; font-size: 20px; font-weight: bold;">{code}</span>
                    </div>
                    
                    <p style="font-size: 16px; color: #333;">Si no has solicitado la recuperación de tu cuenta, por favor ignora este correo.</p>
                    <p style="font-size: 16px; color: #333;">Gracias,</p>
                    <p style="font-size: 16px; color: #333;">El equipo de FocusClass</p>
                </div>
            """,
            "text": f"""
                    Hola,

                    Hemos recibido una solicitud para recuperar tu cuenta en FocusClass. Aquí tienes tu código de recuperación:

                    Código: {code}

                    Si no has solicitado la recuperación de tu cuenta, por favor ignora este correo.

                    Gracias,
                    El equipo de FocusClass
                    """
        })
        
        if response.get('error'):
            print("Error al enviar el correo:", str(response))
            return False
        else:
            print("Correo enviado con éxito. ID del mensaje:", response.get('id'))
            return True

    except Exception as e:
        print("Error al enviar el correo:", str(e))
        return False

def lambda_handler(event, context):
    connection = None
    cursor = None
    response = None

    print("Evento recibido:", event)

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        email = body.get('email')

        if not email:
            response = {
                "statusCode": 400,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "Es necesario proporcionar el correo electrónico."
                })
            }
            return response

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        print(f"Llamando al procedimiento {RECOVERY_PROC} con email: {email}")
        cursor.callproc(RECOVERY_PROC, [email])

        for result in cursor.stored_results():
            response_row = result.fetchone()
            if response_row:
                status = response_row[0]
                if status == SUCCESS:
                    recovery_code = response_row[1]
                    print("Código de recuperación generado:", recovery_code)

                    email_sent = send_email_via_resend(email, recovery_code)

                    if email_sent:
                        response = {
                            "statusCode": 200,
                            "body": json.dumps({
                                "status": SUCCESS,
                                "message": "El código de recuperación ha sido enviado a su correo electrónico."
                            })
                        }
                        connection.commit()
                        return response
                    else:
                        raise Exception("Error al enviar el correo electrónico.")

                else:
                    response = {
                        "statusCode": 404,
                        "body": json.dumps({
                            "status": FAILED,
                            "message": "El correo electrónico proporcionado no está registrado."
                        })
                    }
                    return response

    except Error as db_error:
        print("Error en la base de datos:", str(db_error))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Error en la base de datos. Intente más tarde."
            })
        }
    except Exception as e:
        print("Error general:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error inesperado. Intente más tarde."
            })
        }
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
        print("Respuesta final:", response)
        return response
