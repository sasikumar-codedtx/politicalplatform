# Sticky / Sliver Headers — App-wide Design

Date: 2026-07-25
Status: Approved

## Goal

Give every screen a sticky header like the Vijay detail screen: a collapsing
hero (or a compact pinned bar on form screens) with any tab/filter row pinned
below it, and the content scrolling underneath. Reference: `vijay_detail_screen`
plus the already-sliver `news_screen` / `fan_page_screen`.

Only the scroll/header **structure** changes — every screen keeps its existing
colours, images, content, and behavior. Full-screen media (video/shorts/short
players), `splash_screen`, and `onboarding_screen` are excluded (no bar).

## Reusable toolkit — `lib/widgets/sticky_header.dart`

Three pieces, so 30 screens share one implementation instead of drifting apart.

1. **`PinnedTabBar`** — a `SliverPersistentHeaderDelegate` that pins a `TabBar`.
   Generalizes the private `_TabBarDelegate` already in `fan_page_screen`
   (that private copy is replaced by this shared one).
   - Inputs: `TabBar tabBar`, optional `Color background`.
   - `minExtent == maxExtent == tabBar.preferredSize.height` (+ padding).
   - `shouldRebuild => false`.

2. **`SliverHeroBar`** — a configured collapsing `SliverAppBar`.
   - Inputs: `double expandedHeight`, `Widget background` (image/gradient),
     `Widget title` (shown collapsed, and via `FlexibleSpaceBar` expanded),
     `Widget? leading` (defaults to a circular back button), `List<Widget>?
     actions`, `Color backgroundColor`.
   - `pinned: true`, `FlexibleSpaceBar(background:, title:, titlePadding:)`.

3. **`SliverSimpleBar`** — a pinned compact app bar for screens with no hero.
   - Inputs: `String title`, `Widget? leading` (default back), `List<Widget>?
     actions`, colours from `AppColors`.
   - `pinned: true`, `SliverAppBar` with `title` + optional `bottom`.

## Per-screen conversion

Body becomes a `CustomScrollView` (or `NestedScrollView` when a `TabBarView`
is needed), assembled from the toolkit pieces.

### Hero + tabs → `NestedScrollView` + `SliverHeroBar` + `PinnedTabBar`
(the exact reference pattern; body = `TabBarView`)
- `vijay_detail_screen` (About / Achievements)
- `leader_screen` (About / Achievements / Media)
- `manifesto_screen` — Projects (5-Year Plans / Visions / Goals)
- `policy_leaders_screen` — TVK Family (hero + list; filters pinned)
- `polls_screen` — Take Action (Polls / Complaints / Donation chips pinned)
- `my_posts_screen` (My Posts / Admin)

### Detail pages with a hero → `CustomScrollView` + `SliverHeroBar` + `SliverList`
- `event_detail_screen`, `news_detail_screen`, `manifesto_detail_screen`,
  `policy_leader_detail_screen`, `playlist_detail_screen`,
  `campaign_toolkit_detail_screen`, `fan_post_detail_screen`

### Form / list screens → `CustomScrollView` + `SliverSimpleBar` (pinned) + body
- `settings_screen`, `join_screen`, `complaints_screen`, `chat_list_screen`,
  `members_screen`, `member_id_screen`, `create_poll_screen`,
  `create_fan_post_screen`, `profile_screen`, `services_screen`,
  `phone_login_screen`

### Already sliver — refactor onto the shared toolkit for consistency
- `news_screen`, `fan_page_screen`, `youtube_hub_screen`, `events_screen`

### Excluded (no bar)
- `video_player_screen`, `shorts_reel_screen`, `short_player_screen`,
  `splash_screen`, `onboarding_screen`, `face_capture_screen`, `main_shell`
  (host of tabs), `voice_chat_screen`, `chat_screen` (custom gradient header +
  drawer — keep, optionally pin).

## Phasing (each phase: `flutter analyze` clean before the next)

1. **Toolkit + proof** — build `sticky_header.dart`; refactor `events_screen`
   and `fan_page_screen` onto it (they already use slivers → lowest risk).
2. **Hero + tab screens** — vijay, leader, projects, TVK family, take action,
   my posts.
3. **Detail pages** — the seven detail screens.
4. **Form / list screens** — the remaining forms/lists.

## Non-goals

- No colour/content/behavior changes beyond the header structure.
- No new backend work.
- Media players / splash / onboarding untouched.

## Success criteria

- On every converted screen, the top bar (and any tab/filter row) stays visible
  while the body scrolls; heroes collapse smoothly.
- `flutter analyze` clean after each phase.
- No RenderFlex overflow introduced (fixed hero heights account for `topPad`).
