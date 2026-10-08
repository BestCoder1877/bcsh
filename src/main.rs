use libc::{SIG_IGN, SIGINT, SIGTTOU, signal};
use nix::sys::termios::{InputFlags, LocalFlags, OutputFlags, SetArg, tcgetattr, tcsetattr};
use std::fs::{self};
use std::io::stdin;
use std::io::{self, Read, Write};

#[cfg(test)]
mod tests;

fn ls(dir: String) {
    if std::path::Path::new(&dir).is_dir() {
        for entry in fs::read_dir(dir).unwrap() {
            let entry = entry.unwrap();
            let name = entry.file_name();
            if name != "." && name != ".." {
                print!("{}\r\n", name.to_string_lossy());
            }
        }
    } else if std::path::Path::new(&dir).is_file() {
        println!("{}", dir);
    } else {
        println!("No such file or directory\r\n")
    }
}

fn pwd() {
    match std::env::current_dir() {
        Ok(path) => print!("{}\r\n", path.display()),
        Err(_) => print!("Current directory does not exist"),
    }
}

fn cat(file: String) {
    let path = std::path::Path::new(&file);
    if path.is_dir() {
        println!("You cannot cat a directory\r\n");
        return;
    }
    if !path.exists() {
        print!("No such file or directory\r\n");
        return;
    }
    let thefile = match std::fs::read_to_string(path) {
        Ok(contents) => contents,
        Err(_) => return,
    };
    for line in thefile.lines() {
        print!("{}\r\n", line);
    }
}

fn rm(file: String) {
    let path = std::path::Path::new(&file);
    if path.is_dir() {
        print!("Use rmdir to delete a directory\r\n");
        return;
    }
    let _ = std::fs::remove_file(path);
}

fn rmdir(dir: String) {
    let path = std::path::Path::new(&dir);
    if path.is_file() {
        println!("Use rm to delete a file");
        return;
    }
    let _ = std::fs::remove_dir_all(path);
}

fn touch(file: String) {
    let path = std::path::Path::new(&file);
    if path.exists() {
        print!("File or directory already exists");
        return;
    }
    let _ = std::fs::File::create(path);
}

fn mkdir(dir: String) {
    let path = std::path::Path::new(&dir);
    if path.exists() {
        print!("File or directory already exists");
        return;
    }
    let _ = std::fs::create_dir_all(path);
}

fn cd(dir: String) {
    let path = std::path::Path::new(&dir);
    if path.is_file() {
        print!("Not A Directory");
        return;
    }
    if !path.exists() {
        print!("No Sutch File Or Directory");
        return;
    }
    let _ = std::env::set_current_dir(path);
}

fn tree(dir: String, prefix: &str) {
    let path = std::path::Path::new(&dir);
    if path.is_file() {
        print!("{}{}\r\n", prefix, path.display());
        return;
    }
    if prefix.is_empty() {
        print!("{}\r\n", path.display());
    }
    let entries = match fs::read_dir(&dir) {
        Ok(entries) => entries,
        Err(_) => return,
    };
    let mut names: Vec<String> = entries
        .filter_map(|e| e.ok())
        .map(|e| e.file_name().to_string_lossy().to_string())
        .filter(|n| n != "." && n != "..")
        .collect();
    names.sort();
    for (i, name) in names.iter().enumerate() {
        let is_last = i == names.len() - 1;
        let connector = if is_last { "└── " } else { "├── " };
        print!("{}{}{}\r\n", prefix, connector, name);
        let sub = path.join(name);
        let new_prefix = format!(
            "{}{}",
            prefix,
            if is_last { "    " } else { "│   " }
        );
        tree(sub.to_string_lossy().to_string(), &new_prefix);
    }
}

fn help() {
    print!("BCSH Built-in Commands:\r\n");
    print!("  cd <dir>     Change current directory\r\n");
    print!("  ls [dir]     List directory contents\r\n");
    print!("  pwd          Print current working directory\r\n");
    print!("  cat <file>   Concatenate and display file contents\r\n");
    print!("  rm <file>    Remove a file\r\n");
    print!("  rmdir <dir>  Remove a directory\r\n");
    print!("  touch <file> Create an empty file\r\n");
    print!("  mkdir <dir>  Create a directory\r\n");
    print!("  tree <dir>   Display a directory tree\r\n");
    print!("  clear        Clear screen and scrollback\r\n");
    print!("  reset        Clear screen and scrollback\r\n");
    print!("  help         Display built-in commands\r\n");
    print!("  exit         Exit the shell\r\n");
}

fn clear() {
    print!("\x1b[2J\x1b[3J\x1b[H");
    let _ = io::stdout().flush();
}

