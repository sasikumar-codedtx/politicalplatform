import '../config/app_config.dart';
import '../config/app_strings.dart';
import '../models/news_item.dart';
import '../models/leader.dart';
import '../models/manifesto_plan.dart';
import '../models/event.dart';
import '../models/youtube_video.dart';
import 'dart:async';
import 'agent_service.dart';
import 'local_cache.dart';
import 'youtube_service.dart';

// News + Events are admin-published (backend CMS) via AgentService; the rest
// (leader, manifesto, visions) are still curated mock data. News/Events fall
// back to the mock set while the backend has nothing published yet, so the
// app is never blank. ViewModels do not need to change.
class ContentService {
  static final String _flavor = AppConfig.flavorName;

  /// Backend rows served from disk first so the screen paints immediately,
  /// with a background refresh for the next open.
  static Future<List<Map<String, dynamic>>> _cmsRows(
    String key,
    Future<List<Map<String, dynamic>>> Function() fetch,
  ) async {
    final cached = await LocalCache.read(key);
    if (cached is List && cached.isNotEmpty) {
      unawaited(fetch().then((rows) {
        if (rows.isNotEmpty) LocalCache.write(key, rows);
      }));
      return cached.cast<Map<String, dynamic>>();
    }
    final rows = await fetch();
    if (rows.isNotEmpty) await LocalCache.write(key, rows);
    return rows;
  }

  // ── NEWS ─────────────────────────────────────────────────────────
  // Merged feed: admin-published CMS items first, then the channel's recent
  // YouTube uploads (as playable video cards). Falls back to the curated mock
  // only when BOTH sources are empty, so the app is never blank.
  // (Instagram would plug in here as a third source once a token exists.)
  static Future<List<NewsItem>> getNews() async {
    final results = await Future.wait([
      _cmsRows('cms_news', AgentService.listNews),
      YouTubeService.getVideos(count: 12),
    ]);
    final rows = results[0] as List<Map<String, dynamic>>;
    final videos = results[1] as List<YouTubeVideo>;

    final cms = rows.map((m) => NewsItem(
      id: m['id'].toString(),
      title: m['title'] as String? ?? '',
      summary: m['summary'] as String? ?? '',
      category: m['category'] as String? ?? '',
      date: m['date'] as String? ?? '',
      time: m['time'] as String? ?? '',
      imageUrl: (m['image_url'] as String?)?.isNotEmpty == true
          ? m['image_url'] as String
          : null,
    )).toList();

    final yt = videos.map((v) => NewsItem(
      id: 'yt_${v.videoId}',
      title: v.title,
      summary: v.channelTitle,
      category: 'Video',
      date: v.formattedDate,
      time: '',
      imageUrl: v.thumbnailUrl.isNotEmpty ? v.thumbnailUrl : null,
      videoId: v.videoId,
      source: 'youtube',
    )).toList();

    final merged = [...cms, ...yt];
    if (merged.isNotEmpty) return merged;
    return _isTvk ? _tvkNews : _incNews;
  }

  // ── LEADER ───────────────────────────────────────────────────────
  static Future<Leader> getLeader() async {
    if (_isTvk) return LocaleController.isTamil ? _tvkLeaderTa : _tvkLeader;
    return _incLeader;
  }

  // ── MANIFESTO ────────────────────────────────────────────────────
  static Future<List<ManifestoPlan>> getManifestoPlans() async {
    if (_isTvk) return LocaleController.isTamil ? _tvkPlansTa : _tvkPlans;
    return _incPlans;
  }

  static Future<List<ManifestoVision>> getManifestoVisions() async {
    if (_isTvk) return LocaleController.isTamil ? _tvkVisionsTa : _tvkVisions;
    return _incVisions;
  }

  // ── EVENTS ───────────────────────────────────────────────────────
  static Future<List<PartyEvent>> getEvents() async {
    final rows = await _cmsRows('cms_events', AgentService.listEvents);
    if (rows.isNotEmpty) {
      return rows.map((m) => PartyEvent(
        id: m['id'].toString(),
        title: m['title'] as String? ?? '',
        location: m['location'] as String? ?? '',
        date: m['date'] as String? ?? '',
        time: m['time'] as String? ?? '',
        type: m['type'] as String? ?? 'Event',
        description: m['description'] as String? ?? '',
        imageUrl: (m['image_url'] as String?)?.isNotEmpty == true
            ? m['image_url'] as String
            : null,
      )).toList();
    }
    if (_isTvk) return LocaleController.isTamil ? _tvkEventsTa : _tvkEvents;
    return _incEvents;
  }

  // ── CAMPAIGN TOOLKIT ─────────────────────────────────────────────
  // Admin-published posters / media / slogans / hashtags. Cache-first;
  // returns an empty list when nothing is published, and the toolkit screen
  // falls back to its built-in static content so it is never blank.
  static Future<List<Map<String, dynamic>>> getToolkit(String kind) =>
      _cmsRows('cms_toolkit_$kind', () => AgentService.listToolkit(kind));

  static bool get _isTvk => _flavor == 'tn-tvk';

  // ════════════════════════════════════════════════════════════════
  // TVK MOCK DATA
  // ════════════════════════════════════════════════════════════════

