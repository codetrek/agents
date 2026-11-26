# Agent skills

Reusable agent skills live in `skills/<name>/`. Each directory has a `SKILL.md` entry point and may contain agent metadata or supporting references. Keep the checkout in place: installed skills link to these directories, so edits are immediately available on disk.

## Install

```sh
git clone https://github.com/codetrek/agents.git
cd agents
./setup.sh
```

Run `setup.sh` on macOS or Linux, or `setup.cmd` on Windows. Windows setup uses Windows PowerShell and directory symbolic links. Enable Windows Developer Mode or run it from an Administrator terminal.

Setup links `~/.agents` to this checkout. If the checkout is already at `~/.agents`, setup uses it directly. Codex reads `~/.agents/skills` directly; Claude and Copilot each get a directory link to it. Setup also links the shared `AGENTS.md` for Codex and Claude, and the shared `agents/` directory for Codex and Copilot. It leaves `~/.codex/skills`, including `.system`, alone.

Setup keeps links that already point to the intended location and repairs links that point elsewhere, including broken links. If a link path is occupied by a regular file or directory, setup stops and reports the path.

## Update

Run `git pull --ff-only` in this checkout. New and removed skills are reflected through the directory links; start a new agent session if an existing one still shows the previous catalog. Rerun setup to restore missing or incorrect links. To uninstall, remove the links created by setup and keep the checkout intact.
