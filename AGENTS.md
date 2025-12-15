# Repository Guidelines

## Project Structure & Module Organization
- Root contains reference materials for the ticket manager and RAG workflows: PDFs with process overviews (`Overview of Ticket Workflow Integration.pdf`, `Ticket Manager Workflow Review and Recommendations.pdf`, `ticket_manager_research_full.pdf`) and JSON/CSV assets (`Ticket Manager (Airtable).json`, `RAG Workflow For( Customer service chat-bot).json`, `airtable_tickets_template.csv`).
- No compiled sources or code modules are present; treat the repository as documentation + data. Add new assets in descriptive, dated subfolders if the root becomes crowded (e.g., `docs/2024-05/`).

## Build, Test, and Development Commands
- There is no build system or runtime here. When adding scripts, prefer portable POSIX shell. Document any new command in this section.
- If you add notebooks or prototypes, place them under `experiments/` and include a short `README` with run steps.

## Coding Style & Naming Conventions
- File names: use kebab-case for markdown/text (e.g., `triage-playbook.md`) and snake_case for data exports (e.g., `tickets_2024-05-12.csv`).
- Markdown: wrap at ~100 characters where practical; use `##`-level sections with concise bullets.
- Data files: keep UTF-8 CSV/JSON; include a header row for CSV and schema notes in a sibling `README`.

## Testing Guidelines
- No automated tests exist. If you add scripts, include a lightweight self-check target (e.g., `./scripts/lint.sh` or `make check`) and sample input/output to validate parsing of the provided CSV/JSON files.
- For data changes, provide a brief verification note (rows added/removed, schema changes) in your PR description.

## Commit & Pull Request Guidelines
- Commits: write imperative, scoped subjects (e.g., `add triage playbook outline`, `update airtable template schema`). Keep related changes together; avoid bundling data and doc rewrites without explanation.
- Pull requests: include purpose, key changes, and verification steps (manual checks on CSV/JSON). Link related tickets. Add screenshots only when UI artifacts are introduced.

## Security & Configuration Tips
- Do not commit secrets or live credentials. If sample keys are needed, clearly mark them as placeholders and keep them in a dedicated `samples/` directory.
- For any integration notes (Airtable, RAG backends), describe required environment variables and red-team them for accidental leakage before opening a PR.