  static const List<NewsItem> _tvkNews = [
    NewsItem(id: '1', title: 'TVK App Launch — My TVK for Member Enrolment', summary: 'Vijay launched the official TVK mobile app enabling direct member registration across Tamil Nadu.', category: 'Party', date: 'Jun 4, 2024', time: '5:24 pm'),
    NewsItem(id: '2', title: '2nd State Conference of TVK — Madurai Maanaadu', summary: 'Thousands of TVK cadres flock to Madurai for the party\'s landmark 2nd State Conference.', category: 'Event', date: 'Jun 4, 2024', time: '5:24 pm'),
    NewsItem(id: '3', title: 'New Anthem of TVK — Thaman Delivers Once Again', summary: 'Vijay\'s TVK anthem composed by S. Thaman released to massive public reception.', category: 'Media', date: 'Jun 3, 2024', time: '3:10 pm'),
    NewsItem(id: '4', title: 'TVK Condemns Attack on Women Functionaries', summary: 'Party president Vijay strongly condemns the attack on women party workers in Vyasarpadi.', category: 'Statement', date: 'Jun 2, 2024', time: '11:00 am'),
    NewsItem(id: '5', title: 'TVK Announces District-Level Booth Committees', summary: 'Booth-level committees to be formed across all 234 assembly constituencies in Tamil Nadu.', category: 'Organisation', date: 'Jun 1, 2024', time: '9:00 am'),
    NewsItem(id: '6', title: 'Clean Water Initiative — 500 Villages Targeted', summary: 'TVK\'s flagship scheme to provide solar-powered water purification to 500 villages by 2026.', category: 'Policy', date: 'May 30, 2024', time: '2:45 pm'),
  ];

  static const Leader _tvkLeader = Leader(
    id: 'vijay',
    name: 'Vijay',
    role: 'President, TVK',
    location: 'Chennai, Tamil Nadu',
    bio: 'Joseph Vijay Chandrasekhar, known mononymously as Vijay, is the founder and president of Tamilaga Vettri Kazhagam. Son of director S. A. Chandrasekhar and singer Shoba Chandrasekhar, he holds a B.A. in Visual Communication from Loyola College, Chennai.',
    careerSummary: 'Debuted as a child actor and rose to fame in Tamil cinema. Founded TVK in 2024 to fight for the welfare and rights of Tamil people, focusing on social justice, youth employment, and equitable development.',
    achievements: [
      LeaderAchievement(year: '2024', title: 'Founded TVK', description: 'Launched Tamilaga Vettri Kazhagam with a charter focused on social justice and Tamil welfare.'),
      LeaderAchievement(year: '2024', title: '2nd State Conference', description: 'Organised the landmark Madurai Maanaadu attended by lakhs of supporters.'),
      LeaderAchievement(year: '2024', title: 'Member Enrolment Drive', description: 'Over 10 lakh members enrolled through booth-level committees across Tamil Nadu.'),
    ],
  );

  // Tamil translation of _tvkLeader — machine-translated, same review caveat
  // as the rest of the app's Tamil content.
  static const Leader _tvkLeaderTa = Leader(
    id: 'vijay',
    name: 'விஜய்',
    role: 'தலைவர், தமிழக வெற்றிக் கழகம்',
    location: 'சென்னை, தமிழ்நாடு',
    bio: 'ஜோசப் விஜய் சந்திரசேகர், விஜய் என்ற பெயரில் அறியப்படுபவர், தமிழக வெற்றிக் கழகத்தின் நிறுவனரும் தலைவருமாவார். இயக்குநர் எஸ்.ஏ. சந்திரசேகர் மற்றும் பாடகி சோபா சந்திரசேகர் ஆகியோரின் மகனான இவர், சென்னை லயோலா கல்லூரியில் காட்சி தொடர்பியல் துறையில் இளங்கலை பட்டம் பெற்றவர்.',
    careerSummary: 'சிறுவர் நடிகராக அறிமுகமாகி தமிழ் சினிமாவில் புகழ் பெற்றார். தமிழக மக்களின் நலனுக்காகவும் உரிமைகளுக்காகவும் போராட, சமூக நீதி, இளைஞர் வேலைவாய்ப்பு மற்றும் சமச்சீர் வளர்ச்சியை மையமாகக் கொண்டு 2024ல் தி.வெ.க-வை நிறுவினார்.',
    achievements: [
      LeaderAchievement(year: '2024', title: 'தி.வெ.க நிறுவப்பட்டது', description: 'சமூக நீதி மற்றும் தமிழர் நலனை மையமாகக் கொண்ட சாசனத்துடன் தமிழக வெற்றிக் கழகத்தைத் தொடங்கினார்.'),
      LeaderAchievement(year: '2024', title: '2வது மாநில மாநாடு', description: 'லட்சக்கணக்கான ஆதரவாளர்கள் கலந்துகொண்ட மைல்கல் மதுரை மாநாட்டை ஏற்பாடு செய்தார்.'),
      LeaderAchievement(year: '2024', title: 'உறுப்பினர் சேர்க்கை இயக்கம்', description: 'தமிழ்நாடு முழுவதும் பூத் மட்டக் குழுக்கள் மூலம் 10 லட்சத்திற்கும் அதிகமான உறுப்பினர்கள் சேர்க்கப்பட்டனர்.'),
    ],
  );

