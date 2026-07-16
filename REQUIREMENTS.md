# Product Requirements — TVK App
> Single source of truth for all UI/UX requests from the product owner.
> Updated every session. Never reset unless explicitly told to.
> Status: ✅ Done | 🔄 In Progress | ❌ Not Started | ⚠️ Partially Done

---

## HOME SCREEN

### Hero Section
- ⚠️ "Join TVK Today" card must stay INSIDE the hero section bounds — not overflow outside
- ✅ Vijay home hero image (vijay_home_hero.png) as the main hero figure

### Section 2 — Policy Leaders Deck
- ✅ Historical social justice leaders (Kamarajar, Ambedkar, Periyar, Anjalai, Velu Nachiyar) as swipeable deck cards
- ✅ Each card taps → PolicyLeaderDetailScreen
- ✅ Animated card transitions (no page control dots)
- ✅ "See All" → PolicyLeadersScreen (historical leaders list)

### Section 3 — Campaign Song / Latest Updates
- ✅ Campaign toolkit cards: combined.png shown in bottom-right corner of each card

### Section 4 — Latest Updates
- ✅ News cards navigate to NewsDetailScreen

### Section 5 — TVK Family + Projects (GROUPED TOGETHER)
- ✅ "TVK Family" header
- ✅ VIJAY: FULL-WIDTH card (not sharing row with anyone)
- ✅ N. Anand + K.G. Arunraj in a 2-column row below Vijay
- ✅ Aadhav Arjuna row REMOVED (only Vijay needs special design, other two in 2-col)
- ✅ "Projects" cinematic card: white bg, combined.png full-bleed, bottom dark gradient
- ✅ All in one grouped section — no separation between leaders and manifesto

### Section 6 — TVK Shorts
- ✅ Dynamic from YouTube (not hardcoded)

### Section 7 — TVK TV
- ✅ Navigates to YoutubeHubScreen

### TVK Television Section
- ✅ Uses `tvfull.png` asset (right-aligned in red gradient card → YoutubeHubScreen)

### Join TVK Card (Hero)
- ✅ "Join Now" button navigates to JoinScreen (was broken, pointed to ChatListScreen)

### Campaign Song Section
- ✅ Overflow warning fixed — text/button in Positioned container, no unbounded Spacer

### Login / Join TVK Separation
- ✅ Chat button (centre FAB) → Login gate bottom sheet if not logged in
- ✅ Profile tab (index 4) → Login gate bottom sheet if not logged in
- ✅ Login gate has "Login with Mobile" + "Skip for Now" options
- ✅ After login → "Join TVK" prompt with yellow-red ACTIVE MEMBER badge
- ✅ Users can skip login and browse freely

### Events Home Cards
- ✅ Figma 1328-4617 exact: 171px photo-background card, dark-red bottom gradient, white date box (red month top, BebasNeue day, day-of-week), white title 16px SemiBold + location — cycles event_1..4.png

### Vision Card (to add)
- ❌ Animated TVK flag waving card for Vision section on home page
- ❌ Combine with Goals & Achievements

---

## LEADER CARDS — BACKGROUND (EVERYWHERE)

### Background Style (IMPORTANT — ALL LEADER HERO SECTIONS)
- ✅ Background behind leader portrait must be: **pure black / very dark base + centered dark red radial glow**
- Reference: the dark-black-with-red-glow image shared by user
- This applies to:
  - ✅ Home screen leader mini cards (_VijayFullCard + _LeaderMiniCard)
  - ✅ PolicyLeadersScreen list cards (_PolicyLeaderCard)
  - ✅ PolicyLeaderDetailScreen hero
  - ✅ VijayDetailScreen hero
  - All leader-related hero areas
- ✅ Dark with red glow applied — TVK flag visible (38% opacity + blur) behind leader
- ✅ TVK flag clearly visible with ImageFilter blur behind the leader

### Know Your Leaders (TVK Family leader cards on home)
- ✅ Leader images properly sized, text in bottom strip with dark gradient — no overlap
- ✅ Same dark + red glow background treatment applied

---

## LEADER DETAIL PAGES

### All Leaders (PolicyLeaderDetailScreen)
- ✅ Hero: dark background + red glow + TVK flag visible (blurred, 38% opacity) + leader portrait large
- ✅ Biography card below
- ✅ Back button (dark, white icon)
- No "Next" button

### Vijay (VijayDetailScreen) — Separate page
- ✅ Hero: dark background + red glow + TVK flag blurred + Vijay portrait large
- ✅ Tab bar: About | Achievements (no Media)
- ✅ About: info table + personal background + career summary
- ✅ Achievements: Cinema + Public Service + Historic Events

---

