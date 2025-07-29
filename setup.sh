#!/bin/bash
set -e

# Verificar privilegios
if [[ "$EUID" -ne 0 ]]; then
  echo "Ejecutar como root"
  exit 1
fi

# Habilitar SPI y X11 (Wayland desactivado por compatibilidad con xinput_calibrator)
raspi-config nonint do_spi 0
#raspi-config nonint do_wayland 0

# Modificar /boot/firmware/config.txt
sed -i 's/^dtoverlay=vc4-kms-v3d/#dtoverlay=vc4-kms-v3d/' /boot/firmware/config.txt
sed -i 's/^dtoverlay=vc4-fkms-v3d/#dtoverlay=vc4-fkms-v3d/' /boot/firmware/config.txt

if ! grep -q "dtoverlay=piscreen" /boot/firmware/config.txt; then
  echo "dtoverlay=piscreen,speed=18000000,drm" >> /boot/firmware/config.txt
fi

# Instalar paquetes necesarios
apt-get update
apt-get install -y xserver-xorg-input-evdev xinput-calibrator

# Crear archivo de configuración táctil
mkdir -p /etc/X11/xorg.conf.d

# Mover archivo evdev y reconfigurarlo
if [ -f /usr/share/X11/xorg.conf.d/10-evdev.conf ]; then
  mv /usr/share/X11/xorg.conf.d/10-evdev.conf /usr/share/X11/xorg.conf.d/45-evdev.conf
fi

# Escribir configuración táctil
cat > /usr/share/X11/xorg.conf.d/45-evdev.conf <<EOF
Section "InputClass"
    Identifier "evdev touchscreen catchall"
    MatchIsTouchscreen "on"
    MatchDevicePath "/dev/input/event*"
    Driver "evdev"
    Option "SwapAxes" "true"
    Option "InvertX" "false"
    Option "InvertY" "true"
EndSection
EOF

# Final
echo ""
echo "Instalación completada."
echo "Reiniciá tu Raspberry Pi para aplicar los cambios:"
echo ""
echo "calibrá el táctil con:"
echo ""
echo "DISPLAY=:0.0 xinput_calibrator"
echo ""
echo "Si el touch está mal configurado. Debes modificar evdev.conf"
echo ""
echo "nano /usr/share/X11/xorg.conf.d/45-evdev.conf"
echo ""
echo 'Cambiar Option "SwapAxes","InvertX","InvertY" entre true y false'
echo ""
echo "¿Deseás reiniciar ahora? (S/n)"
read respuesta

if [[ "$respuesta" =~ ^[Ss]$ || "$respuesta" == "" ]]; then
  echo "Reiniciando..."
  reboot
else
  echo "Reiniciar manualmente luego con: sudo reboot"
fi
