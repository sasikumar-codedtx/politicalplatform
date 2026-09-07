import 'app_strings.dart';

/// A value with both an English and Tamil label. The English side is the
/// canonical value stored in state/sent to the backend; `label` picks
/// whichever the active locale should display. Keeping data-in-English and
/// display-in-locale separate means switching language never changes what
/// gets saved.
class Bilingual {
  final String en;
  final String ta;
  const Bilingual(this.en, this.ta);

  String get label => LocaleController.isTamil ? ta : en;

  /// Looks up the display label for a canonical English value, falling back
  /// to the value itself if it isn't in [options] (e.g. legacy/free data).
  static String labelFor(List<Bilingual> options, String? en) {
    if (en == null) return '';
    for (final o in options) {
      if (o.en == en) return o.label;
    }
    return en;
  }

  static List<String> labels(List<Bilingual> options) => options.map((o) => o.label).toList();

  /// Maps a picked display label back to its canonical English value.
  static String? enFor(List<Bilingual> options, String? label) {
    if (label == null) return null;
    for (final o in options) {
      if (o.label == label) return o.en;
    }
    return label;
  }
}

/// The 38 Tamil Nadu districts used across Join TVK and File a Grievance.
const kTnDistricts = <Bilingual>[
  Bilingual('Chennai', 'சென்னை'),
  Bilingual('Coimbatore', 'கோயம்புத்தூர்'),
  Bilingual('Madurai', 'மதுரை'),
  Bilingual('Tiruchirappalli', 'திருச்சிராப்பள்ளி'),
  Bilingual('Salem', 'சேலம்'),
  Bilingual('Tirunelveli', 'திருநெல்வேலி'),
  Bilingual('Vellore', 'வேலூர்'),
  Bilingual('Erode', 'ஈரோடு'),
  Bilingual('Thoothukudi', 'தூத்துக்குடி'),
  Bilingual('Dindigul', 'திண்டுக்கல்'),
  Bilingual('Thanjavur', 'தஞ்சாவூர்'),
  Bilingual('Tiruppur', 'திருப்பூர்'),
  Bilingual('Ranipet', 'ராணிப்பேட்டை'),
  Bilingual('Sivaganga', 'சிவகங்கை'),
  Bilingual('Virudhunagar', 'விருதுநகர்'),
  Bilingual('Nagapattinam', 'நாகப்பட்டினம்'),
  Bilingual('Cuddalore', 'கடலூர்'),
  Bilingual('Villupuram', 'விழுப்புரம்'),
  Bilingual('Kancheepuram', 'காஞ்சிபுரம்'),
  Bilingual('Chengalpattu', 'செங்கல்பட்டு'),
  Bilingual('Kallakurichi', 'கள்ளக்குறிச்சி'),
  Bilingual('Tiruvannamalai', 'திருவண்ணாமலை'),
  Bilingual('Krishnagiri', 'கிருஷ்ணகிரி'),
  Bilingual('Dharmapuri', 'தர்மபுரி'),
  Bilingual('Namakkal', 'நாமக்கல்'),
  Bilingual('Ariyalur', 'அரியலூர்'),
  Bilingual('Perambalur', 'பெரம்பலூர்'),
  Bilingual('Karur', 'கரூர்'),
  Bilingual('Nilgiris', 'நீலகிரி'),
  Bilingual('Tiruvarur', 'திருவாரூர்'),
  Bilingual('Pudukkottai', 'புதுக்கோட்டை'),
  Bilingual('Ramanathapuram', 'இராமநாதபுரம்'),
  Bilingual('Tenkasi', 'தென்காசி'),
  Bilingual('Kanyakumari', 'கன்னியாகுமரி'),
  Bilingual('Mayiladuthurai', 'மயிலாடுதுறை'),
  Bilingual('Tirupathur', 'திருப்பத்தூர்'),
  Bilingual('Chengam', 'செங்கம்'),
  Bilingual('Tirupattur', 'திருப்பத்தூர்'),
];