fn enable_raw() {
    if unsafe { libc::isatty(libc::STDIN_FILENO) } == 1 {
        let mut term = tcgetattr(stdin()).unwrap();
        term.input_flags.remove(
            InputFlags::BRKINT
                | InputFlags::ICRNL
                | InputFlags::INPCK
                | InputFlags::ISTRIP
                | InputFlags::IXON,
        );
        term.output_flags.remove(OutputFlags::OPOST);
        term.local_flags
            .remove(LocalFlags::ECHO | LocalFlags::ICANON | LocalFlags::IEXTEN);
        tcsetattr(stdin(), SetArg::TCSAFLUSH, &term).unwrap();
    }
}

fn disable_raw() {
    if unsafe { libc::isatty(libc::STDIN_FILENO) } == 1 {
        let mut term = tcgetattr(stdin()).unwrap();
        term.local_flags
            .insert(LocalFlags::ECHO | LocalFlags::ICANON | LocalFlags::ISIG | LocalFlags::IEXTEN);
        term.input_flags.insert(
            InputFlags::BRKINT
                | InputFlags::ICRNL
                | InputFlags::INPCK
                | InputFlags::ISTRIP
                | InputFlags::IXON,
        );
        term.output_flags.insert(OutputFlags::OPOST);
        tcsetattr(stdin(), SetArg::TCSAFLUSH, &term).unwrap();
    }
}

fn handle_input(history: &[String]) -> String {
    let mut input = String::new();
    let mut cursor_pos = 0;
    let mut history_pos = history.len();
    loop {
        let mut buffer = [0; 1];
        if io::stdin().read_exact(&mut buffer).is_err() {
            return input;
        }
        match buffer[0] {
            b'\r' | b'\n' => {
                print!("\r\n");
                io::stdout().flush().unwrap();
                return input;
            }
            127 | 8 => {
                if cursor_pos > 0 {
                    input.remove(cursor_pos - 1);
                    cursor_pos -= 1;
                    print!(
                        "\r\x1b[2K{}> {}",
                        std::env::current_dir().unwrap_or_default().display(),
                        input
                    );
                    print!(
                        "\x1b[{}G",
                        cursor_pos
                            + std::env::current_dir()
                                .unwrap_or_default()
                                .display()
                                .to_string()
                                .len()
                            + 3
                    );
                    io::stdout().flush().unwrap();
                }
            }
            27 => {
                let mut sequence = [0; 2];
                if io::stdin().read_exact(&mut sequence).is_err() {
                    continue;
                }
                match sequence {
                    [b'[', b'A'] if history_pos > 0 => {
                        history_pos -= 1;
                        input = history[history_pos].clone();
                        cursor_pos = input.len();
                        print!(
                            "\r\x1b[2K{}> {}",
                            std::env::current_dir().unwrap_or_default().display(),
                            input
                        );
                        io::stdout().flush().unwrap();
                    }
                    [b'[', b'B'] => {
                        if history_pos + 1 < history.len() {
                            history_pos += 1;
                            input = history[history_pos].clone();
                        } else {
                            history_pos = history.len();
                            input.clear();
                        }
                        cursor_pos = input.len();
                        print!(
                            "\r\x1b[2K{}> {}",
                            std::env::current_dir().unwrap_or_default().display(),
                            input
                        );
                        io::stdout().flush().unwrap();
                    }
                    [b'[', b'D'] => {
                        if cursor_pos > 0 {
                            cursor_pos -= 1;
                            print!("\x1b[1D");
                            io::stdout().flush().unwrap();
                        }
                    }
                    [b'[', b'C'] if cursor_pos < input.len() => {
                        cursor_pos += 1;
                        print!("\x1b[1C");
                        io::stdout().flush().unwrap();
                    }
                    _ => {}
                }
            }
            byte => {
                input.insert(cursor_pos, byte as char);
                cursor_pos += 1;
                let prompt = std::env::current_dir()
                    .unwrap_or_default()
                    .display()
                    .to_string();
                print!("\r\x1b[2K{}> {}", prompt, input);
                print!("\x1b[{}G", cursor_pos + prompt.len() + 3);
                io::stdout().flush().unwrap();
            }
        }
    }
}

fn run(args: &[&str]) {
    match unsafe { nix::libc::fork() } {
        0 => {
            unsafe {
                nix::libc::setpgid(0, 0);
                nix::libc::tcsetpgrp(0, nix::libc::getpid());
                nix::libc::signal(nix::libc::SIGINT, nix::libc::SIG_DFL);
            }
            disable_raw();
            let c_args: Vec<std::ffi::CString> = args
                .iter()
                .map(|arg| std::ffi::CString::new(*arg).unwrap())
                .collect();
            let _ = nix::unistd::execvp(&c_args[0], &c_args);
        }
        child if child > 0 => {
            unsafe {
                nix::libc::setpgid(child, child);
                nix::libc::tcsetpgrp(0, child);
            }
            unsafe {
                nix::libc::waitpid(child, std::ptr::null_mut(), 0);
                nix::libc::tcsetpgrp(0, nix::libc::getpgrp());
            }
            enable_raw();
        }
        child if child < 0 => {
            enable_raw();
        }
        _ => {
            enable_raw();
        }
    }
}

