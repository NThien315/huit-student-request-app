import 'package:flutter/material.dart';

import 'pages/admin_categories_page.dart';
import 'pages/admin_maintenance_page.dart';
import 'pages/admin_overview_page.dart';
import 'pages/admin_requests_page.dart';
import 'pages/admin_roles_page.dart';
import 'widgets/admin_common.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_topbar.dart';

class AdminWebDashboard extends StatefulWidget {
  const AdminWebDashboard({super.key});

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: selectedIndex,
            onChanged: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                const AdminTopbar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: _buildPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (selectedIndex) {
      case 0:
        return const AdminOverviewPage();
      case 1:
        return const AdminRequestsPage();
      case 2:
        return const AdminCategoriesPage();
      case 3:
        return const AdminRolesPage();
      case 4:
        return const AdminMaintenancePage();
      default:
        return const AdminOverviewPage();
    }
  }
}
