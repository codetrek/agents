# Agent skills

Reusable agent skills live in `skills/<name>/`. Each directory has a `SKILL.md` entry point and may contain agent metadata or supporting references. Keep the checkout in place: installed skills link to these directories, so edits are immediately available on disk.

## Install

Install Git first. The installer clones the repository to `~/.agents` and runs setup. If that path already exists, preserve its contents before moving it aside, or run setup from your existing checkout.

On macOS or Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/codetrek/agents/main/install.sh | bash
```

On Windows, run this from Command Prompt. Windows setup uses Windows PowerShell and directory symbolic links; enable Developer Mode or run from an Administrator terminal.

```bat
curl.exe -fsSL https://raw.githubusercontent.com/codetrek/agents/main/install.cmd -o "%TEMP%\codetrek-agents-install.cmd" && call "%TEMP%\codetrek-agents-install.cmd"
```

To choose a different checkout path, pass it after `bash -s --` in the Bash command or as the first argument to the downloaded `install.cmd`. You can also clone the repository yourself and run `setup.sh` or `setup.cmd` from the checkout.

Setup links `~/.agents` to this checkout. If the checkout is already at `~/.agents`, setup uses it directly. Codex reads `~/.agents/skills` directly; Claude and Copilot each get a directory link to it. Setup also links the shared `AGENTS.md` for Codex and Claude, and the shared `agents/` directory for Codex and Copilot. It leaves `~/.codex/skills`, including `.system`, alone.

Setup keeps links that already point to the intended location and repairs links that point elsewhere, including broken links. If a link path is occupied by a regular file or directory, setup stops and reports the path.

## Update

Run `git pull --ff-only` in this checkout. New and removed skills are reflected through the directory links; start a new agent session if an existing one still shows the previous catalog. Rerun setup to restore missing or incorrect links. To uninstall, remove the links created by setup and keep the checkout intact.
