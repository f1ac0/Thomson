# Thomson-MEMO7
A multi-ROM Memo7 for the TO7 computer.
- 32x 16k banks
- 32k and 64k using bank switching
- 3D printed case

# Disclaimer and Acknowledgements
This is a hobbyist project, it comes with no warranty and no support. Also remember that the Commodore machines are about 40 years old and may fail because of such hardware expansions.

I publish my work under the CC-BY-NC-SA license, unless stated otherwise. Thanks to everyone who share their knowledge and creations.

# Inspired by
- https://dcmoto.pages-perso.free.fr/bricolage/memo7/index.html
- https://forum.system-cfg.com/viewtopic.php?f=10&t=7086
- https://www.thingiverse.com/thing:5231941
Thanks !

# Making it
- Install the DIP switch so that the switches are closed when the lever is LOW
- Check for shorts at least between 5V, and GND traces before applying power! Also check that R4 and R5 are not shorted : if they are then the pins of the ROM socket are shorted to the nearby 5V pin and setting A17/A18 switch to LOW will short 5V to ground!

To prepare the ROM image,
- select 16k, 32k and 64k files to fill the 512k ROM chip and decide their order in the ROM,
- for 32k and 64k files, make sure they will start respectively on 32k and 64k boundaries,
- for 4k and 8k file, duplicate them 4 times and 2 times respectively,
- for files that are shorter than 16k, pad them up to the full size,
- concatenate them into one single file,
- burn the file into the EEPROM.

For example on linux : cat 16krom.m7 4krom.m7 4krom.m7 4krom.m7 4krom.m7 32krom.m7 64krom.m7 (...) >romfile

I suggest to print the content of the ROM with the correct switch placement to remember it later:
- LLLLLHH 16krom
- LLLLHHH 4krom
- LLLHHLH 32krom
- LLHHHLL 64krom
- ...

# Using it
Choose the ROM while the system is powered down.
- To select a 16k ROM, dial its address on the A14 to A18 switches. Set the 32k and 64k switches UP.
- To select a 32K ROM, dial its address on the A15 to A18 switches. Set A14 UP and 32k LOW.
- To select a 64K ROM, dial its address on the A16 to A18 switches. Set A14 and A15 UP then 32k and 64k LOW.

Make sure to always set A14 UP when 32K is LOW, and A15 UP when 64k is LOW: failing to do so and setting them LOW at the same time will short to ground the outputs of the 74LS173 and may damage them.

