#define VER     "4.0 (GL2.01+)"
#define KEY	0x0000DEAD   // Default KEY used by DAEMON
#define GLGROUP "/glftpd/etc/group"

#include <stdio.h>	/* printf, sprintf */
#include <stdlib.h>	/* exit, free, atoi */
#include <string.h>	/* strncasecmp, strerror, strcpy, strstr */
#include <sys/time.h>	/* gettimeofday */
#include <time.h>	/* time */
#include <errno.h>	/* errno */
#include <ctype.h>	/* isspace */
#include <sys/types.h>	/* shmat, shmdt, open, fstat */
#include <sys/ipc.h>	/* shmget, shmctl */
#include <sys/shm.h>	/* shmget, shmat, shmdt, shmctl, IPC_STAT, IPC_RMID, SHM_RDONLY, struct shmid_ds */
#include <unistd.h>	/* read, close, fstat */
#include <fcntl.h>	/* open, O_NONBLOCK */
#include <sys/stat.h>	/* fstat, open */
#include <inttypes.h>	/* uint64_t */

/* Begin copy from glconf.h */
/* Force structure alignment to 4 bytes (for 64bit support). */
#pragma pack(push, 4)

/* 32-bit time values (for 64bit support). */
typedef int32_t time32_t;

typedef struct {
    int32_t     tv_sec;
    int32_t     tv_usec;
} timeval32_t;

struct ONLINE {
  char        tagline[64];     /* The users tagline */
  char        username[24];    /* The username of the user */
  char        status[256];     /* The status of the user, idle, RETR, etc */
  int16_t     ssl_flag;        /* 0 = no ssl, 1 = ssl on control, 2 = ssl on control and data */
  char        host[256];       /* The host the user is comming from (with ident) */
  char        currentdir[256]; /* The users current dir (fullpath) */
  int32_t     groupid;         /* The groupid of the users primary group */
  time32_t    login_time;      /* The login time since the epoch (man 2 time) */
  timeval32_t tstart;          /* replacement for last_update. */
  timeval32_t txfer;           /* The time of the last succesfull transfer. */
  uint64_t    bytes_xfer;      /* bytes transferred so far. */
  uint64_t    bytes_txfer;     /* bytes transferred in the last loop (speed limiting) */
  int32_t     procid;          /* The processor id of the process */
};

/* Restore default structure alignment for non-critical structures. */
#pragma pack(pop)
/* End copy from glconf.h */

static struct ONLINE *online;
static int num_users = 0;
static int shmid;
static struct shmid_ds ipcbuf;

struct GROUP {
  char *name;
  int32_t id;
};

int groups = 0,	GROUPS = 0;

static struct GROUP **group;

char *
get_g_name(int32_t gid)
{
  int n;

  for (n = 0; n < groups; ++n)
    if (group[n]->id == gid)
      return group[n]->name;

  return "NoGroup";
}

static char *
trim(char *str)
{
  char *ibuf;
  char *obuf;

  if (str)
  {
    for (ibuf = obuf = str; *ibuf;)
    {
      while (*ibuf && isspace(*ibuf))
        ibuf++;
      if (*ibuf && obuf != str)
        *(obuf++) = ' ';
      while (*ibuf && !isspace(*ibuf))
        *(obuf++) = *(ibuf++);
    }
    *obuf = '\0';
  }
  return str;
}

static double
calc_time(int pid)
{
  struct timeval tstop;
  double delta, rate;

  if (online[pid].bytes_xfer < 1)
    return 0;
  gettimeofday(&tstop, NULL);
  delta = ((tstop.tv_sec*10.)+(tstop.tv_usec/100000.)) -
         ((online[pid].tstart.tv_sec*10.)+(online[pid].tstart.tv_usec/100000.));
  delta = delta/10.;
  rate = ((online[pid].bytes_xfer / 1024.0) / (delta));
  if (!rate)
    ++rate;
  return rate;
}

