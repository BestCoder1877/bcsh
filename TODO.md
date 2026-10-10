# BCSH Roadmap & TODO List

- [x] **Environment Variable Expansion**: Expand variables like `$HOME`, `$USER`, and `$?`.
- [x] **Command History Persistence**: Save and load history across sessions in `~/.bcsh_history`.
- [x] **Enhanced Prompt**: Display current path cleanly in the prompt.
- [x] **Piping**: Implement `|` (pipe operator).
- [ ] **Redirection**: Implement `>`, `>>`, and `<`.
- [ ] **Tab Completion**: Auto-complete paths, builtins, and executables in `$PATH`.
- [ ] **Job Control**: Support background processes (`&`), `jobs`, `fg`, and `bg`.
- [x] **Built-in Help**: Add a `help` command listing builtins and descriptions.
- [x] **Alias Support**: Add an `alias` builtin for shortcut management.
- [ ] **Exit Status `$?`**: Track and expose the exit code of the last command.
- [ ] **`export` Builtin**: Set environment variables for child processes.
- [ ] **`cd -`**: Return to the previous directory.
- [ ] **`which` / `type`**: Locate a command in `$PATH`.
- [ ] **`cd ..`**: Navigate up one directory level.