  static final List<ManifestoPlan> _tvkPlans = [
    ManifestoPlan(
      id: 'p1', year: '2026',
      title: 'Clean Water for Villages',
      description: 'The "Clean Water for Villages" project is a comprehensive initiative to transform rural households across Tamil Nadu by ensuring sustainable, safe, and reliable drinking water. Installing solar-powered filtration systems in 500 villages, drawn from rivers, reservoirs, or groundwater, integrated with piped distribution maintained by local Panchayats and the Water Supply Board.',
      timeline: 'Jan 2026 – Sep 2026 (8 months)',
      budget: '₹500 Crore',
      category: 'Infrastructure',
      imageAsset: 'assets/images/plan_water.png',
      ministry: 'Ministry of Rural Development',
      bullets: [
        'Solar-powered filtration systems in 500 villages.',
        'Pipes laid to every household in targeted areas.',
        'Local Panchayat maintenance teams trained.',
        'Water quality testing labs at block level.',
        'Women\'s time saved: 2+ hours daily.',
      ],
      milestones: [
        ManifestoMilestone(date: 'July 2026', title: 'Project Initiation', description: 'Appointing project lead, form steering committee (local leaders + govt + funders + NGO), set high-level objectives.'),
        ManifestoMilestone(date: 'August 2026', title: 'Baseline Assessment & Community Census', description: 'Household census, water-use patterns, current coping strategies, existing infrastructure mapping, social & gender needs.'),
        ManifestoMilestone(date: 'August 2026', title: 'Hydrogeological & Water Quality Survey', description: 'Site-specific surveys (borehole yield, aquifer tests, spring source mapping), seasonal variability assessment, physico-chemical and bacteriological testing.'),
        ManifestoMilestone(date: 'September 2026', title: 'Pilot Construction & Testing (1 Village)', description: 'Mobilize works, install source/treatment/storage/distribution, train 1–2 local operators, implement simple telemetry or manual monitoring.'),
        ManifestoMilestone(date: 'November 2026', title: 'Commissioning & Water Quality Validation', description: 'Hydraulic tests, flow & pressure checks, full lab certification, finalize residual disinfection protocols, user acceptance tests.'),
        ManifestoMilestone(date: 'January 2027', title: 'Scale-up Roll-out (Remaining Villages)', description: 'Refine SOPs from pilot, batch procurement for cost savings, roll out construction in waves, stagger commissioning.'),
        ManifestoMilestone(date: 'March 2027', title: 'Handover & Long-term Sustainability', description: 'Formal handover to local authority/WUC, long-term maintenance contract, spare-parts pipeline, plan for eventual asset replacement.'),
      ],
    ),
    ManifestoPlan(
      id: 'p2', year: '2026',
      title: 'Digital Classrooms Expansion',
      description: 'Equip 1000 schools across Tamil Nadu with state-of-the-art smart classrooms and high-speed internet connectivity. Bridges digital divide in rural and urban schools.',
      timeline: 'Mar 2026 – Dec 2026 (9 months)',
      budget: '₹800 Crore',
      category: 'Education',
      ministry: 'Ministry of Education',
      imageAsset: 'assets/images/plan_education.png',
      bullets: [
        'Free laptops/tablets for students.',
        'Modernisation of government schools & smart classrooms.',
        'Special scholarships for rural & first-generation learners.',
        'AI & coding labs in district-level schools.',
        'Skill training centres linked with industry jobs.',
      ],
      milestones: [
        ManifestoMilestone(date: 'March 2026', title: 'School Assessment', description: 'Audit of 1000 target schools across 38 districts, infrastructure readiness check, bandwidth mapping.'),
        ManifestoMilestone(date: 'June 2026', title: 'Hardware Procurement', description: 'Tender and procurement of smart boards, tablets, laptops, and high-speed internet equipment.'),
        ManifestoMilestone(date: 'September 2026', title: 'Installation & Training', description: 'Deployment across schools with teacher training programmes and digital content integration.'),
        ManifestoMilestone(date: 'December 2026', title: 'Launch & Evaluation', description: 'Official launch with student feedback, performance metrics baseline, continuous improvement plan.'),
      ],
    ),
    ManifestoPlan(
      id: 'p3', year: '2027',
      title: 'Youth Employment Scheme',
      description: 'Create 5 lakh skilled jobs for Tamil youth through industry partnerships and government-funded skill training centres in every district.',
      timeline: 'Jan 2027 – Dec 2027',
      budget: '₹1200 Crore',
      category: 'Employment',
      imageAsset: 'assets/images/campaign1.png',
      bullets: [
        '5 lakh jobs created through industry MoUs.',
        'Skill training centres in all 38 districts.',
        'Government job fair every quarter.',
        'Startup grants up to ₹5 lakh for youth entrepreneurs.',
        'Apprenticeship guarantee for every graduate.',
      ],
    ),
    ManifestoPlan(
      id: 'p4', year: '2027',
      title: 'Farmer Income Guarantee',
      description: 'Guarantee minimum income of ₹15,000 per month to all registered farmers through direct benefit transfer and crop insurance reform.',
      timeline: 'Apr 2027 – Mar 2028',
      budget: '₹2000 Crore',
      category: 'Agriculture',
      imageAsset: 'assets/images/campaign2.png',
      bullets: [
        '₹15,000/month guaranteed via DBT.',
        'Crop insurance reformed — zero premium for small farmers.',
        'Solar pump subsidy for irrigation.',
        'Cold storage chains in every taluk.',
        'Fair price shops expanded to 5000+ outlets.',
      ],
    ),
    ManifestoPlan(
      id: 'p5', year: '2028',
      title: 'Women Safety Network',
      description: 'Deploy 10,000 women police officers across Tamil Nadu with dedicated fast-track courts for crimes against women.',
      timeline: 'Jan 2028 – Dec 2028',
      budget: '₹600 Crore',
      category: 'Safety',
      imageAsset: 'assets/images/plan_water.png',
      bullets: [
        '10,000 women police officers recruited & trained.',
        'Fast-track courts in every district.',
        'Safe city CCTV network: 50,000 cameras.',
        '24/7 women helpline with 30-min response.',
        'School self-defence training programme.',
      ],
    ),
  ];

