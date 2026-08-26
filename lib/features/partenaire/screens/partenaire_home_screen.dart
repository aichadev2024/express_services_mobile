import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/partenaire.dart';
import '../widgets/nouvelle_commande_partenaire_tab.dart';
import '../widgets/statistiques_commandes_tab.dart';
import '../widgets/stock_stats_tab.dart';
import '../widgets/suivi_partenaire_tab.dart';

class PartenaireHomeScreen extends StatelessWidget {
  final Partenaire partenaire;
  const PartenaireHomeScreen({super.key, required this.partenaire});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(partenaire.nom),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/partenaire'),
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Color(0xFFE11D48),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: [
              Tab(text: 'Nouvelle commande', icon: Icon(Icons.add_shopping_cart_outlined)),
              Tab(text: 'Mes Commandes', icon: Icon(Icons.bar_chart_rounded)),
              Tab(text: 'Suivi', icon: Icon(Icons.local_shipping_outlined)),
              Tab(text: 'Stock', icon: Icon(Icons.inventory_2_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            NouvelleCommandePartenaireTab(partenaire: partenaire),
            StatistiquesCommandesTab(partenaire: partenaire),
            SuiviPartenaireTab(partenaire: partenaire),
            StockStatsTab(partenaire: partenaire),
          ],
        ),
      ),
    );
  }
}
