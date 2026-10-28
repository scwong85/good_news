# UI overhaul milestone (Phase 7): a design that feels like good news

Status: **planned, not started.** Phase 5 gave us a correct, accessible, but deliberately plain Material 3 UI. This milestone gives the app its own identity so that opening it feels calm, hopeful and trustworthy, in line with `product-brief.md`. It changes how the app looks and feels, not what it does: no new data, permissions, network calls or tracking.

## Design direction
- **Feeling:** a quiet, sunny morning. Warm and optimistic, never saccharine, never "newsy red alert". Calm first, hopeful second, credible always.
- **Credibility is part of the look.** Optimism must not read as clickbait or marketing. Editorial typography, generous whitespace, plain language, visible source and "why this story" on every story.
- **Finite and kind.** "That's your good news for today" is a feature. The end of the list is a warm, satisfying moment, not an empty screen. No infinite scroll, streaks, badges or pressure.

## Identity
- **Name and logo:** open question (see below). Placeholder "Good News" until the owner decides. Direction: a simple sunrise / rising sun mark that works as an Android adaptive icon (monochrome themed-icon layer included).
- **Colour:** a warm palette built as Material 3 tonal palettes from a seed: a sunrise amber/coral accent, a fresh green for "constructive" signals, soft warm neutrals (cream in light mode, deep warm charcoal in dark). Replace the current generic seed colour. All text pairs keep WCAG AA (4.5:1) in light and dark; the accessibility tests from Phase 5 must still pass unchanged.
- **Type:** a humane serif for headlines (for example Source Serif 4 or Newsreader) with a clean sans for UI text (for example Inter or Nunito Sans). Fonts are open licence (OFL) and **bundled in the app**, never fetched at runtime (privacy, offline). Must respect the system font scale up to 200%.
- **Illustration and icons:** a small set of original, locally bundled vector illustrations (sunrise, sprout, hands, wetlands) for the Today header, empty and end states, and topic icons. **No publisher images**: we do not fetch or hotlink article images (copyright, privacy, data use).
- **Shape and surface:** soft rounded cards, gentle elevation, no harsh dividers; topic chips carry a colour and an icon (never colour alone).

## Screens
- **Today:** a sunrise header with a time-aware greeting ("Good morning"), the date, and a quiet line like "5 stories worth your time". A "lead story" card for the top pick (larger type), then compact cards. Each card shows a topic chip with icon, source, headline, and a one-line reason ("Why: measurable results, local volunteers"). Pull-to-refresh with a gentle animation. A warm end-of-list card: "You're all caught up. Come back tomorrow for more good news." with an option to explore more.
- **Explore:** topic tiles with illustration and colour; filters stay simple. Warm empty states.
- **Story:** large readable headline, source attribution, "Why this story was included" as a friendly expandable card, primary "Read at <source>" button; share/save/hide in a tidy action row.
- **Saved:** a "keepsakes" feel with the same card language; empty state explains how to save.
- **Settings and About:** grouped cards with plain-language descriptions; the privacy promise ("No accounts, no ads, no tracking, everything stays on your phone") shown prominently as a trust badge in About and in first-run.
- **First run:** a 2 to 3 card welcome (what this is, how stories are chosen, your choices) that ends on the user's first Today. Skippable. Stores one local flag.
- **Loading, offline, error:** friendly microcopy and illustration; never blame the user; always show cached stories when available.

## Microcopy tone
Plain, warm, specific. Say what the app did ("We looked at 14 sources and chose these 5."). No exclamation-mark cheerleading, no forced positivity about serious subjects, no emoji in headlines. Copy lives in one place so it can be reviewed and later localised.

## Motion
Short, gentle transitions (fade/slide 200 to 300 ms); a soft sunrise shimmer while loading; a small gentle reward when reaching the end of the list. **All motion respects the system "remove animations" setting** and is covered by a test.

## Platform polish
Android adaptive icon and themed (monochrome) icon, native splash on the brand colour, edge-to-edge with correct insets, predictive back, status/navigation bar styling in both themes, tablet layout keeps the centred column with illustration in the rail.

## Constraints (non-negotiable)
- No new permissions, network calls, analytics or runtime asset downloads. Fonts and illustrations are bundled.
- Attribution rules unchanged: headline, excerpt (<= 300 chars), source, link to the original; no article images.
- Accessibility does not regress: tap targets 48 dp, semantic labels, AA contrast in light and dark, no overflow at 200% text from 320 px wide, colour never the only signal.
- Budgets: release APK/AAB growth <= 5 MB over the Phase 6 build; cold start to cached Today within the Phase 5 budget (measured on a real device before and after); no jank in the Today list on a mid-range phone.
- Every visual decision is implemented as theme tokens (colour, type, spacing, shape) in one place, not scattered literals.

## Tasks
1. Brand brief and choices (name, logo direction, palette, fonts) approved by the owner. Mood board and screen mockups reviewed before any code.
2. Design tokens: new `ColorScheme`, `TextTheme`, spacing, shape and motion tokens; replace literals in widgets.
3. Bundle fonts (OFL) and original illustrations; asset licences recorded in `docs/` (attribution file).
4. Rebuild Today (header, lead card, compact cards, end-of-list), then Story, Explore, Saved, Settings, About; add first-run welcome.
5. Microcopy pass in one file; review for tone and accuracy (never overstate: "chosen by rules", not "verified").
6. Icon, adaptive/themed icon, splash, store graphics and screenshots.
7. Reduce-motion support and tests; golden/screenshot regression tests for key screens in light, dark, small phone, tablet and 200% text.
8. Re-run all Phase 5 accessibility and responsive tests and the full suite; measure size and startup against budgets.
9. User check: 5 people see Today for 5 seconds and then say how it felt; target: most say "calm, hopeful, trustworthy" and none say "ad", "clickbait" or "alarming". Record results in the decision log (small sample, informal).

## Acceptance
- Owner approves the look on a real device (emulator screenshots alone are not enough).
- All existing tests plus new golden tests pass; accessibility guidelines pass in light and dark; no overflow at 200% text.
- Budgets above met; no new permissions or network hosts (policy tests in `app/test/policy_test.dart` still pass).
- The informal 5-second check meets the target above.

## Open questions
- Final app name, logo and brand colour (owner).
- Font pair, once the owner has seen the options.
- Whether to commission or generate the illustration set (licence and originality must be clear either way).
- Whether to add a dark-mode "evening" variant beyond plain dark (probably not).