  static const List<ManifestoVision> _tvkVisions = [
    ManifestoVision(title: 'Social Justice', description: 'We promote social justice principles to ensure equality for all social groups and create equal opportunities without discrimination.'),
    ManifestoVision(title: 'Technological Development', description: 'We want to use modern technologies in public welfare work, simplify political processes, and improve public service delivery.'),
    ManifestoVision(title: 'Opportunity for Youth', description: 'Every young Tamil deserves access to education, employment, and entrepreneurship opportunities regardless of their background.'),
    ManifestoVision(title: 'Farmer Welfare', description: 'Tamil farmers are the backbone of our economy. We will ensure fair prices, modern tools, and dignity for every farming family.'),
  ];

  // Tamil translations of _tvkPlans / _tvkVisions above — machine-translated,
  // needs a native Tamil speaker review pass before release (same caveat as
  // the rest of the app's Tamil strings — see CLAUDE.md changelog 2026-07-24).
  static final List<ManifestoPlan> _tvkPlansTa = [
    ManifestoPlan(
      id: 'p1', year: '2026',
      title: 'கிராமங்களுக்கு சுத்தமான குடிநீர்',
      description: '"கிராமங்களுக்கு சுத்தமான குடிநீர்" திட்டம், தமிழ்நாடு முழுவதும் உள்ள கிராமப்புற வீடுகளுக்கு நிலையான, பாதுகாப்பான மற்றும் நம்பகமான குடிநீரை உறுதி செய்வதற்கான ஒரு விரிவான முயற்சியாகும். 500 கிராமங்களில் சூரிய சக்தியில் இயங்கும் வடிகட்டி அமைப்புகளை நிறுவி, ஆறுகள், நீர்த்தேக்கங்கள் அல்லது நிலத்தடி நீரிலிருந்து பெறப்பட்டு, உள்ளாட்சி பஞ்சாயத்துகள் மற்றும் நீர் வழங்கல் வாரியத்தால் பராமரிக்கப்படும் குழாய் விநியோகத்துடன் இணைக்கப்படும்.',
      timeline: 'ஜன. 2026 – செப். 2026 (8 மாதங்கள்)',
      budget: '₹500 கோடி',
      category: 'உள்கட்டமைப்பு',
      imageAsset: 'assets/images/plan_water.png',
      ministry: 'கிராமப்புற வளர்ச்சி அமைச்சகம்',
      bullets: [
        '500 கிராமங்களில் சூரிய சக்தி வடிகட்டி அமைப்புகள்.',
        'இலக்கு வைக்கப்பட்ட பகுதிகளில் ஒவ்வொரு வீட்டிற்கும் குழாய்கள் அமைக்கப்படும்.',
        'உள்ளூர் பஞ்சாயத்து பராமரிப்புக் குழுக்களுக்கு பயிற்சி.',
        'தொகுதி மட்டத்தில் நீரின் தரம் சோதனை ஆய்வகங்கள்.',
        'பெண்களின் நேரம் மிச்சம்: தினமும் 2+ மணி நேரம்.',
      ],
      milestones: [
        ManifestoMilestone(date: 'ஜூலை 2026', title: 'திட்ட தொடக்கம்', description: 'திட்ட தலைவரை நியமித்தல், வழிநடத்தும் குழுவை (உள்ளூர் தலைவர்கள் + அரசு + நிதியாளர்கள் + தன்னார்வ தொண்டு நிறுவனங்கள்) உருவாக்குதல், உயர்நிலை இலக்குகளை நிர்ணயித்தல்.'),
        ManifestoMilestone(date: 'ஆகஸ்ட் 2026', title: 'அடிப்படை மதிப்பீடு & சமூக கணக்கெடுப்பு', description: 'வீட்டுக் கணக்கெடுப்பு, நீர் பயன்பாட்டு முறைகள், தற்போதைய சமாளிப்பு உத்திகள், தற்போதுள்ள உள்கட்டமைப்பு வரைபடமாக்கல், சமூக & பாலின தேவைகள்.'),
        ManifestoMilestone(date: 'ஆகஸ்ட் 2026', title: 'நிலநீரியல் & நீர் தர ஆய்வு', description: 'இட-குறிப்பிட்ட ஆய்வுகள் (குழாய்க் கிணறு விளைச்சல், நிலத்தடி நீர் அடுக்கு சோதனைகள், ஊற்று மூல வரைபடமாக்கல்), பருவகால மாறுபாடு மதிப்பீடு, இயற்பியல்-வேதியியல் மற்றும் பாக்டீரியாவியல் சோதனை.'),
        ManifestoMilestone(date: 'செப்டம்பர் 2026', title: 'முன்னோடி கட்டுமானம் & சோதனை (1 கிராமம்)', description: 'பணிகளை அணிதிரட்டல், மூலம்/சுத்திகரிப்பு/சேமிப்பு/விநியோகத்தை நிறுவுதல், 1–2 உள்ளூர் இயக்குநர்களுக்கு பயிற்சி, எளிய தொலைநிலை அல்லது கையேடு கண்காணிப்பு செயல்படுத்தல்.'),
        ManifestoMilestone(date: 'நவம்பர் 2026', title: 'இயக்கத்தொடக்கம் & நீர் தர சரிபார்ப்பு', description: 'நீரியல் சோதனைகள், ஓட்டம் & அழுத்தம் சரிபார்ப்பு, முழு ஆய்வக சான்றிதழ், எஞ்சிய கிருமி நீக்கல் நெறிமுறைகளை இறுதி செய்தல், பயனர் ஏற்புச் சோதனைகள்.'),
        ManifestoMilestone(date: 'ஜனவரி 2027', title: 'விரிவாக்க நடைமுறை (மீதமுள்ள கிராமங்கள்)', description: 'முன்னோடியிலிருந்து செயல்முறைகளை மேம்படுத்துதல், செலவு சேமிப்புக்கான தொகுதி கொள்முதல், அலைகளாக கட்டுமானத்தை விரிவுபடுத்துதல், படிப்படியாக இயக்கத்தொடக்கம்.'),
        ManifestoMilestone(date: 'மார்ச் 2027', title: 'ஒப்படைப்பு & நீண்டகால நிலைத்தன்மை', description: 'உள்ளூர் அதிகாரம்/நீர் பயனர் குழுவிடம் முறையான ஒப்படைப்பு, நீண்டகால பராமரிப்பு ஒப்பந்தம், உதிரி பாகங்கள் விநியோகம், சொத்து மாற்று திட்டம்.'),
      ],
    ),
    ManifestoPlan(
      id: 'p2', year: '2026',
      title: 'டிஜிட்டல் வகுப்பறைகள் விரிவாக்கம்',
      description: 'தமிழ்நாடு முழுவதும் 1000 பள்ளிகளுக்கு அதிநவீன ஸ்மார்ட் வகுப்பறைகள் மற்றும் அதிவேக இணைய இணைப்பை வழங்குதல். கிராமப்புற மற்றும் நகர்ப்புற பள்ளிகளில் டிஜிட்டல் இடைவெளியை குறைக்கிறது.',
      timeline: 'மார்ச் 2026 – டிச. 2026 (9 மாதங்கள்)',
      budget: '₹800 கோடி',
      category: 'கல்வி',
      ministry: 'கல்வி அமைச்சகம்',
      imageAsset: 'assets/images/plan_education.png',
      bullets: [
        'மாணவர்களுக்கு இலவச லேப்டாப்/டேப்லெட்.',
        'அரசு பள்ளிகள் நவீனமயமாக்கல் & ஸ்மார்ட் வகுப்பறைகள்.',
        'கிராமப்புற & முதல் தலைமுறை கல்வியாளர்களுக்கு சிறப்பு உதவித்தொகை.',
        'மாவட்ட மட்ட பள்ளிகளில் AI & குறியீட்டு ஆய்வகங்கள்.',
        'தொழில்துறை வேலைகளுடன் இணைக்கப்பட்ட திறன் பயிற்சி மையங்கள்.',
      ],
      milestones: [
        ManifestoMilestone(date: 'மார்ச் 2026', title: 'பள்ளி மதிப்பீடு', description: '38 மாவட்டங்களில் 1000 இலக்கு பள்ளிகளின் தணிக்கை, உள்கட்டமைப்பு தயார்நிலை சோதனை, பட்டையகல வரைபடமாக்கல்.'),
        ManifestoMilestone(date: 'ஜூன் 2026', title: 'வன்பொருள் கொள்முதல்', description: 'ஸ்மார்ட் போர்டுகள், டேப்லெட்கள், லேப்டாப்புகள் மற்றும் அதிவேக இணைய உபகரணங்களுக்கான டெண்டர் மற்றும் கொள்முதல்.'),
        ManifestoMilestone(date: 'செப்டம்பர் 2026', title: 'நிறுவல் & பயிற்சி', description: 'ஆசிரியர் பயிற்சி திட்டங்கள் மற்றும் டிஜிட்டல் உள்ளடக்க ஒருங்கிணைப்புடன் பள்ளிகளில் பொருத்துதல்.'),
        ManifestoMilestone(date: 'டிசம்பர் 2026', title: 'தொடக்கம் & மதிப்பீடு', description: 'மாணவர் கருத்துடன் அதிகாரப்பூர்வ தொடக்கம், செயல்திறன் அளவீடுகள் அடிப்படைக் கோடு, தொடர் மேம்பாட்டுத் திட்டம்.'),
      ],
    ),
    ManifestoPlan(
      id: 'p3', year: '2027',
      title: 'இளைஞர் வேலைவாய்ப்புத் திட்டம்',
      description: 'தொழில்துறை கூட்டாண்மைகள் மற்றும் ஒவ்வொரு மாவட்டத்திலும் அரசு நிதியுதவியுடன் கூடிய திறன் பயிற்சி மையங்கள் மூலம் தமிழ் இளைஞர்களுக்கு 5 லட்சம் திறன்மிக்க வேலைகளை உருவாக்குதல்.',
      timeline: 'ஜன. 2027 – டிச. 2027',
      budget: '₹1200 கோடி',
      category: 'வேலைவாய்ப்பு',
      imageAsset: 'assets/images/campaign1.png',
      bullets: [
        '5 லட்சம் வேலைகள் தொழில்துறை புரிந்துணர்வு ஒப்பந்தங்கள் மூலம்.',
        '38 மாவட்டங்களிலும் திறன் பயிற்சி மையங்கள்.',
        'காலாண்டுக்கு ஒருமுறை அரசு வேலைவாய்ப்பு முகாம்.',
        'இளம் தொழில்முனைவோருக்கு ₹5 லட்சம் வரை தொடக்க மானியம்.',
        'ஒவ்வொரு பட்டதாரிக்கும் பயிற்சிப் பணி உத்தரவாதம்.',
      ],
    ),
    ManifestoPlan(
      id: 'p4', year: '2027',
      title: 'விவசாயி வருமான உத்தரவாதம்',
      description: 'நேரடி நலப் பயன் பரிமாற்றம் மற்றும் பயிர் காப்பீடு சீர்திருத்தத்தின் மூலம் அனைத்து பதிவுசெய்யப்பட்ட விவசாயிகளுக்கும் மாதம் ₹15,000 குறைந்தபட்ச வருமானத்தை உத்தரவாதம் செய்தல்.',
      timeline: 'ஏப். 2027 – மார்ச் 2028',
      budget: '₹2000 கோடி',
      category: 'வேளாண்மை',
      imageAsset: 'assets/images/campaign2.png',
      bullets: [
        'DBT மூலம் மாதம் ₹15,000 உத்தரவாதம்.',
        'பயிர் காப்பீடு சீர்திருத்தம் — சிறு விவசாயிகளுக்கு பூஜ்ஜிய பிரீமியம்.',
        'பாசனத்திற்கான சூரிய சக்தி மோட்டார் மானியம்.',
        'ஒவ்வொரு தாலுகாவிலும் குளிர்பதன கிடங்கு சங்கிலிகள்.',
        'நியாய விலைக் கடைகள் 5000+ கடைகளுக்கு விரிவாக்கம்.',
      ],
    ),
    ManifestoPlan(
      id: 'p5', year: '2028',
      title: 'பெண்கள் பாதுகாப்பு வலையமைப்பு',
      description: 'பெண்களுக்கு எதிரான குற்றங்களுக்கான விரைவு நீதிமன்றங்களுடன் தமிழ்நாடு முழுவதும் 10,000 பெண் காவல் அதிகாரிகளை நியமித்தல்.',
      timeline: 'ஜன. 2028 – டிச. 2028',
      budget: '₹600 கோடி',
      category: 'பாதுகாப்பு',
      imageAsset: 'assets/images/plan_water.png',
      bullets: [
        '10,000 பெண் காவல் அதிகாரிகள் பணியமர்த்தப்பட்டு பயிற்சி அளிக்கப்படுவர்.',
        'ஒவ்வொரு மாவட்டத்திலும் விரைவு நீதிமன்றங்கள்.',
        'பாதுகாப்பான நகர CCTV வலையமைப்பு: 50,000 கேமராக்கள்.',
        '30 நிமிட பதிலளிப்புடன் 24/7 பெண்கள் உதவி எண்.',
        'பள்ளி சுய பாதுகாப்பு பயிற்சித் திட்டம்.',
      ],
    ),
  ];

