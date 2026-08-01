# Thomson-SDDRIVE-MusiqueJeu
This is an expansion combining the SX90-018 "Contrôleur d'extensions modèle 2" that provides a 6 bit DAC for sound and two DB9 joystick ports and the SDDRIVE that emulates a floppy disk controller. The logic is integrated inside a XC9572XL CPLD and using SMD components to reduce size.

Warning : the two joystick ports use an "Atari" pinout and not the specific thomson-only pinout of the original expansion. Make sure to use standard controllers and not Thomson ones if you own any (I dont). 5V is present so you may use powered controllers, but make sure to use limited power to preserve your host PSU and motherboard.

# Disclaimer and Acknowledgements
This is a hobbyist project, it comes with no warranty and no support. Also remember that the Thomson machines are about 40 years old and may fail because of such hardware expansions.

The author of SDDRIVE keeps the intellectual property of his work and gracefully shares his degigns and agrees that users change, improve and share them, and forbids commercial use and selling the products. the content inside this folder is published under the same licensing terms.

It is not supported by the author of SDDRIVE, please don't bother him with issues you might have with it.

# From original designs by
- SDDRIVE by Daniel Coulom : https://dcmoto.pages-perso.free.fr/bricolage/sddrive/index.html
- SX90-018 by Thomson, schematics reverse engineered by Daniel Coulom for his SX90-2018 : https://dcmoto.pages-perso.free.fr/bricolage/sx90-2018/index.html
Thanks !

# Making it
Components are SMD, and have thin pin pitch. You need to know what you are doing.

Check for shorts at least between 5V, 3.3V, and GND traces before applying power ! I suggest to first install the CPLD and check its connections, then the PLCC socket and also check its connections, before the SD socket and through holes connectors that will maker rework more difficult.

Make sure to apply insulating tape under the SD socket where the contacts from the socket may touch the PCB. In order to keep the two layer PCB, this was not possible to use no copper zone there.

For the edge connector, I used a 2x21=42 pins connecto because I could not find an 2x19 one. If you do so then make sure to remove the four pins on the edges and insert a small piece of PCB to force the connector to be aligned with the PCB edge when inserted.

The ROM is oversized however easily available. You have to program it with the original sddrive_control.bin using an EEPROM programmer. Pad the end of the file up to a size of 524288 or tell your programmer to only burn the lower bytes since the higher addresses are grounded anyway.

Prepare the SDCARD as explained on the SDDRIVE page.

# Using it
Connect it to your Thomson. When the system is starting, it should show the disk drive menu that will start the selector. See the instructions for SDDRIVE, it should behave the same.

# FD2SD
You can use SD files that are compatible with your system. You will find some on the dcmoto website. You can also convert some .FD disk images.

The DCMOTO emulator provides a FD2SD windows tool, if you use a different system you may use the FD2SD in this repo.

Compile it with "gcc -o fd2sd fd2sd.c" then convert a file with "fd2sd file.fd". Check other usage with "fd2sd -h".