const kGenderOptions = <Bilingual>[
  Bilingual('Male', 'ஆண்'),
  Bilingual('Female', 'பெண்'),
  Bilingual('Non-binary', 'பால்நிலை மாறுபட்டவர்'),
  Bilingual('Prefer not to say', 'கூற விரும்பவில்லை'),
];

const kLocalBodyTypes = <Bilingual>[
  Bilingual('Corporation', 'மாநகராட்சி'),
  Bilingual('Municipality', 'நகராட்சி'),
  Bilingual('Town Panchayat', 'பேரூராட்சி'),
  Bilingual('Village Panchayat', 'கிராம பஞ்சாயத்து'),
  Bilingual('Other', 'மற்றவை'),
];

/// Grievance category → department, machine-translated (same review caveat
/// as the rest of the app's Tamil strings).
const kCategoryDepartment = <Bilingual, Bilingual>{
  Bilingual('Roads & Infrastructure', 'சாலைகள் & உள்கட்டமைப்பு'): Bilingual('Municipal Administration / Highways', 'நகராட்சி நிர்வாகம் / நெடுஞ்சாலைகள்'),
  Bilingual('Water Supply', 'நீர் வழங்கல்'): Bilingual('Water Supply Department', 'நீர் வழங்கல் துறை'),
  Bilingual('Electricity', 'மின்சாரம்'): Bilingual('TANGEDCO / Electricity Board', 'தமிழ்நாடு மின்சார வாரியம் (TANGEDCO)'),
  Bilingual('Sanitation', 'தூய்மைப் பணி'): Bilingual('Municipal Administration', 'நகராட்சி நிர்வாகம்'),
  Bilingual('Education', 'கல்வி'): Bilingual('School Education Department', 'பள்ளிக் கல்வித் துறை'),
  Bilingual('Health', 'சுகாதாரம்'): Bilingual('Health Department', 'சுகாதாரத் துறை'),
  Bilingual('Land & Property', 'நிலம் & சொத்து'): Bilingual('Revenue Department', 'வருவாய்த் துறை'),
  Bilingual('Police & Public Safety', 'காவல் & பொது பாதுகாப்பு'): Bilingual('Police Department', 'காவல் துறை'),
  Bilingual('Transport', 'போக்குவரத்து'): Bilingual('Transport Department', 'போக்குவரத்துத் துறை'),
  Bilingual('Housing', 'வீட்டுவசதி'): Bilingual('Housing & Urban Development', 'வீட்டுவசதி & நகர்ப்புற வளர்ச்சி'),
  Bilingual('Pension & Welfare', 'ஓய்வூதியம் & நலன்'): Bilingual('Social Welfare Department', 'சமூக நலத் துறை'),
  Bilingual('Other', 'மற்றவை'): Bilingual('General Administration', 'பொது நிர்வாகம்'),
};