  static const List<ManifestoVision> _tvkVisionsTa = [
    ManifestoVision(title: 'சமூக நீதி', description: 'அனைத்து சமூகக் குழுக்களுக்கும் சமத்துவத்தை உறுதி செய்யவும், பாகுபாடின்றி சம வாய்ப்புகளை உருவாக்கவும் சமூக நீதிக் கொள்கைகளை நாங்கள் ஊக்குவிக்கிறோம்.'),
    ManifestoVision(title: 'தொழில்நுட்ப வளர்ச்சி', description: 'பொது நல பணிகளில் நவீன தொழில்நுட்பங்களைப் பயன்படுத்தவும், அரசியல் செயல்முறைகளை எளிதாக்கவும், பொது சேவை வழங்கலை மேம்படுத்தவும் நாங்கள் விரும்புகிறோம்.'),
    ManifestoVision(title: 'இளைஞர்களுக்கான வாய்ப்பு', description: 'ஒவ்வொரு இளம் தமிழரும் தங்கள் பின்னணியைப் பொருட்படுத்தாமல் கல்வி, வேலைவாய்ப்பு மற்றும் தொழில்முனைவோர் வாய்ப்புகளைப் பெற தகுதியுடையவர்.'),
    ManifestoVision(title: 'விவசாயி நலன்', description: 'தமிழ் விவசாயிகள் நமது பொருளாதாரத்தின் முதுகெலும்பு. ஒவ்வொரு விவசாய குடும்பத்திற்கும் நியாயமான விலைகள், நவீன கருவிகள் மற்றும் கண்ணியத்தை நாங்கள் உறுதி செய்வோம்.'),
  ];

