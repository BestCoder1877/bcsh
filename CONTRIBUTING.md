# Contributing to BCSH

Thanks for contributing to **BCSH — The Best Coder Shell**!

BCSH is a small shell written in Rust. The goal is to make a shell that is **simple, lightweight, understandable, and easy to modify**.

BCSH is still in development, so bugs and incomplete features are expected.

## Getting Started

### Requirements

You will need:

- Rust
- Cargo
- Git

Clone the repository:

    git clone https://git.bestcoder1877.qzz.io/bestCoder1877/bcsh.git
    cd bcsh

Build BCSH:

    cargo build

Run BCSH:

    cargo run

## Testing

Run the tests with:

    cargo test

If you change existing behavior, add or update tests when it makes sense.

Tests are especially useful for commands such as:

- `ls`
- `pwd`
- `cat`
- `rm`
- `rmdir`
- `touch`
- `mkdir`
- `cd`
- environment variable expansion

Not everything needs a test. Terminal handling, signals, process groups, and other low-level functionality can be difficult to test and do not need unnecessary testing just for the sake of coverage.

## The BCSH Philosophy

BCSH is not trying to be Bash.

The project is intentionally simple.

When contributing, ask yourself:

> Does this actually make BCSH better, or am I just adding complexity?

### Keep It Simple

Prefer simple code that is easy to read and modify.

Do not add abstractions simply because they are considered "best practice" somewhere else.

If something can be solved with a few simple lines, there is usually no reason to turn it into a complicated system.

### Don't Add Unnecessary Features

Not every feature is useful for BCSH.

Before adding something, consider whether users actually need it.

BCSH should not become complicated just because another shell has a feature.

### Don't Over-Handle Errors

Do not add large amounts of error handling for situations that users will never realistically see or care about.

Error handling should exist when it provides a real benefit to the user or prevents a serious problem.

Do not add complexity just to make the code look more robust.

### Keep It Small

BCSH aims to remain extremely lightweight.

Avoid adding dependencies unless they provide a meaningful benefit.

Before adding a dependency, ask whether the functionality can reasonably be done with the standard library or existing dependencies.

Binary size and code size are important parts of the project.

### Keep It Hackable

BCSH should be easy for someone to open up and change.

A person should be able to find a command, understand it, and modify it without learning a large framework first.

Simple code is a feature.

### Keep the One-File Design

The main shell is intentionally written in one Rust source file.

Please keep it that way unless there is a strong reason to change it.

Additional files are fine for things such as:

- Tests
- Documentation
- Installation
- Project configuration

The shell itself should remain easy to find and understand.

## Adding a Command

When adding a command, keep the implementation simple.

A command should generally:

1. Do what it is supposed to do.
2. Handle important user mistakes.
3. Avoid unnecessary complexity.
4. Follow the existing style of BCSH.

Don't build a large command framework just to add one command.

If adding a command requires significantly more code than the command itself, consider whether there is a simpler approach.

## Fixing Bugs

If practical, add a test that reproduces the bug before fixing it.

For example:

    #[test]
    fn missing_file_is_handled() {
        // Reproduce the bug.
    }

Then fix the problem and run:

    cargo test

Tests are a safety net, not a goal by themselves.

We care more about useful tests than achieving a specific code-coverage number.

## Pull Requests

Please note that you cannot contribute on GitHub. You must submit pull requests on our Forgejo instance at https://git.bestcoder1877.qzz.io/bestCoder1877/bcsh.

When submitting a pull request, explain:

- What you changed.
- Why you changed it.
- Any important behavior changes.
- Any known limitations.

Keep changes focused when possible.

Before submitting, run:

    cargo fmt --check
    cargo test
    cargo clippy

However, don't change working code simply to satisfy a tool if doing so makes the code less clear or adds unnecessary complexity. Use common sense.

## Feature Requests

Feature requests are welcome.

For large features, consider discussing them before implementing them.

When proposing a feature, ask:

- Do users actually need it?
- Does it fit BCSH?
- Does it make the shell more complicated?
- Does it increase the binary size?
- Can it be implemented simply?

A feature being available in Bash does not automatically mean BCSH needs it.

## Breaking Changes

BCSH is still in development, so breaking changes can happen.

Try not to break existing behavior without a good reason.

If a change intentionally changes existing behavior, document it clearly.

## AI Usage

Read the terms for the usage of AI before using it.

## What We Want BCSH to Be

BCSH should be:

- **Simple**
- **Small**
- **Fast**
- **Readable**
- **Hackable**

The code does not need to be perfect.

It needs to be **useful without being unnecessarily complicated**.

When in doubt, prefer the simpler solution.