## POLICY LEADERS SCREEN (Historical)
- ✅ Figma 1328-4500 design
- ✅ 5 leaders: Kamarajar, Ambedkar, Periyar, Anjalai Ammal, Velu Nachiyar
- ✅ Leader portraits large (120px wide, full card height), text safely left of portrait, dark bg + red glow

---

## TVK FAMILY SCREEN (Election Candidates)
- ✅ All 234 real candidates from tvkvijay.com
- ✅ 38 districts
- ✅ Search + district filter

---

## NEWS SCREEN
- ✅ Hero banner: TVK flag bg + "TVK's NEWS" BebasNeue title + subtitle
- ✅ Category filter (All, Party, Event, Policy, Agriculture)
- ✅ District / Sector / Ministry filters in bottom sheet (filter button → modal)
- ✅ Active filters shown as removable chips; Clear All inside sheet
- ✅ News cards → NewsDetailScreen

---

## PROJECTS SCREEN (formerly Manifesto)
- ✅ Renamed to "Projects" 
- ✅ 5-Year Plans tab: segmented tab bar (#EAEBEC grey bg, red active), year timeline 2026→2030 with orange dots, plan cards exactly matching Figma 1328-3847 (Poppins description, bordered chips, red See Details btn)
- ✅ Visions tab: Vijay portrait + side menu (Our policies/Our Purpose/Our basic principle), white content card below — matches Figma 1328-3936
- ✅ Goals & Achievements tab: circular progress ring (75%), Ongoing Goal card, Achievement image cards — matches Figma 1328-3976
- ✅ Detail page: hero image, grey title+ministry header, description, vertical milestone timeline (BebasNeue titles, amber dates, red line) — matches Figma 1328-3743
- ✅ All "See Details" buttons navigate to ManifestoDetailScreen

---

## CAMPAIGN TOOLKIT
- ✅ Home cards: combined.png in bottom-right corner of each toolkit card
- ✅ Detail pages rebuilt matching Figma exactly:
  - Posters (1328-3063): staggered 2-col masonry grid — left col 3×264px, right col [169,264,169,174]px, 10px gap, no offset — Figma-exact
  - Media (1328-3127): Audios tab (Manrope font, 60×47 thumbnail + red play circle + title + views·time + more-vert icon) + Videos tab (180px full-width cards, red play circle, title bottom-left)
  - Slogans (1328-3206): "Best Slogans" list, each row copy button, top-left square corner style
  - Hashtags (1328-3284): "Best Hashtags" with red Copy tab (top-left) + bordered hashtag text blocks
- ✅ Common header: TVK flag bg + black bottom gradient + BebasNeue gradient title + search bar

---

## EVENTS SECTION
- ✅ Events screen back button added to header
- ✅ Home page event cards redesigned: red date block left, title + location + UPCOMING badge right

---

## VIJAY DETAIL PAGE
- ✅ Separate from other leader detail pages
- ✅ About tab: info table + personal background + career
- ✅ Achievements tab: Cinema, Public Service, Historic Events
- ✅ Hero background: dark + red glow + TVK flag blurred (same as all other leaders)

## JOIN TVK FLOW
- ✅ JoinScreen (form) → FaceCaptureScreen (camera/gallery) → MemberIdScreen (ID card with photo)
- ✅ `image_picker` added (v1.1.2), iOS camera + photo library permissions in Info.plist
- ✅ FaceCaptureScreen: black bg, face guide frame, gallery/capture/flash bottom sheet
- ✅ MemberIdScreen: white bg, red glow, ID card with captured photo embedded, Back to Home
- ✅ Member badge: yellow/red "ACTIVE MEMBER" strip on ID card

---

## GENERAL RULES (never forget)
1. Light theme everywhere — no black backgrounds on content screens
2. BUT leader hero sections specifically use DARK background + red radial glow (per user reference image)
3. Vijay card = always full width, never share a row with other leaders
4. TVK Family section and Projects/Manifesto section = always grouped together in one block
5. Leader images must be large and clearly visible, never overlap text
6. Always check previous requirements before making changes
7. Campaign section 3 on home page needs Figma match — don't change arbitrarily

---

## SESSION LOG
| Date | Changes Made |
|------|-------------|
| 2026-05-14 | Created this file. Populated from all previous session requests. |
| 2026-05-14 | Fixed all pending items: news filters → bottom sheet, campaign song overflow, events home card redesign, events back button, login gate (Profile+Chat FAB), post-login Join TVK prompt, hero Join Now nav, TVK TV single image, full Join flow (form→face capture→ID card). flutter analyze clean. |
| 2026-05-14 | TV section uses tvfull.png. Campaign toolkit cards use toolkit.png. Event cards rebuilt to Figma 1328-4617: 171px photo-bg card, dark-red gradient overlay, white date box (red month strip, BebasNeue day, day-of-week), white title+location; cycles event_1..4.png; taps → EventDetailScreen. Zero analyzer issues. |
