import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/nouvelle_commande_particulier_tab.dart';
import '../widgets/suivi_particulier_tab.dart';

class ParticulierHomeScreen extends StatelessWidget {
  const ParticulierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Particulier'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Déposer une commande', icon: Icon(Icons.add_box_outlined)),
              Tab(text: 'Suivre ma commande', icon: Icon(Icons.local_shipping_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NouvelleCommandeParticulierTab(),
            SuiviParticulierTab(),
          ],
        ),
      ),
    );
  }
}
