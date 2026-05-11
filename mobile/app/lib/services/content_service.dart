import '../config/app_config.dart';
import '../models/news_item.dart';
import '../models/leader.dart';
import '../models/manifesto_plan.dart';
import '../models/event.dart';
import '../models/short_video.dart';

// All methods return mock data now.
// To wire real API: replace the return value in each method only.
// ViewModels do not need to change.
class ContentService {
  static final String _flavor = AppConfig.flavorName;

  // ── NEWS ─────────────────────────────────────────────────────────
  static Future<List<NewsItem>> getNews() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _isTvk ? _tvkNews : _incNews;
  }

  // ── LEADER ───────────────────────────────────────────────────────
  static Future<Leader> getLeader() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _isTvk ? _tvkLeader : _incLeader;
  }

  // ── MANIFESTO ────────────────────────────────────────────────────
  static Future<List<ManifestoPlan>> getManifestoPlans() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _isTvk ? _tvkPlans : _incPlans;
  }

  static Future<List<ManifestoVision>> getManifestoVisions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _isTvk ? _tvkVisions : _incVisions;
  }

  // ── EVENTS ───────────────────────────────────────────────────────
  static Future<List<PartyEvent>> getEvents() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _isTvk ? _tvkEvents : _incEvents;
  }

  // ── SHORTS ───────────────────────────────────────────────────────
  static Future<List<ShortVideo>> getShorts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _isTvk ? _tvkShorts : _incShorts;
  }

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

  static final List<ManifestoPlan> _tvkPlans = [
    ManifestoPlan(
      id: 'p1', year: '2026',
      title: 'Clean Water for Villages',
      description: 'Initiative to provide purified drinking water to 500 villages using solar-powered filtration. Reduces water-borne diseases. Saves women\'s time on water collection.',
      timeline: 'Jan 2026 – Sep 2026 (8 months)',
      budget: '₹500 Crore',
      category: 'Infrastructure',
      imageAsset: 'assets/images/plan_water.png',
      bullets: [
        'Solar-powered filtration systems in 500 villages.',
        'Pipes laid to every household in targeted areas.',
        'Local Panchayat maintenance teams trained.',
        'Water quality testing labs at block level.',
        'Women\'s time saved: 2+ hours daily.',
      ],
    ),
    ManifestoPlan(
      id: 'p2', year: '2026',
      title: 'Digital Classrooms Expansion',
      description: 'Equip 1000 schools across Tamil Nadu with state-of-the-art smart classrooms and high-speed internet connectivity. Bridges digital divide in rural and urban schools.',
      timeline: 'Mar 2026 – Dec 2026 (9 months)',
      budget: '₹800 Crore',
      category: 'Education',
      imageAsset: 'assets/images/plan_education.png',
      bullets: [
        'Free laptops/tablets for students.',
        'Modernisation of government schools & smart classrooms.',
        'Special scholarships for rural & first-generation learners.',
        'AI & coding labs in district-level schools.',
        'Skill training centres linked with industry jobs.',
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

  static const List<PartyEvent> _tvkEvents = [
    PartyEvent(id: 'e1', title: 'District Booth Committee Meeting', location: 'Chennai', date: 'May 20, 2026', time: '10:00 AM', type: 'Meeting', description: 'Booth committee formation for Chennai district assembly constituencies.'),
    PartyEvent(id: 'e2', title: 'Youth Wing Rally — Coimbatore', location: 'Coimbatore', date: 'May 24, 2026', time: '4:00 PM', type: 'Rally', description: 'Massive youth rally addressing employment and education rights.'),
    PartyEvent(id: 'e3', title: 'Farmer Convention — Trichy', location: 'Trichy', date: 'May 28, 2026', time: '9:00 AM', type: 'Convention', description: 'State-level farmer convention to discuss minimum income guarantee policy.'),
    PartyEvent(id: 'e4', title: 'TVK Cultural Evening — Madurai', location: 'Madurai', date: 'Jun 2, 2026', time: '6:00 PM', type: 'Cultural', description: 'Music and cultural programme celebrating Tamil heritage.'),
  ];

  static const List<ShortVideo> _tvkShorts = [
    ShortVideo(id: 's1', title: 'Vijay on Clean Water Mission', duration: '1:24', category: 'Policy', timeAgo: '2 hours ago'),
    ShortVideo(id: 's2', title: 'TVK Anthem — Full Version', duration: '4:22', category: 'Media', timeAgo: 'Today'),
    ShortVideo(id: 's3', title: '2nd State Conference Highlights', duration: '3:10', category: 'Event', timeAgo: 'Yesterday'),
    ShortVideo(id: 's4', title: 'Vijay Addresses Youth Wing', duration: '2:45', category: 'Speech', timeAgo: '2 days ago'),
    ShortVideo(id: 's5', title: 'Digital Classrooms Launch', duration: '1:58', category: 'Policy', timeAgo: '3 days ago'),
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

  static const List<ShortVideo> _incShorts = [
    ShortVideo(id: 's1', title: 'Rahul on Nyay Patra', duration: '2:10', category: 'Speech', timeAgo: '1 hour ago'),
    ShortVideo(id: 's2', title: 'Bharat Jodo Nyay Yatra Highlights', duration: '3:45', category: 'Movement', timeAgo: 'Today'),
    ShortVideo(id: 's3', title: 'Kharge on Caste Census', duration: '1:55', category: 'Policy', timeAgo: 'Yesterday'),
    ShortVideo(id: 's4', title: 'Congress Anthem 2024', duration: '4:12', category: 'Media', timeAgo: '2 days ago'),
  ];
}
