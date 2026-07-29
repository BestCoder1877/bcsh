const std = @import("std");

const stdin = std.Io.File.stdin();
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    var buffer: [256]u8 = undefined;
    var reader = stdin.reader(init.io, &buffer);

    print("Welcome To BCSH!\n", .{});

    while (true) {
        const input = try reader.interface.takeDelimiter('\n');
        if (input) |line| {
            if (std.mem.startsWith(u8, line, "ls")) {
                var dir = std.mem.trim(u8, line[2..], " ");
                if (dir.len == 0) {
                    dir = ".";
                    try ls(init, dir);
                } else {
                    var iter = std.mem.splitScalar(u8, dir, ' ');

                    while (iter.next()) |thedir| {
                        if (dir.len != 0) {
                            try ls(init, thedir);
                        }
                    }
                }
            } else if (std.mem.startsWith(u8, line, "cat")) {
                const file = std.mem.trim(u8, line[3..], " ");

                var iter = std.mem.splitScalar(u8, file, ' ');
                while (iter.next()) |thefile| {
                    if (thefile.len != 0) {
                        try cat(init, thefile);
                    }
                }
            } else if (std.mem.startsWith(u8, line, "rm")) {
                if (!std.mem.startsWith(u8, line, "rm ")) continue;
                const file = std.mem.trim(u8, line[2..], " ");

                var iter = std.mem.splitScalar(u8, file, ' ');
                while (iter.next()) |thefile| {
                    if (thefile.len != 0) {
                        rm(init, thefile);
                    }
                }
            } else if (std.mem.startsWith(u8, line, "touch")) {
                const file = std.mem.trim(u8, line[5..], " ");

                var iter = std.mem.splitScalar(u8, file, ' ');
                while (iter.next()) |thefile| {
                    if (thefile.len != 0) {
                        try touch(init, thefile);
                    }
                }
            } else if (std.mem.startsWith(u8, line, "mkdir")) {
                const folder = std.mem.trim(u8, line[5..], " ");

                var iter = std.mem.splitScalar(u8, folder, ' ');
                while (iter.next()) |thefolder| {
                    if (thefolder.len != 0) {
                        try mkdir(init, thefolder);
                    }
                }
            } else if (std.mem.eql(u8, line, "exit")) {
                break;
            } else if (std.mem.eql(u8, line, "clear") or std.mem.eql(u8, line, "reset")) {
                print("\x1b[2J\x1b[H", .{});
            } else {
                print("Unknown Command: {s}\n", .{line});
            }
        }
    }
}

fn ls(init: std.process.Init, dir: []const u8) !void {
    var openedDir = std.Io.Dir.cwd().openDir(init.io, dir, .{ .iterate = true }) catch {
        var file = std.Io.Dir.cwd().openFile(init.io, dir, .{}) catch {
            print("No such file or directory\n", .{});
            return;
        };
        defer file.close(init.io);
        print("{s}\n", .{dir});
        return;
    };
    defer openedDir.close(init.io);

    var itered = openedDir.iterate();

    while (try itered.next(init.io)) |entry| {
        print("{s}\n", .{entry.name});
    }
}

fn cat(init: std.process.Init, file: []const u8) !void {
    if (std.Io.Dir.cwd().openDir(init.io, file, .{}) catch null) |dir| {
        dir.close(init.io);
        print("You cannot cat a directory\n", .{});
        return;
    }
    var openedFile = std.Io.Dir.cwd().openFile(init.io, file, .{}) catch {
        print("No such file or directory\n", .{});
        return;
    };
    defer openedFile.close(init.io);

    var buffer: [1024]u8 = undefined;
    var reader = openedFile.reader(init.io, &buffer);
    var output: [1024]u8 = undefined;

    while (true) {
        const bytes = try reader.interface.readSliceShort(&output);

        if (bytes == 0) break;

        print("{s}", .{output[0..bytes]});
    }
}

fn rm(init: std.process.Init, file: []const u8) void {
    if (std.Io.Dir.cwd().openDir(init.io, file, .{}) catch null) |dir| {
        dir.close(init.io);
        print("Use rmdir to delete a directory\n", .{});
        return;
    }
    std.Io.Dir.cwd().deleteFile(init.io, file) catch {
        print("No such file or directory\n", .{});
        return;
    };
}

fn rmdir(init: std.process.Init, folder: []const u8) void {
    if (std.Io.Dir.cwd().openFile(init.io, folder, .{}) catch null) |file| {
        file.close(init.io);
        print("Use rm to delete a file\n", .{});
        return;
    }
    std.Io.Dir.cwd().deleteDir(init.io, folder) catch {
        print("No such file or directory\n", .{});
        return;
    };
}

fn touch(init: std.process.Init, file: []const u8) !void {
    if (std.Io.Dir.cwd().openFile(init.io, file, .{}) catch null) |thefile| {
        thefile.close(init.io);
        print("File already exists\n", .{});
        return;
    }
    if (std.Io.Dir.cwd().openDir(init.io, file, .{}) catch null) |thefile| {
        thefile.close(init.io);
        print("Directory already exists\n", .{});
        return;
    }
    const newfile = try std.Io.Dir.cwd().createFile(init.io, file, .{});
    newfile.close(init.io);
}

fn mkdir(init: std.process.Init, folder: []const u8) !void {
    if (std.Io.Dir.cwd().openFile(init.io, folder, .{}) catch null) |thefile| {
        thefile.close(init.io);
        print("File already exists\n", .{});
        return;
    }
    if (std.Io.Dir.cwd().openDir(init.io, folder, .{}) catch null) |thefile| {
        thefile.close(init.io);
        print("Directory already exists\n", .{});
        return;
    }
    try std.Io.Dir.cwd().createDir(init.io, folder, .default_dir);
}
