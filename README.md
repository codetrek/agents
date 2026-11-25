# Agent skills

Reusable agent skills live in `skills/<name>/`. Each directory has a `SKILL.md` entry point and may contain agent metadata or supporting references. Keep the checkout in place: installed skills link to these directories, so edits are immediately available on disk.

## Install

```sh
git clone https://github.com/codetrek/agents.git
cd agents
./setup.sh
```

Run `setup.sh` on macOS or Linux, or `setup.cmd` on Windows. The Windows script follows the dotfiles setup and uses Windows PowerShell and directory symbolic links. Enable Windows Developer Mode or run it from an Administrator terminal.

Setup links `~/.agents/skills` to the checkout's `skills/` directory. Codex reads this shared catalog directly. Claude and Copilot each get a single directory link to `~/.agents/skills`. The installers do not manage `~/.codex/skills`, including its built-in `.system` directory. On machines using the dotfiles checkout at `~/.env`, the existing `~/.agents` link and non-skill settings remain available. No dotfiles checkout is required for a standalone installation.

If an installation path contains other skills, files, or a link to a different catalog, inspect and preserve them before moving the conflicting path aside. For an older dotfiles checkout with real skill directories under `~/.env/.agents/skills`, compare them with this catalog and preserve any local changes before switching that directory to a link.

## Update

Run `git pull --ff-only` in this checkout. New and removed skills are reflected through the directory links; start a new agent session if an existing one still shows the previous catalog. Rerun setup to restore missing links. To uninstall the catalog, remove only the installed directory links, preserving their targets and the `.agents` parent.
