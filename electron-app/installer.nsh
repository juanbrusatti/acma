; Script NSIS personalizado para ACMA
; Este script se ejecuta durante la instalación

!include "LogicLib.nsh"
!include "WinVer.nsh"

; Función para verificar si Docker está instalado
Function CheckDockerInstalled
  ; Verificar si Docker Desktop está instalado
  ReadRegStr $0 HKLM "SOFTWARE\Docker Inc.\Docker\1.0" "InstallPath"
  ${If} $0 == ""
    ; Verificar en HKCU también
    ReadRegStr $0 HKCU "SOFTWARE\Docker Inc.\Docker\1.0" "InstallPath"
  ${EndIf}

  ${If} $0 == ""
    ; Docker no está instalado
    StrCpy $R0 "0"
  ${Else}
    ; Docker está instalado
    StrCpy $R0 "1"
  ${EndIf}
FunctionEnd

; Función personalizada que se ejecuta antes de la instalación
Function .onInit
  ; Verificar que sea Windows 10 o superior
  ${IfNot} ${AtLeastWin10}
    MessageBox MB_OK|MB_ICONSTOP "Esta aplicación requiere Windows 10 o superior."
    Abort
  ${EndIf}

  ; Verificar privilegios de administrador
  UserInfo::GetAccountType
  Pop $0
  ${If} $0 != "admin"
    MessageBox MB_OK|MB_ICONSTOP "Se requieren privilegios de administrador para instalar esta aplicación."
    Abort
  ${EndIf}
FunctionEnd

; Sección personalizada que se ejecuta durante la instalación
Section "VerificarDependencias" SEC_DEPS
  DetailPrint "Verificando dependencias del sistema..."

  ; Verificar Docker
  Call CheckDockerInstalled
  ${If} $R0 == "0"
    DetailPrint "Docker Desktop no está instalado."

    ; Preguntar al usuario si quiere instalar Docker
    MessageBox MB_YESNO|MB_ICONQUESTION "Docker Desktop no está instalado. ¿Desea descargarlo e instalarlo ahora?" IDYES InstallDocker IDNO SkipDocker

    InstallDocker:
      DetailPrint "Abriendo página de descarga de Docker Desktop..."
      ExecShell "open" "https://www.docker.com/products/docker-desktop/"

      MessageBox MB_OK|MB_ICONINFORMATION "Se ha abierto la página de descarga de Docker Desktop. Por favor instale Docker y luego ejecute esta aplicación."

      ; Crear un archivo de recordatorio en el escritorio
      FileOpen $0 "$DESKTOP\IMPORTANTE - Instalar Docker.txt" w
      FileWrite $0 "IMPORTANTE: Completar instalación de ACMA$\r$\n"
      FileWrite $0 "==========================================$\r$\n$\r$\n"
      FileWrite $0 "Para que ACMA funcione correctamente, necesitas:$\r$\n$\r$\n"
      FileWrite $0 "1. Instalar Docker Desktop$\r$\n"
      FileWrite $0 "2. Reiniciar la computadora si Docker lo solicita$\r$\n"
      FileWrite $0 "3. Asegurarte de que Docker Desktop esté funcionando$\r$\n"
      FileWrite $0 "4. Ejecutar ACMA desde el acceso directo del escritorio$\r$\n$\r$\n"
      FileWrite $0 "ACMA se ha instalado en: $INSTDIR$\r$\n$\r$\n"
      FileClose $0

      Goto EndDockerCheck

    SkipDocker:
      DetailPrint "Instalación de Docker omitida por el usuario."
      MessageBox MB_OK|MB_ICONWARNING "ADVERTENCIA: ACMA requiere Docker Desktop para funcionar."
  ${Else}
    DetailPrint "Docker Desktop está instalado."
  ${EndIf}

  EndDockerCheck:

SectionEnd

; Función que se ejecuta después de la instalación
Function .onInstSuccess
  DetailPrint "Instalación completada exitosamente."

  ; Verificar nuevamente si Docker está instalado
  Call CheckDockerInstalled
  ${If} $R0 == "0"
    ; Mostrar mensaje final con instrucciones
    MessageBox MB_OK|MB_ICONINFORMATION "ACMA se ha instalado correctamente! Recuerda instalar Docker Desktop para que funcione."
  ${Else}
    MessageBox MB_OK|MB_ICONINFORMATION "ACMA se ha instalado correctamente! Puedes ejecutar la aplicación desde el acceso directo del escritorio."
  ${EndIf}
FunctionEnd