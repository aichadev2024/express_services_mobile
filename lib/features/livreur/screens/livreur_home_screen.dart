import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/commande.dart';
import '../../../models/statut_commande.dart';
import '../../auth/providers/auth_provider.dart';
import '../../commandes/providers/commande_providers.dart';
import '../../commandes/widgets/commande_card.dart';
import '../../partenaire/providers/reference_data_providers.dart';
import '../providers/livreur_providers.dart';

class LivreurHomeScreen extends ConsumerStatefulWidget {
  const LivreurHomeScreen({super.key});

  static const List<IconData> avatarIcons = [
    Icons.two_wheeler_rounded,
    Icons.person_pin_rounded,
    Icons.shield_outlined,
    Icons.directions_bike_rounded,
    Icons.face_rounded,
    Icons.account_circle_rounded,
  ];

  static const List<Color> avatarColors = [
    AppColors.primary,
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
  ];

  @override
  ConsumerState<LivreurHomeScreen> createState() => _LivreurHomeScreenState();
}

class _LivreurHomeScreenState extends ConsumerState<LivreurHomeScreen> {
  int _avatarIndex = 0;
  bool _enService = true;
  File? _customPhotoFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _customPhotoFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir les photos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final commandesAsync = ref.watch(livreurCommandesProvider);
    final filter = ref.watch(livreurStatutFilterProvider);

    final user = auth.user;
    final displayName = (user != null && (user.prenom.isNotEmpty || user.nom.isNotEmpty))
        ? '${user.prenom} ${user.nom}'.trim()
        : (auth.username != null ? 'Livreur ${auth.username}' : 'Espace Livreur');

