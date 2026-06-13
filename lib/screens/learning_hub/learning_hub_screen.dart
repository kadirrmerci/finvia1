import 'package:flutter/material.dart';

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  String _selectedCategory = _blogCategories.first.name;

  List<_BlogPost> get _visiblePosts {
    return _blogPosts
        .where((post) => post.category == _selectedCategory)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LearningHub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isWide
          ? Row(
              children: [
                SizedBox(
                  width: 220,
                  child: _CategoryRail(
                    selectedCategory: _selectedCategory,
                    onSelected: _selectCategory,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _BlogList(posts: _visiblePosts)),
              ],
            )
          : Column(
              children: [
                _CategoryChips(
                  selectedCategory: _selectedCategory,
                  onSelected: _selectCategory,
                ),
                const Divider(height: 1),
                Expanded(child: _BlogList(posts: _visiblePosts)),
              ],
            ),
    );
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.selectedCategory,
    required this.onSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children:
          [
            for (final category in _blogCategories)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: NavigationDrawerDestination(
                  icon: Icon(category.icon),
                  selectedIcon: Icon(category.selectedIcon),
                  label: Text(category.name),
                ),
              ),
          ].asMap().entries.map((entry) {
            final category = _blogCategories[entry.key];
            return _CategoryTile(
              category: category,
              isSelected: category.name == selectedCategory,
              onTap: () => onSelected(category.name),
            );
          }).toList(),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.selectedCategory,
    required this.onSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = _blogCategories[index];
          return FilterChip(
            avatar: Icon(category.icon, size: 18),
            label: Text(category.name),
            selected: category.name == selectedCategory,
            onSelected: (_) => onSelected(category.name),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: _blogCategories.length,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final _BlogCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(isSelected ? category.selectedIcon : category.icon),
        title: Text(category.name),
        selected: isSelected,
        selectedTileColor: colorScheme.primaryContainer,
        selectedColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onTap,
      ),
    );
  }
}

class _BlogList extends StatelessWidget {
  const _BlogList({required this.posts});

  final List<_BlogPost> posts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                post.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _BlogDetailScreen(post: post),
                ),
              );
            },
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemCount: posts.length,
    );
  }
}

class _BlogDetailScreen extends StatelessWidget {
  const _BlogDetailScreen({required this.post});

