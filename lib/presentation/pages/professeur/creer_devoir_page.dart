import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../themes/app_theme.dart';

class CreerDevoirPage extends StatefulWidget {
  const CreerDevoirPage({super.key});

  @override
  State<CreerDevoirPage> createState() => _CreerDevoirPageState();
}

class _CreerDevoirPageState extends State<CreerDevoirPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _type = 'devoir'; // devoir | examen | controle | tp
  String _matiere = 'Mathématiques';
  DateTime _dateRendu = DateTime.now().add(const Duration(days: 7));
  bool _renduEnLigne = false;
  bool _saving = false;

  static const _matieres = [
    'Mathématiques', 'Physique', 'Français',
    'Histoire', 'Anglais', 'SVT', 'Philosophie', 'Informatique',
  ];

  static const _types = [
    _TypeInfo('devoir',    'Devoir',    Icons.assignment_outlined,      Color(0xFF6366F1)),
    _TypeInfo('examen',    'Examen',    Icons.school_outlined,           Color(0xFFEF4444)),
    _TypeInfo('controle',  'Contrôle',  Icons.quiz_outlined,             Color(0xFFF59E0B)),
    _TypeInfo('tp',        'TP',        Icons.science_outlined,          Color(0xFF10B981)),
  ];

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final authState = context.read<AuthBloc>().state;
    final profId = authState is AuthAuthenticated
        ? authState.utilisateur.uid
        : '';

    final id = const Uuid().v4();
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.devoirsCollection)
          .doc(id)
          .set({
        'id': id,
        'titre': _titreCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'matiereId': _matiere,
        'type': _type,
        'classeId': '',
        'professeurId': profId,
        'datePublication': Timestamp.now(),
        'dateRendu': Timestamp.fromDate(_dateRendu),
        'renduEnLigne': _renduEnLigne,
        'pieceJointesUrls': [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_typeLabel(_type)} créé avec succès ✅'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
        _titreCtrl.clear();
        _descCtrl.clear();
        setState(() {
          _type = 'devoir';
          _dateRendu = DateTime.now().add(const Duration(days: 7));
          _renduEnLigne = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
    setState(() => _saving = false);
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'examen':   return 'Examen';
      case 'controle': return 'Contrôle';
      case 'tp':       return 'TP';
      default:         return 'Devoir';
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeInfo = _types.firstWhere((t) => t.value == _type);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sélecteur type ──────────────────────────────────────────
            const Text('Type',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: _types.map((t) {
                final sel = _type == t.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? t.color
                            : t.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel
                                ? t.color
                                : t.color.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(t.icon,
                              color: sel ? Colors.white : t.color,
                              size: 22),
                          const SizedBox(height: 4),
                          Text(t.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      sel ? Colors.white : t.color)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Formulaire ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: typeInfo.color.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                      color: typeInfo.color.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  // Titre
                  TextFormField(
                    controller: _titreCtrl,
                    decoration: InputDecoration(
                      labelText: 'Titre *',
                      prefixIcon: Icon(typeInfo.icon,
                          color: typeInfo.color, size: 20),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description / consignes',
                      prefixIcon: Icon(Icons.notes_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Matière
                  DropdownButtonFormField<String>(
                    value: _matiere,
                    decoration: const InputDecoration(
                      labelText: 'Matière',
                      prefixIcon: Icon(Icons.book_outlined),
                    ),
                    items: _matieres
                        .map((m) =>
                            DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _matiere = v!),
                  ),
                  const SizedBox(height: 14),

                  // Date de rendu
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateRendu,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                        locale: const Locale('fr'),
                      );
                      if (picked != null) {
                        setState(() => _dateRendu = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date limite',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        '${_dateRendu.day.toString().padLeft(2, '0')}/${_dateRendu.month.toString().padLeft(2, '0')}/${_dateRendu.year}',
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rendu en ligne
                  SwitchListTile(
                    value: _renduEnLigne,
                    onChanged: (v) => setState(() => _renduEnLigne = v),
                    title: const Text('Rendu en ligne',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    subtitle: const Text('L\'élève soumet via l\'app',
                        style: TextStyle(fontSize: 12)),
                    activeColor: typeInfo.color,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Bouton publier ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _enregistrer,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.publish_rounded, size: 18),
                label: Text(
                  _saving
                      ? 'Publication...'
                      : 'Publier le ${_typeLabel(_type).toLowerCase()}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeInfo.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Liste des devoirs publiés ────────────────────────────────
            const Text('Publiés récemment',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            _DevoirsPubliesList(),
          ],
        ),
      ),
    );
  }
}

// ── Liste des devoirs publiés par ce prof ─────────────────────────────────────
class _DevoirsPubliesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final profId = authState is AuthAuthenticated
        ? authState.utilisateur.uid
        : '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.devoirsCollection)
          .where('professeurId', isEqualTo: profId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final docs = snap.data!.docs;
        // Trier côté client par dateRendu
        docs.sort((a, b) {
          final da = (a.data() as Map)['dateRendu'] as Timestamp?;
          final db = (b.data() as Map)['dateRendu'] as Timestamp?;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun devoir publié pour l\'instant',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final dateRendu =
                (d['dateRendu'] as Timestamp?)?.toDate() ?? DateTime.now();
            final isExpired = DateTime.now().isAfter(dateRendu);
            final type = d['type'] as String? ?? 'devoir';

            Color typeColor;
            switch (type) {
              case 'examen':   typeColor = const Color(0xFFEF4444); break;
              case 'controle': typeColor = const Color(0xFFF59E0B); break;
              case 'tp':       typeColor = const Color(0xFF10B981); break;
              default:         typeColor = const Color(0xFF6366F1);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExpired
                    ? AppColors.background
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: typeColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      d['type']?.toString().toUpperCase() ?? 'DEVOIR',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: typeColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['titre'] ?? '',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isExpired
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                decoration: isExpired
                                    ? TextDecoration.lineThrough
                                    : null)),
                        Text(
                          '${d['matiereId']} • ${dateRendu.day}/${dateRendu.month}/${dateRendu.year}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Supprimer
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    onPressed: () => doc.reference.delete(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _TypeInfo {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _TypeInfo(this.value, this.label, this.icon, this.color);
}
