#include "main.h"
#include <signal.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>

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

void run(char *path, char *args[]) {
  pid_t process = fork();

  if (process == 0) {
    pid_t child_pid = getpid();
    setpgid(child_pid, child_pid);
    tcsetpgrp(STDIN_FILENO, child_pid);

    enableCtlC();
    execv(path, args);
    _exit(1);
  } else {
    setpgid(process, process);
    tcsetpgrp(STDIN_FILENO, process);

    int status;
    waitpid(process, &status, WUNTRACED);

    tcsetpgrp(STDIN_FILENO, getpgrp());
  }
}
