CC = gcc
RM = rm -f
CP = cp
GLPATH = /glftpd/bin
MAKE = make

CCFLAGS = -O2 -Wall

all: 	clean compile

compile:
		${CC} ${CCFLAGS} -o addaffil addaffil.c
		${CC} ${CCFLAGS} -o delaffil delaffil.c

clean:
	$(RM) addaffil delaffil

install:
	@ echo "Copying the compiled files to ${GLPATH} ..."
	${CP} addaffil ${GLPATH}
	${CP} delaffil ${GLPATH}
	@ echo "Done."
	@ echo "Copy pre.sh addaffil.sh delaffil.sh listaffils.sh to /glftpd/bin and edit them."
	@ echo "Add addaffil.sh, delaffil.sh, listaffils.sh to be custom glftpd commands."
	@ echo "Set your sitebot to announce pres logged by pre.sh and to show affils using listaffils.sh"
	@ echo "All the installation information is located in the README file, please read it."
	@ echo "Enjoy!"
