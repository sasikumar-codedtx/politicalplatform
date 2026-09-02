import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import 'policy_leader_detail_screen.dart';

// ─── Shared data models ───────────────────────────────────────────────────────

class PolicyLeaderData {
  final String role;
  final String name;
  final String imagePath;
  final String biography;
  final String? years;

  const PolicyLeaderData({
    required this.role,
    required this.name,
    required this.imagePath,
    required this.biography,
    this.years,
  });
}

const _kPlaceholderBio =
    'A visionary leader who dedicated their life to the cause of social justice '
    'and equality in Tamil Nadu. Their contributions continue to inspire millions '
    'across India and the world.\n\n'
    'Their legacy lives on through the countless lives they transformed and the '
    'movements they inspired, shaping the social and political landscape of Tamil '
    'Nadu for generations to come.';

const List<PolicyLeaderData> kPolicyLeaders = [
  PolicyLeaderData(
    role: 'Karmaveer',
    name: 'Kamarajar',
    imagePath: 'assets/images/leader_kamarajar.png',
    biography: _kPlaceholderBio,
    years: '1903–1975',
  ),
  PolicyLeaderData(
    role: 'Babasaheb',
    name: 'B. R. Ambedkar',
    imagePath: 'assets/images/leader_ambedkar.png',
    biography: _kPlaceholderBio,
    years: '1891–1956',
  ),
  PolicyLeaderData(
    role: 'Thanthai',
    name: 'Periyar',
    imagePath: 'assets/images/leader_periyar.png',
    biography: _kPlaceholderBio,
    years: '1879–1973',
  ),
  PolicyLeaderData(
    role: 'The Jhansi Rani of South India',
    name: 'Anjalai Ammal',
    imagePath: 'assets/images/leader_anjalai.png',
    years: '1890–1961',
    biography:
        'She started her political activism in 1921 with the Non-cooperation '
        'movement and later took part in the Neil Statue Satyagraha, Salt '
        'Satyagraha and Quit India Movement. Her courage was so well known that '
        'Mahatma Gandhi called her "Jhansi Rani of South India".\n\n'
        'Granddaughter of Anjalai Ammal, Mangai A, explains, "My grandmother was '
        'in jail for more than four and half years and she gave birth to her last '
        'son in the jail itself."\n\n'
        'In 1930, Anjalai Ammal was arrested for picketing shops on Godown Street '
        'in Madras. In 1931, she presided over The All India Women Congress Meet. '
        'She died on 20 February 1961.',
  ),
  PolicyLeaderData(
    role: 'Veeramangai',
    name: 'Velu Nachiyar',
    imagePath: 'assets/images/leader_velunachiyar.png',
    biography: _kPlaceholderBio,
    years: '1730–1796',
  ),
];

// TVK party leaders — used on home screen cards
const List<PolicyLeaderData> kTvkLeaders = [
  PolicyLeaderData(
    role: 'President',
    name: 'Vijay',
    imagePath: 'assets/images/leader_vijay.png',
    biography:
        'Joseph Vijay Chandrasekhar, known professionally as Vijay, is an '
        'Indian actor and politician who founded Tamilaga Vettri Kazhagam (TVK) '
        'in 2024. After a celebrated career in Tamil cinema spanning three decades, '
        'he entered politics with a vision for a modern, technology-enabled and '
        'socially just Tamil Nadu.\n\n'
        'As TVK\'s founding president, Vijay champions youth empowerment, '
        'agricultural welfare, and transparent governance. His movement draws '
        'heavily from the social justice ideology of Periyar, Kamarajar, and '
        'Ambedkar, adapting their principles for the 21st century.',
  ),
  PolicyLeaderData(
    role: 'General Secretary',
    name: 'N. Anand',
    imagePath: 'assets/images/leader_anand.png',
    biography:
        'N. Anand serves as the General Secretary of Tamilaga Vettri Kazhagam. '
        'A close associate of Vijay, Anand brings decades of grassroots political '
        'experience and organisational acumen to the party.\n\n'
        'He has been instrumental in building the party\'s district-level networks '
        'across Tamil Nadu, ensuring that TVK\'s message of inclusive development '
        'reaches every constituency.',
  ),
  PolicyLeaderData(
    role: 'Propaganda & Policy General Secretary',
    name: 'K. G. Arunraj',
    imagePath: 'assets/images/leader_arunraj.png',
    biography:
        'K. G. Arunraj is the Propaganda and Policy General Secretary of '
        'Tamilaga Vettri Kazhagam. He leads the party\'s communications strategy '
        'and policy formulation, translating TVK\'s vision into concrete, '
        'actionable governance plans.\n\n'
        'Arunraj has been a key architect of TVK\'s manifesto, with a special '
        'focus on digital inclusion, agricultural reform, and education policy.',
  ),
  PolicyLeaderData(
    role: 'Youth Wing Secretary',
    name: 'A. Aadhav Arjuna',
    imagePath: 'assets/images/leader_aadhav.png',
    biography:
        'A. Aadhav Arjuna heads the Youth Wing of Tamilaga Vettri Kazhagam, '
        'mobilising millions of young voters across Tamil Nadu. His dynamic '
        'leadership style and connect with the youth has made him one of the '
        'most recognisable faces of the TVK movement.\n\n'
        'Aadhav champions digital literacy programmes and skill development '
        'initiatives designed to prepare Tamil Nadu\'s youth for the emerging '
        'technology economy.',
  ),
];

// ─── Election candidate data ──────────────────────────────────────────────────

class ElectionCandidate {
  final String name;
  final String role;
  final String district;
  final String constituency;
  final int constituencyNo;
  final String? imagePath;

  const ElectionCandidate({
    required this.name,
    required this.role,
    required this.district,
    required this.constituency,
    required this.constituencyNo,
    this.imagePath,
  });
}

class DistrictGroup {
  final String name;
  final List<ElectionCandidate> candidates;
  const DistrictGroup({required this.name, required this.candidates});
}

