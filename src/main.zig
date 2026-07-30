const std = @import("std");

extern fn run(path: [*:0]const u8, args: [*]const ?[*:0]const u8) void;
extern fn disableCtlC() void;

const stdin = std.Io.File.stdin();
const print = std.debug.print;
const allocater = std.heap.page_allocator;
var path = std.ArrayList([]const u8){
    .items = &.{},
    .capacity = 0,
};
var commands = std.ArrayList([]const u8){
    .items = &.{},
    .capacity = 0,
};

pub fn main(init: std.process.Init) !void {
    disableCtlC();

    var buffer: [256]u8 = undefined;
    var reader = stdin.reader(init.io, &buffer);

    print("\x1b[2J\x1b[H", .{});
    print("Welcome To BCSH!\n", .{});
    path = try getPath(init);
    const index = try indexPath(init);
    while (true) {
        print("BCSH> ", .{});
        const input = reader.interface.takeDelimiter('\n') catch continue;
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
            } else if (std.mem.startsWith(u8, line, "rmdir")) {
                const file = std.mem.trim(u8, line[5..], " ");

                var iter = std.mem.splitScalar(u8, file, ' ');
                while (iter.next()) |thefile| {
                    if (thefile.len != 0) {
                        rmdir(init, thefile);
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
            } else if (std.mem.startsWith(u8, line, "cd")) {
                const folder = std.mem.trim(u8, line[2..], " ");

                var iter = std.mem.splitScalar(u8, folder, ' ');
                while (iter.next()) |thefolder| {
                    if (thefolder.len != 0) {
                        try cd(init, thefolder);
                    }
                }
            } else if (std.mem.eql(u8, line, "exit")) {
                break;
            } else if (std.mem.eql(u8, line, "clear") or std.mem.eql(u8, line, "reset")) {
                print("\x1b[2J\x1b[H", .{});
            } else {
                var inputready = std.mem.splitScalar(u8, line, ' ');
                const theinput = inputready.next() orelse continue;
                const command = std.fs.path.basename(theinput);
                var valid = false;
                for (index.items) |thecommand| {
                    if (std.mem.eql(u8, std.fs.path.basename(thecommand), command)) {
                        valid = true;
                        var args = std.ArrayList([]const u8){
                            .items = &.{},
                            .capacity = 0,
                        };
                        while (inputready.next()) |arg| try args.append(allocater, arg);
                        try runCommand(thecommand, args.items);
                        break;
                    }
                }
                if (!valid) print("Command not found\n", .{});
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
    var dir = std.Io.Dir.cwd().openDir(init.io, folder, .{}) catch {
        print("Use rm to delete a file\n", .{});
        return;
    };
    dir.close(init.io);
    std.Io.Dir.cwd().deleteTree(init.io, folder) catch {
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

fn cd(init: std.process.Init, folder: []const u8) !void {
    const targetfolder = if (std.mem.eql(u8, folder, "~")) init.environ_map.get("HOME") orelse "/root" else folder;

    const dir = std.Io.Dir.cwd().openDir(init.io, targetfolder, .{}) catch {
        print("No such file or directory\n", .{});
        return;
    };
    defer dir.close(init.io);

    try std.process.setCurrentDir(init.io, dir);
}

fn getPath(init: std.process.Init) !std.ArrayListUnmanaged([]const u8) {
    const temppath = init.environ_map.get("PATH") orelse "";

    var dirs = std.ArrayList([]const u8){
        .items = &.{},
        .capacity = 0,
    };

    var iter = std.mem.splitScalar(u8, temppath, ':');

    while (iter.next()) |dir| {
        try dirs.append(allocater, dir);
    }

    return dirs;
}

fn indexPath(init: std.process.Init) !std.ArrayListUnmanaged([]const u8) {
    var index = std.ArrayList([]const u8){
        .items = &.{},
        .capacity = 0,
    };
    for (path.items) |dir| {
        var openedDir = std.Io.Dir.cwd().openDir(init.io, dir, .{ .iterate = true }) catch continue;
        defer openedDir.close(init.io);

        var itered = openedDir.iterate();

        while (try itered.next(init.io)) |entry| {
            const command = try std.fs.path.join(allocater, &.{ dir, entry.name });

            try index.append(allocater, command);
        }
    }
    return index;
}

fn runCommand(thepath: []const u8, args: [][]const u8) !void {
    var cArgs = try std.ArrayList(?[*:0]const u8).initCapacity(allocater, args.len + 2);
    defer {
        for (cArgs.items[1..]) |item| if (item) |p| allocater.free(std.mem.span(p));
        cArgs.deinit(allocater);
    }

    cArgs.appendAssumeCapacity(try allocater.dupeSentinel(u8, thepath, 0));
    for (args) |arg| cArgs.appendAssumeCapacity(try allocater.dupeSentinel(u8, arg, 0));
    cArgs.appendAssumeCapacity(null);

    run(cArgs.items[0].?, cArgs.items.ptr);
}
