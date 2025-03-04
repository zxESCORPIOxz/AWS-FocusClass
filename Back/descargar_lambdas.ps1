# Definir la ruta donde se guardarán las funciones Lambda
$destinationPath = "Z:\Back\AWS FocusClass\Back"

# Crear la carpeta si no existe
if (!(Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath
}

# Obtener todas las funciones Lambda
$functions = aws lambda list-functions --query "Functions[*].FunctionName" --output json | ConvertFrom-Json

# Recorrer cada función y descargar su código
foreach ($function in $functions) {
    $zipFile = "$destinationPath\$function.zip"
    Write-Output "Descargando: $function"
    
    # Obtener la URL de descarga
    $downloadUrl = aws lambda get-function --function-name $function --query 'Code.Location' --output text

    # Verificar si la URL es válida
    if ($downloadUrl -match "^https://") {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile
        Write-Output "✅ $function descargado con éxito"
    } else {
        Write-Output "❌ Error al obtener la URL de $function"
    }
}

Write-Output "🚀 Descarga completa. Todas las funciones están en $destinationPath"