const List<DistrictGroup> kDistrictGroups = [
  // ─── TIRUVALLUR ──────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Tiruvallur', candidates: [
    ElectionCandidate(name: 'S. Vijayakumar',   role: 'TVK Candidate', district: 'Tiruvallur', constituency: 'Gummidipoondi',  constituencyNo: 1),
    ElectionCandidate(name: 'M.S. Ravi',         role: 'TVK Candidate', district: 'Tiruvallur', constituency: 'Ponneri',         constituencyNo: 2),
    ElectionCandidate(name: 'M. Sathyakumar',    role: 'TVK Candidate', district: 'Tiruvallur', constituency: 'Tiruttani',       constituencyNo: 3),
    ElectionCandidate(name: 'T. Arun Kumar',     role: 'TVK Candidate', district: 'Tiruvallur', constituency: 'Tiruvallur',      constituencyNo: 4),
    ElectionCandidate(name: 'R. Prakasam',       role: 'TVK Candidate', district: 'Tiruvallur', constituency: 'Poonamalle',      constituencyNo: 5),
    ElectionCandidate(name: 'R. Ramesh Kumar',   role: 'TVK Candidate', district: 'Tiruvallur', constituency: 'Avadi',           constituencyNo: 6),
    ElectionCandidate(name: 'P. Revanth Saran',  role: 'TVK Candidate', district: 'Tiruvallur', constituency: 'Maduravoyal',     constituencyNo: 7),
    ElectionCandidate(name: 'G. Balamurugan',    role: 'TVK Candidate', district: 'Tiruvallur', constituency: 'Ambattur',        constituencyNo: 8),
    ElectionCandidate(name: 'M.L. Vijayprabhu',  role: 'TVK Candidate', district: 'Tiruvallur', constituency: 'Madhavaram',      constituencyNo: 9),
    ElectionCandidate(name: 'N. Senthil Kumar',  role: 'TVK Candidate', district: 'Tiruvallur', constituency: 'Thiruvottiyur',   constituencyNo: 10),
    ElectionCandidate(name: 'N. Marie Wilson',   role: 'TVK Candidate', district: 'Tiruvallur', constituency: 'R.K.Nagar',       constituencyNo: 11),
  ]),
  // ─── CHENNAI ─────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Chennai', candidates: [
    ElectionCandidate(name: 'C. Joseph Vijay',    role: 'TVK Candidate', district: 'Chennai', constituency: 'Perambur',           constituencyNo: 12, imagePath: 'assets/images/leader_vijay.png'),
    ElectionCandidate(name: 'V.S. Babu',          role: 'TVK Candidate', district: 'Chennai', constituency: 'Kolathur',           constituencyNo: 13),
    ElectionCandidate(name: 'A. Aadhav Arjuna',   role: 'TVK Candidate', district: 'Chennai', constituency: 'Villivakkam',        constituencyNo: 14, imagePath: 'assets/images/leader_aadhav.png'),
    ElectionCandidate(name: 'M.R. Pallavi',       role: 'TVK Candidate', district: 'Chennai', constituency: 'Thiru.Vi.Ka. Nagar', constituencyNo: 15),
    ElectionCandidate(name: 'A. Rajmohan',        role: 'TVK Candidate', district: 'Chennai', constituency: 'Egmore',             constituencyNo: 16),
    ElectionCandidate(name: 'K. Vijay Dhamu',     role: 'TVK Candidate', district: 'Chennai', constituency: 'Royapuram',          constituencyNo: 17),
    ElectionCandidate(name: 'Sinora P.S. Ashok',  role: 'TVK Candidate', district: 'Chennai', constituency: 'Harbour',            constituencyNo: 18),
    ElectionCandidate(name: 'D. Selvam',          role: 'TVK Candidate', district: 'Chennai', constituency: 'Chepauk',            constituencyNo: 19),
    ElectionCandidate(name: 'JCD. Prabhakar',     role: 'TVK Candidate', district: 'Chennai', constituency: 'Thousand Lights',    constituencyNo: 20),
    ElectionCandidate(name: 'V.K. Ramkumar',      role: 'TVK Candidate', district: 'Chennai', constituency: 'Anna Nagar',         constituencyNo: 21),
    ElectionCandidate(name: 'R. Sabarinathan',    role: 'TVK Candidate', district: 'Chennai', constituency: 'Virugambakkam',      constituencyNo: 22),
    ElectionCandidate(name: 'M. Arulprakasam',    role: 'TVK Candidate', district: 'Chennai', constituency: 'Saidapet',           constituencyNo: 23),
    ElectionCandidate(name: 'N. Anand',           role: 'TVK Candidate', district: 'Chennai', constituency: 'Thiyagaraya Nagar',  constituencyNo: 24, imagePath: 'assets/images/leader_anand.png'),
    ElectionCandidate(name: 'P. Venkataramanan',  role: 'TVK Candidate', district: 'Chennai', constituency: 'Mylapore',           constituencyNo: 25),
    ElectionCandidate(name: 'R. Kumar',           role: 'TVK Candidate', district: 'Chennai', constituency: 'Velachery',          constituencyNo: 26),
    ElectionCandidate(name: 'P. Saravanamoorthy', role: 'TVK Candidate', district: 'Chennai', constituency: 'Shozhinganallur',    constituencyNo: 27),
    ElectionCandidate(name: 'M. Harish',          role: 'TVK Candidate', district: 'Chennai', constituency: 'Alandur',            constituencyNo: 28),
  ]),
  // ─── KANCHIPURAM ─────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Kanchipuram', candidates: [
    ElectionCandidate(name: 'K. Thennarasu',      role: 'TVK Candidate', district: 'Kanchipuram', constituency: 'Sriperumbudur',  constituencyNo: 29),
    ElectionCandidate(name: 'J. Munirathinam',    role: 'TVK Candidate', district: 'Kanchipuram', constituency: 'Uthiramerur',    constituencyNo: 36),
    ElectionCandidate(name: 'R.V. Ranjith Kumar', role: 'TVK Candidate', district: 'Kanchipuram', constituency: 'Kancheepuram',   constituencyNo: 37),
  ]),
  // ─── CHENGALPATTU ────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Chengalpattu', candidates: [
    ElectionCandidate(name: 'J. Kamatchi',        role: 'TVK Candidate', district: 'Chengalpattu', constituency: 'Pallavaram',    constituencyNo: 30),
    ElectionCandidate(name: 'D. Sarathkumar',     role: 'TVK Candidate', district: 'Chengalpattu', constituency: 'Tambaram',      constituencyNo: 31),
    ElectionCandidate(name: 'S. Thiyagarajan',    role: 'TVK Candidate', district: 'Chengalpattu', constituency: 'Chengalpet',    constituencyNo: 32),
    ElectionCandidate(name: 'B. Vijayaraj',       role: 'TVK Candidate', district: 'Chengalpattu', constituency: 'Thiruporur',    constituencyNo: 33),
    ElectionCandidate(name: 'K. Mohanraja',       role: 'TVK Candidate', district: 'Chengalpattu', constituency: 'Cheyyur',       constituencyNo: 34),
    ElectionCandidate(name: 'E. Ezhil Catherine', role: 'TVK Candidate', district: 'Chengalpattu', constituency: 'Madurantakam',  constituencyNo: 35),
  ]),
  // ─── RANIPET ─────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Ranipet', candidates: [
    ElectionCandidate(name: 'V. Gandhiraj',       role: 'TVK Candidate', district: 'Ranipet', constituency: 'Arakonam',           constituencyNo: 38),
    ElectionCandidate(name: 'Dr. G. Kapil',       role: 'TVK Candidate', district: 'Ranipet', constituency: 'Sholingur',          constituencyNo: 39),
    ElectionCandidate(name: 'Dr. M. Sudhakar',    role: 'TVK Candidate', district: 'Ranipet', constituency: 'Katpadi',            constituencyNo: 40),
    ElectionCandidate(name: 'I. Tahira',          role: 'TVK Candidate', district: 'Ranipet', constituency: 'Ranipet',            constituencyNo: 41),
    ElectionCandidate(name: 'G. Vijay Mohan',     role: 'TVK Candidate', district: 'Ranipet', constituency: 'Arcot',              constituencyNo: 42),
  ]),
  // ─── VELLORE ─────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Vellore', candidates: [
    ElectionCandidate(name: 'M.M. Vinoth Kannan',   role: 'TVK Candidate', district: 'Vellore', constituency: 'Vellore',          constituencyNo: 43),
    ElectionCandidate(name: 'R. Velmurugan',        role: 'TVK Candidate', district: 'Vellore', constituency: 'Anaikattu',         constituencyNo: 44),
    ElectionCandidate(name: 'E. Thendral Kumar',    role: 'TVK Candidate', district: 'Vellore', constituency: 'K.V. Kuppam',       constituencyNo: 45),
    ElectionCandidate(name: 'K. Sindhu',            role: 'TVK Candidate', district: 'Vellore', constituency: 'Gudiyattam',        constituencyNo: 46),
    ElectionCandidate(name: 'S. Syed Bhurhanudeen', role: 'TVK Candidate', district: 'Vellore', constituency: 'Vaniyambadi',       constituencyNo: 47),
    ElectionCandidate(name: 'P. Imthiyas',          role: 'TVK Candidate', district: 'Vellore', constituency: 'Ambur',             constituencyNo: 48),
    ElectionCandidate(name: 'C. Munisamy',          role: 'TVK Candidate', district: 'Vellore', constituency: 'Jolarpettai',       constituencyNo: 49),
  ]),
  // ─── TIRUPATTUR ──────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Tirupattur', candidates: [
    ElectionCandidate(name: 'N. Tiruppathi',      role: 'TVK Candidate', district: 'Tirupattur', constituency: 'Tiruppathur',      constituencyNo: 50),
  ]),
  // ─── KRISHNAGIRI ─────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Krishnagiri', candidates: [
    ElectionCandidate(name: 'P. Kumaravel',       role: 'TVK Candidate', district: 'Krishnagiri', constituency: 'Uthangarai',      constituencyNo: 51),
    ElectionCandidate(name: 'E. Muralidharan',    role: 'TVK Candidate', district: 'Krishnagiri', constituency: 'Bargur',          constituencyNo: 52),
    ElectionCandidate(name: 'P. Mukundan',        role: 'TVK Candidate', district: 'Krishnagiri', constituency: 'Krishnagiri',     constituencyNo: 53),
    ElectionCandidate(name: 'S.R. Sampangi',      role: 'TVK Candidate', district: 'Krishnagiri', constituency: 'Veppanahalli',    constituencyNo: 54),
    ElectionCandidate(name: 'S. Vendarkarasan',   role: 'TVK Candidate', district: 'Krishnagiri', constituency: 'Hosur',           constituencyNo: 55),
    ElectionCandidate(name: 'G. Suresh',          role: 'TVK Candidate', district: 'Krishnagiri', constituency: 'Thali',           constituencyNo: 56),
  ]),
  // ─── DHARMAPURI ──────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Dharmapuri', candidates: [
    ElectionCandidate(name: 'R. Gopi',            role: 'TVK Candidate', district: 'Dharmapuri', constituency: 'Palacode',         constituencyNo: 57),
    ElectionCandidate(name: 'C. Gajenthiran',     role: 'TVK Candidate', district: 'Dharmapuri', constituency: 'Pennagaram',       constituencyNo: 58),
    ElectionCandidate(name: 'M. Sivan',           role: 'TVK Candidate', district: 'Dharmapuri', constituency: 'Dharmapuri',       constituencyNo: 59),
    ElectionCandidate(name: 'S. Thilagavathi',    role: 'TVK Candidate', district: 'Dharmapuri', constituency: 'Pappireddippatti', constituencyNo: 60),
    ElectionCandidate(name: 'K. Rakesh',          role: 'TVK Candidate', district: 'Dharmapuri', constituency: 'Harur',            constituencyNo: 61),
  ]),
  // ─── TIRUVANNAMALAI ──────────────────────────────────────────────────────────
  DistrictGroup(name: 'Tiruvannamalai', candidates: [
    ElectionCandidate(name: 'K. Bharathidhasan',  role: 'TVK Candidate', district: 'Tiruvannamalai', constituency: 'Chengam',      constituencyNo: 62),
    ElectionCandidate(name: 'A. Arul Arumugam',   role: 'TVK Candidate', district: 'Tiruvannamalai', constituency: 'Tiruvannamallai', constituencyNo: 63),
    ElectionCandidate(name: 'D. Raja',            role: 'TVK Candidate', district: 'Tiruvannamalai', constituency: 'Kilpennathur', constituencyNo: 64),
    ElectionCandidate(name: 'P. Elumalai',        role: 'TVK Candidate', district: 'Tiruvannamalai', constituency: 'Kalasapakkam', constituencyNo: 65),
    ElectionCandidate(name: 'R. Abishek',         role: 'TVK Candidate', district: 'Tiruvannamalai', constituency: 'Polur',        constituencyNo: 66),
    ElectionCandidate(name: 'V. Venkatesh Kumar', role: 'TVK Candidate', district: 'Tiruvannamalai', constituency: 'Arani',        constituencyNo: 67),
    ElectionCandidate(name: 'Dusi K. Mohan',      role: 'TVK Candidate', district: 'Tiruvannamalai', constituency: 'Cheyyar',      constituencyNo: 68),
    ElectionCandidate(name: 'M. Udayakumar',      role: 'TVK Candidate', district: 'Tiruvannamalai', constituency: 'Vandhavasi',   constituencyNo: 69),
    ElectionCandidate(name: 'B. Chandrasekaran',  role: 'TVK Candidate', district: 'Tiruvannamalai', constituency: 'Gingee',       constituencyNo: 70),
    ElectionCandidate(name: 'A. Vijay Niranjan',  role: 'TVK Candidate', district: 'Tiruvannamalai', constituency: 'Mailam',       constituencyNo: 71),
  ]),
  // ─── VILLUPURAM ──────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Villupuram', candidates: [
    ElectionCandidate(name: 'S. Sakthivel',           role: 'TVK Candidate', district: 'Villupuram', constituency: 'Tindivanam',   constituencyNo: 72),
    ElectionCandidate(name: 'G.P. Suresh',            role: 'TVK Candidate', district: 'Villupuram', constituency: 'Vanur',        constituencyNo: 73),
    ElectionCandidate(name: 'N. Mohanraj',            role: 'TVK Candidate', district: 'Villupuram', constituency: 'Villupuram',   constituencyNo: 74),
    ElectionCandidate(name: 'A. Vijay Vadivel',       role: 'TVK Candidate', district: 'Villupuram', constituency: 'Vikkiravandi', constituencyNo: 75),
    ElectionCandidate(name: 'Vijay R. Bharanibalaji', role: 'TVK Candidate', district: 'Villupuram', constituency: 'Tirukkoyilur', constituencyNo: 76),
  ]),
  // ─── KALLAKURICHI ────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Kallakurichi', candidates: [
    ElectionCandidate(name: 'M. Sudhakar',        role: 'TVK Candidate', district: 'Kallakurichi', constituency: 'Ulundurpet',     constituencyNo: 77),
    ElectionCandidate(name: 'G. Ashok Kumar',     role: 'TVK Candidate', district: 'Kallakurichi', constituency: 'Rishivandiyam',  constituencyNo: 78),
    ElectionCandidate(name: 'A. Jagadesan',       role: 'TVK Candidate', district: 'Kallakurichi', constituency: 'Sangarapuram',   constituencyNo: 79),
    ElectionCandidate(name: 'C. Arulvignesh',     role: 'TVK Candidate', district: 'Kallakurichi', constituency: 'Kallakurichi',   constituencyNo: 80),
  ]),
  // ─── SALEM ───────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Salem', candidates: [
    ElectionCandidate(name: 'V. Sujatha',                  role: 'TVK Candidate', district: 'Salem', constituency: 'Gangavalli',           constituencyNo: 81),
    ElectionCandidate(name: 'R. Selvabharathi',            role: 'TVK Candidate', district: 'Salem', constituency: 'Attur',                constituencyNo: 82),
    ElectionCandidate(name: 'J. Lakshmi',                  role: 'TVK Candidate', district: 'Salem', constituency: 'Yercaud',              constituencyNo: 83),
    ElectionCandidate(name: 'R.V. Adhiyamaan',             role: 'TVK Candidate', district: 'Salem', constituency: 'Omalur',               constituencyNo: 84),
    ElectionCandidate(name: 'K. Selvam',                   role: 'TVK Candidate', district: 'Salem', constituency: 'Mettur',               constituencyNo: 85),
    ElectionCandidate(name: 'K. Premkumar',                role: 'TVK Candidate', district: 'Salem', constituency: 'Edappadi',             constituencyNo: 86),
    ElectionCandidate(name: 'K. Senthil Kumar',            role: 'TVK Candidate', district: 'Salem', constituency: 'Sangagiri',            constituencyNo: 87),
    ElectionCandidate(name: 'S. Lakshmanan',               role: 'TVK Candidate', district: 'Salem', constituency: 'Salem West',           constituencyNo: 88),
    ElectionCandidate(name: 'K. Sivakumar',                role: 'TVK Candidate', district: 'Salem', constituency: 'Salem North',          constituencyNo: 89),
    ElectionCandidate(name: 'A. Vijay Tamilan Parthipan',  role: 'TVK Candidate', district: 'Salem', constituency: 'Salem South',          constituencyNo: 90),
    ElectionCandidate(name: 'M.S. Palanivel',              role: 'TVK Candidate', district: 'Salem', constituency: 'Veerapandi',           constituencyNo: 91),
  ]),
  // ─── NAMAKKAL ────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Namakkal', candidates: [
    ElectionCandidate(name: 'D. Logesh Tamilselvan', role: 'TVK Candidate', district: 'Namakkal', constituency: 'Rasipuram',       constituencyNo: 92),
    ElectionCandidate(name: 'P. Chandrasekar',       role: 'TVK Candidate', district: 'Namakkal', constituency: 'Senthamangalam',  constituencyNo: 93),
    ElectionCandidate(name: 'C.S. Dileep',           role: 'TVK Candidate', district: 'Namakkal', constituency: 'Namakkal',        constituencyNo: 94),
    ElectionCandidate(name: 'A. Nandakumar',         role: 'TVK Candidate', district: 'Namakkal', constituency: 'Paramathi Velur', constituencyNo: 95),
    ElectionCandidate(name: 'Dr. K.G. Arunraj',      role: 'TVK Candidate', district: 'Namakkal', constituency: 'Tiruchengode',    constituencyNo: 96, imagePath: 'assets/images/leader_arunraj.png'),
  ]),
  // ─── ERODE ───────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Erode', candidates: [
    ElectionCandidate(name: 'C. Vijayalakshmi',   role: 'TVK Candidate', district: 'Erode', constituency: 'Kumarapalayam',        constituencyNo: 97),
    ElectionCandidate(name: 'M. Vijay Balaji',    role: 'TVK Candidate', district: 'Erode', constituency: 'Erode East',           constituencyNo: 98),
    ElectionCandidate(name: 'K.K. Anand Mohan',   role: 'TVK Candidate', district: 'Erode', constituency: 'Erode West',           constituencyNo: 99),
    ElectionCandidate(name: 'D. Sanmugan',        role: 'TVK Candidate', district: 'Erode', constituency: 'Modakkurichi',         constituencyNo: 100),
    ElectionCandidate(name: 'S. Gowrichitra',     role: 'TVK Candidate', district: 'Erode', constituency: 'Dharapuram',           constituencyNo: 101),
    ElectionCandidate(name: 'P. Mani',            role: 'TVK Candidate', district: 'Erode', constituency: 'Kangayam',             constituencyNo: 102),
    ElectionCandidate(name: 'V.P. Arunachalam',   role: 'TVK Candidate', district: 'Erode', constituency: 'Perundurai',           constituencyNo: 103),
    ElectionCandidate(name: 'M.P. Balakrishnan',  role: 'TVK Candidate', district: 'Erode', constituency: 'Bhavani',              constituencyNo: 104),
    ElectionCandidate(name: 'M. Vijay Venkatesh', role: 'TVK Candidate', district: 'Erode', constituency: 'Anthiyur',             constituencyNo: 105),
    ElectionCandidate(name: 'K.A. Sengottaiyan',  role: 'TVK Candidate', district: 'Erode', constituency: 'Gobichettipalayam',    constituencyNo: 106),
    ElectionCandidate(name: 'V.P. Tamilselvi',    role: 'TVK Candidate', district: 'Erode', constituency: 'Bhavanisagar',         constituencyNo: 107),
  ]),
  // ─── NILGIRIS ────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Nilgiris', candidates: [
    ElectionCandidate(name: 'R. Ibrahim',               role: 'TVK Candidate', district: 'Nilgiris', constituency: 'Udhagamandalam', constituencyNo: 108),
    ElectionCandidate(name: 'A. Deepak Sai Kishore',    role: 'TVK Candidate', district: 'Nilgiris', constituency: 'Gudalur',         constituencyNo: 109),
    ElectionCandidate(name: 'C. Thangaraju',            role: 'TVK Candidate', district: 'Nilgiris', constituency: 'Coonoor',          constituencyNo: 110),
    ElectionCandidate(name: 'N. Sunil Anand',           role: 'TVK Candidate', district: 'Nilgiris', constituency: 'Mettupalayam',     constituencyNo: 111),
  ]),
  // ─── TIRUPPUR ────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Tiruppur', candidates: [
    ElectionCandidate(name: 'V. Sathiyabama',     role: 'TVK Candidate', district: 'Tiruppur', constituency: 'Tiruppur North',    constituencyNo: 112),
    ElectionCandidate(name: 'S. Balamurugan',     role: 'TVK Candidate', district: 'Tiruppur', constituency: 'Tiruppur South',    constituencyNo: 113),
    ElectionCandidate(name: 'K. Ramkumar',        role: 'TVK Candidate', district: 'Tiruppur', constituency: 'Palladam',          constituencyNo: 114),
    ElectionCandidate(name: 'S. Kamali',          role: 'TVK Candidate', district: 'Tiruppur', constituency: 'Avanashi',          constituencyNo: 115),
    ElectionCandidate(name: 'G.K. Sankar',        role: 'TVK Candidate', district: 'Tiruppur', constituency: 'Udumalaipettai',    constituencyNo: 116),
    ElectionCandidate(name: 'R. Thirumalai',      role: 'TVK Candidate', district: 'Tiruppur', constituency: 'Madathukulam',      constituencyNo: 117),
  ]),
  // ─── COIMBATORE ──────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Coimbatore', candidates: [
    ElectionCandidate(name: 'N.M. Sukumar',          role: 'TVK Candidate', district: 'Coimbatore', constituency: 'Sulur',            constituencyNo: 118),
    ElectionCandidate(name: 'R.D. Kanimozhi',        role: 'TVK Candidate', district: 'Coimbatore', constituency: 'Kavundampalayam',  constituencyNo: 119),
    ElectionCandidate(name: 'V. Sampathkumar',       role: 'TVK Candidate', district: 'Coimbatore', constituency: 'Coimbatore North', constituencyNo: 120),
    ElectionCandidate(name: 'R. Sathish Raju',       role: 'TVK Candidate', district: 'Coimbatore', constituency: 'Thondamuthur',     constituencyNo: 121),
    ElectionCandidate(name: 'V. Senthilkumar',       role: 'TVK Candidate', district: 'Coimbatore', constituency: 'Coimbatore South', constituencyNo: 122),
    ElectionCandidate(name: 'K.S. Sri Giri Prasath', role: 'TVK Candidate', district: 'Coimbatore', constituency: 'Singanallur',      constituencyNo: 123),
    ElectionCandidate(name: 'K. Vignesh',            role: 'TVK Candidate', district: 'Coimbatore', constituency: 'Kinathukadavu',    constituencyNo: 124),
    ElectionCandidate(name: 'G. Ramanathan',         role: 'TVK Candidate', district: 'Coimbatore', constituency: 'Pollachi',         constituencyNo: 125),
    ElectionCandidate(name: 'A. Sridharan',          role: 'TVK Candidate', district: 'Coimbatore', constituency: 'Valparai',         constituencyNo: 126),
  ]),
  // ─── DINDIGUL ────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Dindigul', candidates: [
    ElectionCandidate(name: 'M. Praveen Kumar',   role: 'TVK Candidate', district: 'Dindigul', constituency: 'Palani',            constituencyNo: 127),
    ElectionCandidate(name: 'S. Mohan',           role: 'TVK Candidate', district: 'Dindigul', constituency: 'Ottanchathiram',    constituencyNo: 128),
    ElectionCandidate(name: 'N. Kalaiselvi',      role: 'TVK Candidate', district: 'Dindigul', constituency: 'Athur',             constituencyNo: 129),
    ElectionCandidate(name: 'R. Ayyanar',         role: 'TVK Candidate', district: 'Dindigul', constituency: 'Nilakkottai',       constituencyNo: 130),
    ElectionCandidate(name: 'L.N. Ramesh',        role: 'TVK Candidate', district: 'Dindigul', constituency: 'Natham',            constituencyNo: 131),
    ElectionCandidate(name: 'G. Nazeer Raja',     role: 'TVK Candidate', district: 'Dindigul', constituency: 'Dindigul',          constituencyNo: 132),
    ElectionCandidate(name: 'N. Naka Jothi',      role: 'TVK Candidate', district: 'Dindigul', constituency: 'Vedasandur',        constituencyNo: 133),
    ElectionCandidate(name: 'P. Karthikeyan',     role: 'TVK Candidate', district: 'Dindigul', constituency: 'Aravakurichi',      constituencyNo: 134),
  ]),
  // ─── KARUR ───────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Karur', candidates: [
    ElectionCandidate(name: 'V.P. Mathiyalagan',  role: 'TVK Candidate', district: 'Karur', constituency: 'Karur',                constituencyNo: 135),
    ElectionCandidate(name: 'M. Sathya',          role: 'TVK Candidate', district: 'Karur', constituency: 'Krishnarayapuram',     constituencyNo: 136),
    ElectionCandidate(name: 'G. Balasubramani',   role: 'TVK Candidate', district: 'Karur', constituency: 'Kulithalai',           constituencyNo: 137),
  ]),
  // ─── TIRUCHIRAPPALLI ─────────────────────────────────────────────────────────
  DistrictGroup(name: 'Tiruchirappalli', candidates: [
    ElectionCandidate(name: 'R. Kathiravan',      role: 'TVK Candidate', district: 'Tiruchirappalli', constituency: 'Manapparai',   constituencyNo: 138),
    ElectionCandidate(name: 'S. Ramesh',          role: 'TVK Candidate', district: 'Tiruchirappalli', constituency: 'Srirangam',    constituencyNo: 139),
    ElectionCandidate(name: 'G. Ramamoorthy',     role: 'TVK Candidate', district: 'Tiruchirappalli', constituency: 'Trichy West',  constituencyNo: 140),
    ElectionCandidate(name: 'C. Joseph Vijay',    role: 'TVK Candidate', district: 'Tiruchirappalli', constituency: 'Tiruchirappalli East', constituencyNo: 141),
    ElectionCandidate(name: 'Navalpattu S. Viji', role: 'TVK Candidate', district: 'Tiruchirappalli', constituency: 'Thiruverumbur', constituencyNo: 142),
    ElectionCandidate(name: 'Ku. Pa. Krishnan',   role: 'TVK Candidate', district: 'Tiruchirappalli', constituency: 'Lalgudi',      constituencyNo: 143),
    ElectionCandidate(name: 'V. Saravanan',       role: 'TVK Candidate', district: 'Tiruchirappalli', constituency: 'Manachanallur', constituencyNo: 144),
    ElectionCandidate(name: 'M. Vignesh',         role: 'TVK Candidate', district: 'Tiruchirappalli', constituency: 'Musiri',       constituencyNo: 145),
    ElectionCandidate(name: 'M. Ravisankar',      role: 'TVK Candidate', district: 'Tiruchirappalli', constituency: 'Thuraiyur',    constituencyNo: 146),
  ]),
  // ─── PERAMBALUR ──────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Perambalur', candidates: [
    ElectionCandidate(name: 'K. Sivakumar',       role: 'TVK Candidate', district: 'Perambalur', constituency: 'Perambalur',       constituencyNo: 147),
    ElectionCandidate(name: 'M. Revathy',         role: 'TVK Candidate', district: 'Perambalur', constituency: 'Kunnam',           constituencyNo: 148),
  ]),
  // ─── ARIYALUR ────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Ariyalur', candidates: [
    ElectionCandidate(name: 'M. Sivakumar',           role: 'TVK Candidate', district: 'Ariyalur', constituency: 'Ariyalur',       constituencyNo: 149),
    ElectionCandidate(name: 'Kavitha G. Rajendhiran', role: 'TVK Candidate', district: 'Ariyalur', constituency: 'Jayankondam',    constituencyNo: 150),
  ]),
  // ─── CUDDALORE ───────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Cuddalore', candidates: [
    ElectionCandidate(name: 'A. Rajasekar',       role: 'TVK Candidate', district: 'Cuddalore', constituency: 'Thittakudi',       constituencyNo: 151),
    ElectionCandidate(name: 'S. Vijay',           role: 'TVK Candidate', district: 'Cuddalore', constituency: 'Vridhachalam',     constituencyNo: 152),
    ElectionCandidate(name: 'K. Anand',           role: 'TVK Candidate', district: 'Cuddalore', constituency: 'Neyveli',          constituencyNo: 153),
    ElectionCandidate(name: 'M. Manikandan',      role: 'TVK Candidate', district: 'Cuddalore', constituency: 'Panruti',          constituencyNo: 154),
    ElectionCandidate(name: 'B. Rajkumar',        role: 'TVK Candidate', district: 'Cuddalore', constituency: 'Cuddalore',        constituencyNo: 155),
    ElectionCandidate(name: 'D. Rajkumar',        role: 'TVK Candidate', district: 'Cuddalore', constituency: 'Kurinjipadi',      constituencyNo: 156),
    ElectionCandidate(name: 'T. Mahalingam',      role: 'TVK Candidate', district: 'Cuddalore', constituency: 'Bhuvanagiri',      constituencyNo: 157),
    ElectionCandidate(name: 'A. Nedunchezhiyan',  role: 'TVK Candidate', district: 'Cuddalore', constituency: 'Chidambaram',      constituencyNo: 158),
    ElectionCandidate(name: 'S. Seenuvasan',      role: 'TVK Candidate', district: 'Cuddalore', constituency: 'Kattumannarkovil', constituencyNo: 159),
    ElectionCandidate(name: 'C.S. Gopinath',      role: 'TVK Candidate', district: 'Cuddalore', constituency: 'Sirkazhi',         constituencyNo: 160),
  ]),
  // ─── MAYILADUTHURAI ──────────────────────────────────────────────────────────
  DistrictGroup(name: 'Mayiladuthurai', candidates: [
    ElectionCandidate(name: 'S.S. Haroon Rasheed', role: 'TVK Candidate', district: 'Mayiladuthurai', constituency: 'Mayiladuthurai', constituencyNo: 161),
    ElectionCandidate(name: 'J. Vijayabalan',      role: 'TVK Candidate', district: 'Mayiladuthurai', constituency: 'Poompuhar',      constituencyNo: 162),
  ]),
  // ─── NAGAPATTINAM ────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Nagapattinam', candidates: [
    ElectionCandidate(name: 'M. Sukumar',          role: 'TVK Candidate', district: 'Nagapattinam', constituency: 'Nagapattinam',   constituencyNo: 163),
    ElectionCandidate(name: 'TAP. Senthilpandian', role: 'TVK Candidate', district: 'Nagapattinam', constituency: 'Kilvelur',       constituencyNo: 164),
    ElectionCandidate(name: 'A. Kingsly Gerald',   role: 'TVK Candidate', district: 'Nagapattinam', constituency: 'Vedaranyam',     constituencyNo: 165),
  ]),
  // ─── TIRUVARUR ───────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Tiruvarur', candidates: [
    ElectionCandidate(name: 'S. Pandiyan',        role: 'TVK Candidate', district: 'Tiruvarur', constituency: 'Tiruthuraipoondi',  constituencyNo: 166),
    ElectionCandidate(name: 'U. Rajarajan',       role: 'TVK Candidate', district: 'Tiruvarur', constituency: 'Mannargudi',        constituencyNo: 167),
    ElectionCandidate(name: 'V. Veeramani',       role: 'TVK Candidate', district: 'Tiruvarur', constituency: 'Tiruvarur',         constituencyNo: 168),
  ]),
  // ─── THANJAVUR ───────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Thanjavur', candidates: [
    ElectionCandidate(name: 'S. Prabhakaran',     role: 'TVK Candidate', district: 'Thanjavur', constituency: 'Nannilam',          constituencyNo: 169),
    ElectionCandidate(name: 'S. Priyadharshan',   role: 'TVK Candidate', district: 'Thanjavur', constituency: 'Thiruvidaimaruthur',constituencyNo: 170),
    ElectionCandidate(name: 'R. Vinoth',          role: 'TVK Candidate', district: 'Thanjavur', constituency: 'Kumbakonam',        constituencyNo: 171),
    ElectionCandidate(name: 'U. Azarudeen',       role: 'TVK Candidate', district: 'Thanjavur', constituency: 'Papanasam',         constituencyNo: 172),
    ElectionCandidate(name: 'M. Manikandan',      role: 'TVK Candidate', district: 'Thanjavur', constituency: 'Tiruvaiyaru',       constituencyNo: 173),
    ElectionCandidate(name: 'R. Vijay Saravanan', role: 'TVK Candidate', district: 'Thanjavur', constituency: 'Thanjavur',         constituencyNo: 174),
    ElectionCandidate(name: 'K. Arvindh',         role: 'TVK Candidate', district: 'Thanjavur', constituency: 'Orathanadu',        constituencyNo: 175),
    ElectionCandidate(name: 'C. Mathan',          role: 'TVK Candidate', district: 'Thanjavur', constituency: 'Pattukkottai',      constituencyNo: 176),
    ElectionCandidate(name: 'D. Chandrakandeepan',role: 'TVK Candidate', district: 'Thanjavur', constituency: 'Peravurani',        constituencyNo: 177),
  ]),
  // ─── PUDUKOTTAI ──────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Pudukottai', candidates: [
    ElectionCandidate(name: 'N. Subramanian',     role: 'TVK Candidate', district: 'Pudukottai', constituency: 'Kandharvakottai',  constituencyNo: 178),
    ElectionCandidate(name: 'P. Murugesan',       role: 'TVK Candidate', district: 'Pudukottai', constituency: 'Viralimalai',      constituencyNo: 179),
    ElectionCandidate(name: 'K.M. Sheriff',       role: 'TVK Candidate', district: 'Pudukottai', constituency: 'Pudukottai',       constituencyNo: 180),
    ElectionCandidate(name: 'C. Chinthamani',     role: 'TVK Candidate', district: 'Pudukottai', constituency: 'Thirumayam',       constituencyNo: 181),
    ElectionCandidate(name: 'Durai Kandasamy',    role: 'TVK Candidate', district: 'Pudukottai', constituency: 'Alangudi',         constituencyNo: 182),
    ElectionCandidate(name: 'J. Mohammed Farvas', role: 'TVK Candidate', district: 'Pudukottai', constituency: 'Aranthangi',       constituencyNo: 183),
  ]),
  // ─── SIVAGANGA ───────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Sivaganga', candidates: [
    ElectionCandidate(name: 'T.K. Prabhu',          role: 'TVK Candidate', district: 'Sivaganga', constituency: 'Karaikkudi',      constituencyNo: 184),
    ElectionCandidate(name: 'Seenivasa Sethupathy', role: 'TVK Candidate', district: 'Sivaganga', constituency: 'Tiruppathur',     constituencyNo: 185),
    ElectionCandidate(name: 'A. Kulanthai Rani',    role: 'TVK Candidate', district: 'Sivaganga', constituency: 'Sivagangai',      constituencyNo: 186),
    ElectionCandidate(name: 'D. Elangovan',         role: 'TVK Candidate', district: 'Sivaganga', constituency: 'Manamadurai',     constituencyNo: 187),
    ElectionCandidate(name: 'A. Maduraiveeran',     role: 'TVK Candidate', district: 'Sivaganga', constituency: 'Melur',           constituencyNo: 188),
  ]),
  // ─── MADURAI ─────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Madurai', candidates: [
    ElectionCandidate(name: 'S. Karthikeyan',     role: 'TVK Candidate', district: 'Madurai', constituency: 'Madurai East',        constituencyNo: 189),
    ElectionCandidate(name: 'M.V. Karuppaiya',    role: 'TVK Candidate', district: 'Madurai', constituency: 'Sholavandan',         constituencyNo: 190),
    ElectionCandidate(name: 'A. Kallanai',        role: 'TVK Candidate', district: 'Madurai', constituency: 'Madurai North',       constituencyNo: 191),
    ElectionCandidate(name: 'M.M. Gopisan',       role: 'TVK Candidate', district: 'Madurai', constituency: 'Madurai South',       constituencyNo: 192),
    ElectionCandidate(name: 'VMS. Mustafa',       role: 'TVK Candidate', district: 'Madurai', constituency: 'Madurai Central',     constituencyNo: 193),
    ElectionCandidate(name: 'S.R. Thangapandi',   role: 'TVK Candidate', district: 'Madurai', constituency: 'Madurai West',        constituencyNo: 194),
    ElectionCandidate(name: 'CTR Nirmal Kumar',   role: 'TVK Candidate', district: 'Madurai', constituency: 'Thiruparangundram',   constituencyNo: 195),
    ElectionCandidate(name: 'N. Sathishkumar',    role: 'TVK Candidate', district: 'Madurai', constituency: 'Thirumangalam',       constituencyNo: 196),
    ElectionCandidate(name: 'M. Vijay',           role: 'TVK Candidate', district: 'Madurai', constituency: 'Usilampatti',         constituencyNo: 197),
    ElectionCandidate(name: 'V. Pandi',           role: 'TVK Candidate', district: 'Madurai', constituency: 'Andipatti',           constituencyNo: 198),
  ]),
  // ─── THENI ───────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Theni', candidates: [
    ElectionCandidate(name: 'G. Sabari Iyngaran',     role: 'TVK Candidate', district: 'Theni', constituency: 'Periyakulam',       constituencyNo: 199),
    ElectionCandidate(name: 'S. Prakash',             role: 'TVK Candidate', district: 'Theni', constituency: 'Bodinayakanur',     constituencyNo: 200),
    ElectionCandidate(name: 'P.L.A. Jeganath Mishra', role: 'TVK Candidate', district: 'Theni', constituency: 'Cumbum',            constituencyNo: 201),
  ]),
  // ─── VIRUDHUNAGAR ────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Virudhunagar', candidates: [
    ElectionCandidate(name: 'K. Jagadeshwari',    role: 'TVK Candidate', district: 'Virudhunagar', constituency: 'Rajapalayam',    constituencyNo: 202),
    ElectionCandidate(name: 'A. Karthik',         role: 'TVK Candidate', district: 'Virudhunagar', constituency: 'Srivilliputhur', constituencyNo: 203),
    ElectionCandidate(name: 'M. Ajith',           role: 'TVK Candidate', district: 'Virudhunagar', constituency: 'Satthur',        constituencyNo: 204),
    ElectionCandidate(name: 'S. Keerthana',       role: 'TVK Candidate', district: 'Virudhunagar', constituency: 'Sivakasi',       constituencyNo: 205),
    ElectionCandidate(name: 'S.P. Selvam',        role: 'TVK Candidate', district: 'Virudhunagar', constituency: 'Virudhunagar',   constituencyNo: 206),
    ElectionCandidate(name: 'K. Karthik Kumar',   role: 'TVK Candidate', district: 'Virudhunagar', constituency: 'Aruppukkottai',  constituencyNo: 207),
    ElectionCandidate(name: 'S. Samaiyan',        role: 'TVK Candidate', district: 'Virudhunagar', constituency: 'Tiruchuzhi',     constituencyNo: 208),
  ]),
  // ─── RAMANATHAPURAM ──────────────────────────────────────────────────────────
  DistrictGroup(name: 'Ramanathapuram', candidates: [
    ElectionCandidate(name: 'G. Gopirajan',           role: 'TVK Candidate', district: 'Ramanathapuram', constituency: 'Paramakkudi',   constituencyNo: 209),
    ElectionCandidate(name: 'V.K. Rajeev',            role: 'TVK Candidate', district: 'Ramanathapuram', constituency: 'Tiruvadanai',   constituencyNo: 210),
    ElectionCandidate(name: 'EA. Shahul Hameed',      role: 'TVK Candidate', district: 'Ramanathapuram', constituency: 'Ramanathapuram', constituencyNo: 211),
    ElectionCandidate(name: 'B. Malarvizhi Jayabala', role: 'TVK Candidate', district: 'Ramanathapuram', constituency: 'Muthugulathur',  constituencyNo: 212),
  ]),
  // ─── THOOTHUKUDI ─────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Thoothukudi', candidates: [
    ElectionCandidate(name: 'P. Kasiram',         role: 'TVK Candidate', district: 'Thoothukudi', constituency: 'Vilathikulam',    constituencyNo: 213),
    ElectionCandidate(name: 'A. Srinath',         role: 'TVK Candidate', district: 'Thoothukudi', constituency: 'Tuticorin',       constituencyNo: 214),
    ElectionCandidate(name: 'J. Murugan',         role: 'TVK Candidate', district: 'Thoothukudi', constituency: 'Tiruchendur',     constituencyNo: 215),
    ElectionCandidate(name: 'G. Saravanan',       role: 'TVK Candidate', district: 'Thoothukudi', constituency: 'Tiruvaikundam',   constituencyNo: 216),
    ElectionCandidate(name: 'P. Mathan Raja',     role: 'TVK Candidate', district: 'Thoothukudi', constituency: 'Ottapidaram',     constituencyNo: 217),
    ElectionCandidate(name: 'S. Balasubramanian', role: 'TVK Candidate', district: 'Thoothukudi', constituency: 'Kovilpatti',      constituencyNo: 218),
  ]),
  // ─── TENKASI ─────────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Tenkasi', candidates: [
    ElectionCandidate(name: 'C. Ramarajan',           role: 'TVK Candidate', district: 'Tenkasi', constituency: 'Sankarankovil',   constituencyNo: 219),
    ElectionCandidate(name: 'R. Amutharani',          role: 'TVK Candidate', district: 'Tenkasi', constituency: 'Vasudevanallur',  constituencyNo: 220),
    ElectionCandidate(name: 'R.K. Abdul Jaleel',      role: 'TVK Candidate', district: 'Tenkasi', constituency: 'Kadayanallur',    constituencyNo: 221),
    ElectionCandidate(name: 'A. Rajaprakash',         role: 'TVK Candidate', district: 'Tenkasi', constituency: 'Tenkasi',         constituencyNo: 222),
    ElectionCandidate(name: 'V. Vibin Chakkaravarthy', role: 'TVK Candidate', district: 'Tenkasi', constituency: 'Alangulam',      constituencyNo: 223),
  ]),
  // ─── TIRUNELVELI ─────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Tirunelveli', candidates: [
    ElectionCandidate(name: 'R.S. Murugan',          role: 'TVK Candidate', district: 'Tirunelveli', constituency: 'Tirunelveli',  constituencyNo: 224),
    ElectionCandidate(name: 'S. Rajagopal',          role: 'TVK Candidate', district: 'Tirunelveli', constituency: 'Ambasamudram', constituencyNo: 225),
    ElectionCandidate(name: 'S. Maria John',         role: 'TVK Candidate', district: 'Tirunelveli', constituency: 'Palayamkottai', constituencyNo: 226),
    ElectionCandidate(name: 'V. Narayanan',          role: 'TVK Candidate', district: 'Tirunelveli', constituency: 'Nanguneri',    constituencyNo: 227),
    ElectionCandidate(name: 'K. Sathish Christopher', role: 'TVK Candidate', district: 'Tirunelveli', constituency: 'Radhapuram',  constituencyNo: 228),
  ]),
  // ─── KANYAKUMARI ─────────────────────────────────────────────────────────────
  DistrictGroup(name: 'Kanyakumari', candidates: [
    ElectionCandidate(name: 'S.R. Madhavan',      role: 'TVK Candidate', district: 'Kanyakumari', constituency: 'Kanyakumari',     constituencyNo: 229),
    ElectionCandidate(name: 'G. Bervin Kings',    role: 'TVK Candidate', district: 'Kanyakumari', constituency: 'Nagercoil',       constituencyNo: 230),
    ElectionCandidate(name: 'Prem Alex Lawrence', role: 'TVK Candidate', district: 'Kanyakumari', constituency: 'Colachel',        constituencyNo: 231),
    ElectionCandidate(name: 'S. Krishnakumar',    role: 'TVK Candidate', district: 'Kanyakumari', constituency: 'Padmanabhapuram', constituencyNo: 232),
    ElectionCandidate(name: 'K. Michael Kumar',   role: 'TVK Candidate', district: 'Kanyakumari', constituency: 'Vilavangode',     constituencyNo: 233),
    ElectionCandidate(name: 'S. Sabin',           role: 'TVK Candidate', district: 'Kanyakumari', constituency: 'Killiyur',        constituencyNo: 234),
  ]),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class TvkFamilyScreen extends StatefulWidget {
  const TvkFamilyScreen({super.key});

  @override
  State<TvkFamilyScreen> createState() => _TvkFamilyScreenState();
}

