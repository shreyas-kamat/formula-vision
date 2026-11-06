---
target: dashboard (declutter)
total_score: 22
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:D:\\Projects\\Flutter\\formulavision\\lib\\pages\\dashboard_page.dart"
target_fingerprint: "sha256:3ebd9cc5b2f1bb7c882c34ce3f29bdcf86038141405eeeb493f94f25d35502e8"
target_path: "D:\\Projects\\Flutter\\formulavision\\lib\\pages\\dashboard_page.dart"
timestamp: 2026-10-11T12-27-14Z
slug: lib-pages-dashboard-page-dart
---
⚠️ DEGRADED: single-context (detect.mjs does not parse Dart/Flutter and there is no browser surface; review based on live emulator screenshots + widget source)

## Design Health Score
| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Track status + race bar are clear; the 8px green connection strip is unlabeled |
| 2 | Match System / Real World | 3 | F1 vocabulary right; "L16*" for used tyre is cryptic |
| 3 | User Control and Freedom | 3 | Expand/collapse and stint sheet are reversible |
| 4 | Consistency and Standards | 2 | Green means "any gap" on interval pills, "best lap" on the second line, and "personal best" in mini-sectors |
| 5 | Error Prevention | 3 | Little to get wrong on a read-only screen |
| 6 | Recognition Rather Than Recall | 2 | Mini-sector colours, tappable tyre, "*" suffix have no legend or cue |
| 7 | Flexibility and Efficiency | 2 | No way to jump to the leaderboard or choose a denser view |
| 8 | Aesthetic and Minimalist Design | 1 | Every block is a card, every row repeats its labels, every value is saturated |
| 9 | Error Recovery | 2 | Radio failures snackbar; feed errors not surfaced on dashboard |
| 10 | Help and Documentation | 1 | No legend for sector colours / tyre age |
| **Total** | | **22/40** | **Acceptable** |

## Design Specificity Verdict
Feels like F1 (team colours, Formula font title, tyre roundels, mini-sectors), but structurally it is a generic stack of rounded dark cards. The leaderboard, the one thing a race viewer opens this screen for, is treated as just another card and sits ~1.4 screens down.

## Priority Issues
- [P1] Leaderboard buried under secondary cards: race bar + Track Conditions + Speed Trap (5 card rows) + Team Radio (5 card rows) before driver #1. Fix: leaderboard directly under race bar; conditions collapse into one inline line; speed trap + radio move below the leaderboard as a compact, flat "Race feed" (top 3 each, expand for more). Cmd: distill / layout.
- [P1] Driver rows ~120dp each, ~5 drivers per screen, 22 drivers ≈ 4+ screens. LAP TIME / INTERVAL / TYRE labels repeated 22×, two lap times stacked, 54dp coloured position block. Fix: ~64dp single-line rows, one sticky column header, best lap into the expanded view, thinner sector strip. Cmd: distill / layout.
- [P1] Colour carries no signal: every interval is a green pill, leader a red pill, best lap green, positions are saturated team-colour blocks, timer FAB is bright yellow. Green collides with F1's personal-best green used in mini-sectors. Fix: intervals/lap times plain white tabular mono; reserve green/purple for PB/fastest; position number neutral with a 3dp team-colour stripe. Cmd: quieter / colorize.
- [P2] Cards inside cards: each speed trap / radio row is a bordered card inside a bordered panel; Track Conditions tiles clip horizontally (wind tile cut off). Fix: flat rows with hairline dividers; conditions as inline text. Cmd: distill.
- [P2] Header competition: title, session name, track chip, and a saturated yellow stopwatch FAB (a secondary delay control) all at the top. Fix: quiet outline icon button. Cmd: quieter.

## Persona Red Flags
- Alex (power user, race on TV + phone): wants P1–P10 gaps at a glance; gets P1–P3 after scrolling past two feature cards; must read through 22 "INTERVAL" labels.
- Sam (accessibility): mini-sector state is colour-only; 11px white70 labels; interval meaning carried by pill colour.
- Casey (distracted, one hand): leaderboard requires a long thumb scroll each time they come back; the main control (delay FAB) sits top-right out of thumb reach.

## Minor Observations
- "L16*" → "16 laps · used".
- Speed trap rows show "km/h" on every row; put the unit in the header.
- "Drivers" section title is redundant once the leaderboard leads the page.
- Team-colour bars are used three different ways (position block, radio stripe, speed trap stripe).

## Questions to Consider
- What if the screen were just the timing tower, and everything else were one tap away?
- Does a speed trap need five bordered rows, or one sentence: "Fastest: RUS 306 km/h"?
- What would this look like if colour only appeared when something actually happened?