static void
checkusers(void)
{
  int i;
  char statbuf[500];
  char idletime[500];
  struct timeval tstop;

  gettimeofday(&tstop, NULL);

  for (i = 0; i < num_users; ++i)
  {
    if (online[i].procid == 0)
      continue;

    /* Uploading */
    if ((!strncasecmp(online[i].status, "STOR", 4) ||
        !strncasecmp(online[i].status, "APPE", 4)) &&
        online[i].bytes_xfer != 0)
    {
      sprintf(statbuf, "Up:^%.1f", calc_time(i));
      idletime[0] = '\0';
    }
    /* Downloading */
    else if (!strncasecmp(online[i].status, "RETR", 4) && online[i].bytes_xfer != 0)
    {
      sprintf(statbuf, "Dn:^%.1f", calc_time(i));
      idletime[0] = '\0';
    }
    /* Idling */
    else if (time(NULL) - online[i].tstart.tv_sec > 5)
    {
      int32_t hours = 0;
      int32_t minutes = 0;
      int32_t seconds = tstop.tv_sec - online[i].tstart.tv_sec;
      while (seconds >= 3600)
      {
        ++hours;
        seconds -= 3600;
      }
      while (seconds >= 60)
      {
        ++minutes;
        seconds -= 60;
      }
      sprintf(statbuf, "Idle:");
      sprintf(idletime, "%02d:%02d:%02d", hours, minutes, seconds);
    }
    /* Doing something else... */
    else
    {
      sprintf(statbuf, "\"%s\"", online[i].status);
      trim(statbuf);
      idletime[0] = '\0';
    }

    printf("%-1s^%-1u^%-1.44s^%-1s^%-1s^%s\n",
           online[i].username, online[i].procid, statbuf, online[i].currentdir, get_g_name(online[i].groupid), idletime);
    }
}

static void
quit(int exit_status)
{
  shmctl(shmid, IPC_STAT, &ipcbuf);
  if (ipcbuf.shm_nattch <= 1)
    shmctl(shmid, IPC_RMID, 0);
  shmdt(0);
  exit(exit_status);
}

/* Buffer groups file */
void
buffer_groups(char *groupfile)
{
  char	*f_buf, *g_name;
  long	f, n, m, g_n_size, l_start = 0;
  int32_t g_id;
  off_t f_size;
  struct stat filestat;

  f = open(groupfile, O_NONBLOCK);
  fstat(f, &filestat);
  f_size = filestat.st_size;
  f_buf = malloc(f_size);
  if (read(f, f_buf, f_size) < 0)
  {
    printf("Error occured while reading %s: %s", groupfile, strerror(errno));
    if (f_buf) free(f_buf);
    close(f);
    quit(0);
  }
  close(f);

  for (n = 0; n < f_size; ++n)
    if (f_buf[n] == '\n')
      ++GROUPS;
  group = malloc(GROUPS * sizeof(*group));

  for (n = 0; n < f_size; ++n)
  {
    if (f_buf[n] == '\n' || n == f_size)
    {
      f_buf[n] = 0;
      m = l_start;
      while (f_buf[m] != ':' && m < n)
        ++m;
      if (m != l_start)
      {
        f_buf[m] = 0;
        g_name = f_buf + l_start;
        g_n_size = m - l_start;
        m = n;
        while (f_buf[m] != ':' && m > l_start)
          --m;
        f_buf[m] = 0;
        while (f_buf[m] != ':' && m > l_start)
          --m;
        if (m != n)
        {
          g_id = atoi(f_buf + m + 1);
          group[groups] = malloc(sizeof(struct GROUP));
          group[groups]->name = malloc(g_n_size + 1);
          strcpy(group[groups]->name, g_name);
          group[groups]->id = g_id;
          ++groups;
        }
      }
      l_start = n + 1;
    }
  }

  if (f_buf) free(f_buf);
}

int
main(int argc, char **argv)
{
  if (argc >= 2 && strstr(argv[1],"-v") != NULL)
  {
    printf("Tur-FtpWho. A modified ftpwho by Turranius\n");
    printf("Version %s - modified by f|lowman and fixed for 64bit and cleaned up by Sked.\n", VER);
    quit(0);
  }

  buffer_groups(GLGROUP);

  if ((shmid = shmget((key_t)KEY, 0, 0)) == -1)
  {
    printf("No Users Currently On Site!\n");
    quit(0);
  }

  if ((online = (struct ONLINE *)shmat(shmid, NULL, SHM_RDONLY)) == (struct ONLINE *)-1)
  {
    printf("Error: (SHMAT) Failed!\n");
    quit(1);
  }

  shmctl(shmid, IPC_STAT, &ipcbuf);
  num_users = ipcbuf.shm_segsz / sizeof(struct ONLINE);

  checkusers();

  quit(0);
}