const kGrievanceCategories = <Bilingual, List<Bilingual>>{
  Bilingual('Roads & Infrastructure', 'சாலைகள் & உள்கட்டமைப்பு'): [
    Bilingual('Damaged Road', 'சேதமடைந்த சாலை'),
    Bilingual('Potholes', 'குழிகள்'),
    Bilingual('Road Construction', 'சாலை கட்டுமானம்'),
    Bilingual('Road Widening', 'சாலை விரிவாக்கம்'),
    Bilingual('Drainage', 'வடிகால்'),
    Bilingual('Street Light', 'தெரு விளக்கு'),
    Bilingual('Other', 'மற்றவை'),
  ],
  Bilingual('Water Supply', 'நீர் வழங்கல்'): [
    Bilingual('No Water Supply', 'குடிநீர் இல்லை'),
    Bilingual('Contaminated Water', 'அசுத்தமான நீர்'),
    Bilingual('Pipeline Leakage', 'குழாய் கசிவு'),
    Bilingual('Water Tanker Request', 'தண்ணீர் லாரி கோரிக்கை'),
    Bilingual('Other', 'மற்றவை'),
  ],
  Bilingual('Electricity', 'மின்சாரம்'): [
    Bilingual('Power Outage', 'மின்தடை'),
    Bilingual('Transformer Issue', 'மின்மாற்றி பிரச்சினை'),
    Bilingual('Streetlight Not Working', 'தெரு விளக்கு வேலை செய்யவில்லை'),
    Bilingual('New Connection', 'புதிய இணைப்பு'),
    Bilingual('Other', 'மற்றவை'),
  ],
  Bilingual('Sanitation', 'தூய்மைப் பணி'): [
    Bilingual('Garbage Not Collected', 'குப்பை அகற்றப்படவில்லை'),
    Bilingual('Public Toilet Issue', 'பொது கழிப்பறை பிரச்சினை'),
    Bilingual('Drainage Blockage', 'வடிகால் அடைப்பு'),
    Bilingual('Other', 'மற்றவை'),
  ],
  Bilingual('Education', 'கல்வி'): [
    Bilingual('School Infrastructure', 'பள்ளி உள்கட்டமைப்பு'),
    Bilingual('Teacher Shortage', 'ஆசிரியர் பற்றாக்குறை'),
    Bilingual('Scholarship Issue', 'உதவித்தொகை பிரச்சினை'),
    Bilingual('Other', 'மற்றவை'),
  ],
  Bilingual('Health', 'சுகாதாரம்'): [
    Bilingual('Hospital Service', 'மருத்துவமனை சேவை'),
    Bilingual('Medicine Shortage', 'மருந்து பற்றாக்குறை'),
    Bilingual('Ambulance Delay', 'ஆம்புலன்ஸ் தாமதம்'),
    Bilingual('Other', 'மற்றவை'),
  ],
  Bilingual('Land & Property', 'நிலம் & சொத்து'): [
    Bilingual('Patta Issue', 'பட்டா பிரச்சினை'),
    Bilingual('Land Encroachment', 'நில ஆக்கிரமிப்பு'),
    Bilingual('Property Dispute', 'சொத்து தகராறு'),
    Bilingual('Other', 'மற்றவை'),
  ],
  Bilingual('Police & Public Safety', 'காவல் & பொது பாதுகாப்பு'): [
    Bilingual('Law and Order', 'சட்டம் ஒழுங்கு'),
    Bilingual('Traffic Issue', 'போக்குவரத்து பிரச்சினை'),
    Bilingual('Public Safety', 'பொது பாதுகாப்பு'),
    Bilingual('Other', 'மற்றவை'),
  ],
  Bilingual('Transport', 'போக்குவரத்து'): [
    Bilingual('Bus Service', 'பேருந்து சேவை'),
    Bilingual('Road Transport', 'சாலை போக்குவரத்து'),
    Bilingual('Auto/Taxi Issue', 'ஆட்டோ/டாக்ஸி பிரச்சினை'),
    Bilingual('Other', 'மற்றவை'),
  ],
  Bilingual('Housing', 'வீட்டுவசதி'): [
    Bilingual('Housing Scheme', 'வீட்டுவசதி திட்டம்'),
    Bilingual('Slum Clearance', 'சேரி அகற்றம்'),
    Bilingual('Other', 'மற்றவை'),
  ],
  Bilingual('Pension & Welfare', 'ஓய்வூதியம் & நலன்'): [
    Bilingual('Pension Delay', 'ஓய்வூதிய தாமதம்'),
    Bilingual('Welfare Scheme', 'நலத் திட்டம்'),
    Bilingual('Ration Card', 'ரேஷன் கார்டு'),
    Bilingual('Other', 'மற்றவை'),
  ],
  Bilingual('Other', 'மற்றவை'): [
    Bilingual('Other', 'மற்றவை'),
  ],
};
