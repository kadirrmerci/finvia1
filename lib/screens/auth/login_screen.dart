import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedCity = 'İstanbul';
  String _selectedDistrict = '';
  String _loginMethod = 'email';
  String _verificationId = '';
  bool _otpSent = false;

  final Map<String, List<String>> _cityDistricts = {
    'Adana': [
      'Aladağ',
      'Ceyhan',
      'Çukurova',
      'Feke',
      'İmamoğlu',
      'Karaisalı',
      'Karataş',
      'Kozan',
      'Pozantı',
      'Saimbeyli',
      'Sarıçam',
      'Seyhan',
      'Tufanbeyli',
      'Yumurtalık',
      'Yüreğir',
    ],
    'Adıyaman': [
      'Besni',
      'Çelikhan',
      'Gerger',
      'Gölbaşı',
      'Kahta',
      'Merkez',
      'Samsat',
      'Sincik',
      'Tut',
    ],
    'Afyonkarahisar': [
      'Başmakçı',
      'Bayat',
      'Bolvadin',
      'Çay',
      'Çobanlar',
      'Dazkırı',
      'Dinar',
      'Emirdağ',
      'Evciler',
      'Hocalar',
      'İhsaniye',
      'İscehisar',
      'Kızılören',
      'Merkez',
      'Sandıklı',
      'Sinanpaşa',
      'Sultandağı',
      'Şuhut',
    ],
    'Ağrı': [
      'Diyadin',
      'Doğubayazıt',
      'Eleşkirt',
      'Hamur',
      'Merkez',
      'Patnos',
      'Taşlıçay',
      'Tutak',
    ],
    'Aksaray': [
      'Ağaçören',
      'Eskil',
      'Gülağaç',
      'Güzelyurt',
      'Merkez',
      'Ortaköy',
      'Sarıyahşi',
      'Sultanhanı',
    ],
    'Amasya': [
      'Göynücek',
      'Gümüşhacıköy',
      'Hamamözü',
      'Merkez',
      'Merzifon',
      'Suluova',
      'Taşova',
    ],
    'Ankara': [
      'Akyurt',
      'Altındağ',
      'Ayaş',
      'Bala',
      'Beypazarı',
      'Çamlıdere',
      'Çankaya',
      'Çubuk',
      'Elmadağ',
      'Etimesgut',
      'Evren',
      'Gölbaşı',
      'Güdül',
      'Haymana',
      'Kalecik',
      'Kahramankazan',
      'Keçiören',
      'Kızılcahamam',
      'Mamak',
      'Nallıhan',
      'Polatlı',
      'Pursaklar',
      'Sincan',
      'Şereflikoçhisar',
      'Yenimahalle',
    ],
    'Antalya': [
      'Akseki',
      'Aksu',
      'Alanya',
      'Demre',
      'Döşemealtı',
      'Elmalı',
      'Finike',
      'Gazipaşa',
      'Gündoğmuş',
      'İbradı',
      'Kaş',
      'Kemer',
      'Kepez',
      'Konyaaltı',
      'Korkuteli',
      'Kumluca',
      'Manavgat',
      'Muratpaşa',
      'Serik',
    ],
    'Ardahan': ['Çıldır', 'Damal', 'Göle', 'Hanak', 'Merkez', 'Posof'],
    'Artvin': [
      'Ardanuç',
      'Arhavi',
      'Borçka',
      'Hopa',
      'Kemalpaşa',
      'Merkez',
      'Murgul',
      'Şavşat',
      'Yusufeli',
    ],
    'Aydın': [
      'Bozdoğan',
      'Buharkent',
      'Çine',
      'Didim',
      'Efeler',
      'Germencik',
      'İncirliova',
      'Karacasu',
      'Karpuzlu',
      'Koçarlı',
      'Köşk',
      'Kuşadası',
      'Kuyucak',
      'Nazilli',
      'Söke',
      'Sultanhisar',
      'Yenipazar',
    ],
    'Balıkesir': [
      'Altıeylül',
      'Ayvalık',
      'Balya',
      'Bandırma',
      'Bigadiç',
      'Burhaniye',
      'Dursunbey',
      'Edremit',
      'Erdek',
      'Gömeç',
      'Gönen',
      'Havran',
      'İvrindi',
      'Karesi',
      'Kepsut',
      'Manyas',
      'Marmara',
      'Savaştepe',
      'Sındırgı',
      'Susurluk',
    ],
    'Bartın': ['Amasra', 'Kurucaşile', 'Merkez', 'Ulus'],
    'Batman': ['Beşiri', 'Gercüş', 'Hasankeyf', 'Kozluk', 'Merkez', 'Sason'],
    'Bayburt': ['Aydıntepe', 'Demirözü', 'Merkez'],
    'Bilecik': [
      'Bozüyük',
      'Gölpazarı',
      'İnhisar',
      'Merkez',
      'Osmaneli',
      'Pazaryeri',
      'Söğüt',
      'Yenipazar',
    ],
    'Bingöl': [
      'Adaklı',
      'Genç',
      'Karlıova',
      'Kiğı',
      'Merkez',
      'Solhan',
      'Yayladere',
      'Yedisu',
    ],
    'Bitlis': [
      'Adilcevaz',
      'Ahlat',
      'Güroymak',
      'Hizan',
      'Merkez',
      'Mutki',
      'Tatvan',
    ],
    'Bolu': [
      'Dörtdivan',
      'Gerede',
      'Göynük',
      'Kıbrıscık',
      'Mengen',
      'Merkez',
      'Mudurnu',
      'Seben',
      'Yeniçağa',
    ],
    'Burdur': [
      'Ağlasun',
      'Altınyayla',
      'Bucak',
      'Çavdır',
      'Çeltikçi',
      'Gölhisar',
      'Karamanlı',
      'Kemer',
      'Merkez',
      'Tefenni',
      'Yeşilova',
    ],
    'Bursa': [
      'Büyükorhan',
      'Gemlik',
      'Gürsu',
      'Harmancık',
      'İnegöl',
      'İznik',
      'Karacabey',
      'Keles',
      'Kestel',
      'Mudanya',
      'Mustafakemalpaşa',
      'Nilüfer',
      'Orhaneli',
      'Orhangazi',
      'Osmangazi',
      'Yıldırım',
      'Yenişehir',
    ],
    'Çanakkale': [
      'Ayvacık',
      'Bayramiç',
      'Biga',
      'Bozcaada',
      'Çan',
      'Eceabat',
      'Ezine',
      'Gelibolu',
      'Gökçeada',
      'Lapseki',
      'Merkez',
      'Yenice',
    ],
    'Çankırı': [
      'Atkaracalar',
      'Bayramören',
      'Çerkeş',
      'Eldivan',
      'Ilgaz',
      'Khanköy',
      'Korgun',
      'Kurşunlu',
      'Merkez',
      'Orta',
      'Şabanözü',
      'Yapraklı',
    ],
    'Çorum': [
      'Alaca',
      'Bayat',
      'Boğazkale',
      'Dodurga',
      'İskilip',
      'Kargı',
      'Laçin',
      'Mecitözü',
      'Merkez',
      'Oğuzlar',
      'Ortaköy',
      'Osmancık',
      'Sungurlu',
      'Uğurludağı',
    ],
    'Denizli': [
      'Acıpayam',
      'Babadağ',
      'Baklan',
      'Bekilli',
      'Beyağaç',
      'Bozkurt',
      'Buldan',
      'Çal',
      'Çameli',
      'Çardak',
      'Çivril',
      'Güney',
      'Honaz',
      'Kale',
      'Merkezefendi',
      'Pamukkale',
      'Sarayköy',
      'Serinhisar',
      'Tavas',
    ],
    'Diyarbakır': [
      'Bağlar',
      'Bismil',
      'Çermik',
      'Çınar',
      'Çüngüş',
      'Dicle',
      'Eğil',
      'Ergani',
      'Hani',
      'Hazro',
      'Kayapınar',
      'Kocaköy',
      'Kulp',
      'Lice',
      'Silvan',
      'Sur',
      'Yenişehir',
    ],
    'Düzce': [
      'Akçakoca',
      'Cumayeri',
      'Çilimli',
      'Gölyaka',
      'Gümüşova',
      'Kaynaşlı',
      'Merkez',
      'Yığılca',
    ],
    'Edirne': [
      'Enez',
      'Havsa',
      'İpsala',
      'Keşan',
      'Lalapaşa',
      'Meriç',
      'Merkez',
      'Süloğlu',
      'Uzunköprü',
    ],
    'Elazığ': [
      'Ağın',
      'Alacakaya',
      'Arıcak',
      'Baskil',
      'Karakoçan',
      'Keban',
      'Kovancılar',
      'Maden',
      'Merkez',
      'Palu',
      'Sivrice',
    ],
    'Erzincan': [
      'Çayırlı',
      'İliç',
      'Kemah',
      'Kemaliye',
      'Merkez',
      'Otlukbeli',
      'Refahiye',
      'Tercan',
      'Üzümlü',
    ],
    'Erzurum': [
      'Aşkale',
      'Aziziye',
      'Çat',
      'Hınıs',
      'Horasan',
      'İspir',
      'Karayazı',
      'Köprüköy',
      'Merkez',
      'Narman',
      'Oltu',
      'Olur',
      'Palandöken',
      'Pasinler',
      'Pazaryolu',
      'Şenkaya',
      'Tekman',
      'Tortum',
      'Uzundere',
      'Yakutiye',
    ],
    'Eskişehir': [
      'Alpu',
      'Beylikova',
      'Çifteler',
      'Günyüzü',
      'Han',
      'İnönü',
      'Mahmudiye',
      'Mihalgazi',
      'Mihalıççık',
      'Odunpazarı',
      'Sarıcakaya',
      'Seyitgazi',
      'Sivrihisar',
      'Tepebaşı',
    ],
    'Gaziantep': [
      'Araban',
      'İslahiye',
      'Karkamış',
      'Nurdağı',
      'Oğuzeli',
      'Şahinbey',
      'Şehitkamil',
      'Yavuzeli',
    ],
    'Giresun': [
      'Alucra',
      'Bulancak',
      'Çamoluk',
      'Çanakçı',
      'Dereli',
      'Doğankent',
      'Espiye',
      'Eynesil',
      'Görele',
      'Güce',
      'Keşap',
      'Merkez',
      'Piraziz',
      'Şebinkarahisar',
      'Tirebolu',
      'Yağlıdere',
    ],
    'Gümüşhane': ['Kelkit', 'Köse', 'Kürtün', 'Merkez', 'Şiran', 'Torul'],
    'Hakkari': ['Çukurca', 'Derecik', 'Merkez', 'Şemdinli', 'Yüksekova'],
    'Hatay': [
      'Altınözü',
      'Antakya',
      'Arsuz',
      'Belen',
      'Defne',
      'Dörtyol',
      'Erzin',
      'Hassa',
      'İskenderun',
      'Kırıkhan',
      'Kumlu',
      'Payas',
      'Reyhanlı',
      'Samandağ',
      'Yayladağı',
    ],
    'Iğdır': ['Aralık', 'Karakoyunlu', 'Merkez', 'Tuzluca'],
    'Isparta': [
      'Aksu',
      'Atabey',
      'Eğirdir',
      'Gelendost',
      'Gönen',
      'Keçiborlu',
      'Merkez',
      'Senirkent',
      'Sütçüler',
      'Şarkikaraağaç',
      'Uluborlu',
      'Yalvaç',
      'Yenişarbademli',
    ],
    'İstanbul': [
      'Adalar',
      'Arnavutköy',
      'Ataşehir',
      'Avcılar',
      'Bağcılar',
      'Bahçelievler',
      'Bakırköy',
      'Başakşehir',
      'Bayrampaşa',
      'Beşiktaş',
      'Beykoz',
      'Beylikdüzü',
      'Beyoğlu',
      'Büyükçekmece',
      'Çatalca',
      'Çekmeköy',
      'Esenler',
      'Esenyurt',
      'Eyüpsultan',
      'Fatih',
      'Gaziosmanpaşa',
      'Güngören',
      'Kadıköy',
      'Kağıthane',
      'Kartal',
      'Küçükçekmece',
      'Maltepe',
      'Pendik',
      'Sancaktepe',
      'Sarıyer',
      'Silivri',
      'Sultanbeyli',
      'Sultangazi',
      'Şile',
      'Şişli',
      'Tuzla',
      'Ümraniye',
      'Üsküdar',
      'Zeytinburnu',
    ],
    'İzmir': [
      'Aliağa',
      'Balçova',
      'Bayındır',
      'Bayraklı',
      'Bergama',
      'Beydağ',
      'Bornova',
      'Buca',
      'Çeşme',
      'Çiğli',
      'Dikili',
      'Foça',
      'Gaziemir',
      'Güzelbahçe',
      'Karabağlar',
      'Karaburun',
      'Karşıyaka',
      'Kemalpaşa',
      'Kınık',
      'Kiraz',
      'Konak',
      'Menderes',
      'Menemen',
      'Narlıdere',
      'Ödemiş',
      'Seferihisar',
      'Selçuk',
      'Tire',
      'Torbalı',
      'Urla',
    ],
    'Kahramanmaraş': [
      'Afşin',
      'Andırın',
      'Çağlayancerit',
      'Dulkadiroğlu',
      'Ekinözü',
      'Elbistan',
      'Göksun',
      'Nurhak',
      'Onikişubat',
      'Pazarcık',
      'Türkoğlu',
    ],
    'Karabük': [
      'Eflani',
      'Eskipazar',
      'Merkez',
      'Ovacık',
      'Safranbolu',
      'Yenice',
    ],
    'Karaman': [
      'Ayrancı',
      'Başyayla',
      'Ermenek',
      'Kazımkarabekir',
      'Merkez',
      'Sarıveliler',
    ],
    'Kars': [
      'Akyaka',
      'Arpaçay',
      'Digor',
      'Kağızman',
      'Merkez',
      'Sarıkamış',
      'Selim',
      'Susuz',
    ],
    'Kastamonu': [
      'Abana',
      'Ağlı',
      'Araç',
      'Azdavay',
      'Bozkurt',
      'Cide',
      'Çatalzeytin',
      'Daday',
      'Devrekani',
      'Doğanyurt',
      'Hanönü',
      'İhsangazi',
      'İnebolu',
      'Küre',
      'Merkez',
      'Pınarbaşı',
      'Şenpazar',
      'Taşköprü',
      'Tosya',
    ],
    'Kayseri': [
      'Akkışla',
      'Bünyan',
      'Develi',
      'Felahiye',
      'Hacılar',
      'İncesu',
      'Kocasinan',
      'Melikgazi',
      'Özvatan',
      'Pınarbaşı',
      'Sarıoğlan',
      'Sarız',
      'Talas',
      'Tomarza',
      'Yahyalı',
      'Yeşilhisar',
    ],
    'Kırıkkale': [
      'Bahşili',
      'Balışeyh',
      'Çelebi',
      'Delice',
      'Karakeçili',
      'Keskin',
      'Merkez',
      'Sulakyurt',
      'Yahşihan',
    ],
    'Kırklareli': [
      'Babaeski',
      'Demirköy',
      'Kofçaz',
      'Lüleburgaz',
      'Merkez',
      'Pehlivanköy',
      'Pınarhisar',
      'Vize',
    ],
    'Kırşehir': [
      'Akçakent',
      'Akpınar',
      'Boztepe',
      'Çiçekdağı',
      'Kaman',
      'Merkez',
      'Mucur',
    ],
    'Kilis': ['Elbeyli', 'Merkez', 'Musabeyli', 'Polateli'],
    'Kocaeli': [
      'Başiskele',
      'Çayırova',
      'Darıca',
      'Derince',
      'Dilovası',
      'Gebze',
      'Gölcük',
      'İzmit',
      'Kandıra',
      'Karamürsel',
      'Kartepe',
      'Körfez',
    ],
    'Konya': [
      'Ahırlı',
      'Akören',
      'Akşehir',
      'Altınekin',
      'Beyşehir',
      'Bozkır',
      'Cihanbeyli',
      'Çeltik',
      'Çumra',
      'Derbent',
      'Derebucak',
      'Doğanhisar',
      'Emirgazi',
      'Ereğli',
      'Güneysınır',
      'Hadim',
      'Halkapınar',
      'Hüyük',
      'Ilgın',
      'Kadınhanı',
      'Karapınar',
      'Karatay',
      'Kulu',
      'Meram',
      'Sarayönü',
      'Selçuklu',
      'Seydişehir',
      'Taşkent',
      'Tuzlukçu',
      'Yalıhüyük',
      'Yunak',
    ],
    'Kütahya': [
      'Altıntaş',
      'Aslanapa',
      'Çavdarhisar',
      'Domaniç',
      'Dumlupınar',
      'Emet',
      'Gediz',
      'Hisarcık',
      'Merkez',
      'Pazarlar',
      'Simav',
      'Şaphane',
      'Tavşanlı',
    ],
    'Malatya': [
      'Akçadağ',
      'Arapgir',
      'Arguvan',
      'Battalgazi',
      'Darende',
      'Doğanşehir',
      'Doğanyol',
      'Hekimhan',
      'Kale',
      'Kuluncak',
      'Merkez',
      'Pütürge',
      'Yazıhan',
      'Yeşilyurt',
    ],
    'Manisa': [
      'Ahmetli',
      'Akhisar',
      'Alaşehir',
      'Demirci',
      'Gölmarmara',
      'Gördes',
      'Kırkağaç',
      'Köprübaşı',
      'Kula',
      'Merkez',
      'Salihli',
      'Sarıgöl',
      'Saruhanlı',
      'Selendi',
      'Soma',
      'Şehzadeler',
      'Turgutlu',
      'Yunusemre',
    ],
    'Mardin': [
      'Artuklu',
      'Dargeçit',
      'Derik',
      'Kızıltepe',
      'Mazıdağı',
      'Midyat',
      'Nusaybin',
      'Ömerli',
      'Savur',
      'Yeşilli',
    ],
    'Mersin': [
      'Akdeniz',
      'Anamur',
      'Aydıncık',
      'Bozyazı',
      'Çamlıyayla',
      'Erdemli',
      'Gülnar',
      'Mezitli',
      'Mut',
      'Silifke',
      'Tarsus',
      'Toroslar',
      'Yenişehir',
    ],
    'Muğla': [
      'Bodrum',
      'Dalaman',
      'Datça',
      'Fethiye',
      'Kavaklıdere',
      'Köyceğiz',
      'Marmaris',
      'Menteşe',
      'Milas',
      'Ortaca',
      'Seydikemer',
      'Ula',
      'Yatağan',
    ],
    'Muş': ['Bulanık', 'Hasköy', 'Korkut', 'Malazgirt', 'Merkez', 'Varto'],
    'Nevşehir': [
      'Acıgöl',
      'Avanos',
      'Derinkuyu',
      'Gülşehir',
      'Hacıbektaş',
      'Kozaklı',
      'Merkez',
      'Ürgüp',
    ],
    'Niğde': ['Altunhisar', 'Bor', 'Çamardı', 'Çiftlik', 'Merkez', 'Ulukışla'],
    'Ordu': [
      'Akkuş',
      'Altınordu',
      'Aybastı',
      'Çamaş',
      'Çatalpınar',
      'Çaybaşı',
      'Fatsa',
      'Gölköy',
      'Gülyalı',
      'Gürgentepe',
      'İkizce',
      'Kabadüz',
      'Kabataş',
      'Korgan',
      'Kumru',
      'Mesudiye',
      'Perşembe',
      'Ulubey',
      'Ünye',
    ],
    'Osmaniye': [
      'Bahçe',
      'Düziçi',
      'Hasanbeyli',
      'Kadirli',
      'Merkez',
      'Sumbas',
      'Toprakkale',
    ],
    'Rize': [
      'Ardeşen',
      'Çamlıhemşin',
      'Çayeli',
      'Derepazarı',
      'Fındıklı',
      'Güneysu',
      'Hemşin',
      'İkizdere',
      'İyidere',
      'Kalkandere',
      'Merkez',
      'Pazar',
    ],
    'Sakarya': [
      'Adapazarı',
      'Akyazı',
      'Arifiye',
      'Erenler',
      'Ferizli',
      'Geyve',
      'Hendek',
      'Karapürçek',
      'Karasu',
      'Kaynarca',
      'Kocaali',
      'Mithatpaşa',
      'Pamukova',
      'Sapanca',
      'Serdivan',
      'Söğütlü',
      'Taraklı',
    ],
    'Samsun': [
      'Alaçam',
      'Asarcık',
      'Atakum',
      'Ayvacık',
      'Bafra',
      'Canik',
      'Çarşamba',
      'Havza',
      'İlkadım',
      'Kavak',
      'Ladik',
      'Ondokuzmayıs',
      'Salıpazarı',
      'Tekkeköy',
      'Terme',
      'Vezirköprü',
      'Yakakent',
    ],
    'Siirt': [
      'Baykan',
      'Eruh',
      'Kurtalan',
      'Merkez',
      'Pervari',
      'Şirvan',
      'Tillo',
    ],
    'Sinop': [
      'Ayancık',
      'Boyabat',
      'Dikmen',
      'Durağan',
      'Erfelek',
      'Gerze',
      'Merkez',
      'Saraydüzü',
      'Türkeli',
    ],
    'Sivas': [
      'Akıncılar',
      'Altınyayla',
      'Divriği',
      'Doğanşar',
      'Gemerek',
      'Gölova',
      'Gürün',
      'Hafik',
      'İmranlı',
      'Kangal',
      'Koyulhisar',
      'Merkez',
      'Suşehri',
      'Şarkışla',
      'Ulaş',
      'Yıldızeli',
      'Zara',
    ],
    'Şanlıurfa': [
      'Akçakale',
      'Birecik',
      'Bozova',
      'Ceylanpınar',
      'Eyyübiye',
      'Halfeti',
      'Haliliye',
      'Harran',
      'Hilvan',
      'Karaköprü',
      'Merkez',
      'Siverek',
      'Suruç',
      'Viranşehir',
    ],
    'Şırnak': [
      'Beytüşşebap',
      'Cizre',
      'Güçlükonak',
      'İdil',
      'Merkez',
      'Silopi',
      'Uludere',
    ],
    'Tekirdağ': [
      'Çerkezköy',
      'Çorlu',
      'Ergene',
      'Hayrabolu',
      'Kapaklı',
      'Malkara',
      'Marmaraereğlisi',
      'Merkez',
      'Muratlı',
      'Saray',
      'Süleymanpaşa',
      'Şarköy',
    ],
    'Tokat': [
      'Almus',
      'Artova',
      'Başçiftlik',
      'Erbaa',
      'Merkez',
      'Niksar',
      'Pazar',
      'Reşadiye',
      'Sulusaray',
      'Turhal',
      'Yeşilyurt',
      'Zile',
    ],
    'Trabzon': [
      'Akçaabat',
      'Araklı',
      'Arsin',
      'Beşikdüzü',
      'Çarşıbaşı',
      'Çaykara',
      'Dernekpazarı',
      'Düzköy',
      'Hayrat',
      'Köprübaşı',
      'Maçka',
      'Of',
      'Ortahisar',
      'Sürmene',
      'Şalpazarı',
      'Tonya',
      'Vakfıkebir',
      'Yomra',
    ],
    'Tunceli': [
      'Çemişgezek',
      'Hozat',
      'Mazgirt',
      'Merkez',
      'Nazımiye',
      'Ovacık',
      'Pertek',
      'Pülümür',
    ],
    'Uşak': ['Banaz', 'Eşme', 'Karahallı', 'Merkez', 'Sivaslı', 'Ulubey'],
    'Van': [
      'Bahçesaray',
      'Başkale',
      'Çaldıran',
      'Çatak',
      'Edremit',
      'Erciş',
      'Gevaş',
      'Gürpınar',
      'İpekyolu',
      'Merkez',
      'Muradiye',
      'Özalp',
      'Saray',
      'Tuşba',
    ],
    'Yalova': [
      'Altınova',
      'Armutlu',
      'Çınarcık',
      'Çiftlikkköy',
      'Merkez',
      'Termal',
    ],
    'Yozgat': [
      'Akdağmadeni',
      'Aydıncık',
      'Boğazlıyan',
      'Çandır',
      'Çayıralan',
      'Çekerek',
      'Kadışehri',
      'Merkez',
      'Saraykent',
      'Sarıkaya',
      'Şefaatli',
      'Sorgun',
      'Yenifakılı',
      'Yerköy',
    ],
    'Zonguldak': [
      'Alaplı',
      'Çaycuma',
      'Devrek',
      'Gökçebey',
      'Kilimli',
      'Kozlu',
      'Merkez',
    ],
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) return false;
    final parts = email.split('@');
    if (parts.length != 2) return false;
    final domain = parts[1];
    if (!domain.contains('.')) return false;
    final tld = domain.split('.').last;
    if (tld.length < 2) return false;
    return true;
  }

  Future<void> _saveUserToFirestore(User user, {String? phone}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid != user.uid) {
      throw FirebaseAuthException(
        code: 'user-token-expired',
        message: 'Aktif Firebase oturumu kullanıcı profiliyle eşleşmiyor.',
      );
    }

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final values = <String, dynamic>{
      'uid': user.uid,
      'name': user.displayName ?? _nameController.text.trim(),
      'email': user.email ?? _emailController.text.trim(),
      'phone': phone ?? _phoneController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 0,
      'city': _selectedCity,
      'district': _selectedDistrict,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    Future<void> saveProfile() async {
      await userRef.set(values, SetOptions(merge: true));
    }

    try {
      await saveProfile();
    } on FirebaseException catch (error) {
      if (error.plugin != 'cloud_firestore' ||
          error.code != 'permission-denied') {
        rethrow;
      }

      final retryUser = FirebaseAuth.instance.currentUser;
      if (retryUser?.uid != user.uid) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await saveProfile();
    }
  }

  Future<void> _signOutAfterRegistration() async {
    try {
      await FirebaseAuth.instance.signOut().timeout(
        const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Kayıt sonrası çıkış yapılamadı: $e');
    }
  }

  Future<T> _runRegistrationStep<T>(
    String step,
    Future<T> Function() operation,
  ) async {
    debugPrint('Email kayıt adımı başladı: $step');
    try {
      final result = await operation().timeout(const Duration(seconds: 20));
      debugPrint('Email kayıt adımı tamamlandı: $step');
      return result;
    } on TimeoutException {
      debugPrint('Email kayıt adımı zaman aşımına uğradı: $step');
      throw TimeoutException(step);
    } catch (error) {
      debugPrint('Email kayıt adımı başarısız: $step - $error');
      rethrow;
    }
  }

  Future<void> _completeEmailRegistration(User user) async {
    await _runRegistrationStep(
      'kullanıcı adını güncelleme',
      () => user.updateDisplayName(_nameController.text.trim()),
    );
    await _runRegistrationStep(
      'profil kaydını oluşturma',
      () => _saveUserToFirestore(user),
    );
    if (!user.emailVerified) {
      await _runRegistrationStep(
        'doğrulama e-postası gönderme',
        user.sendEmailVerification,
      );
    }
    await _signOutAfterRegistration();
    if (mounted) _showVerificationDialog();
  }

  Future<bool> _repairPartialEmailRegistration() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = credential.user;
      if (user == null) return false;
      await _completeEmailRegistration(user);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return false;
      }
      rethrow;
    }
  }

  Future<void> _submitEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun');
      return;
    }
    if (!_isValidEmail(_emailController.text.trim())) {
      _showError('Geçerli bir email adresi girin');
      return;
    }
    if (!_isLogin) {
      if (_nameController.text.isEmpty) {
        _showError('Ad soyad gerekli');
        return;
      }
      if (_ageController.text.isEmpty) {
        _showError('Yaş gerekli');
        return;
      }
      if (_selectedDistrict.isEmpty) {
        _showError('İlçe seçiniz');
        return;
      }
    }
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (cred.user != null && !cred.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          _showError('Lütfen önce emailinizi doğrulayın');
        }
      } else {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        final user = credential.user;
        if (user != null) {
          await _completeEmailRegistration(user);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!_isLogin && e.code == 'email-already-in-use') {
        try {
          if (await _repairPartialEmailRegistration()) return;
        } on FirebaseException catch (repairError) {
          final source = repairError.plugin == 'cloud_firestore'
              ? 'Firestore'
              : 'Firebase Auth';
          _showError(
            'Hesap mevcut ancak profil kaydı sırasında $source hatası oluştu '
            '(${repairError.code}): '
            '${repairError.message ?? repairError.code}',
          );
          return;
        }
      }

      String message = 'Hata: ${e.code}';
      if (e.code == 'user-not-found') message = 'Kullanıcı bulunamadı';
      if (e.code == 'wrong-password') message = 'Hatalı şifre';
      if (e.code == 'email-already-in-use') {
        message = 'Bu email zaten kullanımda';
      }
      if (e.code == 'weak-password') {
        message = 'Şifre çok zayıf (min 6 karakter)';
      }
      if (e.code == 'invalid-email') message = 'Geçersiz email adresi';
      if (e.code == 'invalid-credential') message = 'Email veya şifre hatalı';
      if (e.code == 'too-many-requests') {
        message = 'Çok fazla deneme. Lütfen bekleyin';
      }
      if (e.code == 'network-request-failed') {
        message = 'İnternet bağlantısı yok';
      }
      _showError(message);
    } on FirebaseException catch (e) {
      _showError(
        'Hesap oluşturuldu ancak profil Firebase’e kaydedilemedi: '
        '${e.message ?? e.code}',
      );
    } on TimeoutException catch (e) {
      _showError(
        'Kayıt işlemi "${e.message ?? 'bilinmeyen adım'}" adımında zaman '
        'aşımına uğradı. Lütfen bağlantınızı kontrol edip tekrar deneyin.',
      );
    } catch (e) {
      _showError('Beklenmedik hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      if (userCred.user != null) await _saveUserToFirestore(userCred.user!);
    } catch (e) {
      _showError('Google girişi başarısız: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty) {
      _showError('Telefon numarası gerekli');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+90${_phoneController.text.trim()}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showError('Doğrulama hatası: ${e.message}');
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS gönderildi!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showError('Hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showError('Doğrulama kodu gerekli');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      if (userCred.user != null && _nameController.text.isNotEmpty) {
        await userCred.user!.updateDisplayName(_nameController.text.trim());
        await _saveUserToFirestore(
          userCred.user!,
          phone: '+90${_phoneController.text.trim()}',
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Hata: ${e.code}';
      if (e.code == 'invalid-verification-code') {
        message = 'Hatalı doğrulama kodu';
      }
      if (e.code == 'session-expired') {
        message = 'Kod süresi doldu, tekrar gönderin';
      }
      _showError(message);
    } catch (e) {
      _showError('Beklenmedik hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('📧 Email Doğrulama'),
        content: Text(
          '${_emailController.text.trim()} adresine doğrulama emaili gönderildi.\n\nEmailinizi doğruladıktan sonra giriş yapabilirsiniz.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF89CC2A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isLogin = true);
            },
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final districts = _cityDistricts[_selectedCity] ?? [];
    return Scaffold(
      body: Column(
        children: [
          // ÜST KISIM - Gradient yeşil
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF9AD62E),
                    Color(0xFF89CC2A),
                    Color(0xFF76BC2B),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/icon/icon.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isLogin ? 'Hoş Geldin' : 'Hesap Oluştur',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLogin ? 'Finvia\'ya giriş yap' : 'Yeni hesap oluştur',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ALT KISIM - Beyaz form
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Giriş yöntemi seçici
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _loginMethod = 'email';
                              _otpSent = false;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _loginMethod == 'email'
                                    ? const Color(0xFF89CC2A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF89CC2A),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    color: _loginMethod == 'email'
                                        ? Colors.white
                                        : const Color(0xFF89CC2A),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Email',
                                    style: TextStyle(
                                      color: _loginMethod == 'email'
                                          ? Colors.white
                                          : const Color(0xFF89CC2A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _loginMethod = 'phone';
                              _otpSent = false;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _loginMethod == 'phone'
                                    ? const Color(0xFF89CC2A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF89CC2A),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    color: _loginMethod == 'phone'
                                        ? Colors.white
                                        : const Color(0xFF89CC2A),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Telefon',
                                    style: TextStyle(
                                      color: _loginMethod == 'phone'
                                          ? Colors.white
                                          : const Color(0xFF89CC2A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Email girişi
                    if (_loginMethod == 'email') ...[
                      if (!_isLogin) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ad Soyad',
                            prefixIcon: Icon(Icons.person_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Yaş',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'İl',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          items: _cityDistricts.keys
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedCity = v ?? 'İstanbul';
                            _selectedDistrict = '';
                          }),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDistrict.isEmpty
                              ? null
                              : _selectedDistrict,
                          decoration: const InputDecoration(
                            labelText: 'İlçe',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                          items: districts
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedDistrict = v ?? ''),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF89CC2A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isLoading ? null : _submitEmail,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'veya',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: const Icon(
                            Icons.g_mobiledata,
                            color: Colors.red,
                            size: 28,
                          ),
                          label: const Text(
                            'Google ile Giriş Yap',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() {
                            _isLogin = !_isLogin;
                            _otpSent = false;
                          }),
                          child: Text(
                            _isLogin
                                ? 'Hesabın yok mu? Kayıt ol'
                                : 'Zaten hesabın var mı? Giriş yap',
                            style: const TextStyle(color: Color(0xFF89CC2A)),
                          ),
                        ),
                      ),
                    ],

                    // Telefon girişi
                    if (_loginMethod == 'phone') ...[
                      if (!_otpSent) ...[
                        if (!_isLogin) ...[
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Ad Soyad',
                              prefixIcon: Icon(Icons.person_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '+90',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Telefon Numarası',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF89CC2A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading ? null : _sendOtp,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'SMS Gönder',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'SMS ile gönderilen 6 haneli kodu girin',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'Doğrulama Kodu',
                            prefixIcon: Icon(Icons.lock_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF89CC2A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading ? null : _verifyOtp,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Doğrula',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _otpSent = false),
                            child: const Text(
                              'Kodu tekrar gönder',
                              style: TextStyle(color: Color(0xFF89CC2A)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
