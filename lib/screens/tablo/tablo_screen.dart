import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/puzzle_progress_service.dart';

class TabloScreen extends StatefulWidget {
  const TabloScreen({super.key});

  @override
  State<TabloScreen> createState() => _TabloScreenState();
}

class _TabloScreenState extends State<TabloScreen> {
  late Future<PuzzleProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  void _loadProgress() {
    _progressFuture = PuzzleProgressService(DatabaseService()).calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tablo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<PuzzleProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text('Tablo verileri yüklenemedi.'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar dene'),
                      onPressed: () => setState(_loadProgress),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final progress = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PuzzlePortrait(progress: progress),
              const SizedBox(height: 16),
              _ProgressCard(progress: progress),
              const SizedBox(height: 12),
              _SourceTile(
                title: 'Finans',
                value: progress.financePieces,
                subtitle: 'Aylık tasarruf oranında her %0,1 için 1 parça',
                icon: Icons.savings_outlined,
              ),
              _SourceTile(
                title: 'Yatırım',
                value: progress.investmentPieces,
                subtitle: 'Pozitif hisse karında her 1 birim için 1 parça',
                icon: Icons.trending_up,
              ),
              _SourceTile(
                title: 'Sağlık',
                value: progress.healthPieces,
                subtitle: 'Yağ oranı düşüşünde her %0,1 için 1 parça',
                icon: Icons.favorite_outline,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PuzzlePortrait extends StatelessWidget {
  const _PuzzlePortrait({required this.progress});

  final PuzzleProgress progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filledCells = (progress.progress * 225).floor();

    return AspectRatio(
      aspectRatio: 0.78,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomPaint(
                painter: _AtaturkPortraitPainter(
                  color: colorScheme.onSurface.withValues(alpha: 0.18),
                ),
              ),
            ),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 15,
              children: List.generate(225, (index) {
                final filled = index < filledCells;
                return Container(
                  margin: const EdgeInsets.all(0.5),
                  decoration: BoxDecoration(
                    color: filled
                        ? colorScheme.primary.withValues(alpha: 0.82)
                        : colorScheme.surface.withValues(alpha: 0.54),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final PuzzleProgress progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.progress * 100).toStringAsFixed(1);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${progress.visiblePieces} / ${progress.totalPieces} parça',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress.progress, minHeight: 10),
            const SizedBox(height: 8),
            Text(
              progress.completedBoards == 0
                  ? 'Atatürk portresi tamamlanıyor • %$percent'
                  : '${progress.completedBoards} tablo tamamlandı. Sıradaki manzara tablosu başlıyor.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final int value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          '$value',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _AtaturkPortraitPainter extends CustomPainter {
  const _AtaturkPortraitPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.27),
        width: size.width * 0.38,
        height: size.height * 0.26,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.28,
          size.height * 0.42,
          size.width * 0.44,
          size.height * 0.42,
        ),
        const Radius.circular(18),
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.25, size.height * 0.2)
        ..lineTo(size.width * 0.75, size.height * 0.2)
        ..lineTo(size.width * 0.66, size.height * 0.13)
        ..lineTo(size.width * 0.34, size.height * 0.13)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AtaturkPortraitPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
