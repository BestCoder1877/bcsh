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
}
