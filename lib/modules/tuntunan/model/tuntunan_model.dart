// Pose figur yang digambar pada animasi tuntunan.
enum PrayerPose {
  // Tahap wudhu — figur berdiri dengan sorotan pada bagian tubuh tertentu.
  wudhuHands,
  wudhuMouth,
  wudhuNose,
  wudhuFace,
  wudhuArms,
  wudhuHead,
  wudhuEars,
  wudhuFeet,
  wudhuDoa,
  // Tahap shalat.
  berdiri,
  takbir,
  sedekap,
  rukuk,
  itidal,
  sujud,
  dudukAntaraSujud,
  tasyahud,
  salamKanan,
}

// Satu langkah tuntunan: judul, penjelasan, dan bacaannya.
class TuntunanStep {
  const TuntunanStep({
    required this.title,
    required this.description,
    required this.pose,
    this.arabic = "",
    this.latin = "",
    this.translation = "",
  });

  final String title;
  final String description;
  final PrayerPose pose;
  final String arabic;
  final String latin;
  final String translation;

  bool get hasReading => arabic.trim().isNotEmpty;
}

// Kelompok tahapan (Wudhu / Shalat).
class TuntunanSection {
  const TuntunanSection({
    required this.name,
    required this.steps,
  });

  final String name;
  final List<TuntunanStep> steps;
}

// ---------------------------------------------------------------------------
// Data tuntunan: dari wudhu sampai salam.
// ---------------------------------------------------------------------------

const List<TuntunanStep> wudhuSteps = [
  TuntunanStep(
    title: "Niat Wudhu",
    description:
        "Berniat di dalam hati untuk berwudhu menghilangkan hadas kecil, "
        "lalu membaca basmalah sebelum memulai.",
    pose: PrayerPose.wudhuHands,
    arabic:
        "نَوَيْتُ الْوُضُوْءَ لِرَفْعِ الْحَدَثِ الْأَصْغَرِ فَرْضًا لِلّٰهِ تَعَالَى",
    latin:
        "Nawaitul wudhuu-a lirof'il hadatsil ashghari fardhal lillaahi ta'aalaa",
    translation:
        "Aku niat berwudhu untuk menghilangkan hadas kecil, fardhu karena Allah Ta'ala.",
  ),
  TuntunanStep(
    title: "Membasuh Telapak Tangan",
    description:
        "Basuh kedua telapak tangan sampai pergelangan sebanyak tiga kali, "
        "sela-sela jari ikut dibersihkan.",
    pose: PrayerPose.wudhuHands,
  ),
  TuntunanStep(
    title: "Berkumur",
    description:
        "Berkumur-kumur tiga kali sambil membersihkan sisa makanan di mulut.",
    pose: PrayerPose.wudhuMouth,
  ),
  TuntunanStep(
    title: "Membersihkan Hidung",
    description:
        "Menghirup air ke dalam hidung lalu mengeluarkannya kembali, "
        "dilakukan tiga kali.",
    pose: PrayerPose.wudhuNose,
  ),
  TuntunanStep(
    title: "Membasuh Wajah",
    description:
        "Basuh seluruh wajah dari batas tumbuh rambut sampai dagu, dan dari "
        "telinga kanan sampai telinga kiri, sebanyak tiga kali. Ini rukun wudhu.",
    pose: PrayerPose.wudhuFace,
  ),
  TuntunanStep(
    title: "Membasuh Kedua Tangan sampai Siku",
    description:
        "Basuh tangan kanan lebih dulu sampai melewati siku, lalu tangan kiri, "
        "masing-masing tiga kali.",
    pose: PrayerPose.wudhuArms,
  ),
  TuntunanStep(
    title: "Mengusap Sebagian Kepala",
    description:
        "Usap sebagian kepala (rambut) dengan tangan yang basah, cukup satu kali "
        "atau tiga kali.",
    pose: PrayerPose.wudhuHead,
  ),
  TuntunanStep(
    title: "Mengusap Kedua Telinga",
    description:
        "Usap bagian luar dan dalam kedua telinga dengan jari yang telah dibasahi.",
    pose: PrayerPose.wudhuEars,
  ),
  TuntunanStep(
    title: "Membasuh Kedua Kaki",
    description:
        "Basuh kaki kanan lalu kaki kiri sampai melewati mata kaki, tiga kali, "
        "sambil menyela-nyela jari kaki. Lakukan berurutan (tertib).",
    pose: PrayerPose.wudhuFeet,
  ),
  TuntunanStep(
    title: "Doa Setelah Wudhu",
    description:
        "Menghadap kiblat, mengangkat kedua tangan, lalu membaca doa setelah wudhu.",
    pose: PrayerPose.wudhuDoa,
    arabic:
        "أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُوْلُهُ. اَللّٰهُمَّ اجْعَلْنِيْ مِنَ التَّوَّابِيْنَ وَاجْعَلْنِيْ مِنَ الْمُتَطَهِّرِيْنَ",
    latin:
        "Asyhadu an laa ilaaha illallaahu wahdahuu laa syariika lah, wa asyhadu anna "
        "muhammadan 'abduhuu wa rasuuluh. Allaahummaj'alnii minat tawwaabiina waj'alnii "
        "minal mutathahhiriin",
    translation:
        "Aku bersaksi bahwa tiada Tuhan selain Allah Yang Maha Esa, tiada sekutu bagi-Nya, "
        "dan aku bersaksi bahwa Muhammad adalah hamba dan utusan-Nya. Ya Allah, jadikanlah "
        "aku termasuk orang-orang yang bertaubat dan jadikanlah aku termasuk orang-orang "
        "yang bersuci.",
  ),
];

