# Which AI UI/UX design skills and strategies are worth using for a SwiftUI driving HUD designed in Pencil?

Date: 2026-10-26. Scope: Claude Code skills and plugins first, plus design MCP servers; web and native iOS (SwiftUI); fit for an iPhone dark-UI speed HUD drawn in Pencil. "[unverified]" marks anything I could not confirm from a primary source. All pages were read on 2026-10-26 through a fetch tool that summarises the page, so numbers are as that tool reported them. Nothing was cloned or installed.

**Short answer:** keep `impeccable` as the one design skill: it is the only popular one that carries real iOS/HIG rules (its local copy has `reference/ios.md`), and it is already installed. Add one SwiftUI code skill (`swiftui-pro` is the best-adopted) only when we start writing SwiftUI. The strategy that matters more than any skill is a screenshot-compare loop plus a short project DESIGN.md. No candidate covers glance-read, large-numeral driving UI, so that rule set has to come from us.

## Sources
- G1 github.com/anthropics/skills (stars, README)
- G2 github.com/pbakaus/impeccable (README, install, harnesses)
- G3 github.com/nextlevelbuilder/ui-ux-pro-max-skill
- G4 github.com/leonxlnx/taste-skill
- G5 github.com/twostraws/SwiftUI-Agent-Skill
- G6 github.com/AvdLee/SwiftUI-Agent-Skill
- G7 github.com/ehmo/platform-design-skills
- G8 github.com/wshobson/agents (repo of 185 skills)
- G9 github.com/google-labs-code/design.md
- G10 github.com/anthropics/claude-plugins-official (no plugin list or install counts visible)
- G11 github.com/anthropics/claude-code, `plugins/frontend-design/skills/frontend-design/SKILL.md` (the plugin copy, which is the one installed here)
- S1 skills.sh home leaderboard ("All Time (1,442,305)"; page shows no date)
- S2 skills.sh per-skill pages: anthropics/skills/frontend-design, pbakaus/impeccable, twostraws/swiftui-agent-skill/swiftui-pro, avdlee/swiftui-agent-skill/swiftui-expert-skill, wshobson/agents/mobile-ios-design, designed-by-ai/skills/design-mobile-apps
- A1 Anthropic blog "Improving frontend design through Skills" (claude.com/blog, 2025-11-12)
- A2 Claude Code docs "Best practices" (code.claude.com/docs/en/best-practices)
- P1 pen.dev docs: home and AI-integration page (docs.pencil.dev)
- X1 Apple newsroom "Xcode 26.3 unlocks the power of agentic coding" (2026-02-03)
- F1 Figma Help "Guide to the Figma MCP server"
- L1 Local install `~/.claude/skills/impeccable/` v4.0.4 (SKILL.md, `reference/ios.md`)
- C1 composio.dev/blog/top-design-skills (2026-05-05; a lead only, no stars given)
- H1 Apple Human Interface Guidelines page: the page did not render for the fetch tool, so I have no primary read of the HIG [unverified]

## 1. Ranked skills
Ranked by GitHub repo stars (checked 2026-10-26), then by what the skill contains. Two cautions:
- **Stars of a multi-skill repo are not the skill's popularity.** `anthropics/skills` (183.8k) and `wshobson/agents` (41.7k) hold many skills, and skills.sh prints the repo number next to each skill.
- **skills.sh install counts are a weak quality signal.** `design-mobile-apps` shows 1.0M installs on a 20-star repo that wraps a paid sleek.design API and fails Snyk (S2). Treat installs as secondary evidence.