  final _BlogPost post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(post.category)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            post.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            post.summary,
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ...post.paragraphs.map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                paragraph,
                style: textTheme.bodyLarge?.copyWith(height: 1.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlogCategory {
  const _BlogCategory(this.name, this.icon, this.selectedIcon);

  final String name;
  final IconData icon;
  final IconData selectedIcon;
}

class _BlogPost {
  const _BlogPost({
    required this.category,
    required this.title,
    required this.summary,
    required this.paragraphs,
  });

  final String category;
  final String title;
  final String summary;
  final List<String> paragraphs;
}

const _blogCategories = [
  _BlogCategory(
    'Finans',
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet,
  ),
  _BlogCategory('Sağlık', Icons.favorite_outline, Icons.favorite),
  _BlogCategory('Yatırım', Icons.trending_up_outlined, Icons.trending_up),
  _BlogCategory('Yaşam', Icons.home_outlined, Icons.home),
  _BlogCategory('Giyim', Icons.checkroom_outlined, Icons.checkroom),
  _BlogCategory('Bakım', Icons.spa_outlined, Icons.spa),
];

const _blogPosts = [
  _BlogPost(
    category: 'Finans',
    title: 'Aylık bütçe planına nereden başlanır?',
    summary:
        'Gelir, zorunlu gider ve hedefleri sade bir plana bağlama rehberi.',
    paragraphs: [
      'Aylık bütçe planı, gelirini kısıtlamak için değil, paranı nereye yönlendirdiğini net görmek için yapılır. İlk adım tüm düzenli gelirleri ve sabit giderleri ayrı ayrı yazmaktır.',
      'Sonrasında değişken harcamaları haftalık takip etmek işleri kolaylaştırır. Market, ulaşım, eğlence ve abonelik gibi kalemler küçük görünse de ay sonunda büyük fark oluşturabilir.',
      'Bütçenin sürdürülebilir olması için kendine esnek bir alan bırak. Çok katı planlar hızlı bozulur; küçük bir pay ise planın gerçek hayata uyum sağlamasını kolaylaştırır.',
    ],
  ),
  _BlogPost(
    category: 'Finans',
    title: 'Abonelikleri kontrol altında tutma',
    summary:
        'Unutulan dijital abonelikleri fark etmek ve gereksiz giderleri azaltmak.',
    paragraphs: [
      'Abonelikler çoğu zaman düşük tutarlı olduğu için gözden kaçar. Ancak birkaç servis bir araya geldiğinde bütçede hissedilir bir kalem haline gelir.',
      'Her ay aynı gün aboneliklerini listelemek, kullanmadıklarını iptal etmek ve yıllık ödeme yerine aylık ödeme riskini değerlendirmek iyi bir alışkanlıktır.',
      'Bir aboneliği iptal etmek sadece tasarruf değildir; aynı zamanda hangi hizmetlerin gerçekten hayatına değer kattığını seçmektir.',
    ],
  ),
  _BlogPost(
    category: 'Sağlık',
    title: 'Küçük alışkanlıklarla daha iyi enerji',
    summary: 'Uyku, su ve hareket düzenini zorlamadan iyileştirme fikirleri.',
    paragraphs: [
      'Enerji seviyesini yükseltmek için büyük değişimler şart değildir. Düzenli uyku saati, gün içinde yeterli su ve kısa yürüyüşler çoğu zaman iyi bir başlangıçtır.',
      'Alışkanlıkları küçük tutmak sürdürülebilirliği artırır. Her gün on dakika yürümek, haftada bir kez uzun ve yorucu bir hedef koymaktan daha etkili olabilir.',
      'Kendini takip etmek motivasyon sağlar. İyi hissettiğin günleri ve o gün yaptığın küçük seçimleri not almak, sana kendi ritmini gösterir.',
    ],
  ),
  _BlogPost(
    category: 'Sağlık',
    title: 'Kilo takibinde sayının ötesine bakmak',
    summary: 'Tartı değerini tek ölçüt yapmadan ilerlemeyi değerlendirmek.',
    paragraphs: [
      'Kilo takibi faydalı olabilir, ancak tek başına tüm resmi göstermez. Uyku, stres, su tüketimi ve hareket düzeyi de günlük değişimleri etkiler.',
      'Haftalık ortalamaya bakmak, tek bir güne takılmaktan daha sağlıklıdır. Böylece doğal dalgalanmaları daha sakin yorumlayabilirsin.',
      'Amaç sadece sayı düşürmek değil, daha iyi hissettiren bir düzen kurmaktır. Bu yüzden ölçümleri davranışlarla birlikte değerlendirmek daha anlamlıdır.',
    ],
  ),
  _BlogPost(
    category: 'Yatırım',
    title: 'Risk profilini anlamak',
    summary:
        'Yatırım kararı vermeden önce kendine sorman gereken temel sorular.',
    paragraphs: [
      'Yatırımda ilk konu hangi ürünü alacağın değil, hangi riski taşıyabileceğindir. Zaman ufku, gelir düzeni ve acil nakit ihtiyacı bu kararı etkiler.',
      'Kısa vadede ihtiyaç duyacağın parayı yüksek dalgalı ürünlere bağlamak stres yaratabilir. Uzun vadeli hedefler için ise farklı araçları birlikte düşünmek daha dengeli olabilir.',
      'Her yatırım kararı kişiseldir. Başkasına uygun olan strateji senin hedeflerinle uyumlu olmayabilir.',
    ],
  ),
  _BlogPost(
    category: 'Yatırım',
    title: 'Portföy çeşitlendirmesi neden önemlidir?',
    summary: 'Tüm birikimi tek araca bağlamanın risklerini azaltma yaklaşımı.',
    paragraphs: [
      'Çeşitlendirme, belirsizliği tamamen ortadan kaldırmaz; fakat tek bir varlığa bağımlı kalma riskini azaltır.',
      'Farklı sektörler, farklı vadeler ve farklı risk seviyeleri birlikte değerlendirildiğinde portföy daha dengeli hale gelebilir.',
      'Dengeyi korumak için belirli aralıklarla portföyü gözden geçirmek gerekir. Bu kontrol, gereksiz panik kararlarını azaltır.',
    ],
  ),
  _BlogPost(
    category: 'Yaşam',
    title: 'Günlük düzeni sadeleştirmek',
    summary: 'Daha az karar yorgunluğu için pratik planlama önerileri.',
    paragraphs: [
      'Günlük düzeni sadeleştirmek, her dakikayı planlamak anlamına gelmez. Asıl amaç sık tekrar eden kararları kolaylaştırmaktır.',
      'Sabah rutini, haftalık alışveriş listesi ve sabit odak saatleri gün içindeki zihinsel yükü azaltabilir.',
      'Sade bir düzen daha fazla boşluk yaratır. Bu boşluk, hem dinlenmek hem de önemli işlere odaklanmak için değerlidir.',
    ],
  ),
  _BlogPost(
    category: 'Yaşam',
    title: 'Evde daha sakin bir çalışma alanı',
    summary: 'Odaklanmayı kolaylaştıran küçük çevre düzenlemeleri.',
    paragraphs: [
      'Çalışma alanında her şeyin kusursuz olması gerekmez. Temiz bir masa, iyi ışık ve kolay erişilen temel araçlar çoğu zaman yeterlidir.',
      'Dikkat dağıtan eşyaları azaltmak, odaklanmayı destekler. Telefon bildirimlerini kapatmak veya ayrı bir alanda tutmak da etkili olabilir.',
      'Alanını kişiselleştirirken işlevi öncele. Sana iyi gelen ama gözünü yormayan birkaç detay yeterli olur.',
    ],
  ),
  _BlogPost(
    category: 'Giyim',
    title: 'Kapsül gardırop fikri',
    summary: 'Az parça ile daha kolay kombin yapmanın temel mantığı.',
    paragraphs: [
      'Kapsül gardırop, çok az kıyafetle yaşamak zorunda olmak değildir. Birbiriyle uyumlu parçaları seçerek karar süresini azaltma yaklaşımıdır.',
      'Nötr renkler, iyi oturan temel parçalar ve mevsime uygun katmanlar kombin yapmayı kolaylaştırır.',
      'Yeni parça almadan önce mevcut gardırobunda hangi eksik rolü tamamlayacağını düşünmek gereksiz alışverişi azaltır.',
    ],
  ),
  _BlogPost(
    category: 'Giyim',
    title: 'Kıyafet bakımında uzun ömür',
    summary:
        'Sevdiğin parçaları daha uzun kullanmak için basit bakım önerileri.',
    paragraphs: [
      'Kıyafetlerin ömrü çoğu zaman yıkama ve saklama alışkanlıklarıyla belirlenir. Etiket talimatlarına uymak küçük ama etkili bir adımdır.',
      'Benzer renkleri birlikte yıkamak, düşük ısı kullanmak ve bazı parçaları ters çevirerek yıkamak yıpranmayı azaltabilir.',
      'Daha az ama daha iyi bakılan kıyafet, hem bütçe hem de stil açısından daha verimli bir seçimdir.',
    ],
  ),
  _BlogPost(
    category: 'Bakım',
    title: 'Basit cilt bakım rutini',
    summary:
        'Temizleme, nemlendirme ve güneş korumasını temel alan sade rutin.',
    paragraphs: [
      'Cilt bakımında çok ürün kullanmak her zaman daha iyi sonuç vermez. Temizleme, nemlendirme ve güneş koruması çoğu rutinin temelidir.',
      'Yeni ürünleri aynı anda eklemek yerine tek tek denemek cildinin neye iyi tepki verdiğini anlamanı kolaylaştırır.',
      'Rutin sürdürülebilir olduğunda etkisi artar. Kısa ve uygulanabilir bir plan, karmaşık ama yarım kalan bir plandan daha değerlidir.',
    ],
  ),
  _BlogPost(
    category: 'Bakım',
    title: 'Kişisel bakımda haftalık plan',
    summary:
        'Bakımı zorunluluk değil, düzenli bir yenilenme alanı haline getirmek.',
    paragraphs: [
      'Haftalık bakım planı, kendine ayırdığın zamanı görünür kılar. Bu plan saç, cilt, dinlenme ve hareket gibi küçük başlıklardan oluşabilir.',
      'Her şeyi tek güne sıkıştırmak yerine haftaya yaymak daha sürdürülebilirdir. Böylece bakım rutini yorucu bir listeye dönüşmez.',
      'Amaç mükemmel görünmek değil, kendini daha düzenli ve iyi hissettiren bir ritim kurmaktır.',
    ],
  ),
];
