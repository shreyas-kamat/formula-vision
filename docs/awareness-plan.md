# FormulaVision Awareness Plan

Goal: grow organic installs on Google Play and the App Store, and stars and contributors on GitHub, with no ad budget.

Status: the README badges are done. Everything below is a proposal. The channel impact claims come from indie-dev blog posts and forum threads, so treat them as anecdotal.

## Positioning

- One line: **the free, open-source F1 race companion with live timing.** No ads, no subscription, no account.
- Differentiators to repeat everywhere:
  - Open source (Apache-2.0)
  - Free with no ads
  - Live timing tower with a compact or expanded layout
  - Speed trap, team radio and weather
  - Android and iOS
- The disclaimer "unofficial, not affiliated with Formula 1" stays visible in every channel.

## Guardrails (F1 trademark risk)

Formula One Group has pulled unofficial apps before, for example Lapz on TestFlight. To reduce risk:

- Never use F1 logos, car or driver photography, or official fonts in promo material.
- Keep "Unofficial" in the store description and in every post.
- Don't imply the live feed is endorsed. Telemetry streams that need F1 TV auth stay out of marketing, since the track map is deliberately hidden.
- Keep the app free, which weakens any commercial-infringement argument.

## Phase 0: Foundations (1 week, do first)

| Task | Why |
|---|---|
| Add 4-6 screenshots plus a 20-30s screen recording to the README, replacing the old Screenshots section | The README is the landing page for GitHub visitors |
| Add GitHub topics: `formula1`, `f1`, `flutter`, `dart`, `motorsport`, `live-timing`, `android`, `ios` | Discoverability in GitHub search and topic pages |
| Set the repo description and website link to the store page or landing page | Shows in search results and social cards |
| Upload a 1280x640 social preview image (reuse `store-assets/feature-graphic.png`) | Every shared repo link gets a card |
| Enable GitHub Discussions and add a "good first issue" label | Gives contributors somewhere to land |
| Fix the repo URL mix-up (`skat9234` vs `shreyas-kamat`) in the README links | Broken or inconsistent links look unmaintained |
| Add a short landing page from `store-assets/site` on GitHub Pages | Gives you a link that ranks and that you can share |
| Add an in-app "Rate FormulaVision" prompt (`in_app_review`), shown after several race sessions, never on first launch | Ratings drive store ranking more than anything else you control |
| Add a share button and a "Support / Feedback" link (a support page already exists) | Turns users into a distribution channel |

## Phase 1: Store optimisation (ASO, ongoing)

- Title: `FormulaVision: Race Companion`, plus keywords in the subtitle or short description such as "live timing, standings, schedule".
- Use real F1 terms: standings, live timing, race calendar, constructors.
- First two screenshots should show the live timing tower and the standings. Add captions.
- Localise the listing for top F1 markets: Spanish, Italian, German, Portuguese (Brazil), French, Japanese.
- Reply to every review in the first few months.
- Check Play Console and App Store Connect monthly for which search terms bring installs, then adjust.
- Consider a Play Store "What's New" entry after each race weekend update. It shows the app is alive.

## Phase 2: Community launch (weeks 2-4)

Post once per community, not on a schedule, and read each community's self-promotion rules first.

| Channel | Angle | Notes |
|---|---|---|
| r/formulavision | Launch post with changelog | Your own subreddit, safe to post freely |
| r/FlutterDev | "Built a live-timing F1 app in Flutter. Here's how the SignalR feed, broadcast delay and layouts work" | Technical write-ups do well here |
| r/opensource, r/androidapps, r/iosapps | Release announcement | Follow each sub's flair and weekly-thread rules |
| r/fossdroid | Release post | Requires the license in the post |
| r/formula1, r/F1Technical | Don't post an ad. Participate normally and mention the app only when it answers a question | Strict self-promo rules, high ban risk |
| Show HN | "Show HN: Open-source F1 live timing app (Flutter)" | One shot, so post it on a Tuesday-Thursday morning US time with the repo link |
| Product Hunt | Launch only after you have 20+ people who will upvote and comment | A launch with no audience tends to flop |
| F-Droid | Submit the Android build, which needs a reproducible, tracker-free build | Slow but gets the FOSS audience; the Play build's dependencies need checking first |
| AlternativeTo, Fossdroid, LibHunt | List as an alternative to the official F1 app, F1 Live Timing and similar | Free, and ranks in search for years |
| Hacker News / dev.to / Hashnode | Write-up of the engineering story | Doubles as content for later phases |

## Phase 3: Content engine (ongoing, tied to the race calendar)

Demand follows the calendar, so schedule content around race weekends:

- **Race-weekend screenshots.** Post a screenshot or short clip of the timing tower during a session on X, Reddit and Instagram Reels / YouTube Shorts / TikTok. No broadcast footage.
- **Weekly "standings after round N" graphic** generated from the app's own data.
- **Dev log posts** every few releases: what changed, what broke, what's next.
- **Short demo videos** (15-30s): compact vs expanded layout, speed trap, team radio.
- **Pitch lists, not people:** F1 newsletters, Flutter Weekly, Android Weekly, iOS Dev Weekly, "awesome-flutter" and "awesome-f1" GitHub lists.
- Open a PR to add FormulaVision to `awesome-flutter` and any `awesome-formula1` style list.

## Phase 4: Contributors and retention

- Label 5-10 issues `good first issue` (themes, translations, track maps, tests).
- Write a roadmap in GitHub Projects and link it from the README.
- Add a "Contributors" section or all-contributors bot.
- Ship small updates around races so users see a living project.
- Push notifications for session start and results (opt-in) are the best retention lever, but they need a backend or a scheduled sender, so decide separately.

## Timing

The 2026 season is close to its end, and the off-season is quiet. Verify the dates, but roughly:

- **Now to the final race:** Phase 0 and Phase 1, plus a soft launch on r/formulavision and the dev communities.
- **Off-season (Dec-Feb):** Phase 3 dev-log content, contributor work, F-Droid submission, and a Product Hunt / Show HN launch prepared for pre-season testing.
- **Pre-season testing through the opening race:** the main push. Interest in F1 apps peaks here.

## Metrics

Track weekly, and write the numbers in this file:

| Metric | Source |
|---|---|
| Store page views, installs, conversion | Play Console, App Store Connect |
| Rating and review count | Both consoles |
| Top search terms | Both consoles |
| GitHub stars, clones, traffic referrers | GitHub Insights |
| Reddit post upvotes and comments | Manual |

Initial targets (set your own after week 2 baselines): 4.5+ rating, 50 reviews on each store, 250 GitHub stars by the opening race.

## Next actions (suggested order)

1. Add screenshots and a demo clip to the README.
2. Set GitHub topics, description and social preview.
3. Add the in-app review prompt and a share button.
4. Tidy the store listings (title, subtitle, screenshots).
5. Post the soft launch on r/formulavision and r/FlutterDev.
6. Prepare the Show HN and Product Hunt launch for pre-season.