| # | Skill (publisher) | What it does | Web | iOS / SwiftUI | Repo stars | skills.sh installs |
|---|---|---|---|---|---|---|
| 1 | `frontend-design` (Anthropic) | Picks a bold aesthetic direction, plans a token system, then builds; fights generic AI look | Strong | Not covered (web only, G11) | 183.8k (whole repo, G1) | 1.0M (S2) |
| 2 | `ui-ux-pro-max` (nextlevelbuilder) | BM25 search over style, palette and font CSVs; emits a design-system doc; `--persist` writes `MASTER.md` | Strong | SwiftUI listed as one of 22 stacks (G3); depth not checked | 140.4k (G3) | 415.0K (S1) |
| 3 | `design-taste-frontend` (leonxlnx) | Art-direction pass, build, browser check, self-critique, up to 3 rounds; needs Node 22 and Chrome | Strong | None; web only (G4) | ~102.6k (G4) | 677.6K (S1) |
| 4 | `impeccable` (Paul Bakaus) | 24 commands (craft, critique, audit, polish, adapt...), deterministic anti-pattern rules, reads PRODUCT.md and DESIGN.md | Strong | Yes in v4.0.4: `ios.md`, `audit.native.md`, `adapt.native.md`, `android.md` (L1) | 88.0k (G2) | 360.9K (S2) |
| 5 | `mobile-ios-design` (wshobson/agents) | HIG + SwiftUI patterns: NavigationStack, SF Symbols, Dynamic Type, safe areas | No | Yes (listing text only) | 41.7k (whole repo, G8) | 23.8K (S2) |
| 6 | `swiftui-pro` (Paul Hudson) | Fixes common AI mistakes in SwiftUI API use, design, performance, accessibility; iOS 26+ | No | Yes, code side | 6.4k (G5) | 35.1K (S2) |
| 7 | `swiftui-expert-skill` (Antoine van der Lee) | State, composition, performance, Liquid Glass, Instruments traces; "non-opinionated" | No | Yes, code side | 3.8k (G6) | ~35.1K (S2) |
| 8 | `ios-design-guidelines` (ehmo/platform-design-skills) | iPhone rules distilled from a scrape of the HIG (67+ iOS rules per README) | No | Yes, HIG-derived | 625 (G7) | ~1.3k [unverified, secondary listing] |

Seen but not rankable:
- `ios-design` (uizze.sh): 414.4K installs on the leaderboard (S1), but its page returned 404 and a search found nothing. [unverified]
- `design-mobile-apps` (designed-by-ai): 1.0M installs, 20 stars, Snyk fail (S2). Not recommended.
- From C1 only [unverified]: Owl-Listener/designer-skills, julianoczkowski/designer-skills, Accesslint, theme-factory.

Publisher, install, licence:
- **`impeccable`:** created by Paul Bakaus (G2; the secondary guide calling him a former Google developer advocate and creator of jQuery UI is [unverified]). Apache-2.0. Install `npx impeccable install` or `/plugin marketplace add pbakaus/impeccable`. Runs in 17 harnesses including Claude Code, Codex CLI and Cursor (G2). skills.sh audits: Gen Pass, Socket Warn, Snyk Pass (S2).
- **`frontend-design`:** Anthropic, in `anthropics/skills` and the Claude Code plugin set (G1, G11). skills.sh audits all pass (S2).
- **`ui-ux-pro-max`:** MIT. `/plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill` or `npx ui-ux-pro-max-cli init --ai claude`. Needs Python 3; its scripts claim no network calls (G3).
- **SwiftUI skills:** both MIT. `/plugin marketplace add twostraws/SwiftUI-Agent-Skill` then `/plugin install swiftui-pro@swiftui-agent-skill` (G5). `/plugin marketplace add AvdLee/SwiftUI-Agent-Skill` then `/plugin install swiftui-expert@swiftui-expert-skill` (G6). Both pass all three audits on skills.sh (S2).
- **Correction to the README:** the `impeccable` README and skills.sh blurb never mention iOS (G2, S2). The installed v4.0.4 does ship an iOS reference (L1), so those descriptions understate it.

