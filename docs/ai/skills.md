# Skills

Agent skills declared in .chezmoidata/skills.yaml and installed into ~/.agents/skills and ~/.claude/skills by a chezmoi script.

Agent skills are folders with a `SKILL.md` file (frontmatter `name` and `description`, then instructions) that agents load on demand. The repo does not vendor them. It declares each skill and its source in `.chezmoidata/skills.yaml`, and the `run_onchange_after_25-skills.sh.tmpl` script installs them with the Skills CLI (`npx skills`) on `chezmoi apply`.

## Files

| Source in repo | Target | Notes |
| --- | --- | --- |
| `.chezmoidata/skills.yaml` | chezmoi data `.skills` | CLI version, default agents, and one entry per source |
| `.chezmoiscripts/run_onchange_after_25-skills.sh.tmpl` | runs `skills add` / `skills remove` | Re-runs when `.skills` changes; see [Scripts](../chezmoi/scripts.md#25-skills) |

Not role-gated; the sync runs on every machine. Installed skill files are machine state, not repo files:

| Path | Written by | Contents |
| --- | --- | --- |
| `~/.agents/skills/<name>/` | Skills CLI | Shared library for `universal` installs, read by Codex, Gemini CLI, OpenCode, Zed, … |
| `~/.claude/skills/<name>` | Skills CLI | Relative symlink `../../.agents/skills/<name>` for universal installs; a real copied directory for Claude-only installs |
| `$XDG_STATE_HOME/skills/.skill-lock.json` | Skills CLI | The CLI's own install record (`~/.agents/.skill-lock.json` when `XDG_STATE_HOME` is unset) |
| `${XDG_STATE_HOME:-~/.local/state}/chezmoi/skills.txt` | sync script | Skill names installed by the previous sync, used to remove undeclared ones |

## skills.yaml

```yaml
skills:
  cli: skills@1.7.0                 # pinned CLI, run via npx -y
  agents: [universal, claude-code]  # default install targets
  sources:
    - source: cloudflare/skills
      agents: [claude-code]         # Claude Code only
      skills: [agents-sdk, durable-objects]
```

| Key | Meaning |
| --- | --- |
| `cli` | npm spec of the Skills CLI, run as `npx -y <cli>` |
| `agents` | Default `-a` targets. `universal` is `~/.agents/skills`; `claude-code` is `~/.claude/skills` |
| `sources[].source` | Anything `skills add` accepts: `owner/repo` (default branch), a GitHub tree URL (pins a ref or subdirectory), or a well-known endpoint URL |
| `sources[].skills` | Skill names to install from that source (`--skill`) |
| `sources[].agents` | Optional override of the default `agents` |

108 skills across 42 source entries. `cloudflare/skills` appears twice: once with the defaults, once with `agents: [claude-code]`.

### Pinned sources

Unpinned sources track the upstream default branch, so skill content updates whenever the sync runs. Skills that upstream deleted or renamed are pinned to the last ref that still has them:

| Source | Skills | Reason |
| --- | --- | --- |
| `https://github.com/mattpocock/skills/tree/v1.1.0` | `design-an-interface`, `obsidian-vault`, `qa`, `request-refactor-plan`, `ubiquitous-language`, `writing-great-skills` | Removed upstream in c66bdee (`writing-great-skills` became `writing-for-agents`) |
| `https://github.com/mattpocock/skills/tree/153fc1b…` | `resolving-merge-conflicts` | Removed upstream in daa01d8 |
| `https://github.com/terrylica/cc-skills/tree/6d35f84…` | `mise-tasks` | Retired upstream in dd0d3f2f |
| `https://github.com/cloudflare/skills/tree/30553f8…` | `sandbox-sdk` | Replaced upstream by `sandbox-stable` / `sandbox-next` in f96bff7 |

`create-beads-orchestration` uses the subdirectory URL `https://github.com/AvivK5498/Claude-Code-Beads-Orchestration/tree/main/skills/create-beads-orchestration`, because the bare repo's root `SKILL.md` would install the whole repository as the skill. The Mintlify skills come from the well-known endpoint `https://mintlify.com/docs`.

### Not managed

`omarchy` and `diagnose-crash` (symlinks into `/usr/share/omarchy`) and `terminal-browser` are installed by other packages. They are not in `skills.yaml`, and the sync never touches them.

## Managing skills

Find a skill's source and name with the CLI, then declare it:

```sh
npx skills find <query>              # search the registry
npx skills add <source> --list       # list the skills a source provides
```

- **Add**: add the name under its source in `.chezmoidata/skills.yaml` (or a new `source` entry) and run `chezmoi apply`.
- **Remove**: delete the name and run `chezmoi apply`; the sync runs `skills remove` for it.
- **Claude Code only**: put it in an entry with `agents: [claude-code]`.

Do not `npx skills add` by hand and expect chezmoi to track it; only `skills.yaml` is the record. The script only re-runs when `.skills` changes, so unpinned sources pick up upstream updates on the next sync after an edit to `skills.yaml`.

## How the sync works

1. **Trigger**

   The script is `run_onchange_after_`: chezmoi re-runs it after applying files whenever the sha256 of `.skills` (as JSON) changes. If `npx` is missing it warns and skips.

2. **Migrate**

   One-time cleanup of the old vendored layout: deletes any directory in `~/.agents/skills` or `~/.claude/skills` that contains symlinks into the chezmoi source directory, and removes `~/.agents/.skill-lock.json` if it is a symlink into the source directory.

3. **Remove**

   Skills listed in `skills.txt` (the previous sync) but no longer declared are removed with `skills remove -g -y`.

4. **Install**

   One `skills add <source> -g -y -a <agents> --skill <names…>` per source entry. Output is captured; on failure the last 8 lines are printed.

5. **Record**

   The declared names are written to `skills.txt`. Claude-only (`-a claude-code`) installs are not recorded in the CLI lock, which is why the script keeps its own state file.

6. **Retry**

   If any source failed the script exits 1, so chezmoi keeps the old hash and runs it again on the next apply.

Every universal skill gets both a `~/.agents/skills` directory and a `~/.claude/skills` link. Claude Code resolves `~/.claude/skills/<name>` → `../../.agents/skills/<name>`, so both read the same files.

## Library

The Description column is the first sentence of each installed skill's `SKILL.md` frontmatter `description`. Source is the `source` from `skills.yaml` (GitHub URLs shortened to `owner/repo/tree/<ref>`). Agents `claude-code` means the skill is installed as a real directory in `~/.claude/skills` only.

| Skill | Source | Agents | Description |
| --- | --- | --- | --- |
| `absurd` | `earendil-works/absurd` | claude-code | Debug and operate Absurd durable workflows with absurdctl. |
| `agents-sdk` | `cloudflare/skills` | claude-code | Build, debug, or review Cloudflare Agents SDK applications using the agents package. |
| `brandkit` | `Leonxlnx/taste-skill` | universal + claude-code | Premium brand-kit image generation skill for creating high-end brand-guidelines boards, logo systems, identity decks, and visual-world presentations. |
| `bun-development` | `sickn33/antigravity-awesome-skills` | universal + claude-code | Fast, modern JavaScript/TypeScript development with the Bun runtime, inspired by [oven-sh/bun](https://github.com/oven-sh/bun). |
| `cloudflare` | `cloudflare/skills` | universal + claude-code | Discover and choose Cloudflare products for apps, APIs, AI agents, storage, networking, and security. |
| `cloudflare-email-service` | `cloudflare/skills` | claude-code | Implement or troubleshoot Cloudflare Email Sending and Email Routing integrations and their delivery configuration. |
| `cloudflare-one` | `cloudflare/skills` | claude-code | Design, configure, troubleshoot, or review Cloudflare One Zero Trust and SASE deployments. |
| `cloudflare-one-migrations` | `cloudflare/skills` | claude-code | Assess and plan migrations from existing VPN, SWG, or SASE platforms to Cloudflare One, including policy mapping, parity gaps, and rollout. |
| `codebase-design` | `mattpocock/skills` | universal + claude-code | Shared vocabulary for designing deep modules. |
| `core` | `vercel-labs/json-render` | universal + claude-code | Core package for defining schemas, catalogs, and AI prompt generation for json-render. |
| `create-beads-orchestration` | `AvivK5498/Claude-Code-Beads-Orchestration/tree/main/skills/create-beads-orchestration` | claude-code | Bootstrap lean multi-agent orchestration with beads task tracking. |
| `deepinit` | `yeachan-heo/oh-my-claudecode` | universal + claude-code | Deep codebase initialization with hierarchical AGENTS.md documentation |
| `design-an-interface` | `mattpocock/skills/tree/v1.1.0` | universal + claude-code | Generate multiple radically different interface designs for a module using parallel sub-agents. |
| `design-taste-frontend` | `Leonxlnx/taste-skill` | universal + claude-code | Anti-slop frontend skill for landing pages, portfolios, and redesigns. |
| `diagnosing-bugs` | `mattpocock/skills` | universal + claude-code | Diagnosis loop for hard bugs and performance regressions. |
| `domain-modeling` | `mattpocock/skills` | universal + claude-code | Build and sharpen a project's domain model. |
| `durable-objects` | `cloudflare/skills` | claude-code | Build, debug, or review Cloudflare Durable Objects code for persistent state and coordination. |
| `eli5` | `coldteadotai/pr-lens` | universal + claude-code | Explains a codebase, a folder, a feature, a command or a pull request to someone who knows nothing about it, as a PR Lens canvas whose walkthrough builds the picture one part at a time. |
| `find-skills` | `vercel-labs/skills` | universal + claude-code | Helps users discover and install agent skills when they ask questions like "how do I do X", "find a skill for X", "is there a skill that can...", or express interest in extending capabilities. |
| `fumadocs-component-docs` | `TheOrcDev/8bitcn-ui` | universal + claude-code | Create component documentation with installation, usage examples, and preview sections. |
| `fumadocs-mdx-structure` | `TheOrcDev/8bitcn-ui` | universal + claude-code | Create MDX documentation files with proper frontmatter, imports, and component integration. |
| `fumadocs-registry-integration` | `TheOrcDev/8bitcn-ui` | universal + claude-code | Register 8-bit components in registry.json for shadcn/ui add command. |
| `git-guardrails-claude-code` | `mattpocock/skills` | universal + claude-code | Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. |
| `golang-pro` | `jeffallan/claude-skills` | universal + claude-code | Implements concurrent Go patterns using goroutines and channels, designs and builds microservices with gRPC or REST, optimizes Go application performance with pprof, and enforces idiomatic Go with generics, interfaces, and robust error handling. |
| `gpt-taste` | `Leonxlnx/taste-skill` | universal + claude-code | Elite UX/UI & Advanced GSAP Motion Engineer. |
| `grill-me` | `mattpocock/skills` | universal + claude-code | A relentless interview to sharpen a plan or design. |
| `grill-with-docs` | `mattpocock/skills` | universal + claude-code | A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go. |
| `grilling` | `mattpocock/skills` | universal + claude-code | Grill the user relentlessly about a plan, decision, or idea. |
| `handoff` | `mattpocock/skills` | universal + claude-code | Compact the current conversation into a handoff document for another agent to pick up. |
| `high-end-visual-design` | `Leonxlnx/taste-skill` | universal + claude-code | Teaches the AI to design like a high-end agency. |
| `imagegen-frontend-web` | `Leonxlnx/taste-skill` | universal + claude-code | Elite frontend image-direction skill for generating premium, conversion-aware website design references. |
| `implement` | `mattpocock/skills` | universal + claude-code | Implement a piece of work based on a spec or set of tickets. |
| `improve-codebase-architecture` | `mattpocock/skills` | universal + claude-code | Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick. |
| `interface-design` | `Dammyjay93/interface-design` | universal + claude-code | Craft-first interface design for dashboards, admin panels, SaaS apps, tools, settings pages, data interfaces, and interactive products. |
| `laws-of-ux` | `RoleModel/rolemodel-skills` | universal + claude-code | Review and guide UI implementations using the 21 Laws of UX. |
| `linear` | `openai/skills` | universal + claude-code | Manage issues, projects & team workflows in Linear. |
| `linear-cli` | `schpet/linear-cli` | universal + claude-code | Manage Linear issues from the command line using the linear cli. |
| `linear-documents` | `finesssee/linear-cli` | universal + claude-code | Manage Linear documents. |
| `loop-me` | `mattpocock/skills` | universal + claude-code | Grill me about specs for the workflows I want to build, within this workspace. |
| `loopy` | `Forward-Future/loop-library` | universal + claude-code | Discover, find, compare, audit, repair, adapt, craft, run, debrief, save, and prepare repeatable AI-agent loops for publication. |
| `migrate-to-shoehorn` | `mattpocock/skills` | universal + claude-code | Migrate test files from `as` type assertions to @total-typescript/shoehorn. |
| `minimalist-ui` | `Leonxlnx/taste-skill` | universal + claude-code | Clean editorial-style interfaces. |
| `mintlify` | `https://mintlify.com/docs` | universal + claude-code | Build and maintain documentation sites with Mintlify. |
| `mintlify-api` | `https://mintlify.com/docs` | universal + claude-code | Interact with the Mintlify REST API to manage deployments, trigger builds, and query documentation site metadata programmatically. |
| `mintlify-docs` | `https://mintlify.com/docs` | universal + claude-code | Build and maintain documentation sites with Mintlify. |
| `mise-tasks` | `terrylica/cc-skills/tree/6d35f84` | universal + claude-code | Orchestrate multi-step project workflows using mise task definitions with dependency management and argument handling. |
| `native-sdk` | `vercel-labs/native` | universal + claude-code | Discovery skill for the Native SDK, the complete toolkit for building native desktop applications. |
| `no-ai-slop` | `petergyang/no-ai-slop` | universal + claude-code | Edit drafts into sharper, more human writing while preserving the writer's personal voice, or detect AI-slop patterns without rewriting. |
| `obscura` | `h4ckf0r0day/obscura` | universal + claude-code | Operate and validate Obscura for JavaScript page loading, stealth browsing, anti-fingerprinting, and browser automation. |
| `obsidian-vault` | `mattpocock/skills/tree/v1.1.0` | universal + claude-code | Search, create, and manage notes in the Obsidian vault with wikilinks and index notes. |
| `openlogs-server-logs` | `charlietlamb/openlogs` | universal + claude-code | Fetch and inspect recent local server logs in repos that use openlogs or the `ol` CLI. |
| `pr-lens` | `coldteadotai/pr-lens` | universal + claude-code | Draws a code change or part of a codebase as an animated architecture or data-flow diagram, on its own or in a pull request. |
| `prototype` | `mattpocock/skills` | universal + claude-code | Build a throwaway prototype to answer a design question. |
| `qa` | `mattpocock/skills/tree/v1.1.0` | universal + claude-code | Interactive QA session where user reports bugs or issues conversationally, and the agent files GitHub issues. |
| `react` | `vercel-labs/json-render` | universal + claude-code | React renderer for json-render that turns JSON specs into React components. |
| `react-email` | `vercel-labs/json-render` | universal + claude-code | React Email renderer for json-render that turns JSON specs into HTML or plain-text emails using @react-email/components and @react-email/render. |
| `redesign-existing-projects` | `Leonxlnx/taste-skill` | universal + claude-code | Upgrades existing websites and apps to premium quality. |
| `remix` | `remix-run/remix` | universal + claude-code | Builds, reviews, and refactors Remix 3 apps using the remix package and remix/* imports. |
| `remotion-best-practices` | `remotion-dev/skills` | universal + claude-code | Router for all Remotion skills |
| `remotion-captions` | `remotion-dev/skills` | universal + claude-code | Transcribing, displaying and animating captions |
| `remotion-create` | `remotion-dev/skills` | universal + claude-code | Create a new Remotion video |
| `remotion-docs` | `remotion-dev/skills` | universal + claude-code | Search Remotion documentation |
| `remotion-interactivity` | `remotion-dev/skills` | universal + claude-code | Structure Remotion markup for interactivity |
| `remotion-maps` | `remotion-dev/skills` | universal + claude-code | Remotion Map animation knowledge |
| `remotion-markup` | `remotion-dev/skills` | universal + claude-code | Content, animation and effects best practices |
| `remotion-multimedia` | `remotion-dev/skills` | universal + claude-code | Interacting with Mediabunny |
| `remotion-render` | `remotion-dev/skills` | universal + claude-code | Export a Remotion video |
| `remotion-saas` | `remotion-dev/skills` | universal + claude-code | Build an app with Remotion |
| `remotion-studio` | `remotion-dev/skills` | universal + claude-code | Preview a Remotion video |
| `remotion-upgrade` | `remotion-dev/skills` | universal + claude-code | Upgrade Remotion, and related packages |
| `request-refactor-plan` | `mattpocock/skills/tree/v1.1.0` | universal + claude-code | Create a detailed refactor plan with tiny commits via user interview, then file it as a GitHub issue. |
| `resolving-merge-conflicts` | `mattpocock/skills/tree/153fc1b` | universal + claude-code | Use when you need to resolve an in-progress git merge/rebase conflict. |
| `rust-async-patterns` | `wshobson/agents` | universal + claude-code | Master Rust async programming with Tokio, async traits, error handling, and concurrent patterns. |
| `rust-best-practices` | `apollographql/skills` | universal + claude-code | Guide for writing idiomatic Rust code based on Apollo GraphQL's best practices handbook. |
| `rust-skills` | `leonardomso/rust-skills` | universal + claude-code | Comprehensive Rust coding guidelines with 265 rules across 26 categories. |
| `rust-testing` | `affaan-m/everything-claude-code` | universal + claude-code | Rust testing patterns including unit tests, integration tests, async testing, property-based testing, mocking, and coverage. |
| `sandbox-sdk` | `cloudflare/skills/tree/30553f8` | claude-code | Build sandboxed applications for secure code execution. |
| `scaffold-exercises` | `mattpocock/skills` | universal + claude-code | Create exercise directory structures with sections, problems, solutions, and explainers that pass linting. |
| `setup-matt-pocock-skills` | `mattpocock/skills` | universal + claude-code | Configure this repo for the engineering skills: set up its issue tracker, triage label vocabulary, and domain doc layout. |
| `setup-pre-commit` | `mattpocock/skills` | universal + claude-code | Set up Husky pre-commit hooks with lint-staged (Prettier), type checking, and tests in the current repo. |
| `shadcn` | `shadcn-ui/ui` | universal + claude-code | Manages shadcn components and projects — adding, searching, fixing, debugging, styling, and composing UI, including chat interfaces. |
| `solidity-foundry-development` | `whackur/solidity-agent-toolkit` | universal + claude-code | Foundry development workflow for Solidity smart contracts. |
| `solidity-security` | `wshobson/agents` | universal + claude-code | Master smart contract security best practices to prevent common vulnerabilities and implement secure Solidity patterns. |
| `stop-slop` | `hardikpandya/stop-slop` | universal + claude-code | Remove AI writing patterns from prose. |
| `tanstack-form` | `tanstack-skills/tanstack-skills` | universal + claude-code | Headless, performant, and type-safe form state management for TS/JS, React, Vue, Angular, Solid, Lit, and Svelte. |
| `tanstack-integration-best-practices` | `deckardger/tanstack-agent-skills` | universal + claude-code | Best practices for integrating TanStack Query with TanStack Router and TanStack Start. |
| `tanstack-query-best-practices` | `deckardger/tanstack-agent-skills` | universal + claude-code | TanStack Query (React Query) best practices for data fetching, caching, mutations, and server state management. |
| `tanstack-router-best-practices` | `deckardger/tanstack-agent-skills` | universal + claude-code | TanStack Router best practices for type-safe routing, data loading, search params, and navigation. |
| `tanstack-start-best-practices` | `deckardger/tanstack-agent-skills` | universal + claude-code | TanStack Start best practices for full-stack React applications. |
| `tanstack-table` | `tanstack-skills/tanstack-skills` | universal + claude-code | Headless UI for building powerful tables & datagrids for TS/JS, React, Vue, Solid, Svelte, Qwik, Angular, and Lit. |
| `tdd` | `mattpocock/skills` | universal + claude-code | Test-driven development. |
| `teach` | `mattpocock/skills` | universal + claude-code | Teach the user a new skill or concept, within this workspace. |
| `todoist-cli` | `Doist/todoist-cli` | universal + claude-code | Manage Todoist tasks, projects, labels, filters, sections, comments, reminders, and workspaces via the `td` CLI. |
| `triage` | `mattpocock/skills` | universal + claude-code | Move issues and external PRs through a state machine of triage roles, categorise, verify, grill if needed, and write agent-ready briefs. |
| `turnstile-spin` | `cloudflare/skills` | claude-code | Set up, repair, or migrate to Cloudflare Turnstile bot verification in an existing frontend and backend, including server-side Siteverify. |
| `typescript-expert` | `remix-run/remix` | universal + claude-code | Write, refactor, or review TypeScript code with strict, precise, maintainable types and without unnecessary `any`, type assertions, or type suppressions. |
| `ubiquitous-language` | `mattpocock/skills/tree/v1.1.0` | universal + claude-code | Extract a DDD-style ubiquitous language glossary from the current conversation, flagging ambiguities and proposing canonical terms. |
| `ui-ux-pro-max` | `nextlevelbuilder/ui-ux-pro-max-skill` | universal + claude-code | UI/UX design intelligence for web, mobile, and desktop. |
| `uv-package-manager` | `wshobson/agents` | universal + claude-code | Master the uv package manager for fast Python dependency management, virtual environments, and modern Python project workflows. |
| `web-design-guidelines` | `vercel-labs/agent-skills` | universal + claude-code | Review UI code for Web Interface Guidelines compliance. |
| `web-perf` | `cloudflare/skills` | claude-code | Audit, diagnose, or optimize website loading and interaction performance, Core Web Vitals, and Lighthouse performance scores. |
| `workers-best-practices` | `cloudflare/skills` | universal + claude-code | Cloudflare Workers best practices for production applications. |
| `wrangler` | `cloudflare/skills` | universal + claude-code | Run or troubleshoot Wrangler CLI commands and configure Worker projects for local development, Previews, deployment, and Cloudflare resource management. |
| `write-tests` | `remix-run/remix` | universal + claude-code | Write, refactor, or review tests in the Remix repository. |
| `writing-beats` | `mattpocock/skills` | universal + claude-code | Writing, exploit; assemble raw material into a journey of beats, grounding each term before a beat leans on it. |
| `writing-fragments` | `mattpocock/skills` | universal + claude-code | Writing, explore: mine raw fragments, no structure yet. |
| `writing-great-skills` | `mattpocock/skills/tree/v1.1.0` | universal + claude-code | Reference for writing and editing skills well — the vocabulary and principles that make a skill predictable. |
| `writing-shape` | `mattpocock/skills` | universal + claude-code | Writing, exploit: shape raw material into an article, paragraph by paragraph. |
