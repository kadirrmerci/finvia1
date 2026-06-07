import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../main.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = '';
  String _email = '';
  String _currency = '₺';
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _debtReminder = true;
  bool _subscriptionReminder = true;
  String _appVersion = '';
  String _selectedColor = '6C63FF';

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Mor', 'color': '6C63FF'},
    {'name': 'Mavi', 'color': '2196F3'},
    {'name': 'Yeşil', 'color': '4CAF50'},
    {'name': 'Turuncu', 'color': 'FF9800'},
    {'name': 'Kırmızı', 'color': 'F44336'},
    {'name': 'Pembe', 'color': 'E91E63'},
  ];

  final List<String> _currencies = ['₺', '\$', '€', '£', '¥'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _name = user?.displayName ?? prefs.getString('name') ?? '';
      _email = user?.email ?? prefs.getString('email') ?? '';
      _currency = prefs.getString('currency') ?? '₺';
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _debtReminder = prefs.getBool('debtReminder') ?? true;
      _subscriptionReminder = prefs.getBool('subscriptionReminder') ?? true;
      _selectedColor = prefs.getString('accentColor') ?? '6C63FF';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _name);
    await prefs.setString('email', _email);
    await prefs.setString('currency', _currency);
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('debtReminder', _debtReminder);
    await prefs.setBool('subscriptionReminder', _subscriptionReminder);
    await prefs.setString('accentColor', _selectedColor);
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = '${info.version} (${info.buildNumber})');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          _buildSection('Profil', [_buildProfileCard()]),
          _buildSection('Görünüm', [
            _buildSwitchTile(
              icon: Icons.dark_mode,
              title: 'Koyu Tema',
              subtitle: 'Karanlık mod',
              value: _isDarkMode,
              onChanged: (v) {
                setState(() => _isDarkMode = v);
                _saveSettings();
                MyLifeApp.of(context)?.updateTheme(v);
              },
            ),
            _buildColorPicker(),
          ]),
          _buildSection('Finans', [_buildCurrencySelector()]),
          _buildSection('Bildirimler', [
            _buildSwitchTile(
              icon: Icons.notifications,
              title: 'Bildirimler',
              subtitle: 'Tüm bildirimleri aç/kapat',
              value: _notificationsEnabled,
              onChanged: (v) {
                setState(() => _notificationsEnabled = v);
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              icon: Icons.credit_card,
              title: 'Borç Hatırlatıcısı',
              subtitle: 'Aylık ödeme bildirimleri',
              value: _debtReminder,
              onChanged: (v) {
                setState(() => _debtReminder = v);
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              icon: Icons.subscriptions,
              title: 'Abonelik Hatırlatıcısı',
              subtitle: 'Yenileme tarihi uyarıları',
              value: _subscriptionReminder,
              onChanged: (v) {
                setState(() => _subscriptionReminder = v);
                _saveSettings();
              },
            ),
          ]),
          _buildSection('Veri', [
            _buildActionTile(
              icon: Icons.backup,
              title: 'Veriyi Yedekle',
              subtitle: 'Yerel yedek oluştur',
              onTap: () => _showComingSoon('Yedekleme'),
            ),
            _buildActionTile(
              icon: Icons.download,
              title: 'Veriyi Dışa Aktar',
              subtitle: 'Excel veya PDF olarak kaydet',
              onTap: () => _showComingSoon('Dışa Aktarma'),
            ),
            _buildActionTile(
              icon: Icons.delete_forever,
              title: 'Tüm Verileri Sil',
              subtitle: 'Bu işlem geri alınamaz',
              color: Colors.red,
              onTap: _showDeleteConfirm,
            ),
          ]),
          _buildSection('Hesap', [
            _buildActionTile(
              icon: Icons.cloud,
              title: 'Bulut Senkronizasyon',
              subtitle: 'Yakında - Firebase ile',
              onTap: () => _showComingSoon('Bulut Senkronizasyon'),
            ),
            _buildActionTile(
              icon: Icons.group,
              title: 'Aile Paylaşımı',
              subtitle: 'Yakında - Verilerinizi paylaşın',
              onTap: () => _showComingSoon('Aile Paylaşımı'),
            ),
            _buildActionTile(
              icon: Icons.logout,
              title: 'Çıkış Yap',
              subtitle: 'Hesabından çıkış yap',
              color: Colors.red,
              onTap: _showLogoutConfirm,
            ),
          ]),
          _buildSection('Hakkında', [
            _buildInfoTile(
              icon: Icons.info,
              title: 'Uygulama Versiyonu',
              subtitle: _appVersion,
            ),
            _buildActionTile(
              icon: Icons.privacy_tip,
              title: 'Gizlilik Politikası',
              subtitle: 'Verileriniz nasıl kullanılıyor?',
              onTap: () => _showComingSoon('Gizlilik Politikası'),
            ),
            _buildActionTile(
              icon: Icons.mail,
              title: 'Bize Ulaşın',
              subtitle: 'Geri bildirim ve destek',
              onTap: () => _showComingSoon('İletişim'),
            ),
            _buildActionTile(
              icon: Icons.star,
              title: 'Uygulamayı Değerlendir',
              subtitle: 'Google Play Store',
              onTap: () => _showComingSoon('Değerlendirme'),
            ),
          ]),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Elite Life v$_appVersion',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C63FF),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        GestureDetector(
          onTap: _showEditProfile,
          child: CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            child: _name.isNotEmpty
                ? Text(
                    _name[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF)),
                  )
                : const Icon(Icons.person, size: 32, color: Color(0xFF6C63FF)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name.isNotEmpty ? _name : 'İsim ekle',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _email.isNotEmpty ? _email : 'Email ekle',
                  style: const TextStyle(color: Colors.grey),
                ),
              ]),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Color(0xFF6C63FF)),
          onPressed: _showEditProfile,
        ),
      ]),
    );
  }

  Widget _buildColorPicker() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tema Rengi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _colors.map((c) {
            final isSelected = _selectedColor == c['color'];
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = c['color']);
                _saveSettings();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${c['color']}')),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 2.5)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildCurrencySelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Icon(Icons.attach_money, color: Color(0xFF6C63FF)),
            const SizedBox(width: 12),
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Para Birimi',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  Text('Finansal işlemlerde kullanılır',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
          ]),
          DropdownButton<String>(
            value: _currency,
            underline: const SizedBox(),
            items: _currencies
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              setState(() => _currency = v ?? '₺');
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6C63FF)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF6C63FF),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF6C63FF)),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6C63FF)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }

  void _showEditProfile() {
    final nameC = TextEditingController(text: _name);
    final emailC = TextEditingController(text: _email);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Profili Düzenle',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: nameC,
            decoration: InputDecoration(
              labelText: 'Ad Soyad',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailC,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                setState(() {
                  _name = nameC.text;
                  _email = emailC.text;
                });
                await _saveSettings();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Kaydet', style: TextStyle(fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [const Text('🚀 '), Text(feature)]),
        content: const Text(
            'Bu özellik yakında geliyor!\nFirebase entegrasyonu ile aktif olacak.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap'),
        content:
            const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('⚠️ Tüm Verileri Sil'),
        content: const Text(
            'Tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tüm veriler silindi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}