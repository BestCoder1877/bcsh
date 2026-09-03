# BCSH Roadmap & TODO List

## Phase 1: Core Shell Ergonomics & Environment
- [x] **Environment Variable Expansion**: Expand variables like `$HOME`, `$USER`, and `$?`.
- [ ] **Command History Persistence**: Save and load history across sessions in `~/.bcsh_history`.
- [ ] **Enhanced Prompt**: Display current path (and optional git branch) cleanly in the prompt.

## Phase 2: Input & Process Flow
- [ ] **Piping and Redirection**: Implement `|`, `>`, `>>`, and `<`.
- [ ] **Tab Completion**: Auto-complete paths, builtins, and executables in `$PATH`.
- [ ] **Job Control**: Support background processes (`&`), `jobs`, `fg`, and `bg`.

## Phase 3: Usability & Customization
- [ ] **Built-in Help**: Add a `help` command listing builtins and descriptions.
- [ ] **Alias Support**: Add an `alias` builtin for shortcut management.