fn run_pipeline(commands: &[Vec<&str>]) {
    let mut fds: Vec<[libc::c_int; 2]> = Vec::new();

    for i in 0..commands.len() {
        let mut pipe_fd: [libc::c_int; 2] = [-1; 2];
        if i < commands.len() - 1 {
            let flags = libc::O_CLOEXEC;
            unsafe { nix::libc::pipe2(pipe_fd.as_mut_ptr(), flags) };
            fds.push(pipe_fd);
        } else {
            fds.push([-1; 2]);
        }
    }

    let mut children: Vec<libc::c_int> = Vec::new();
    let mut current_stdin: libc::c_int = -1;

    for (i, cmd) in commands.iter().enumerate() {
        let fd_in = if i == 0 { 0 } else { current_stdin };

        let fd_out = if i < commands.len() - 1 { fds[i][1] } else { 1 };

        let child_pid = unsafe { nix::libc::fork() };
        match child_pid {
            0 => {
                unsafe { nix::libc::setpgid(0, 0) };
                unsafe { nix::libc::tcsetpgrp(0, nix::libc::getpid()) };

                if fd_in != 0 {
                    unsafe { libc::dup2(fd_in, 0) };
                }
                if fd_out != 1 {
                    unsafe { libc::dup2(fd_out, 1) };
                }

                for fd in &fds {
                    if fd[0] != -1 {
                        unsafe { libc::close(fd[0]) };
                    }
                    if fd[1] != -1 {
                        unsafe { libc::close(fd[1]) };
                    }
                }

                let c_args: Vec<std::ffi::CString> = cmd
                    .iter()
                    .map(|arg| std::ffi::CString::new(*arg).unwrap())
                    .collect();
                match nix::unistd::execvp(&c_args[0], &c_args) {
                    Ok(_) => {}
                    Err(_) => {
                        eprint!("bcsh: command not found: {}", cmd[0]);
                        unsafe { libc::_exit(1) };
                    }
                }
            }
            pid if pid > 0 => {
                children.push(pid);
                if fd_in != -1 && fd_in != 0 {
                    unsafe { libc::close(fd_in) };
                }
                if fd_out != -1 && fd_out != 1 {
                    unsafe { libc::close(fd_out) };
                }
                current_stdin = if i < commands.len() - 1 {
                    fds[i][0]
                } else {
                    -1
                };
            }
            _ => {}
        }
    }

    for pid in &children {
        unsafe { nix::libc::waitpid(*pid, std::ptr::null_mut(), 0) };
    }

    unsafe { nix::libc::tcsetpgrp(0, nix::libc::getpgrp()) };
}

fn expand_tilde(path: &str) -> String {
    if path == "~" || path.starts_with("~/") {
        let home = std::env::var("HOME").unwrap_or_default();
        if path == "~" {
            home
        } else {
            format!("{}{}", home, &path[1..])
        }
    } else {
        path.to_string()
    }
}

fn parse_pipeline(input: &str) -> Vec<Vec<&str>> {
    input
        .split('|')
        .map(|cmd| cmd.split_whitespace().collect())
        .filter(|cmd: &Vec<&str>| !cmd.is_empty())
        .collect()
}

fn env(input: &str) -> String {
    input
        .split_whitespace()
        .map(|word| {
            let expanded = if let Some(name) = word.strip_prefix('$') {
                std::env::var(name).unwrap_or_default()
            } else {
                word.to_string()
            };
            expand_tilde(&expanded)
        })
        .collect::<Vec<_>>()
        .join(" ")
}

fn startup() {
    let path = expand_tilde("~/.bcsh/startup");
    if let Ok(content) = fs::read_to_string(path) {
        for line in content.lines() {
            if let Some(input) = line.strip_prefix("hide") {
                let args: Vec<&str> = input.split_whitespace().collect();
                if args.is_empty() {
                    continue;
                }
                run(&args);
            } else if let Some(input) = line.strip_prefix("show") {
                let args: Vec<&str> = input.split_whitespace().collect();
                if args.is_empty() {
                    continue;
                }
                run(&args);
                println!("\r\n");
            }
        }
    }
}

fn list_alias() -> (Vec<String>, Vec<String>) {
    let path = expand_tilde("~/.bcsh/alias");
    let mut alias_commands = vec![];
    let mut alias_titles = vec![];
    if let Ok(content) = fs::read_to_string(path) {
        for line in content.lines() {
            let args: Vec<&str> = line.split("=").collect();
            alias_titles.push(args[0].to_string());
            alias_commands.push(args[1..].join("="));
        }
    }
    (alias_commands, alias_titles)
}

