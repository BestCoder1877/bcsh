#include <dirent.h>
#include <libgen.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>

void ls(char *dir) {
  DIR *directory = opendir(dir);

  if (directory != NULL) {
    struct dirent *entry;

    while ((entry = readdir(directory)) != NULL) {
      if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0)
        printf("%s\r\n", entry->d_name);
    }

    closedir(directory);
    return;
  }

  FILE *file = fopen(dir, "r");

  if (file != NULL) {
    printf("%s\r\n", basename(dir));
    fclose(file);
  } else {
    printf("No such file or directory\r\n");
  }
}

void cat(char *file) {
  DIR *directory = opendir(file);
  if (directory != NULL) {
    printf("You cannot cat a directory\n");
    return;
  }
  closedir(directory);
  FILE *thefile = fopen(file, "r");

  if (thefile == NULL) {
    printf("No such file or directory\r\n");
    return;
  } else {
    int thechar;
    while ((thechar = fgetc(thefile)) != EOF) {
      if (thechar == '\r')
        continue;
      else if (thechar == '\n')
        printf("\r\n");
      else
        putchar(thechar);
    }
  }
  fclose(thefile);
}

void rm(char *file) {
  DIR *directory = opendir(file);
  if (directory != NULL) {
    printf("Use rmdir to delete a directory\r\n");
    return;
  }
  closedir(directory);
  if (remove(file) != 0) {
    printf("No such file or directory\r\n");
  }
}

void thermdir(char *dir) {
  DIR *directory = opendir(dir);

  if (directory == NULL) {
    printf("Use rm to delete a file\n");
    return;
  }

  struct dirent *entry;
  char path[1024];

  while ((entry = readdir(directory)) != NULL) {
    if (!strcmp(entry->d_name, ".") || !strcmp(entry->d_name, ".."))
      continue;

    sprintf(path, "%s/%s", dir, entry->d_name);

    DIR *sub = opendir(path);
    if (sub != NULL) {
      closedir(sub);
      thermdir(path);
    } else {
      remove(path);
    }
  }

  closedir(directory);
  rmdir(dir);
}

void touch(char *file) {
  FILE *thefile = fopen(file, "a");

  if (file[strlen(file) - 1] == '/') {
    printf("Use mkdir to make a directory");
    return;
  }

  if (thefile == NULL) {
    printf("File or directory already exists");
    return;
  }

  fclose(thefile);
}

void themkdir(char *dir) {
  if (mkdir(dir, 0755) != 0) {
    printf("File or directory already exists");
  }
}

void cd(char *dir) {
  if (chdir(dir) != 0) {
    perror("No sutch directory");
  }
}

void disableCtlC() {
  signal(SIGINT, SIG_IGN);
  signal(SIGTTOU, SIG_IGN);

  struct termios term;
  tcgetattr(STDIN_FILENO, &term);
  term.c_lflag &= ~ISIG;
  tcsetattr(STDIN_FILENO, TCSANOW, &term);
}

void enableCtlC() {
  signal(SIGINT, SIG_DFL);
  signal(SIGTTOU, SIG_DFL);

  struct termios term;
  tcgetattr(STDIN_FILENO, &term);
  term.c_lflag |= ISIG;
  tcsetattr(STDIN_FILENO, TCSANOW, &term);
}

void enableRaw() {
  struct termios term;
  tcgetattr(STDIN_FILENO, &term);
  term.c_iflag &= ~BRKINT;
  term.c_iflag &= ~ICRNL;
  term.c_iflag &= ~INPCK;
  term.c_iflag &= ~ISTRIP;
  term.c_iflag &= ~IXON;
  term.c_oflag &= ~OPOST;
  term.c_cflag |= CS8;
  term.c_lflag &= ~ECHO;
  term.c_lflag &= ~ICANON;
  term.c_lflag &= ~IEXTEN;
  term.c_lflag &= ~ISIG;
  term.c_cc[VMIN] = 1;
  term.c_cc[VTIME] = 0;
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &term);
}