  static const List<PartyEvent> _tvkEvents = [
    PartyEvent(id: 'e1', title: 'District Booth Committee Meeting', location: 'Chennai', date: 'May 20, 2026', time: '10:00 AM', type: 'Meeting', description: 'Booth committee formation for Chennai district assembly constituencies.'),
    PartyEvent(id: 'e2', title: 'Youth Wing Rally — Coimbatore', location: 'Coimbatore', date: 'May 24, 2026', time: '4:00 PM', type: 'Rally', description: 'Massive youth rally addressing employment and education rights.'),
    PartyEvent(id: 'e3', title: 'Farmer Convention — Trichy', location: 'Trichy', date: 'May 28, 2026', time: '9:00 AM', type: 'Convention', description: 'State-level farmer convention to discuss minimum income guarantee policy.'),
    PartyEvent(id: 'e4', title: 'TVK Cultural Evening — Madurai', location: 'Madurai', date: 'Jun 2, 2026', time: '6:00 PM', type: 'Cultural', description: 'Music and cultural programme celebrating Tamil heritage.'),
  ];

  // Tamil translation of _tvkEvents — date/time stay in the canonical English
  // "MMM D, YYYY" format since the UI parses the month abbreviation for the
  // date-box/weekday display; only display text is translated.
  static const List<PartyEvent> _tvkEventsTa = [
    PartyEvent(id: 'e1', title: 'மாவட்ட பூத் குழு கூட்டம்', location: 'சென்னை', date: 'May 20, 2026', time: '10:00 AM', type: 'கூட்டம்', description: 'சென்னை மாவட்ட சட்டமன்ற தொகுதிகளுக்கான பூத் குழு அமைப்பு.'),
    PartyEvent(id: 'e2', title: 'இளைஞர் பிரிவு பேரணி — கோயம்புத்தூர்', location: 'கோயம்புத்தூர்', date: 'May 24, 2026', time: '4:00 PM', type: 'பேரணி', description: 'வேலைவாய்ப்பு மற்றும் கல்வி உரிமைகளைப் பேசும் மாபெரும் இளைஞர் பேரணி.'),
    PartyEvent(id: 'e3', title: 'விவசாயிகள் மாநாடு — திருச்சி', location: 'திருச்சி', date: 'May 28, 2026', time: '9:00 AM', type: 'மாநாடு', description: 'குறைந்தபட்ச வருமான உத்தரவாதக் கொள்கையை விவாதிக்கும் மாநில அளவிலான விவசாயிகள் மாநாடு.'),
    PartyEvent(id: 'e4', title: 'தி.வெ.க கலை நிகழ்ச்சி — மதுரை', location: 'மதுரை', date: 'Jun 2, 2026', time: '6:00 PM', type: 'கலை நிகழ்ச்சி', description: 'தமிழ் பாரம்பரியத்தைக் கொண்டாடும் இசை மற்றும் கலை நிகழ்ச்சி.'),
  ];

