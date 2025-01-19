<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

define("SUCCESS", "SUCCESS");
define("FAILED", "FAILED");

$uploadDir = __DIR__ . '/IMG/';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        "status" => FAILED,
        "message" => "Solo se permiten solicitudes POST."
    ]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['nombre']) || !isset($data['imgb64'])) {
    echo json_encode([
        "status" => FAILED,
        "message" => "Faltan parámetros. Se requieren 'nombre' e 'imgb64'."
    ]);
    exit;
}

$nombre = preg_replace("/[^a-zA-Z0-9_-]/", "_", $data['nombre']);
$imgb64 = $data['imgb64'];

if (preg_match("/^data:image\/(jpeg|png);base64,/", $imgb64, $matches)) {
    $extension = $matches[1];
    $imgb64 = str_replace(" ", "+", preg_replace("/^data:image\/(jpeg|png);base64,/", "", $imgb64));

    $fileName = $nombre . "." . $extension;
    $filePath = $uploadDir . $fileName;

    if (file_put_contents($filePath, base64_decode($imgb64))) {
        echo json_encode([
            "status" => SUCCESS,
            "message" => "Imagen guardada con éxito.",
            "path" => "https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=" . $fileName
        ]);
    } else {
        echo json_encode([
            "status" => FAILED,
            "message" => "Error al guardar la imagen."
        ]);
    }
} else {
    echo json_encode([
        "status" => FAILED,
        "message" => "El formato de la imagen no es válido. Se aceptan jpeg y png."
    ]);
}
?>
