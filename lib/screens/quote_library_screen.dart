import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/number_formatter.dart';
import '../utils/productivity_quotes.dart';

class QuoteLibraryScreen extends StatefulWidget {
  const QuoteLibraryScreen({super.key});

  @override
  State<QuoteLibraryScreen> createState() => _QuoteLibraryScreenState();
}

class _QuoteLibraryScreenState extends State<QuoteLibraryScreen> {
  String _category = 'all';

  String _catLabel(AppLocalizations l10n, String cat) {
    switch (cat) {
      case ProductivityQuotes.focus: return l10n.catFocus;
      case ProductivityQuotes.discipline: return l10n.catDiscipline;
      case ProductivityQuotes.work: return l10n.catWork;
      case ProductivityQuotes.success: return l10n.catSuccess;
      case ProductivityQuotes.consistency: return l10n.catConsistency;
      case ProductivityQuotes.learning: return l10n.catLearning;
    }
    return cat;
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case ProductivityQuotes.focus: return Icons.center_focus_strong_rounded;
      case ProductivityQuotes.discipline: return Icons.rule_rounded;
      case ProductivityQuotes.work: return Icons.schedule_rounded;
      case ProductivityQuotes.success: return Icons.emoji_events_rounded;
      case ProductivityQuotes.consistency: return Icons.all_inclusive_rounded;
      case ProductivityQuotes.learning: return Icons.school_rounded;
    }
    return Icons.format_quote_rounded;
  }

  void _showAddEditDialog({Map<String, String>? existing}) {
    final l10n = AppLocalizations.of(context);
    final isEdit = existing != null;
    final arCtrl = TextEditingController(text: existing?['ar'] ?? '');
    final enCtrl = TextEditingController(text: existing?['en'] ?? '');
    final authorCtrl = TextEditingController(text: existing?['author'] ?? '');
    String selectedCat = existing?['cat'] ?? ProductivityQuotes.focus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 14),
                      Text(isEdit ? l10n.editQuote : l10n.addQuote, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 16),
                      TextField(controller: arCtrl, textDirection: TextDirection.rtl, maxLines: 3, decoration: InputDecoration(labelText: l10n.quoteArabic, hintText: l10n.quoteArabicHint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      TextField(controller: enCtrl, maxLines: 3, decoration: InputDecoration(labelText: l10n.quoteEnglish, hintText: l10n.quoteEnglishHint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      TextField(controller: authorCtrl, decoration: InputDecoration(labelText: l10n.quoteAuthor, hintText: l10n.quoteAuthorHint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      Text(l10n.quoteCategory, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: ProductivityQuotes.categories.map((cat) {
                          final active = selectedCat == cat;
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedCat = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(_catIcon(cat), size: 14, color: active ? Colors.white : AppColors.primary),
                                const SizedBox(width: 5),
                                Text(_catLabel(l10n, cat), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.primary)),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () {
                          final ar = arCtrl.text.trim();
                          final en = enCtrl.text.trim();
                          if (ar.isEmpty) return;
                          final id = existing?['id'] ?? 'custom_${DateTime.now().millisecondsSinceEpoch}';
                          DatabaseService.saveQuote(id: id, ar: ar, en: en, cat: selectedCat, author: authorCtrl.text.trim());
                          Navigator.pop(ctx);
                        },
                        icon: Icon(isEdit ? Icons.check : Icons.add, size: 18),
                        label: Text(isEdit ? l10n.save : l10n.addQuote),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Map<String, String> q) {
    final l10n = AppLocalizations.of(context);
    final isCustom = q['id']?.startsWith('custom_') ?? false;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteQuote),
        content: Text(l10n.deleteQuoteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (isCustom) {
                DatabaseService.deleteCustomQuote(q['id']!);
              } else {
                DatabaseService.hideQuote(q['id']!);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chips = <(String, Widget)>[
      ('all', Icon(Icons.apps_rounded, size: 16, color: _category == 'all' ? Colors.white : AppColors.primary)),
      ...ProductivityQuotes.categories.map((c) => (
            c,
            Icon(_catIcon(c), size: 16, color: _category == c ? Colors.white : AppColors.primary),
          )),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(title: Text(l10n.quoteLibrary)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add, size: 20),
        label: Text(l10n.addQuote, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (cat, icon) = chips[i];
                final active = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? AppColors.primary : Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      icon,
                      const SizedBox(width: 6),
                      Text(cat == 'all' ? l10n.catAll : _catLabel(l10n, cat),
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: active ? Colors.white : isDark ? Colors.white70 : AppColors.textLight)),
                    ]),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: DatabaseService.customQuotesRevision,
              builder: (context, _, __) {
                final quotes = DatabaseService.getMergedQuotes(category: _category);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: quotes.length,
                  itemBuilder: (context, i) {
                    final q = quotes[i];
                    final text = ProductivityQuotes.textOf(q, l10n.isArabic);
                    final author = (q['author'] ?? '').isEmpty ? null : toArabicNumerals(q['author']!);
                    final isCustom = q['id']?.startsWith('custom_') ?? false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isCustom ? AppColors.primary.withValues(alpha: 0.35) : Colors.grey.withValues(alpha: 0.12),
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(_catIcon(q['cat']!), size: 15, color: AppColors.primary.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            Text(_catLabel(l10n, q['cat']!), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary.withValues(alpha: 0.8))),
                            if (isCustom) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                child: Text(l10n.custom, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 8),
                          Text('\u201E$text\u201C', style: TextStyle(fontSize: 14.5, height: 1.65, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textLight)),
                          if (author != null) ...[const SizedBox(height: 6), Text('\u2014 $author', style: TextStyle(fontSize: 12, color: Colors.grey[500]))],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _QuoteAction(icon: Icons.edit_outlined, color: AppColors.primary, onTap: () => _showAddEditDialog(existing: q)),
                              const SizedBox(width: 4),
                              _QuoteAction(icon: Icons.delete_outline_rounded, color: AppColors.error, onTap: () => _confirmDelete(q)),
                              const SizedBox(width: 4),
                              _QuoteAction(
                                icon: Icons.copy_rounded, color: Colors.grey[500]!,
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: text));
                                  HapticFeedback.selectionClick();
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copiedToClipboard), behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 900)));
                                },
                              ),
                              const SizedBox(width: 4),
                              _QuoteAction(icon: Icons.share_outlined, color: Colors.grey[500]!, onTap: () => Share.share(text)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuoteAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onTap, icon: Icon(icon, size: 20, color: color), visualDensity: VisualDensity.compact);
  }
}