  // ════════════════════════════════════════════════════════════════
  // INC MOCK DATA
  // ════════════════════════════════════════════════════════════════

  static const List<NewsItem> _incNews = [
    NewsItem(id: '1', title: 'Rahul Gandhi\'s Clarion Call Against Vote Chori', summary: 'The Congress leader speaks out against electoral malpractices ahead of the general elections.', category: 'Statement', date: 'Jun 4, 2024', time: '5:24 pm'),
    NewsItem(id: '2', title: 'Right to Work Must Be Saved', summary: 'Congress demands the government protect MNREGA and employment rights for rural India.', category: 'Policy', date: 'Jun 4, 2024', time: '5:24 pm'),
    NewsItem(id: '3', title: 'Paanch Nyay: Five Guarantees for India', summary: 'The Congress Nyay Patra 2024 promises justice for farmers, youth, women, workers, and equity.', category: 'Manifesto', date: 'Jun 3, 2024', time: '3:10 pm'),
    NewsItem(id: '4', title: 'Bharat Jodo Nyay Yatra Concludes', summary: 'The 6,700 km journey across India concludes, connecting citizens to the Congress vision.', category: 'Movement', date: 'Jun 2, 2024', time: '11:00 am'),
    NewsItem(id: '5', title: 'Kharge Addresses Congress Working Committee', summary: 'Congress President outlines the party\'s strategy and organisational priorities for 2024.', category: 'Party', date: 'Jun 1, 2024', time: '9:00 am'),
    NewsItem(id: '6', title: 'Congress Promises Full Caste Census in Year One', summary: 'A full socio-economic caste census to be conducted within the first year of forming government.', category: 'Policy', date: 'May 30, 2024', time: '2:45 pm'),
  ];

