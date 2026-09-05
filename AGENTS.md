# AGENTS.md

> Instructions for AI coding agents working on BCSH.
>
> Recognized by: opencode, Claude Code, Cursor, Windsurf, Codex, DeepSeek, and other agent harnesses that look for `AGENTS.md`.

## What is BCSH?

BCSH ("The Best Coder Shell") is a small shell written in Rust.

- The shell implementation lives in **a single Rust source file**: `src/main.rs`.
- It aims to stay under 1 MB and to be **simple, lightweight, understandable, and easy to modify**.
- It is **not** trying to be Bash.

Read [CONTRIBUTING.md](CONTRIBUTING.md) end-to-end before making changes. It defines the philosophy. The summary below is not a substitute for it.

If you only have time to internalize one thing, internalize this:

> Does this actually make BCSH better, or am I just adding complexity?

## Core Philosophy (keep this in mind for every change)

BCSH should be:

- **Simple**
- **Small**
- **Fast**
- **Readable**
- **Hackable**

Code does not need to be perfect. It needs to be **useful without being unnecessarily complicated**. When in doubt, prefer the simpler solution.

### Keep it simple
Prefer simple code that is easy to read and modify. Do not add abstractions because they are "best practice" elsewhere. If something can be solved with a few simple lines, don't turn it into a framework.

### Don't add unnecessary features
Not every feature is useful for BCSH. Before adding something, ask whether users actually need it. A feature being available in Bash does **not** mean BCSH needs it.

### Don't over-handle errors
Do not add large amounts of error handling for situations users will never realistically see. Error handling should exist when it provides a real benefit, not to make the code *look* robust.

### Keep it small
Binary size and code size matter. Avoid new dependencies unless they provide meaningful benefit. Before adding a dependency, ask whether the standard library or an existing dependency already covers it.

### Keep it hackable
A person should be able to open the file, find a command, understand it, and modify it without learning a framework first. Simple code is a feature.

### Keep the one-file design
The shell itself must remain in **one** Rust source file. Do not split `src/main.rs` into multiple modules unless there is a strong reason. Additional files are fine for tests, docs, install scripts, and project config.

## Repository Layout

```
bcsh/
├── src/
│   ├── main.rs      # The entire shell implementation lives here
│   └── tests.rs     # Unit/integration tests
├── CONTRIBUTING.md  # Project philosophy and contribution rules
├── AI.md            # AI usage policy (human review + human testing required)
├── README.md        # User-facing docs (human-written)
├── Cargo.toml       # Keep dependencies minimal
├── flake.nix
├── install.sh
└── TODO.md
```

## When You Add a Command

A command should generally:

1. Do what it is supposed to do.
2. Handle important user mistakes.
3. Avoid unnecessary complexity.
4. Follow the existing style in `src/main.rs`.

Don't build a large command framework just to add one command. If a command needs significantly more code than the command itself, step back and pick a simpler approach.

Look at existing commands (`ls`, `pwd`, `cat`, `cd`, `rm`, `mkdir`, `touch`, `rmdir`, env var expansion) and **match their style**. Don't reinvent the pattern.

## When You Fix a Bug

1. If practical, add a test in `src/tests.rs` that reproduces the bug first.
2. Fix the problem.
3. Run `cargo test`.
4. Confirm the fix actually works by running the shell manually when possible.

Tests are a safety net, not a goal. We care about useful tests, not coverage numbers.

Commands worth testing: `ls`, `pwd`, `cat`, `rm`, `rmdir`, `touch`, `mkdir`, `cd`, env var expansion. Don't waste effort trying to test terminal handling, signals, process groups, or other low-level behavior that is hard to test reliably.

## Working Style for Agents

- **Read before writing.** Read `CONTRIBUTING.md`, `AI.md`, and the relevant code in `src/main.rs` before changing anything.
- **Match the existing style.** Don't introduce new patterns, crates, or abstractions when the file already shows a simpler way.
- **Smallest change that solves the problem.** Resist scope creep.
- **Don't refactor surrounding code** as part of an unrelated change. Use common sense — don't change working code just to satisfy a tool if it makes the code less clear.
- **No new dependencies** unless they clearly earn their keep. Prefer the standard library and crates already in `Cargo.toml` (`nix`, `glob`, `crossterm`, `signal-hook`, `libc`).
- **Don't split `src/main.rs`.** Keep the shell in one file.
- **Don't add comments** unless they add real value. No narration of obvious code.
- **User-facing content is off-limits for AI.** Anything a non-contributor will read (README, install instructions, release notes, website content, user guides, examples) must be written by a human. You may help brainstorm, but the final text must be human-authored. See `AI.md`.

## Before You Submit

Run, in order:

```
cargo fmt --check
cargo test
cargo clippy
```

If a tool complains and the fix makes the code less clear or more complex, **leave it alone**. Use common sense over tool worship.

## Pull Requests

- PRs go to the Forgejo instance at `https://git.bestcoder1877.qzz.io/bestCoder1877/bcsh`, **not** GitHub.
- Explain what you changed, why, any behavior changes, and any known limitations.
- Keep changes focused.

## AI-Specific Reminders

The human who submits your work is fully responsible for it. From `AI.md`:

- All AI-generated code must be **reviewed by a human** before submission.
- All AI-generated code must be **tested by a human** before it is considered complete. Automated tests are not enough — the contributor should actually use the feature when practical.
- Do not submit code blindly. The submitter must understand it and be able to explain it.
- AI output is not automatically correct.
- Don't use AI as a reason to make BCSH unnecessarily complicated. Shorter, simpler solutions beat complicated ones, even if the complicated one came from an LLM.

## Hard "Do Not" List

- Do not split `src/main.rs` into multiple modules.
- Do not add dependencies without a clear, meaningful benefit.
- Do not add error handling for cases users will never encounter.
- Do not add features just because Bash has them.
- Do not write or edit user-facing docs (README, install instructions, release notes, user guides) — humans only.
- Do not submit AI-generated code on behalf of a human without it being reviewed and tested by that human.
- Do not open PRs on GitHub. Forgejo only.

## Hard "Do" List

- Do keep code small and readable.
- Do match the style of the surrounding code in `src/main.rs`.
- Do prefer the standard library.
- Do add a test when fixing a bug, if practical.
- Do run `cargo fmt --check`, `cargo test`, and `cargo clippy` before considering work complete.
- Do ask: *"Does this make BCSH better, or am I just adding complexity?"*