## 2. Strategies, as their owners state them
1. **Fight "distributional convergence" (Anthropic).** Models sample from the high-probability centre of design in their training data, so output looks generic (A1). Fix: commit to one aesthetic, "dominant colors with sharp accents outperform timid, evenly-distributed palettes", one distinctive font used decisively, one orchestrated motion moment, depth in backgrounds (A1).
2. **Plan a token system before code (G11).** The current SKILL.md asks for 4-6 named colors, type roles and a layout concept, a check for generic defaults, then build, screenshot and a "remove one accessory" critique. Its rule: "Spend your boldness in one place." It is web-oriented; the only mobile line is "responsive down to mobile" (G11).
3. **Screenshot-compare loop (Anthropic docs).** "[paste screenshot] implement this design. take a screenshot of the result and compare it to the original. list differences and fix them" (A2). Anthropic's stated principle is to give Claude a check it can run, and to have it show evidence (A2).
4. **Project context files.** `impeccable` reads PRODUCT.md and DESIGN.md to stay on brand (S2). Google's open DESIGN.md format (28.5k stars, Apache-2.0) pairs YAML tokens with prose; it is alpha, with `lint`, `diff` and `export` to Tailwind or W3C tokens (G9). Its exports are web-shaped (inference; the page does not say web-only).
5. **Native iOS: platform first.** `impeccable`'s `ios.md` states: HIG governs structure, navigation and interaction; brand lives in tint, type, motion and content. Its tests: 44x44 pt targets, Dynamic Type, semantic system colors, Dark Mode as first-class, "no hand-rolled glassmorphism" (L1). I could not read the HIG itself (H1).
6. **Xcode previews as the screenshot source.** Xcode 26.3 lets Claude Agent and Codex "capture Xcode Previews" and iterate on builds, exposed over MCP (X1). Tool names and `xcrun mcpbridge` are [unverified].
7. **Design-tool MCP servers.**
   - **Pencil:** runs a local MCP server with `get_style`, `read_skill`, `get_app_state`, `execute`, and `browser` (desktop only). Works with Claude Code, Codex and ChatGPT; open the target `.pen` first and pass its full path (P1). That matches the tools in this session. Its design-to-code and skills pages returned 404, so SwiftUI export and HTML import are [unverified] from docs; a search only showed React, Next, Vue, Svelte and HTML/CSS targets.
   - **Figma MCP:** pulls frame context and variables into code, writes to the canvas, supports Code Connect, and lists Xcode among clients; no SwiftUI claim (F1). We are on Pencil, so it is only a reference.
8. **Taste/critique loops (taste-skill).** Three build rounds with self-review of screenshots, 30-45 minutes and a few hundred thousand tokens per build, web only (G4).

## 3. Fit for this project
No fetched source addresses a glance-read driving HUD: very large numerals, arm's-length legibility, minimal text, night glare. `impeccable`'s 44 pt and Dynamic Type rules (L1) are a floor, not a HUD guide. That is a gap shared by every candidate.

Recommendations:
1. **Keep `impeccable`, use its native commands, and write a HUD DESIGN.md.** Evidence: 88.0k stars, 360.9K installs, the only high-adoption skill with an iOS reference (G2, S2, L1). Run `critique` and `audit` against Pencil screenshots; put the HUD rules (glance time, minimum numeral size, dark palette, one accent) in PRODUCT.md/DESIGN.md so it reads them. No install needed.
2. **Add `swiftui-pro` when implementation starts.** Evidence: 6.4k stars, 35.1K installs, three audits pass, by Paul Hudson of Hacking with Swift (G5, S2). It targets AI mistakes in SwiftUI code and accessibility. Version note: one read said iOS 26+ and Swift 6.4+, another said Swift 6.2+; check before installing.
3. **Adopt the screenshot-compare loop with Xcode Preview or simulator captures.** Evidence: Anthropic's own docs name it (A2); Apple documents preview capture for agents (X1). Compare the Pencil frame to the built screen and list differences.

Not worth adding:
- **`ui-ux-pro-max`** (140.4k stars): web-leaning palette and style search; our dark palette is already chosen and there is one primary screen. Its SwiftUI depth is unchecked.
- **`design-taste-frontend`** (~102.6k): web only, needs Chrome, 30-45 minutes per build (G4).
- **`mobile-ios-design`, `ios-design-guidelines`:** add only if `ios.md` (45 lines) proves too thin. `ehmo` is the only HIG-derived one but has 625 stars. Overlap with `impeccable` is likely; not diffed.
- **`design-mobile-apps`:** paid API wrapper, Snyk fail, inflated installs.
- **Figma MCP, DESIGN.md CLI, Tailwind tooling:** wrong tool (we use Pencil) or web-shaped output.
- **Another web-first design skill:** `frontend-design` and `impeccable` already cover that ground.

## Limits
- Stars and installs move daily; the skills.sh count appears to include any install, with no quality filter visible.
- Cursor rules files and Codex-only skills were not researched beyond `impeccable`'s harness list.
- Apple's HIG and the Xcode MCP docs could not be read directly.