fn swap_alias(command: String) -> bool {
    let aliases = list_alias();
    for (i, alias_title) in aliases.1.iter().enumerate() {
        if command == *alias_title {
            let args: Vec<&str> = aliases.0[i].split_whitespace().collect();
            run(&args);
            return true;
        }
    }
    false
}

fn main() {
    unsafe {
        signal(SIGINT, SIG_IGN);
        signal(SIGTTOU, SIG_IGN);
    }
    enable_raw();

    let home = std::env::var("HOME").unwrap();
    let history_path = format!("{home}/.bcsh_history");
    let mut current_path = std::env::current_dir()
        .unwrap()
        .to_string_lossy()
        .to_string();
    let mut history: Vec<String> = match fs::read_to_string(history_path.clone()) {
        Ok(data) => data.lines().map(String::from).collect(),
        Err(_) => {
            fs::write(history_path.clone(), "").unwrap();
            print!("Welcome To BCSH!\r\n");
            Vec::new()
        }
    };
    clear();
    startup();

    loop {
        if let Ok(dir) = std::env::current_dir() {
            current_path = dir.to_string_lossy().to_string();
        }
        print!("{}> ", current_path);
        io::stdout().flush().unwrap();

        let input = handle_input(&history);
        let input = env(&input);
        let _ = std::fs::write(&history_path, history.join("\n"));
        println!("\r\n");
        if !input.is_empty() {
            history.push(input.clone());
        }
        if swap_alias(input.clone()) == true {
            continue;
        }
        if input.trim() == "exit" {
            disable_raw();
            break;
        } else if input.contains("|") {
            disable_raw();
            let commands = parse_pipeline(&input);
            run_pipeline(&commands);
            enable_raw();
            println!("\r\n");
        } else if input.starts_with("ls") {
            let mut dir = &input[2..];
            if dir.is_empty() {
                dir = ".";
                ls(dir.to_string());
                println!("\r\n");
            } else {
                for iter in dir.split_whitespace() {
                    ls(iter.to_string());
                    println!("\r\n");
                }
            }
        } else if input.starts_with("pwd") {
            pwd();
        } else if input.starts_with("cat") {
            let dir = &input[3..];
            if dir.is_empty() {
                print!("Please specify an argument\r\n");
                continue;
            } else {
                for iter in dir.split_whitespace() {
                    cat(iter.to_string());
                    println!("\r\n");
                }
            }
        } else if input.starts_with("rmdir") {
            let dir = &input[5..];
            if dir.is_empty() {
                print!("Please specify an argument\r\n");
                continue;
            } else {
                for iter in dir.split_whitespace() {
                    rmdir(iter.to_string());
                    println!("\r\n");
                }
            }
        } else if input.starts_with("rm") {
            let dir = &input[2..];
            if dir.is_empty() {
                print!("Please specify an argument\r\n");
                continue;
            } else {
                for iter in dir.split_whitespace() {
                    rm(iter.to_string());
                    println!("\r\n");
                }
            }
        } else if input.starts_with("touch") {
            let dir = &input[5..];
            if dir.is_empty() {
                print!("Please specify an argument\r\n");
                continue;
            } else {
                for iter in dir.split_whitespace() {
                    touch(iter.to_string());
                    println!("\r\n");
                }
            }
        } else if input.starts_with("mkdir") {
            let dir = &input[5..];
            if dir.is_empty() {
                print!("Please specify an argument\r\n");
                continue;
            } else {
                for iter in dir.split_whitespace() {
                    mkdir(iter.to_string());
                    println!("\r\n");
                }
            }
        } else if input.starts_with("cd") {
            let dir = &input[2..];
            if dir.is_empty() {
                print!("Please specify an argument\r\n");
                continue;
            } else {
                for iter in dir.split_whitespace() {
                    cd(iter.to_string());
                    println!("\r\n");
                }
            }
        } else if input.starts_with("tree") {
            let mut dir = &input[4..];
            if dir.is_empty() {
                dir = ".";
            }
            for iter in dir.trim_start_matches(" ").split_whitespace() {
                tree(iter.to_string(), "");
                println!("\r\n");
            }
        } else if input == "help" || input.starts_with("help ") {
            help();
            println!("\r\n");
        } else if input == "clear"
            || input.starts_with("clear ")
            || input == "reset"
            || input.starts_with("reset ")
        {
            clear();
        } else {
            let args: Vec<&str> = input.split_whitespace().collect();
            if args.is_empty() {
                continue;
            }
            run(&args);
            println!("\r\n");
        }
    }
}