void run(char *path, char *args[]) {
  pid_t process = fork();

  if (process == 0) {
    pid_t child_pid = getpid();
    setpgid(child_pid, child_pid);
    tcsetpgrp(STDIN_FILENO, child_pid);

    enableCtlC();

    struct termios term;
    tcgetattr(STDIN_FILENO, &term);
    term.c_lflag |= (ICANON | ECHO | ISIG | IEXTEN);
    term.c_iflag |= (BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    term.c_oflag |= OPOST;
    tcsetattr(STDIN_FILENO, TCSANOW, &term);

    execvp(path, args);
    _exit(1);
  } else {
    setpgid(process, process);
    tcsetpgrp(STDIN_FILENO, process);

    int status;
    waitpid(process, &status, WUNTRACED);

    tcsetpgrp(STDIN_FILENO, getpgrp());

    disableCtlC();
    enableRaw();
  }
}

char *handleInput() {
  char buffer[1];

  char *chars = NULL;
  int len = 0;

  while (1) {
    int bytes = read(0, buffer, 1);
    if (bytes == 0) {
        free(chars);
        return NULL;
    }
    if (bytes < 0) {
        perror("read");
        free(chars);
        return NULL;
    }
    if (buffer[0] == '\r' || buffer[0] == '\n') {
      write(1, "\r\n", 2);
      break;
    }
    if (buffer[0] == 127 || buffer[0] == '\b') {
      if (len > 0) {
        len--;
        chars[len] = '\0';
        write(1, "\b \b", 3);
      }
      continue;
    }
    if (buffer[0] == '\x1b') {
      char seq[2];
      read(0, &seq[0], 1);
      read(0, &seq[1], 1);
      if (seq[0] == '[' && seq[1] == 'D' && len > 0) {
        write(1, "\x1b[1D", 4);
        len--;
      }
      if (seq[0] == '[' && seq[1] == 'C' && chars != NULL &&
          len < (int)strlen(chars)) {
        write(1, "\x1b[1C", 4);
        len++;
      }
      continue;
    }
    write(1, buffer, 1);
    chars = realloc(chars, len + 2);
    chars[len++] = buffer[0];
    chars[len] = '\0';
  }
  if (chars == NULL) {
    chars = malloc(1);
    chars[0] = '\0';
  }
  return chars;
}

char **getPath() {
  char *path = strdup(getenv("PATH"));

  char **dirs = malloc(0 * sizeof(char *));
  int dirCount = 0;

  char *iter = strtok(path, ":");

  while (iter != NULL) {
    char *dir = iter;

    dirs = realloc(dirs, (dirCount + 2) * sizeof(char *));
    dirs[dirCount] = strdup(dir);
    dirCount++;
    dirs[dirCount] = NULL;

    iter = strtok(NULL, ":");
  }
	free(path);
  return dirs;
}

char **indexPath(char **path) {
  char **index = malloc(0 * sizeof(char *));
  int indexCount = 0;

  for (int i = 0; path[i] != NULL; i++) {
    char *dir = path[i];

    DIR *openedDir = opendir(dir);
    if (openedDir == NULL)
      continue;

    struct dirent *entry;

    while ((entry = readdir(openedDir)) != NULL) {
      index = realloc(index, (indexCount + 2) * sizeof(char *));

      char fullpath[1024];
      snprintf(fullpath, sizeof(fullpath), "%s/%s", dir, entry->d_name);
      index[indexCount] = strdup(fullpath);

      indexCount++;
      index[indexCount] = NULL;
    }

    closedir(openedDir);
  }
  return index;
}

int main() {
  disableCtlC();
  enableRaw();

  char **path = getPath();

  char **index = indexPath(path);

  int indexCount = 0;
  while (index[indexCount] != NULL) {
    indexCount++;
  }

  printf("\x1b[2J\x1b[H");
  printf("Welcome To BCSH!\r\n");

  while (1) {
    printf("BCSH> ");
    fflush(stdout);

    char *input = handleInput();
    printf("\r\n");

    if (strcmp(input, "exit") == 0) {
      free(input);
      return 0;
    } else if ((input[0] == 'l' && input[1] == 's' &&
                (input[2] == ' ' || input[2] == '\0'))) {
      char *dir = input + 2;

      if (*dir == '\0') {
        dir = ".";
        ls(dir);
        printf("\r\n");
      } else {
        char *iter = strtok(dir, " ");
        while (iter != NULL) {
          ls(iter);
          printf("\r\n");
          iter = strtok(NULL, " ");
        }
      }
    } else if ((input[0] == 'c' && input[1] == 'a' && input[2] == 't' &&
                (input[3] == ' ' || input[3] == '\0'))) {
      char *dir = input + 3;

      if (*dir == '\0') {
        printf("Please specify an agrument\r\n\r\n");
      } else {
        char *iter = strtok(dir, " ");
        while (iter != NULL) {
          cat(iter);
          printf("\r\n");
          iter = strtok(NULL, " ");
        }
      }
    } else if ((input[0] == 'r' && input[1] == 'm' && input[2] == 'd' &&
                input[3] == 'i' && input[4] == 'r' &&
                (input[5] == ' ' || input[5] == '\0'))) {
      char *dir = input + 6;

      if (*dir == '\0') {
        printf("Please specify an agrument\r\n\r\n");
      } else {
        char *iter = strtok(dir, " ");
        while (iter != NULL) {
          thermdir(iter);
          printf("\r\n");
          iter = strtok(NULL, " ");
        }
      }
    } else if ((input[0] == 'r' && input[1] == 'm' &&
                (input[2] == ' ' || input[2] == '\0'))) {
      char *dir = input + 2;

      if (*dir == '\0') {
        printf("Please specify an agrument\r\n\r\n");
      } else {
        char *iter = strtok(dir, " ");
        while (iter != NULL) {
          rm(iter);
          printf("\r\n");
          iter = strtok(NULL, " ");
        }
      }
    } else if ((input[0] == 't' && input[1] == 'o' && input[2] == 'u' &&
                input[3] == 'c' && input[4] == 'h' &&
                (input[5] == ' ' || input[5] == '\0'))) {
      char *dir = input + 5;

      if (*dir == '\0') {
        printf("Please specify an agrument\r\n\r\n");
      } else {
        char *iter = strtok(dir, " ");
        while (iter != NULL) {
          touch(iter);
          printf("\r\n");
          iter = strtok(NULL, " ");
        }
      }
    } else if ((input[0] == 'm' && input[1] == 'k' && input[2] == 'd' &&
                input[3] == 'i' && input[4] == 'r' &&
                (input[5] == ' ' || input[5] == '\0'))) {
      char *dir = input + 5;

      if (*dir == '\0') {
        printf("Please specify an agrument\r\n\r\n");
      } else {
        char *iter = strtok(dir, " ");
        while (iter != NULL) {
          themkdir(iter);
          printf("\r\n");
          iter = strtok(NULL, " ");
        }
      }
    } else if ((input[0] == 'c' && input[1] == 'd' &&
                (input[2] == ' ' || input[2] == '\0'))) {
      char *dir = input + 2;

      if (*dir == '\0') {
        printf("Please specify an agrument\r\n\r\n");
      } else {
        char *iter = strtok(dir, " ");
        while (iter != NULL) {
          cd(iter);
          printf("\r\n");
          iter = strtok(NULL, " ");
        }
      }
    } else if ((strcmp(input, "clear") == 0) || (strcmp(input, "reset") == 0)) {
      printf("\x1b[2J\x1b[H");
    } else {
      char *inputready = strtok(input, " ");
      if (inputready == NULL)
        continue;

      char *theinput = inputready;
      char *command = strrchr(theinput, '/');
      if (command != NULL)
        command++;
      else
        command = theinput;

      int valid = 0;
      for (int i = 0; i < indexCount; i++) {
        char *thecommand = strrchr(index[i], '/');
        if (thecommand != NULL)
          thecommand++;
        else
          thecommand = index[i];
        if (strcmp(thecommand, command) == 0) {
          valid = 1;
          char **args = NULL;
          int argsCount = 0;

          char *arg;
          while ((arg = strtok(NULL, " ")) != NULL) {
            args = realloc(args, (argsCount + 1) * sizeof(char *));
            args[argsCount] = arg;
            argsCount++;
          }

          args = realloc(args, (argsCount + 1) * sizeof(char *));
          args[argsCount] = NULL;
          run(index[i], args);
          free(args);
          break;
        }
      }
      if (!valid)
        printf("Command not found\r\n");

      free(input);
    }
  }
}
