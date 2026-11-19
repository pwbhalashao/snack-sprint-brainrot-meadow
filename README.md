# Snack Sprint: Brainrot Meadow

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

An original 3D Roblox brainrot game for make.fun's
**“Make the best AI Roblox brainrot game”** bounty (`roblox-brainrot-01`,
$1,000 USDC, 50 places paid, entries close **2026-11-20 14:30 UTC**).

> **Status on this Linux VM: LOCAL SOURCE ONLY — not yet a submittable entry.**
> See [What is still missing](#what-is-still-missing) below. No GitHub repo was
> created, no Solana keypair was created, and nothing was submitted.

## The game

A 3D world (not a 2D screen game): your character runs around a grass
meadow, a conveyor belt down the middle carries absurd meme-born
characters past, and you buy them, keep them on your base, and earn money
every second.

- **Collect:** 8 original characters walk the conveyor — Sir Croissant,
  DJ Pickle, Captain Noodle, Professor Waffle, Turbo Taco Cat, Queen Boba,
  Lord Dumpling, and Cosmic Ramen Dragon. Rarities: Common → Rare → Epic →
  Legendary → Mythic. Press **E** near one to buy it (if you can afford it
  and have a free base slot).
- **Earn:** every character on your base pays $/sec (e.g. Sir Croissant
  $2/s, Cosmic Ramen Dragon $350/s). Mutations multiply income:
  Golden ×2, Frozen ×3, Spicy ×4, Rainbow ×5.
- **Steal:** walk up to a character on someone else's base and press **F**
  to steal it — then dash it home to your own base before the owner
  catches you. The owner can press **Q** to slap you (10 s cooldown):
  if you are carrying *their* character you drop it and are stunned 3 s.
- **Rebirth:** pay $5,000 × (rebirths + 1) to reset your money and
  characters for +25% income per rebirth, forever.
- **Pickle Storm:** every 3 minutes a 20-second storm speeds the conveyor
  up and spawns characters faster — the best time to grab a rare one,
  and the worst time to be caught out in the open.

All characters, names, and the world are **original inventions for this
game**. Nothing is copied from Steal a Brainrot or any other game — no
borrowed names, characters, art, meshes, or music. Characters are built
at runtime from plain Roblox Parts (see `src/server/CharacterFactory.luau`),
so the game needs no external assets at all.

HUD (top-right, clear of Roblox's top-left menu buttons): money,
income/sec, rebirths, storm countdown, rebirth button, and a context
prompt (E buy / Q slap).

## Repo layout

| File | What it is |
|---|---|
| `main.ts` | Entrypoint the grader runs (Node 22, stdlib only). Copies `game.rbxl`, `src/`, `screenshots/`, `PLAY.json` to `/output` and writes `dossier.json` via `vendor/makefun-roblox.ts`. |
| `default.project.json` | Rojo project: DataModel, Lighting, baseplate, conveyor, 8 base pads, spawn, and the `src/` mounts. |
| `game.rbxl` | **NOT in this folder yet** — built by Rojo on a Windows/Mac computer (see below). `.rbxlx` is refused by the bounty. |
| `src/shared/Characters.luau` | Character catalogue (8 originals) + mutations + weighted rolls. |
| `src/shared/Config.luau` | Tuning: prices, speeds, cooldowns, storm timing. |
| `src/server/Game.server.luau` | Server: bases, conveyor spawning, income, buy/steal/slap/rebirth, storm, leaderstats. |
| `src/server/CharacterFactory.luau` | Builds each character Model from plain Parts + name tag. |
| `src/client/HUD.client.luau` | Client HUD, prompts, E/F/Q input. |
| `vendor/makefun-roblox.ts` | Kit's library, copied **unchanged** (sha256 `0add4358…`). |
| `screenshots/` | **Empty here** — 3–4 real Studio captures go here (see below). |
| `PLAY.json` | Placeholder (`place_id: 0`) — fill in after publishing. |
| `LICENSE` | MIT. |

## How to finish it (on Charlotte's Windows/Mac computer)

Roblox Studio is Windows/macOS only — it does not run on this Linux VM,
and neither Studio nor Rojo is installed here. Do these steps on a
Windows 10+/11 or macOS 10.14+ computer:

```sh
# 1. Install: Roblox Studio (https://create.roblox.com), Node.js 22.18+,
#    Git, and Rojo 7.7 (e.g. `rokit add rojo-rbx/rojo && rokit install`,
#    or the prebuilt Linux/Windows/macOS binary from Rojo's releases).
# 2. In this repo folder:
rojo build default.project.json --output game.rbxl

# 3. Open game.rbxl in Roblox Studio, press Play, and play-test:
#    buy a character (E), check income ticks, steal/slap with a second
#    account if possible, rebirth, and wait for a Pickle Storm.
# 4. While the game is running in Studio, take 3-4 screenshots
#    (1280x720, 16:9, each <= 256 KiB — re-encode/scale down if needed).
#    Save them as screenshots/1-start.png, 2-play.png, 3-steal.png,
#    4-storm.png (first by name is the cover = your Roblox thumbnail).
# 5. Publish from Studio as a Public experience (account must be 2+ days
#    old and past Roblox's age check). On the Creator Dashboard add a
#    description, genre, and content answers, set it Public, and upload
#    your icon + thumbnail (the first thumbnail must be the same picture
#    as one of your screenshots). Put your make.fun play code in the
#    description.
# 6. Fill in PLAY.json:
#    {"url": "https://www.roblox.com/games/<placeId>",
#     "place_id": <placeId>, "universe_id": <universeId>}
# 7. Test the entrypoint locally:
#    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
#    # out/ must contain game.rbxl, PLAY.json, src/, screenshots/,
#    # dossier.json — and no dotfiles anywhere under out/.
```

## What is still missing

- [ ] `game.rbxl` — needs Rojo 7.7 (`rojo build`) or Studio on Windows/Mac.
  **Rojo alone can build it, but it cannot run/play-test it** — only Studio can.
- [ ] 3–4 screenshots of the game actually running in Studio (none exist yet;
  do not submit placeholder/starter images — the bounty checks them).
- [ ] A published **Public** Roblox experience + uploaded icon/thumbnail,
  with the make.fun play code in its description, and real ids in `PLAY.json`.
- [ ] A **public GitHub repo created after 2026-11-17** (competition opened
  2026-11-17 14:30 UTC) containing this code + MIT LICENSE + `main.ts` at root.
  (Or a source bundle via the kit's `init` — same repo requirement, no GitHub.)
- [ ] A **Solana wallet / keypair** for the make.fun account (payout wallet).
  Never share the keypair file or seed phrase in chat.
- [ ] **Sealed recordings** of the agent sessions that built the game, made
  with the kit's `record` command *before* the build work starts. This
  build was made by Muse as a subagent, not inside a `record` session, so
  a recorded harness session (Claude Code / Codex / Muse app / Superbot /
  etc.) would need to re-run the build under `record` for the transcripts
  to count. Do not submit this code as-is and expect the transcript check
  to pass.
- [ ] Roblox account that can publish Public (2+ days old, age check passed).

## Run it (grader-style, once game.rbxl exists)

```sh
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## Local checks done on this VM (2026-11-19)

- `default.project.json` and `PLAY.json` parse as JSON.
- `main.ts` runs under Node v24.22.1 and writes `dossier.json` — verified
  against the kit starter's `game.rbxl` in a throwaway copy only (the
  starter place is *not* this game; the repo's own `game.rbxl` is still missing).
- Luau files pass a structural sanity check (balanced `function`/`end`,
  `if`/`then`/`end`, `do`/`end`, `for`/`end`, `while`/`end`, no tabs/spaces
  mix-ups that break Luau). They have **not** been run in Roblox — no
  Studio, no Luau runtime, and no Rojo on this VM to build or test them.
- No Roblox Studio, no Rojo, no Wine, no Roblox account, no GitHub repo,
  no Solana keypair were created or used here.

---

<sub>Entered on [make.fun](https://make.fun/?ref=&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
