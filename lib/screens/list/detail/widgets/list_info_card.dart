import 'package:flutter/material.dart';
import 'package:sixin_front/screens/list/detail/logic/list_detail_vm.dart';

class ListInfoCard extends StatelessWidget {
  final ListDetailVM vm;

  const ListInfoCard({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            'Detalles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: _buildSubtitle(),
          children: [
            if (vm.levels.isNotEmpty) ...[
              Text(
                'Nivel de juego',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vm.levels
                    .map((level) => Chip(label: Text(level)))
                    .toList(),
              ),
            ],

            if (vm.systems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Sistema de juego',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vm.systems
                    .map((system) => Chip(label: Text(system)))
                    .toList(),
              ),
            ],

            const SizedBox(height: 16),
            Text('Precio total', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(vm.totalPriceLabel ?? '-'),

            if (vm.description != null) ...[
              const SizedBox(height: 16),
              Text(
                'Descripción',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(vm.description!),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildSubtitle() {
    final parts = <String>[];

    if (vm.systems.isNotEmpty) {
      parts.add(vm.systems.join(', '));
    }

    if (vm.levels.isNotEmpty) {
      parts.add(vm.levels.join(', '));
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
