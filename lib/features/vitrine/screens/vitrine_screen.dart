import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/express_logo.dart';
import '../../partenaire/providers/reference_data_providers.dart';
import '../../particulier/widgets/nouvelle_commande_particulier_tab.dart';
import '../../particulier/widgets/suivi_particulier_tab.dart';

class VitrineScreen extends ConsumerStatefulWidget {
  const VitrineScreen({super.key});

  @override
  ConsumerState<VitrineScreen> createState() => _VitrineScreenState();
}

class _VitrineScreenState extends ConsumerState<VitrineScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _trackingCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trackingCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        toolbarHeight: 65,
        titleSpacing: 12,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ExpressLogoHeader(iconSize: 32, isDarkBackground: true),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 24),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            tooltip: 'Connexion Espace Pro',
            onPressed: () => _showLoginPortalModal(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Hero Showcase Header Banner
            _buildHeroBanner(context),

            // 2. Interactive Navigation Tabs (Demander une livraison, Suivi, Tarifs)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFFE11D48),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFFE11D48),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.add_shopping_cart_rounded, size: 20), text: 'Demander une Livraison'),
                  Tab(icon: Icon(Icons.search_rounded, size: 20), text: 'Suivi de Colis'),
                  Tab(icon: Icon(Icons.calculate_outlined, size: 20), text: 'Tarifs par Quartier'),
                ],
              ),
            ),

            // TabBar Views
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  const NouvelleCommandeParticulierTab(),
                  const SuiviParticulierTab(),
                  _buildCalculateurTarifTab(context),
                ],
              ),
            ),

            // 3. Portal Entry Card for Partners & Delivery Agents
            _buildPortalAccessCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D2149),
            Color(0xFF070D1F),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: Color(0xFFE11D48), size: 16),
                SizedBox(width: 4),
                Text(
                  'EXPRESS SERVICES MALI',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white, height: 1.25),
              children: [
                TextSpan(text: 'La logistique des '),
                TextSpan(text: 'E-commerçants ', style: TextStyle(color: Color(0xFFE11D48))),
                TextSpan(text: 'à Bamako'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Confiez-nous vos livraisons et concentrez-vous sur vos ventes. EXPRESS SERVICES prend en charge vos commandes, vos colis et leur livraison jusqu’au client.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 16),

          // 4 Key Highlight Cards Scrollable / Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHeroStatCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Gestion des commandes',
                  subtitle: 'Centralisez vos livraisons',
                ),
                const SizedBox(width: 10),
                _buildHeroStatCard(
                  icon: Icons.local_shipping_outlined,
                  title: 'Livraison',
                  subtitle: 'Vos commandes livrées',
                ),
                const SizedBox(width: 10),
                _buildHeroStatCard(
                  icon: Icons.payments_outlined,
                  title: 'Encaissement',
                  subtitle: 'Paiements à la livraison',
                ),
                const SizedBox(width: 10),
                _buildHeroStatCard(
                  icon: Icons.bar_chart_rounded,
                  title: '📊 Suivi',
                  subtitle: 'Activité en temps réel',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: 135,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildCalculateurTarifTab(BuildContext context) {
    final quartiersAsync = ref.watch(quartiersProvider);

    return quartiersAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text('Chargement des tarifs par quartier...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ],
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.danger),
              const SizedBox(height: 12),
              const Text(
                'Erreur de chargement des tarifs',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                err.toString().replaceAll('ApiException: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(quartiersProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
      data: (quartiers) {
        if (quartiers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_outlined, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                const Text('Aucun quartier configuré.', style: TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(quartiersProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Rafraîchir'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quartiers.length,
          itemBuilder: (context, index) {
            final q = quartiers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                title: Text(q.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${q.tarifLivraison.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPortalAccessCard(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          const ExpressLogoHeader(iconSize: 44, isDarkBackground: true),
          const SizedBox(height: 10),
          const Text(
            'Vous êtes un partenaire commerçant ou un livreur ?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/partenaire/select'),
                  icon: const Icon(Icons.storefront, size: 18, color: Colors.white),
                  label: const Text('Accès Partenaire', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/livreur/login'),
                  icon: const Icon(Icons.shield_outlined, size: 18, color: Colors.white),
                  label: const Text('Espace Livreur', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLoginPortalModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Choisissez votre espace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.shield_outlined, color: AppColors.navy)),
                title: const Text('Espace Livreur', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Accès sécurisé pour la gestion des courses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/livreur/login');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFEF2F2), child: Icon(Icons.storefront, color: AppColors.primary)),
                title: const Text('Accès Espace Partenaire', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Consultez vos stocks et vos ventes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/partenaire/select');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
