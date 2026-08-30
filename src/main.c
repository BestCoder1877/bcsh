#include <dirent.h>
#include <glob.h>
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
void pwd() {
  char cwd[1024];
  if (getcwd(cwd, sizeof(cwd)) != NULL) {
    printf("%s\r\n", cwd);
  } else {
    printf("Current directory does not exist");
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
  term.c_cc[VMIN] = 1;
  term.c_cc[VTIME] = 0;
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &term);
}

void disableRaw() {
  struct termios term;
  tcgetattr(STDIN_FILENO, &term);
  term.c_lflag |= (ECHO | ICANON | ISIG | IEXTEN);
  term.c_iflag |= (BRKINT | ICRNL | INPCK | ISTRIP | IXON);
  term.c_oflag |= OPOST;
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &term);
}


char *parser(char *og) {
  int i = 0;

  while (og[i] != '\0') {
    if (og[i] == '"') {
    }
    i++;
  }
	return og;
}

void run(char *args[]) {
  pid_t process = fork();

  if (process == 0) {
    pid_t child_pid = getpid();
    setpgid(child_pid, child_pid);
    tcsetpgrp(STDIN_FILENO, child_pid);

    signal(SIGINT, SIG_DFL);

    struct termios term;
    tcgetattr(STDIN_FILENO, &term);
    term.c_lflag |= (ICANON | ECHO | ISIG | IEXTEN);
    term.c_iflag |= (BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    term.c_oflag |= OPOST;
    tcsetattr(STDIN_FILENO, TCSANOW, &term);

    execvp(args[0], args);
    _exit(1);
  } else {
    setpgid(process, process);
    tcsetpgrp(STDIN_FILENO, process);

    int status;
    waitpid(process, &status, WUNTRACED);

    tcsetpgrp(STDIN_FILENO, getpgrp());

    enableRaw();
  }
}

char *handleInput(char **history, int historyCount) {
  char buffer[1];

  char *chars = NULL;
  int len = 0;
  int historyPos = historyCount;

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
      if (seq[0] == '[' && seq[1] == 'A') {
        if (historyPos > 0) {
          while (len > 0) {
            write(1, "\b \b", 3);
            len--;
          }
          historyPos--;
          free(chars);
          chars = strdup(history[historyPos]);
          len = strlen(chars);
          write(1, chars, len);
        }
      }
      if (seq[0] == '[' && seq[1] == 'B') { // DOWN arrow
        while (len > 0) {
          write(1, "\b \b", 3);
          len--;
        }
        if (historyPos < historyCount - 1) {
          historyPos++;
          free(chars);
          chars = strdup(history[historyPos]);
          len = strlen(chars);
          write(1, chars, len);
        } else {
          historyPos = historyCount;
          free(chars);
          chars = NULL;
        }
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
  return parser(chars);
}

int main() {
  signal(SIGINT, SIG_IGN);
  signal(SIGTTOU, SIG_IGN);
  enableRaw();

  char **history = NULL;
  int historyCount = 0;

  printf("\x1b[2J\x1b[H");
  printf("Welcome To BCSH!\r\n");

  while (1) {
    printf("BCSH> ");
    fflush(stdout);

    char *input = handleInput(history, historyCount);
    printf("\r\n");

    if (strlen(input) > 0) {
      history = realloc(history, (historyCount + 1) * sizeof(char *));
      history[historyCount] = strdup(input);
      historyCount++;
    }

    if (strcmp(input, "exit") == 0) {
			disableRaw();
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
    } else if ((input[0] == 'p' && input[1] == 'w' && input[2] == 'd' &&
                (input[3] == ' ' || input[3] == '\0'))) {
      char *dir = input + 3;

      pwd();
      printf("\r\n");
    } else if ((strcmp(input, "clear") == 0) || (strcmp(input, "reset") == 0)) {
      printf("\x1b[2J\x1b[H");
    } else {
      char *inputready = strtok(input, " ");
      if (inputready == NULL)
        continue;

      char **args = malloc(sizeof(char *) * 1);
      int argsCount = 0;

      args[argsCount++] = inputready;

      char *arg;
      while ((arg = strtok(NULL, " ")) != NULL) {
        if (arg[0] == '"') {
          arg++;

          char *next = strtok(NULL, "\"");
          if (next != NULL) {
            args = realloc(args, (argsCount + 1) * sizeof(char *));
            args[argsCount] = malloc(strlen(arg) + strlen(next) + 2);
            strcpy(args[argsCount], arg);
            strcat(args[argsCount], " ");
            strcat(args[argsCount], next);
            argsCount++;
          }
        } else {
          args = realloc(args, (argsCount + 1) * sizeof(char *));
          args[argsCount] = arg;
          argsCount++;
        }
      }

      args = realloc(args, (argsCount + 1) * sizeof(char *));
      args[argsCount] = NULL;
      run(args);
      printf("\r\n");
      free(args);

      free(input);
    }
  }
}
