#include <string.h>
#include <stdio.h>

#define SECOND_GRP "SiteOP"

int main(int argc, char **argv) {
  FILE *fp;
  FILE *fw;
  FILE *fa;
  char buf[1024];
  char newline[1024];
  char searchstr[256];
  char group[128];
  int already_written = 0;

  if (argc != 4) {
    printf("Usage: %s <source file> <group> <pre_path>\n", argv[0]);
    return 1;                       
  }
  if ((fp = fopen(argv[1], "r")) == NULL) {
    printf("Error opening file %s for reading\n", argv[1]);
    return 1;
  }
   if ((fw = fopen(argv[1], "r+")) == NULL) {
    printf("Error opening file %s for writing\n", argv[1]);
    return 1;                       
  }
  strcpy(group, argv[2]);
  strcpy(newline, "privpath ");
  strcat(newline, argv[3]);
  strcpy(searchstr, newline);
  if (newline[strlen(newline)-1] != '/') {
    strcat(newline, "/");
  }
  strcat(newline, group);
  strcat(newline, "                       =");
  strcat(newline, group);
  strcat(newline, " =");
  strcat(newline, SECOND_GRP);
  strcat(newline,"\n");
  while (fgets(buf, sizeof(buf), fp)) {
	  if ((!already_written) && (strstr(buf, searchstr) != NULL)) {
		fputs(newline, fw);
		already_written = 1;
	  }
	  fputs(buf, fw);
  }
  fclose(fp);
  fflush(fw);
  fclose(fw);
  if (already_written == 1) {
	printf("Successfully added the %s dir to %s.\n", group, argv[1]);
  } else {
	printf("Couldn't find a place to add the %s dir to %s.\nAppending %s to its end ...\n", group, argv[1], group);
	fa = fopen(argv[1], "a");
	fputs(newline, fa);
	printf("Successfully appended %s as the first pre dir to %s.\n", group, argv[1]);
        fflush(fa);
        fclose(fa);
  }  
  return 0;
}