  static const Leader _incLeader = Leader(
    id: 'rahul',
    name: 'Rahul Gandhi',
    role: 'MP, Wayanad | Former INC President',
    location: 'New Delhi',
    bio: 'Rahul Gandhi is a Member of Parliament representing Wayanad, Kerala, and a senior leader of the Indian National Congress. He has been a central figure in Indian politics, championing social justice, farmers\' rights, and constitutional values.',
    careerSummary: 'Led the historic Bharat Jodo Yatra (2022) and Bharat Jodo Nyay Yatra (2024), walking thousands of kilometres to connect with ordinary Indians. Champion of the Nyay Patra — five pillars of justice for every Indian.',
    achievements: [
      LeaderAchievement(year: '2022', title: 'Bharat Jodo Yatra', description: 'Led a 3,570 km padyatra from Kanyakumari to Kashmir connecting with 10 crore citizens.'),
      LeaderAchievement(year: '2024', title: 'Bharat Jodo Nyay Yatra', description: 'A 6,700 km journey across India pushing the Nyay Patra agenda.'),
      LeaderAchievement(year: '2024', title: 'Nyay Patra Launch', description: 'Released the Congress Manifesto 2024 — five pillars of justice for every Indian.'),
    ],
  );

  static final List<ManifestoPlan> _incPlans = [
    ManifestoPlan(id: 'p1', year: '2024', title: 'Legal MSP Guarantee', description: 'Enact a law guaranteeing Minimum Support Price for all crops, protecting every farmer\'s income immediately upon forming government.', timeline: 'Year 1 (2024–25)', budget: '₹2,80,000 Crore', category: 'Agriculture'),
    ManifestoPlan(id: 'p2', year: '2025', title: '30 Lakh Government Jobs', description: 'Fill all 30 lakh vacant government posts within the first year, and create 30 lakh new posts every year thereafter.', timeline: 'Year 1–2', budget: 'Budgetary Allocation', category: 'Employment'),
    ManifestoPlan(id: 'p3', year: '2025', title: 'Right to Health Act', description: 'Pass the Right to Health as a fundamental right with ₹25 lakh free health insurance for every family and 25 lakh new health workers.', timeline: 'Year 1–2', budget: '₹1,50,000 Crore', category: 'Health'),
    ManifestoPlan(id: 'p4', year: '2026', title: 'Socio-Economic Caste Census', description: 'Conduct a full caste census to uncover the real picture of inequality and enable proportional representation for all communities.', timeline: 'Year 1 (within 12 months)', budget: '₹5,000 Crore', category: 'Social Justice'),
    ManifestoPlan(id: 'p5', year: '2026', title: 'Mahalakshmi Scheme', description: 'Provide ₹1 lakh annual financial assistance to every woman from the poorest households, directly to their bank accounts.', timeline: 'Year 2–3', budget: '₹3,60,000 Crore', category: 'Women'),
  ];

  static const List<ManifestoVision> _incVisions = [
    ManifestoVision(title: 'Kisan Nyay', description: 'Legal MSP guarantee, farm loan waiver, and crop insurance reform. Every farmer earns ₹72,000 minimum per year.'),
    ManifestoVision(title: 'Yuva Nyay', description: '30 lakh government jobs annually, 1-year paid apprenticeship for every graduate, MNREGA at 200 days ₹400/day.'),
    ManifestoVision(title: 'Nari Nyay', description: '50% women in all government recruitment, ₹1 lakh annual assistance, free LPG for all BPL households.'),
    ManifestoVision(title: 'Hissedari Nyay', description: 'Caste census in year 1, proportional representation for OBC, SC, and ST in all institutions.'),
  ];

  static const List<PartyEvent> _incEvents = [
    PartyEvent(id: 'e1', title: 'Public Rally — Connaught Place', location: 'New Delhi', date: 'May 18, 2026', time: '4:00 PM', type: 'Rally', description: 'Massive public rally on unemployment and farmer rights.'),
    PartyEvent(id: 'e2', title: 'Youth Congress Leadership Meet', location: 'Mumbai', date: 'May 22, 2026', time: '10:00 AM', type: 'Meeting', description: 'Youth Congress national leadership meet.'),
    PartyEvent(id: 'e3', title: 'Farmers Convention — Patna', location: 'Patna', date: 'May 26, 2026', time: '9:00 AM', type: 'Convention', description: 'State-level farmers convention on MSP guarantee.'),
    PartyEvent(id: 'e4', title: 'Bharat Jodo Padyatra', location: 'Chennai', date: 'Jun 1, 2026', time: '7:00 AM', type: 'Yatra', description: 'Tamil Nadu leg of Bharat Jodo connecting grassroots workers.'),
  ];

}