class _TvkFamilyScreenState extends State<TvkFamilyScreen> {
  String _searchQuery = '';
  String _activeDistrict = 'All';

  List<DistrictGroup> get _filteredGroups {
    var groups = kDistrictGroups;

    // District filter
    if (_activeDistrict != 'All') {
      groups = groups.where((g) => g.name == _activeDistrict).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      groups = groups
          .map((g) => DistrictGroup(
                name: g.name,
                candidates: g.candidates
                    .where((c) =>
                        c.name.toLowerCase().contains(q) ||
                        c.constituency.toLowerCase().contains(q) ||
                        c.role.toLowerCase().contains(q))
                    .toList(),
              ))
          .where((g) => g.candidates.isNotEmpty)
          .toList();
    }
    return groups;
  }

  int get _totalCandidates =>
      _filteredGroups.fold(0, (sum, g) => sum + g.candidates.length);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final districts = ['All', ...kDistrictGroups.map((g) => g.name)];
    final filtered = _filteredGroups;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        // The candidate list scrolls on its own; keep the fixed hero + search
        // header from overflowing when the keyboard opens on short screens
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            // ── Hero banner ─────────────────────────────────────────────────
            _HeroBanner(topPad: topPad, totalCount: _totalCandidates),

            // ── Search bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(color: Color(0x18000000), blurRadius: 4),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: t('policy_leaders.search_hint'),
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // ── District filter chips ────────────────────────────────────────
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: districts.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final d = districts[i];
                  final isActive = d == _activeDistrict;
                  return GestureDetector(
                    onTap: () => setState(() => _activeDistrict = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFE40101)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFE40101)
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        d,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ── Candidate list grouped by district ──────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        t('policy_leaders.no_candidates_found'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          _DistrictSection(group: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final double topPad;
  final int totalCount;
  const _HeroBanner({required this.topPad, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: topPad + 160,
      child: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/leader_group_banner.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D0A0A), Color(0xFF6B1212)],
                  ),
                ),
              ),
            ),
          ),
          // Top vignette
          Positioned(
            top: 0, left: 0, right: 0, height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Colors.transparent],
                ),
              ),
            ),
          ),
          // Bottom vignette
          Positioned(
            bottom: 0, left: 0, right: 0, height: 130,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: topPad + 14,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          // Title + badge
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TVK',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 36,
                          color: const Color(0xFFE40101),
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        t('policy_leaders.family'),
                        style: GoogleFonts.bebasNeue(
                          fontSize: 36,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('policy_leaders.know_your_leaders_subtitle'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Count badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE40101).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalCount',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 28,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        t('policy_leaders.members'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── District section (header + candidate cards) ──────────────────────────────

class _DistrictSection extends StatelessWidget {
  final DistrictGroup group;
  const _DistrictSection({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // District header
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFE40101),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              group.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE40101).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${group.candidates.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE40101),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Cards
        ...group.candidates.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CandidateCard(candidate: c),
            )),
      ],
    );
  }
}

