#[cfg(test)]
mod tests {
    use crate::*;

    struct TempDir {
        path: std::path::PathBuf,
    }

    impl TempDir {
        fn new() -> Self {
            let path = std::env::temp_dir().join(format!("bcsh_test_{}", uuid()));
            fs::create_dir_all(&path).unwrap();
            Self { path }
        }

        fn path(&self) -> &std::path::Path {
            &self.path
        }
    }

    impl Drop for TempDir {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.path);
        }
    }

    fn uuid() -> u64 {
        use std::time::{SystemTime, UNIX_EPOCH};
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos() as u64
    }

    #[test]
    fn test_env() {
        unsafe {
            std::env::set_var("BCSH_TEST_VAR", "hello_world");
        }
        let result = env("echo $BCSH_TEST_VAR test");
        assert_eq!(result, "echo hello_world test");

        let empty = env("echo $NON_EXISTENT_BCSH_VAR_XYZ");
        assert_eq!(empty, "echo ");
    }

    #[test]
    fn test_touch_and_rm() {
        let tmp = TempDir::new();
        let filename = tmp.path().join("test_file.txt").to_string_lossy().to_string();

        touch(filename.clone());
        assert!(std::path::Path::new(&filename).exists());

        // touch existing file should not fail/panic
        touch(filename.clone());

        rm(filename.clone());
        assert!(!std::path::Path::new(&filename).exists());
    }

    #[test]
    fn test_mkdir_and_rmdir() {
        let tmp = TempDir::new();
        let dirname = tmp.path().join("test_dir").to_string_lossy().to_string();

        mkdir(dirname.clone());
        assert!(std::path::Path::new(&dirname).is_dir());

        rmdir(dirname.clone());
        assert!(!std::path::Path::new(&dirname).exists());
    }

    #[test]
    fn test_cd() {
        let tmp = TempDir::new();
        let sub_path = tmp.path().join("sub_dir");
        fs::create_dir(&sub_path).unwrap();

        let orig_dir = std::env::current_dir().unwrap();
        cd(sub_path.to_string_lossy().to_string());
        assert_eq!(
            std::env::current_dir().unwrap().canonicalize().unwrap(),
            sub_path.canonicalize().unwrap()
        );
        let _ = std::env::set_current_dir(&orig_dir);
    }

    #[test]
    fn test_ls() {
        let tmp = TempDir::new();
        let file_path = tmp.path().join("ls_file.txt");
        fs::write(&file_path, "content").unwrap();

        // Just test that calling ls doesn't panic
        ls(file_path.to_string_lossy().to_string());
        ls(tmp.path().to_string_lossy().to_string());
    }

    #[test]
    fn test_cat() {
        let tmp = TempDir::new();
        let file_path = tmp.path().join("cat_file.txt");
        fs::write(&file_path, "line1\nline2").unwrap();

        cat(file_path.to_string_lossy().to_string());
        cat(tmp.path().join("non_existent_file.txt").to_string_lossy().to_string());
        cat(tmp.path().to_string_lossy().to_string()); // directory check
    }

    #[test]
    fn test_env_multiple() {
        unsafe {
            std::env::set_var("BCSH_TEST_A", "foo");
            std::env::set_var("BCSH_TEST_B", "bar");
        }
        assert_eq!(env("$BCSH_TEST_A $BCSH_TEST_B"), "foo bar");
        assert_eq!(env("plain text"), "plain text");
    }

    #[test]
    fn test_touch_existing() {
        let tmp = TempDir::new();
        let filename = tmp.path().join("exists.txt").to_string_lossy().to_string();
        touch(filename.clone());
        assert!(std::path::Path::new(&filename).exists());
        touch(filename.clone()); // should not panic, should not overwrite
        assert!(std::path::Path::new(&filename).exists());
    }

    #[test]
    fn test_mkdir_existing() {
        let tmp = TempDir::new();
        let dirname = tmp.path().join("dup_dir").to_string_lossy().to_string();
        mkdir(dirname.clone());
        assert!(std::path::Path::new(&dirname).is_dir());
        mkdir(dirname.clone()); // should not panic
        assert!(std::path::Path::new(&dirname).is_dir());
    }

    #[test]
    fn test_mkdir_nested() {
        let tmp = TempDir::new();
        let nested = tmp.path().join("a/b/c").to_string_lossy().to_string();
        mkdir(nested.clone());
        assert!(std::path::Path::new(&nested).is_dir());
    }

    #[test]
    fn test_rm_dir() {
        let tmp = TempDir::new();
        let dirname = tmp.path().join("rm_dir").to_string_lossy().to_string();
        mkdir(dirname.clone());
        rm(dirname.clone()); // rm on dir should not remove it
        assert!(std::path::Path::new(&dirname).exists());
    }

    #[test]
    fn test_rmdir_file() {
        let tmp = TempDir::new();
        let filename = tmp.path().join("file.txt").to_string_lossy().to_string();
        touch(filename.clone());
        rmdir(filename.clone()); // rmdir on file should not remove it
        assert!(std::path::Path::new(&filename).exists());
    }

    #[test]
    fn test_cd_to_file() {
        let tmp = TempDir::new();
        let filename = tmp.path().join("notdir.txt").to_string_lossy().to_string();
        touch(filename.clone());
        let orig = std::env::current_dir().unwrap();
        cd(filename);
        assert_eq!(std::env::current_dir().unwrap(), orig);
    }

    #[test]
    fn test_cd_missing() {
        let orig = std::env::current_dir().unwrap();
        cd("/no/such/path/exists/here".to_string());
        assert_eq!(std::env::current_dir().unwrap(), orig);
    }

    #[test]
    fn test_ls_missing() {
        // should not panic
        ls("/no/such/path/here".to_string());
    }

    #[test]
    fn test_expand_tilde() {
        let home = std::env::var("HOME").unwrap();
        assert_eq!(expand_tilde("~"), home);
        assert_eq!(expand_tilde("~/foo/bar"), format!("{}/foo/bar", home));
        assert_eq!(expand_tilde("/abs/path"), "/abs/path");
        assert_eq!(expand_tilde("foo/bar"), "foo/bar");
        assert_eq!(expand_tilde("~user"), "~user");
    }

    #[test]
    fn test_env_tilde() {
        assert_eq!(env("~"), std::env::var("HOME").unwrap());
        assert_eq!(
            env("~/foo"),
            format!("{}/foo", std::env::var("HOME").unwrap())
        );
    }

    #[test]
    fn test_help() {
        help();
    }

    #[test]
    fn test_simple_pipeline() {
        use std::fs;
        use std::process::Command;

        let tmp_dir = TempDir::new();
        let file1 = tmp_dir.path().join("input.txt");
        let file2 = tmp_dir.path().join("output.txt");

        fs::write(&file1, "hello world").unwrap();

        let echo_cmd = format!("echo \"hello world\" > {}", file2.display());
        let cat_cmd = format!("cat {}", file2.display());
        let pipeline_cmd = format!("{} | {} | wc -l", echo_cmd, cat_cmd);

        let output = match Command::new("sh").arg("-c").arg(pipeline_cmd).output() {
            Ok(output) => output,
            Err(e) => {
                println!("Error executing pipeline: {}", e);
                return;
            }
        };

        let result = String::from_utf8_lossy(&output.stdout);
        let line_count = result.trim().parse::<i32>();
        match line_count {
            Ok(count) => assert_eq!(count, 1),
            Err(e) => println!("Error parsing count: {}", e),
        }
    }

    #[test]
    fn test_parse_pipeline() {
        let result = parse_pipeline("ls | grep file");
        assert_eq!(result.len(), 2);
        assert_eq!(result[0], vec!["ls"]);
        assert_eq!(result[1], vec!["grep", "file"]);

        let result2 = parse_pipeline("echo hello | wc -l");
        assert_eq!(result2.len(), 2);
        assert_eq!(result2[0], vec!["echo", "hello"]);
        assert_eq!(result2[1], vec!["wc", "-l"]);

        let result3 = parse_pipeline("simple command");
        assert_eq!(result3.len(), 1);
        assert_eq!(result3[0], vec!["simple", "command"]);

        let result4 = parse_pipeline("");
        assert_eq!(result4.len(), 0);

        let result5 = parse_pipeline("ls | grep file | wc -l");
        assert_eq!(result5.len(), 3);
        assert_eq!(result5[0], vec!["ls"]);
        assert_eq!(result5[1], vec!["grep", "file"]);
        assert_eq!(result5[2], vec!["wc", "-l"]);
    }
}
