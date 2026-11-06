# Skills

Agent skills from [prdlk/skills](https://github.com/prdlk/skills), installed into ~/.agents/skills and ~/.claude/skills by a chezmoi script.

Agent skills are folders with a `SKILL.md` file (frontmatter `name` and `description`, then instructions) that agents load on demand. The repo does not vendor or list them: [prdlk/skills](https://github.com/prdlk/skills) is the single source, and `run_onchange_after_25-skills.sh.tmpl` installs every skill in it with the Skills CLI (`npx skills`) on `chezmoi apply`. Any skill the CLI installed from another source is removed.

## Files

| Source in repo | Target | Notes |
| --- | --- | --- |
| `.chezmoidata/skills.yaml` | chezmoi data `.skills` | CLI version, agents, and the one source |
| `.chezmoiscripts/run_onchange_after_25-skills.sh.tmpl` | runs `skills add` / `skills remove` | Re-runs when `.skills` changes; see [Scripts](../chezmoi/scripts.md#25-skills) |

Not role-gated; the sync runs on every machine. Installed skill files are machine state, not repo files:

| Path | Written by | Contents |
| --- | --- | --- |
| `~/.agents/skills/<name>/` | Skills CLI | Shared library for `universal` installs, read by Codex, Gemini CLI, OpenCode, Zed, … |
| `~/.claude/skills/<name>` | Skills CLI | Relative symlink `../../.agents/skills/<name>` |
| `${XDG_STATE_HOME:-~/.local/state}/skills/.skill-lock.json` | Skills CLI | The CLI's install record: each skill's `source` (`owner/repo`), path, and hash. The sync reads it to find skills from other sources |

## skills.yaml

```yaml
skills:
  cli: skills@1.7.0                 # pinned CLI, run via npx -y
  agents: [universal, claude-code]  # install targets
  source: prdlk/skills              # every skill in this repo is installed
```

| Key | Meaning |
| --- | --- |
| `cli` | npm spec of the Skills CLI, run as `npx -y <cli>` |
| `agents` | `-a` targets. `universal` is `~/.agents/skills`; `claude-code` is `~/.claude/skills` |
| `source` | Anything `skills add` accepts. `prdlk/skills` tracks its default branch; `https://github.com/prdlk/skills/tree/<ref>` pins a ref |

### Not managed

`omarchy`, `omarchy-app` and `diagnose-crash` (symlinks into `/usr/share/omarchy`) and `terminal-browser` are installed by other packages. They are not in the CLI's lock file, so the sync never touches them.

## Managing skills

- **Add or remove a skill**: change it in [prdlk/skills](https://github.com/prdlk/skills) and push. The script only re-runs when `.skills` changes, so pull the change in with `npx -y skills@1.7.0 update -g`, or re-run the sync by editing `skills.yaml` (for example pinning a new ref).
- **Skills from other sources**: not supported. A skill added with `npx skills add <other>` is removed by the next sync; add it to prdlk/skills instead.

## How the sync works

1. **Trigger**

   The script is `run_onchange_after_`: chezmoi re-runs it after applying files whenever the sha256 of `.skills` (as JSON) changes. If `npx` or `jq` is missing it warns and skips.

2. **Migrate**

   One-time cleanup: deletes any directory in `~/.agents/skills` or `~/.claude/skills` that contains symlinks into the chezmoi source directory (the old vendored layout), removes `~/.agents/.skill-lock.json` if it is a symlink into the source directory, and deletes the old per-skill state file `~/.local/state/chezmoi/skills.txt`.

3. **Install**

   `skills add <source> -g -y -a <agents> --skill '*'` installs every skill in the source. A skill already installed from another source under the same name is reinstalled from prdlk/skills, and the lock records the new source.

4. **Prune**

   Every lock entry whose `source` is not the configured repo (tree URLs reduced to `owner/repo`) is removed with `skills remove -g -y`.

5. **Retry**

   If the install or the removal fails the script exits 1, so chezmoi keeps the old hash and runs it again on the next apply. A failed install removes nothing.

Every skill gets both a `~/.agents/skills` directory and a `~/.claude/skills` link. Claude Code resolves `~/.claude/skills/<name>` → `../../.agents/skills/<name>`, so both read the same files.

## Library

The 69 skills in prdlk/skills when this page was written. The Description column is the first sentence of each skill's `SKILL.md` frontmatter `description`.

| Skill | Description |
| --- | --- |
| `absurd` | Debug and operate Absurd durable workflows with absurdctl. |
| `attach-db` | Attach a DuckDB database file for use with /duckdb-skills:query. |
| `blume` | Build and maintain documentation sites with Blume, the markdown-first docs framework on Astro and Vite. |
| `blume-migrate` | Migrate an existing documentation site (Mintlify, Docusaurus, Fumadocs, Nextra, Starlight, or any docs framework) to Blume, the markdown-first docs framework on Astro. |
| `blume-update-docs` | Keep a Blume docs site in sync with the product it documents. |
| `cloudflare` | Discover and choose Cloudflare products for apps, APIs, AI agents, storage, networking, and security. |
| `cloudflare-email-service` | Implement or troubleshoot Cloudflare Email Sending and Email Routing integrations and their delivery configuration. |
| `codebase-design` | Shared vocabulary for designing deep modules. |
| `deepinit` | Deep codebase initialization with hierarchical AGENTS.md documentation |
| `design-taste-frontend` | Anti-slop frontend skill for landing pages, portfolios, and redesigns. |
| `duckdb-docs` | Search DuckDB and DuckLake documentation and blog posts. |
| `durable-objects` | Build, debug, or review Cloudflare Durable Objects code for persistent state and coordination. |
| `find-skills` | Helps users discover and install agent skills when they ask questions like "how do I do X", "find a skill for X", "is there a skill that can...", or express interest in extending capabilities. |
| `golang-pro` | Implements concurrent Go patterns using goroutines and channels, designs and builds microservices with gRPC or REST, optimizes Go application performance with pprof, and enforces idiomatic Go with generics, interfaces, and robust error handling. |
| `grill-me` | A relentless interview to sharpen a plan or design. |
| `grill-with-docs` | A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go. |
| `grilling` | Grill the user relentlessly about a plan, decision, or idea. |
| `gum` | Gum 0.17.x for interactive and formatted terminal scripts: all 13 commands, GUM_* variables, the stdout/stderr and exit-code contract, theming, and shell traps. |
| `high-end-visual-design` | Teaches the AI to design like a high-end agency. |
| `improve-codebase-architecture` | Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick. |
| `interface-design` | Craft-first interface design for dashboards, admin panels, SaaS apps, tools, settings pages, data interfaces, and interactive products. |
| `laws-of-ux` | Review and guide UI implementations using the 21 Laws of UX. |
| `minimalist-ui` | Clean editorial-style interfaces. |
| `mise-expert` | Mise development environment manager (asdf + direnv + make replacement). |
| `no-ai-slop` | Edit drafts into sharper, more human writing while preserving the writer's personal voice, or detect AI-slop patterns without rewriting. |
| `obscura` | Operate and validate Obscura for JavaScript page loading, stealth browsing, anti-fingerprinting, tracker blocking, screenshots and visual comparison, CDP automation with Puppeteer or Playwright, screencasting, PDF export, MCP browser interaction, and web extraction. |
| `obsidian-vault` | Search, create, and manage notes in the Obsidian vault with wikilinks and index notes. |
| `openlogs-server-logs` | Fetch and inspect recent local server logs in repos that use openlogs or the `ol` CLI. |
| `pr-lens` | WHAT: Draws a code change or part of a codebase as an animated architecture or data-flow diagram, on its own or in a pull request. |
| `prototype` | Build a throwaway prototype to answer a design question. |
| `qa` | Interactive QA session where user reports bugs or issues conversationally, and the agent files GitHub issues. |
| `query` | Run SQL queries against the attached DuckDB database or ad-hoc against files. |
| `react` | React renderer for json-render that turns JSON specs into React components. |
| `react-email` | React Email renderer for json-render that turns JSON specs into HTML or plain-text emails using @react-email/components and @react-email/render. |
| `remotion-best-practices` | Router for all Remotion skills |
| `remotion-captions` | Transcribing, displaying and animating captions |
| `remotion-create` | Create a new Remotion video |
| `remotion-docs` | Search Remotion documentation |
| `remotion-interactivity` | Structure Remotion markup for interactivity |
| `remotion-maps` | Remotion Map animation knowledge |
| `remotion-markup` | Content, animation and effects best practices |
| `remotion-multimedia` | Interacting with Mediabunny |
| `remotion-render` | Export a Remotion video |
| `remotion-saas` | Build an app with Remotion |
| `remotion-studio` | Preview a Remotion video |
| `remotion-upgrade` | Upgrade Remotion, and related packages |
| `request-refactor-plan` | Create a detailed refactor plan with tiny commits via user interview, then file it as a GitHub issue. |
| `resolving-merge-conflicts` | Use when you need to resolve an in-progress git merge/rebase conflict. |
| `rust-async-patterns` | Master Rust async programming with Tokio, async traits, error handling, and concurrent patterns. |
| `rust-best-practices` | Guide for writing idiomatic Rust code based on Apollo GraphQL's best practices handbook. |
| `rust-skills` | Comprehensive Rust coding guidelines with 265 rules across 26 categories. |
| `rust-testing` | Rust testing patterns including unit tests, integration tests, async testing, property-based testing, mocking, and coverage. |
| `setup-matt-pocock-skills` | Configure this repo for the engineering skills: set up its issue tracker, triage label vocabulary, and domain doc layout. |
| `shadcn` | Manages shadcn components and projects — adding, searching, fixing, debugging, styling, and composing UI, including chat interfaces. |
| `stop-slop` | Remove AI writing patterns from prose. |
| `tanstack-form` | Headless, performant, and type-safe form state management for TS/JS, React, Vue, Angular, Solid, Lit, and Svelte. |
| `tanstack-integration-best-practices` | Best practices for integrating TanStack Query with TanStack Router and TanStack Start. |
| `tanstack-query-best-practices` | TanStack Query (React Query) best practices for data fetching, caching, mutations, and server state management. |
| `tanstack-router-best-practices` | TanStack Router best practices for type-safe routing, data loading, search params, and navigation. |
| `tanstack-start-best-practices` | TanStack Start best practices for full-stack React applications. |
| `tanstack-table` | Headless UI for building powerful tables & datagrids for TS/JS, React, Vue, Solid, Svelte, Qwik, Angular, and Lit. |
| `tdd` | Test-driven development. |
| `typescript-expert` | Write, refactor, or review TypeScript code with strict, precise, maintainable types and without unnecessary `any`, type assertions, or type suppressions. |
| `ui-ux-pro-max` | UI/UX design intelligence for web, mobile, and desktop. |
| `uv-package-manager` | Master the uv package manager for fast Python dependency management, virtual environments, and modern Python project workflows. |
| `web-design-guidelines` | Review UI code for Web Interface Guidelines compliance. |
| `web-perf` | Audit, diagnose, or optimize website loading and interaction performance, Core Web Vitals, and Lighthouse performance scores. |
| `workers-best-practices` | Cloudflare Workers best practices for production applications. |
| `wrangler` | Run or troubleshoot Wrangler CLI commands and configure Worker projects for local development, Previews, deployment, and Cloudflare resource management. |
