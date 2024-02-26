/****************************************************************
 *
 * TUrranius LS (tuls) Version 1.0 in the year of the devil (2004)
 *
 * Just for scripting. Fun all the way. Keep the spirit and dont
 * let the lamers get to you *ARGHADFAlaAmeRyoDusFucHkHHHH*
 *
 * signin' off. /cruxis
 *
 * ps. no pants production ds.
 *
 ******************************
 *
 * Arguments should be a directory name. Or delimiter AND a dir name.
 * E.g. tuls :::: /tmp   or   tuls /tmp   or   tuls
 *
 * Output as follows (and dont use trailing / as input dir.)
 * (spaces in ctime date output is replaced by ^ signs)
 *
 * permissions[DELIMITER]uid[DELIMITER]gid[DELIMITER]filename[DELIMITER]ctime^seconds since flower power
 *
 ****************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <string.h>
#include <dirent.h>
#include <sys/sysmacros.h>
#include <ctype.h>
#ifndef PATHMAX
#define PATHMAX 255
#endif

#define _XOPEN_SOURCE 500 
#define DEFAULT_DELIMITER "::::"

char *typeoffile(mode_t);  /* need mode_t to use st_mode */
char *permoffile(mode_t);
char cwd[PATHMAX + 1];
char delimiter[PATHMAX +1];

void outputstatinfo(char *, struct stat *,char *);
void arglist(const char *dir);


static inline char *
mytrim (char *str)
{
        char *p = str;
        char *m = strdup(str);
        while (*m) {

          if (isspace(*m))
          {
            m++;
            if (isspace(*m))
              m++;
            *p = '^';
          }
          else
          {
            *p = *m;
            m++;
          }

          p++;
        }

        *p-- = 0;
        *p=0;
        return str;
}


int main(int argc, char *argv[]) {
  if(argc <2)
  {
     if(getcwd(cwd, PATHMAX) == NULL) {
       perror("Couldnt get directory");
       exit(1);
     }
     strcpy(delimiter,DEFAULT_DELIMITER);
     arglist(cwd);
  }
  else if(argc == 2) {
    printf("Listing contents of %s\n", argv[1]);
    strcpy(delimiter,DEFAULT_DELIMITER);
    arglist(argv[1]);
  }
  else if(argc == 3) {
    strcpy(delimiter,argv[1]);
    arglist(argv[2]);
  }
  return 0;
}

void arglist(const char *dir)
{
   DIR *dirp;
   struct dirent *direntp;
   char *filename;
   char *filenameshort;

   struct stat st;


   if((dirp=opendir(dir)) == NULL) {
     fprintf(stderr, "Could not open %s directory: %s\n",
             dir, strerror(errno));
     exit(1);
   }

   while((direntp=readdir(dirp)) != NULL) {

     /* build the full name */
     filename = malloc((strlen(dir) + strlen(direntp->d_name) + 2) * sizeof(char));
     filenameshort = malloc((strlen(direntp->d_name) +1)*sizeof(char));
     sprintf(filename, "%s/%s", dir, direntp->d_name);
     sprintf(filenameshort, "%s",direntp->d_name);     

     if(lstat(filename,&st) < 0) {
       free(filename);
       free(filenameshort);
       continue;
     }
     outputstatinfo(filename,&st,filenameshort);
     free(filename);
     free(filenameshort);
   }

   closedir(dirp);
   exit(0);
}

char *  typeoffile(mode_t mode)
{
   switch(mode & S_IFMT) {
          case S_IFREG:
                       return("-");
          case S_IFDIR:
                       return("d");
          case S_IFCHR:
                       return("c");
          case S_IFBLK:
                       return("b");
          case S_IFLNK:
                       return("l");
          case S_IFIFO:
                       return("f");
          case S_IFSOCK:
                       return("s");
    }
  return "-";
}


void outputstatinfo(char *filename, struct stat *st, char *filenameshort) {
  printf("%s%s%s%d%s%d%s%s%s%s^%d\n",typeoffile(st->st_mode),permoffile(st->st_mode),delimiter,st->st_uid,delimiter,st->st_gid,delimiter,filenameshort,delimiter,mytrim(ctime(&st->st_mtime)),(int)st->st_mtime);
 }
   /* OK LAST BUT NOT LEAST OUR "permoffile()" function. */
   char *
   permoffile(mode_t mode)
   {
      int i;
      char *p;
      static char perms[10];

      p = perms;
      strcpy(perms, "---------");

        /*
         * Being the bits are three sets of three bits:
         * User - read/write/exec, group - read/write/exec
         * other - read/write/exec. Will deal with each set
         * of three bits in a pass through the loop.
         */

        for(i=0;i<3;i++) {
           if(mode &(S_IREAD>>i*3))
             *p='r';
         p++;

            if(mode &(S_IWRITE>>i*3))
                  *p='w';
             p++;

               if(mode &(S_IEXEC>>i*3))
                  *p='x';
               p++;
         }

                // now

        if((mode & S_ISUID) != 0)
           perms[2] = 's';

        if((mode & S_ISGID) != 0)
           perms[5] = 's';

        if((mode & S_ISVTX) != 0)
           perms[8] = 't';

      return(perms);
}