// ─── Candidate card ───────────────────────────────────────────────────────────

class _CandidateCard extends StatelessWidget {
  final ElectionCandidate candidate;
  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar — photo or initials
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: 56,
              height: 56,
              child: candidate.imagePath != null
                  ? Image.asset(
                      candidate.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          _InitialsAvatar(name: candidate.name),
                    )
                  : _InitialsAvatar(name: candidate.name),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  candidate.role,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                // Constituency pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '${candidate.constituencyNo}. ${candidate.constituency}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Arrow
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 22),
        ],
      ),
    );
  }
}

// ─── Initials avatar ──────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  // Deterministic color from name
  Color get _bgColor {
    final colors = [
      const Color(0xFF9F1D1F),
      const Color(0xFF1A5276),
      const Color(0xFF1E8449),
      const Color(0xFF7D3C98),
      const Color(0xFFB9770E),
      const Color(0xFF2E4053),
    ];
    return colors[name.codeUnits.first % colors.length];
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Policy Leaders Screen (Figma 1328:4500) ──────────────────────────────────
// Historical social-justice leaders list — separate from TVK Family

class PolicyLeadersScreen extends StatelessWidget {
  const PolicyLeadersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            // ── Hero banner ────────────────────────────────────────────────
            _PolicyHeroBanner(topPad: topPad),

            // ── Leader cards list ──────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: kPolicyLeaders.length,
                separatorBuilder: (context, i) => const SizedBox(height: 18),
                itemBuilder: (context, i) => _PolicyLeaderCard(
                  leader: kPolicyLeaders[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PolicyLeaderDetailScreen(
                          leader: kPolicyLeaders[i]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero banner ──────────────────────────────────────────────────────────────

class _PolicyHeroBanner extends StatelessWidget {
  final double topPad;
  const _PolicyHeroBanner({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: topPad + 162,
      child: Stack(
        children: [
          // Group photo background
          Positioned.fill(
            child: Image.asset(
              'assets/images/leader_group_banner.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, e, s) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D0A0A), Color(0xFF6B1212)],
                  ),
                ),
              ),
            ),
          ),

          // Dark gradient — bottom (text readability)
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: topPad + 162,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.838, 1.0],
                  colors: [
                    Colors.black,
                    Color(0xCC000000),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: topPad + 14,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
            ),
          ),

          // Title
          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t('policy_leaders.our_policy_leaders'),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 34,
                    color: const Color(0xFFE40101),
                    letterSpacing: 0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t('policy_leaders.know_our_policy_leaders'),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Policy leader card (Figma exact) ────────────────────────────────────────

class _PolicyLeaderCard extends StatelessWidget {
  final PolicyLeaderData leader;
  final VoidCallback onTap;
  const _PolicyLeaderCard({required this.leader, required this.onTap});

  // Portrait position per leader — right-anchored so the image stays inside
  // the card on any screen width (Figma coords assumed a ~372px card)
  _PortraitSpec get _portrait {
    switch (leader.name) {
      case 'Kamarajar':
        return const _PortraitSpec(right: 15, top: 12, width: 97, height: 101);
      case 'B. R. Ambedkar':
        return const _PortraitSpec(right: 26, top: 0, width: 118, height: 113);
      case 'Periyar':
        return const _PortraitSpec(right: 0, top: 8, width: 149, height: 112);
      case 'Anjalai Ammal':
        return const _PortraitSpec(right: 18, top: 6, width: 134, height: 107);
      case 'Velu Nachiyar':
        return const _PortraitSpec(right: 25, top: 16, width: 114, height: 97);
      default:
        return const _PortraitSpec(right: 22, top: 6, width: 110, height: 107);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _portrait;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 113,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C000000),
              blurRadius: 17,
              offset: Offset.zero,
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Red radial glow behind portrait — right side
            Positioned(
              right: -20, top: (113 - 96) / 2,
              width: 130, height: 96,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.65,
                    colors: [Color(0x44E89090), Color(0x00E89090)],
                  ),
                ),
              ),
            ),

            // Leader portrait — per-leader sizing, right side
            Positioned(
              right: p.right, top: p.top,
              width: p.width, height: p.height,
              child: Image.asset(
                leader.imagePath,
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                errorBuilder: (_, e, s) => const SizedBox.shrink(),
              ),
            ),

            // Role + Name — left
            Positioned(
              left: 14, top: 16,
              right: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leader.role,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    leader.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow ↗ — bottom-left
            const Positioned(
              left: 14, bottom: 12,
              child: Icon(Icons.arrow_outward_rounded,
                  color: Color(0xFFE40101), size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortraitSpec {
  final double right;
  final double top;
  final double width;
  final double height;
  const _PortraitSpec({
    required this.right,
    required this.top,
    required this.width,
    required this.height,
  });
}
