# Obtener la ruta de la USB automáticamente
$letraUSB = (Get-WMIObject Win32_Volume | Where-Object { $_.DriveType -eq 2 -and $_.Label -eq "KINGSTON" }).DriveLetter

if (-not $letraUSB) {
    Write-Host "No se encontró la USB con etiqueta 'BROMA'"
    exit
}

# Definir rutas de los archivos en la USB
$iconoCalvo = "$letraUSB\calvo.ico"
$fondoCalvo = "$letraUSB\calvo.jpg"
$rutaCursor = "$letraUSB\calvo.cur"
$rutaEscritorio = [System.Environment]::GetFolderPath("Desktop")

# Verificar que los archivos existan
if (-not (Test-Path $iconoCalvo)) {
    Write-Host "No se encontró el archivo de ícono: $iconoCalvo"
    exit
}
if (-not (Test-Path $fondoCalvo)) {
    Write-Host "No se encontró el archivo de fondo: $fondoCalvo"
    exit
}
if (-not (Test-Path $rutaCursor)) {
    Write-Host "No se encontró el archivo de cursor: $rutaCursor"
    exit
}

# Cambiar iconos de accesos directos
$accesosDirectos = Get-ChildItem -Path $rutaEscritorio -Filter "*.lnk"
foreach ($atajo in $accesosDirectos) {
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut($atajo.FullName)
    $lnk.IconLocation = "$iconoCalvo,0"  # Asegura que se use el primer ícono del archivo .ico
    $lnk.Save()
}

# Cambiar ícono de carpetas (modificando el registro)
try {
    # Ruta del registro para íconos de carpetas
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "3" -Value $iconoCalvo  # Ícono de carpetas
    Write-Host "Ícono de carpetas cambiado exitosamente."
}
catch {
    Write-Host "Error al cambiar el ícono de carpetas: $_"
}

# Cambiar ícono de la papelera (modificando el registro)
try {
    # Ruta del registro para la papelera
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}\DefaultIcon"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value $iconoCalvo  # Ícono de la papelera
    Write-Host "Ícono de la papelera cambiado exitosamente."
}
catch {
    Write-Host "Error al cambiar el ícono de la papelera: $_"
}

# Cambiar fondo de pantalla
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
[Wallpaper]::SystemParametersInfo(20, 0, $fondoCalvo, 3)

# Cambiar el cursor del sistema
try {
    # Establece el cursor en el archivo especificado
    Set-ItemProperty -Path "HKCU:\Control Panel\Cursors\" -Name "Arrow" -Value $rutaCursor
    Set-ItemProperty -Path "HKCU:\Control Panel\Cursors\" -Name "IBeam" -Value $rutaCursor
    Set-ItemProperty -Path "HKCU:\Control Panel\Cursors\" -Name "Wait" -Value $rutaCursor
    Set-ItemProperty -Path "HKCU:\Control Panel\Cursors\" -Name "Hand" -Value $rutaCursor
    Set-ItemProperty -Path "HKCU:\Control Panel\Cursors\" -Name "AppStarting" -Value $rutaCursor

    # Notifica al sistema que el cursor ha cambiado
    $signature = @"
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uiAction, int uiParam, ref string pvParam, int fWinIni);
"@
    $systemParametersInfo = Add-Type -MemberDefinition $signature -Name "Win32SystemParametersInfo" -Namespace Win32Functions -PassThru
    $systemParametersInfo::SystemParametersInfo(0x0057, 0, [ref]$null, 3) | Out-Null

    Write-Host "Cursor cambiado exitosamente."
}
catch {
    Write-Host "Error al cambiar el cursor: $_"
}

# Reiniciar el Explorador de Windows para aplicar los cambios
Stop-Process -Name explorer -Force
Start-Process explorer

Write-Host "Broma ejecutada. 😈 El escritorio, el fondo, el cursor y los íconos han cambiado."