    final avatarIcon = LivreurHomeScreen.avatarIcons[_avatarIndex % LivreurHomeScreen.avatarIcons.length];
    final avatarColor = LivreurHomeScreen.avatarColors[_avatarIndex % LivreurHomeScreen.avatarColors.length];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Pro avec dégradé Bleu Marine, Avatar & Statut
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D2149),
                    Color(0xFF1E293B),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar & Name (Tapping navigates to WhatsApp-style Profile screen)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/livreur/profile'),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: _customPhotoFile != null ? Colors.transparent : avatarColor,
                                      backgroundImage: _customPhotoFile != null
                                          ? FileImage(_customPhotoFile!)
                                          : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                                              ? NetworkImage(user.photoUrl!.startsWith('http') ? user.photoUrl! : '${ApiConfig.baseUrl}${user.photoUrl}') as ImageProvider
                                              : null),
                                      child: (_customPhotoFile == null && (user?.photoUrl == null || user!.photoUrl!.isEmpty))
                                          ? Icon(avatarIcon, color: Colors.white, size: 26)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _showAvatarPickerModal(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1D4ED8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),

                              // Infos Livreur (Nom et Prénom clairs)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 2,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _enService ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: _enService ? const Color(0xFF10B981) : Colors.orange,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 5,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _enService ? const Color(0xFF10B981) : Colors.orange,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _enService ? 'En service' : 'En pause',
                                                style: TextStyle(
                                                  color: _enService ? const Color(0xFF34D399) : Colors.orangeAccent,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Text(
                                          '• Livreur',
                                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Interrupteur Service & Bouton Déconnexion
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: _enService,
                              activeColor: const Color(0xFF10B981),
                              onChanged: (val) => setState(() => _enService = val),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFF87171), size: 22),
                            tooltip: 'Déconnexion',
                            onPressed: () => _confirmLogout(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cartes Statistiques KPI (Total, En Cours, Livrées)
                  commandesAsync.maybeWhen(
                    data: (commandes) => _buildStatsRow(commandes),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // 2. Bar de filtres de statut
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'Toutes',
                      selected: filter == null,
                      onTap: () => ref.read(livreurStatutFilterProvider.notifier).state = null,
                    ),
                    ...StatutCommande.values.map((s) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: s.label,
                            selected: filter == s.value,
                            onTap: () => ref.read(livreurStatutFilterProvider.notifier).state = s.value,
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // 3. Liste des commandes assignées
            Expanded(
              child: commandesAsync.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.navy),
                      SizedBox(height: 12),
                      Text('Chargement de vos courses...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
                error: (err, _) => _ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(livreurCommandesProvider),
                ),
                data: (commandes) {
                  if (commandes.isEmpty) {
                    return const _EmptyView();
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(livreurCommandesProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: commandes.length,
                      itemBuilder: (context, index) {
                        final commande = commandes[index];
                        return CommandeCard(
                          commande: commande,
                          onTap: () => context.push('/livreur/commande/${commande.id}'),
                          onEditQuartier: () => _editQuartier(context, ref, commande),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editQuartier(BuildContext context, WidgetRef ref, Commande commande) async {
    try {
      final quartiers = await ref.read(referenceDataRepositoryProvider).getQuartiers();
      if (!context.mounted) return;

      int? selectedQuartierId = commande.quartierId > 0 ? commande.quartierId : null;

      final newQuartierId = await showDialog<int>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Modifier le Quartier', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16)),
            content: StatefulBuilder(
              builder: (context, setState) {
                return DropdownButton<int>(
                  isExpanded: true,
                  value: selectedQuartierId,
                  hint: const Text('Sélectionner un quartier'),
                  items: quartiers.map((q) => DropdownMenuItem(
                    value: q.id,
                    child: Text('${q.nom} · ${q.tarifLivraison.toInt()} FCFA'),
                  )).toList(),
                  onChanged: (val) => setState(() => selectedQuartierId = val),
                );
              }
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, selectedQuartierId),
                child: const Text('Enregistrer')
              )
            ],
          );
        }
      );

      if (newQuartierId != null && newQuartierId != commande.quartierId) {
        if (!context.mounted) return;
        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)));
        
        await ref.read(commandeRepositoryProvider).changerQuartier(commande.id, newQuartierId);
        
        if (!context.mounted) return;
        Navigator.pop(context); // Close loading
        ref.invalidate(livreurCommandesProvider); // Refresh list
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quartier modifié avec succès', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (!context.mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context); // Close possibly opened dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger));
    }
  }

  Widget _buildStatsRow(List<Commande> commandes) {
    final total = commandes.length;
    final enCours = commandes.where((c) => c.statut == StatutCommande.enCours).length;
    final livrees = commandes.where((c) => c.statut == StatutCommande.livree).length;

    return Row(
      children: [
        Expanded(child: _buildKpiCard('Total Courses', '$total', Icons.assignment_outlined, const Color(0xFF3B82F6))),
        const SizedBox(width: 8),
        Expanded(child: _buildKpiCard('En Cours', '$enCours', Icons.directions_run_rounded, const Color(0xFFF59E0B))),
        const SizedBox(width: 8),
        Expanded(child: _buildKpiCard('Livrées', '$livrees', Icons.check_circle_outline_rounded, const Color(0xFF10B981))),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Photo de profil du livreur',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Définissez une vraie photo depuis votre téléphone ou un avatar',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 18),

                // Options Photo Réelle (Appareil photo & Galerie)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text(
                          'Appareil photo',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text(
                          'Galerie photo',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Ou avatars prédéfinis',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  ],
                ),
                const SizedBox(height: 14),

                // Avatars prédéfinis
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: List.generate(LivreurHomeScreen.avatarIcons.length, (index) {
                    final isSelected = _customPhotoFile == null && _avatarIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _customPhotoFile = null;
                          _avatarIndex = index;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.navy : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: LivreurHomeScreen.avatarColors[index],
                          child: Icon(
                            LivreurHomeScreen.avatarIcons[index],
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showChangePasswordModal(context);
                    },
                    icon: const Icon(Icons.lock_reset_rounded, color: AppColors.navy),
                    label: const Text(
                      'Changer mon mot de passe',
                      style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    String? errorMsg;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('Changer le mot de passe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 4),
                  const Text('Entrez votre mot de passe actuel puis définissez votre nouveau mot de passe.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  const SizedBox(height: 16),
                  if (errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorMsg!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: oldPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe actuel',
                      prefixIcon: Icon(Icons.lock_outline, size: 20),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      prefixIcon: Icon(Icons.lock_reset, size: 20),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le nouveau mot de passe',
                      prefixIcon: Icon(Icons.check_circle_outline, size: 20),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final oldP = oldPassCtrl.text.trim();
                              final newP = newPassCtrl.text.trim();
                              final confP = confirmPassCtrl.text.trim();

                              if (oldP.isEmpty || newP.isEmpty || confP.isEmpty) {
                                setModalState(() => errorMsg = 'Veuillez remplir tous les champs.');
                                return;
                              }
                              if (newP != confP) {
                                setModalState(() => errorMsg = 'Les nouveaux mots de passe ne correspondent pas.');
                                return;
                              }
                              if (newP.length < 6) {
                                setModalState(() => errorMsg = 'Le nouveau mot de passe doit contenir au moins 6 caractères.');
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                                errorMsg = null;
                              });

                              try {
                                await ref.read(authControllerProvider.notifier).changePassword(oldP, newP);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Mot de passe modifié avec succès !'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  isSubmitting = false;
                                  errorMsg = e.toString().replaceAll('ApiException: ', '');
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Enregistrer le nouveau mot de passe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/');
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.navy,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF475569),
        fontSize: 12,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
      ),
      side: BorderSide(color: selected ? AppColors.navy : const Color(0xFFCBD5E1)),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 52, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text('Aucune course assignée pour le moment', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 4),
          const Text('Tirez vers le bas pour rafraîchir la liste.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
