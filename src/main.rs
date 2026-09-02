use libc::{SIG_IGN, SIGINT, SIGTTOU, signal};
use nix::sys::termios::{InputFlags, LocalFlags, OutputFlags, SetArg, tcgetattr, tcsetattr};
use std::fs::{self};
use std::io::stdin;
use std::io::{self, Read, Write};

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
        println!("You cannot cat a directory\r\n"); return;
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
        print!("Use rm to delete a file\n");
        return;
    }
    let _ = std::fs::remove_dir_all(path);
}

fn touch(file: String) {
    if file.contains('/') {
        print!("Use mkdir to make a directory");
        return;
    }
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

fn enable_raw() {
    let mut term = tcgetattr(&stdin()).unwrap();
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
    tcsetattr(&stdin(), SetArg::TCSAFLUSH, &term).unwrap();
}

fn disable_raw() {
    let mut term = tcgetattr(&stdin()).unwrap();
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
    tcsetattr(&stdin(), SetArg::TCSAFLUSH, &term).unwrap();
}

fn handle_input(history: &[String]) -> String {
    let mut input = String::new();
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
                if input.pop().is_some() {
                    print!("\x08 \x08");
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
                        print!("\r\x1b[2KBCSH> {}", history[history_pos]);
                        input = history[history_pos].clone();
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
                        print!("\r\x1b[2KBCSH> {}", input);
                        io::stdout().flush().unwrap();
                    }
                    [b'[', b'D'] => {
                        print!("\x1b[1D");
                        io::stdout().flush().unwrap();
                    }
                    [b'[', b'C'] => {
                        print!("\x1b[1C");
                        io::stdout().flush().unwrap();
                    }
                    _ => {}
                }
            }
            byte => {
                input.push(byte as char);
                print!("{}", byte as char);
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
        child => {
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
        _ => {}
    }
}

fn main() {
    unsafe {
        signal(SIGINT, SIG_IGN);
        signal(SIGTTOU, SIG_IGN);
    }
    enable_raw();

    let mut history: Vec<String> = Vec::new();
    println!("\x1b[2J\x1b[H");
    print!("Welcome To BCSH!\r\n");

    loop {
        print!("BCSH> ");
        io::stdout().flush().unwrap();

        let input = handle_input(&history);
        println!("\r\n");
        if input.len() > 0 {
            history.push(input.clone());
        }
        if input == "exit" {
            disable_raw();
            return;
        } else if input.starts_with("ls ") {
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
        } else if input.starts_with("pwd ") {
            pwd();
        } else if input.starts_with("cat ") {
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
        } else if input.starts_with("rmdir ") {
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
        } else if input.starts_with("rm ") {
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
        } else if input.starts_with("touch ") {
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
        } else if input.starts_with("mkdir ") {
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
        } else if input.starts_with("cd ") {
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