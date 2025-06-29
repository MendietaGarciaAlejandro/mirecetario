import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mirecetario/features/recipes/presentation/recipes_screen.dart';
import 'package:mirecetario/features/meal_planner/presentation/meal_planner_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implementar búsqueda
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recetas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Menú',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Compras',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Mis Recetas';
      case 1:
        return 'Planificador de Menú';
      case 2:
        return 'Lista de Compras';
      default:
        return 'Mi Recetario';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const RecipesScreen();
      case 1:
        return const MealPlannerScreen();
      case 2:
        return const Center(child: Text('Lista de Compras'));
      default:
        return const SizedBox.shrink();
    }
  }
}