const List<TuntunanStep> shalatSteps = [
  TuntunanStep(
    title: "Berdiri Menghadap Kiblat",
    description:
        "Berdiri tegak menghadap kiblat bagi yang mampu, lalu berniat shalat "
        "di dalam hati sesuai shalat yang dikerjakan.",
    pose: PrayerPose.berdiri,
  ),
  TuntunanStep(
    title: "Takbiratul Ihram",
    description:
        "Mengangkat kedua tangan sejajar telinga atau bahu sambil mengucapkan takbir. "
        "Sejak takbir ini, seluruh perbuatan di luar shalat menjadi terlarang.",
    pose: PrayerPose.takbir,
    arabic: "اَللّٰهُ أَكْبَرُ",
    latin: "Allaahu akbar",
    translation: "Allah Maha Besar.",
  ),
  TuntunanStep(
    title: "Doa Iftitah",
    description:
        "Setelah takbir, tangan bersedekap di dada lalu membaca doa iftitah "
        "(hukumnya sunnah).",
    pose: PrayerPose.sedekap,
    arabic:
        "اَللّٰهُمَّ بَاعِدْ بَيْنِيْ وَبَيْنَ خَطَايَايَ كَمَا بَاعَدْتَ بَيْنَ الْمَشْرِقِ وَالْمَغْرِبِ. اَللّٰهُمَّ نَقِّنِيْ مِنْ خَطَايَايَ كَمَا يُنَقَّى الثَّوْبُ الْأَبْيَضُ مِنَ الدَّنَسِ",
    latin:
        "Allaahumma baa'id bainii wa baina khathaayaaya kamaa baa'adta bainal masyriqi "
        "wal maghrib. Allaahumma naqqinii min khathaayaaya kamaa yunaqqats tsaubul abyadhu "
        "minad danas",
    translation:
        "Ya Allah, jauhkanlah antara aku dan kesalahan-kesalahanku sebagaimana Engkau "
        "menjauhkan antara timur dan barat. Ya Allah, bersihkanlah aku dari kesalahanku "
        "sebagaimana kain putih dibersihkan dari kotoran.",
  ),
  TuntunanStep(
    title: "Membaca Al-Fatihah",
    description:
        "Membaca surah Al-Fatihah pada setiap rakaat. Ini rukun shalat — "
        "shalat tidak sah tanpanya.",
    pose: PrayerPose.sedekap,
    arabic:
        "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ ۝ اَلْحَمْدُ لِلّٰهِ رَبِّ الْعٰلَمِيْنَ ۝ اَلرَّحْمٰنِ الرَّحِيْمِ ۝ مٰلِكِ يَوْمِ الدِّيْنِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِيْنُ ۝ اِهْدِنَا الصِّرَاطَ الْمُسْتَقِيْمَ ۝ صِرَاطَ الَّذِيْنَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوْبِ عَلَيْهِمْ وَلَا الضَّالِّيْنَ",
    latin:
        "Bismillaahir rahmaanir rahiim. Alhamdu lillaahi rabbil 'aalamiin. Ar rahmaanir "
        "rahiim. Maaliki yaumid diin. Iyyaaka na'budu wa iyyaaka nasta'iin. Ihdinash "
        "shiraathal mustaqiim. Shiraathal ladziina an'amta 'alaihim ghairil maghdhuubi "
        "'alaihim wa ladh dhaalliin",
    translation:
        "Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang. Segala puji bagi Allah "
        "Tuhan semesta alam. Yang Maha Pengasih lagi Maha Penyayang. Pemilik hari pembalasan. "
        "Hanya kepada-Mu kami menyembah dan hanya kepada-Mu kami memohon pertolongan. "
        "Tunjukilah kami jalan yang lurus. Yaitu jalan orang-orang yang telah Engkau beri "
        "nikmat, bukan jalan mereka yang dimurkai dan bukan pula jalan mereka yang sesat.",
  ),
  TuntunanStep(
    title: "Membaca Surah Pendek",
    description:
        "Pada rakaat pertama dan kedua, dianjurkan membaca surah atau ayat "
        "Al-Qur'an setelah Al-Fatihah.",
    pose: PrayerPose.sedekap,
    arabic:
        "قُلْ هُوَ اللّٰهُ أَحَدٌ ۝ اَللّٰهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُوْلَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ",
    latin:
        "Qul huwallaahu ahad. Allaahush shamad. Lam yalid wa lam yuulad. Wa lam yakul "
        "lahuu kufuwan ahad",
    translation:
        "Katakanlah: Dialah Allah Yang Maha Esa. Allah tempat bergantung segala sesuatu. "
        "Dia tidak beranak dan tidak pula diperanakkan. Dan tidak ada sesuatu pun yang "
        "setara dengan Dia.",
  ),
  TuntunanStep(
    title: "Rukuk",
    description:
        "Membungkuk hingga punggung rata, kedua tangan memegang lutut, "
        "dengan tenang (tuma'ninah). Bacaan diulang tiga kali.",
    pose: PrayerPose.rukuk,
    arabic: "سُبْحَانَ رَبِّيَ الْعَظِيْمِ وَبِحَمْدِهِ",
    latin: "Subhaana rabbiyal 'azhiimi wa bihamdih",
    translation: "Maha Suci Tuhanku Yang Maha Agung dan segala puji bagi-Nya.",
  ),
  TuntunanStep(
    title: "I'tidal",
    description:
        "Bangkit dari rukuk sampai berdiri tegak kembali sambil mengangkat "
        "kedua tangan.",
    pose: PrayerPose.itidal,
    arabic:
        "سَمِعَ اللّٰهُ لِمَنْ حَمِدَهُ. رَبَّنَا لَكَ الْحَمْدُ مِلْءَ السَّمٰوَاتِ وَمِلْءَ الْأَرْضِ وَمِلْءَ مَا شِئْتَ مِنْ شَيْءٍ بَعْدُ",
    latin:
        "Sami'allaahu liman hamidah. Rabbanaa lakal hamdu mil-as samaawaati wa mil-al "
        "ardhi wa mil-a maa syi'ta min syai-in ba'du",
    translation:
        "Allah mendengar orang yang memuji-Nya. Ya Tuhan kami, bagi-Mu segala puji "
        "sepenuh langit dan bumi, dan sepenuh apa yang Engkau kehendaki sesudahnya.",
  ),
  TuntunanStep(
    title: "Sujud",
    description:
        "Sujud dengan tujuh anggota badan: dahi dan hidung, kedua telapak tangan, "
        "kedua lutut, dan ujung jari kedua kaki. Bacaan diulang tiga kali.",
    pose: PrayerPose.sujud,
    arabic: "سُبْحَانَ رَبِّيَ الْأَعْلَى وَبِحَمْدِهِ",
    latin: "Subhaana rabbiyal a'laa wa bihamdih",
    translation: "Maha Suci Tuhanku Yang Maha Tinggi dan segala puji bagi-Nya.",
  ),
  TuntunanStep(
    title: "Duduk di Antara Dua Sujud",
    description:
        "Duduk iftirasy: kaki kiri diduduki dan kaki kanan ditegakkan, "
        "kedua tangan di atas paha.",
    pose: PrayerPose.dudukAntaraSujud,
    arabic:
        "رَبِّ اغْفِرْ لِيْ وَارْحَمْنِيْ وَاجْبُرْنِيْ وَارْفَعْنِيْ وَارْزُقْنِيْ وَاهْدِنِيْ وَعَافِنِيْ وَاعْفُ عَنِّيْ",
    latin:
        "Rabbighfir lii warhamnii wajburnii warfa'nii warzuqnii wahdinii wa 'aafinii "
        "wa'fu 'annii",
    translation:
        "Ya Tuhanku, ampunilah aku, sayangilah aku, cukupkanlah kekuranganku, angkatlah "
        "derajatku, berilah aku rezeki, berilah aku petunjuk, berilah aku kesehatan, "
        "dan maafkanlah aku.",
  ),
  TuntunanStep(
    title: "Sujud Kedua",
    description:
        "Sujud sekali lagi dengan cara dan bacaan yang sama, lalu bangkit "
        "untuk rakaat berikutnya.",
    pose: PrayerPose.sujud,
    arabic: "سُبْحَانَ رَبِّيَ الْأَعْلَى وَبِحَمْدِهِ",
    latin: "Subhaana rabbiyal a'laa wa bihamdih",
    translation: "Maha Suci Tuhanku Yang Maha Tinggi dan segala puji bagi-Nya.",
  ),
  TuntunanStep(
    title: "Tasyahud Awal",
    description:
        "Pada rakaat kedua (untuk shalat tiga atau empat rakaat), duduk iftirasy "
        "sambil membaca tasyahud awal dan shalawat kepada Nabi.",
    pose: PrayerPose.tasyahud,
    arabic:
        "اَلتَّحِيَّاتُ الْمُبَارَكَاتُ الصَّلَوَاتُ الطَّيِّبَاتُ لِلّٰهِ. اَلسَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللّٰهِ وَبَرَكَاتُهُ. اَلسَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللّٰهِ الصَّالِحِيْنَ. أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُوْلُ اللّٰهِ",
    latin:
        "Attahiyyaatul mubaarakaatush shalawaatuth thayyibaatu lillaah. Assalaamu 'alaika "
        "ayyuhan nabiyyu wa rahmatullaahi wa barakaatuh. Assalaamu 'alainaa wa 'alaa "
        "'ibaadillaahish shaalihiin. Asyhadu an laa ilaaha illallaah, wa asyhadu anna "
        "muhammadar rasuulullaah",
    translation:
        "Segala penghormatan, keberkahan, shalawat, dan kebaikan hanya milik Allah. "
        "Semoga keselamatan, rahmat Allah, dan keberkahan-Nya tercurah kepadamu wahai Nabi. "
        "Semoga keselamatan juga tercurah kepada kami dan kepada hamba-hamba Allah yang saleh. "
        "Aku bersaksi bahwa tiada Tuhan selain Allah, dan aku bersaksi bahwa Muhammad "
        "adalah utusan Allah.",
  ),
  TuntunanStep(
    title: "Tasyahud Akhir",
    description:
        "Pada rakaat terakhir, duduk tawarruk (pinggul menempel lantai) sambil "
        "membaca tasyahud dilanjutkan shalawat Ibrahimiyah.",
    pose: PrayerPose.tasyahud,
    arabic:
        "اَللّٰهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيْمَ وَعَلَى آلِ إِبْرَاهِيْمَ. وَبَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيْمَ وَعَلَى آلِ إِبْرَاهِيْمَ. فِي الْعَالَمِيْنَ إِنَّكَ حَمِيْدٌ مَجِيْدٌ",
    latin:
        "Allaahumma shalli 'alaa muhammadin wa 'alaa aali muhammad, kamaa shallaita 'alaa "
        "ibraahiima wa 'alaa aali ibraahiim. Wa baarik 'alaa muhammadin wa 'alaa aali "
        "muhammad, kamaa baarakta 'alaa ibraahiima wa 'alaa aali ibraahiim. Fil 'aalamiina "
        "innaka hamiidum majiid",
    translation:
        "Ya Allah, limpahkanlah rahmat kepada Nabi Muhammad dan keluarganya, sebagaimana "
        "Engkau telah melimpahkan rahmat kepada Nabi Ibrahim dan keluarganya. Berkahilah "
        "Nabi Muhammad dan keluarganya, sebagaimana Engkau telah memberkahi Nabi Ibrahim "
        "dan keluarganya. Di seluruh alam, sesungguhnya Engkau Maha Terpuji lagi Maha Mulia.",
  ),
  TuntunanStep(
    title: "Salam",
    description:
        "Menoleh ke kanan lalu ke kiri sambil mengucapkan salam. Dengan salam ini "
        "shalat selesai dan sempurna.",
    pose: PrayerPose.salamKanan,
    arabic: "اَلسَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللّٰهِ",
    latin: "Assalaamu 'alaikum wa rahmatullaah",
    translation: "Semoga keselamatan dan rahmat Allah tercurah kepada kalian.",
  ),
];

const List<TuntunanSection> tuntunanSections = [
  TuntunanSection(name: "Wudhu", steps: wudhuSteps),
  TuntunanSection(name: "Shalat", steps: shalatSteps),
];
