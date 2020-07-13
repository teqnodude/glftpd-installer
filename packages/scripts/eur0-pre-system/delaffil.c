#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#define SECOND_GRP "SiteOP"

int main(int argc, char **argv) {
  FILE *fp;
  FILE *fw;
  char buf[1024];
  char newline[1024];
  char group[128];
  char searchstr[256];
  char ** storage;
  int total_lines_num;
  int lines_num = 0;
  int i;
  int already_written = 0;

  if (argc != 5) {
    printf("Usage: %s <source file> <group> <pre_path> <glftpd_conf_lines_num>\n", argv[0]);
    return 1;                       
  }
  if ((fp = fopen(argv[1], "r")) == NULL) {
    printf("Error opening file %s for reading\n", argv[1]);
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
  total_lines_num = atoi(argv[4]);
  storage = (char **)malloc(total_lines_num * sizeof(char *));  

  while (fgets(buf, sizeof(buf), fp)) {
	  if ((!already_written) && (strstr(buf, group) != NULL) &&
  		 (strstr(buf, searchstr) != NULL) && (strstr(buf, SECOND_GRP) != NULL)) {
		if (fgets(buf, sizeof(buf), fp)) {
			storage[lines_num]=(char *)malloc(strlen(buf)+1);
			strcpy(storage[lines_num], buf);
           		already_written = 1;
		} else {
			already_written = 1;
			break;
		}
	  }
	  else {
                storage[lines_num]=(char *)malloc(strlen(buf)+1);
                strcpy(storage[lines_num], buf);
          }
	  lines_num++;
  }
  fclose(fp);

  if (already_written == 1) {
  	if ((fw = fopen(argv[1], "w")) == NULL) {
    		printf("Error opening file %s for writing\n", argv[1]);
		for(i=0; i<lines_num; i++) {
			free(storage[i]);
		}
		free(storage);
    		return 1;
  	}
  	for(i=0; i<lines_num; i++) {
		fputs(storage[i], fw);
		free(storage[i]);
  	} 
  	free(storage);
  	fflush(fw);
  	fclose(fw);
  	printf("The %s has been updated, group %s has been removed from it.\n", argv[1], group); 
  } else {
	for(i=0; i<lines_num; i++) {
                free(storage[i]);
        }
        free(storage);
	printf("The %s wasn't updated, group %s wasn't found in it.\n", argv[1], group);
  }
  return 0;
}

