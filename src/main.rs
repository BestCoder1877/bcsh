use libc::{SIG_IGN, SIGINT, SIGTTOU, signal};
use nix::sys::termios::{InputFlags, LocalFlags, OutputFlags, SetArg, tcgetattr, tcsetattr};
use std::fs;
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
            nix::unistd::execvp(&c_args[0], &c_args).unwrap();
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
