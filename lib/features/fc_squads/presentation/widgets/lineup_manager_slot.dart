import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/lineup_draft.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/squad_builder_cubit.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/manager_card_placeholder_asset.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/manager_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cardzinho do técnico, sobreposto no canto inferior direito do campo.
///
/// Fora dos 11 titulares de propósito, mas dentro do campo (não abaixo dele)
/// -- é um detalhe do elenco, não uma segunda seção com o mesmo peso visual
/// da escalação. Tocar abre o mesmo picker de sempre.
///
/// [size] vem de [SquadField], que sabe o tamanho real do campo -- o card
/// cresce/encolhe junto com ele em vez de ficar num tamanho fixo que sobra
/// em campos grandes e aperta em campos pequenos.
///
/// Sem técnico: ícone + "TÉCNICO" (rótulo genérico, é tudo que há pra
/// mostrar). Com técnico: some o rótulo -- o nome já diz o que é, repetir
/// "TÉCNICO" embaixo de um nome de verdade vira ruído -- e no lugar aparece
/// a liga selecionada, abreviada (a coluna não tem sigla própria, então
/// deriva das iniciais das palavras -- "Premier League" -> "PL").
///
/// Sem foto por decisão de DADO: `fc_managers.image_url` está vazia, e a
/// coluna é ambígua (não diz se guardaria carta ou retrato). O escudo de
/// [managerCardPlaceholderAsset] (mesma linguagem visual do placeholder de
/// jogador) ocupa esse espaço e some sozinho no dia em que a foto existir.
class LineupManagerCorner extends StatelessWidget {
  const LineupManagerCorner({
    required this.draft,
    required this.size,
    super.key,
  });

  final LineupDraft draft;
  final double size;

  static String _abbreviateLeague(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    if (words.length > 1) {
      final initials = words.map((w) => w[0]).join().toUpperCase();
      return initials.length > 4 ? initials.substring(0, 4) : initials;
    }
    if (words.isEmpty) {
      return '';
    }
    final word = words.first;
    return word.substring(0, word.length < 4 ? word.length : 4).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<SquadBuilderCubit>();
    final manager = draft.manager;
    final league = draft.managerLeague;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.borderSm,
        onTap: () async {
          final selection = await showManagerPickerSheet(
            context: context,
            currentManager: manager,
            currentLeague: league,
          );
          if (selection != null) {
            // So rascunho: o tecnico e a liga dele entram no mesmo save do
            // resto da escalacao.
            cubit.setManager(
              manager: selection.manager,
              league: selection.league,
            );
          }
        },
        child: SizedBox(
          width: size,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(managerCardPlaceholderAsset, fit: BoxFit.contain),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size * 0.12,
                    vertical: size * 0.08,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: manager == null
                        ? <Widget>[
                            Icon(
                              Icons.person_outline,
                              size: (size * 0.22).clamp(14.0, 22.0),
                              color: colors.textTertiary,
                            ),
                            SizedBox(height: size * 0.04),
                            Text(
                              l10n.squadManagerLabel.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: context.textStyles.labelSmall?.copyWith(
                                color: colors.textTertiary,
                                fontSize: (size * 0.10).clamp(8.0, 10.0),
                                letterSpacing: 0.6,
                                height: 1,
                              ),
                            ),
                          ]
                        : <Widget>[
                            Text(
                              manager.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              // Branco fixo, não colors.textPrimary: o fundo do
                              // card (managerCardPlaceholderAsset) é sempre
                              // escuro nos dois temas, então um texto que segue
                              // o tema (escuro no light mode) ficava ilegível
                              // em cima dele.
                              style: context.textStyles.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: (size * 0.105).clamp(8.5, 11.0),
                                height: 1.05,
                              ),
                            ),
                            if (league != null) ...<Widget>[
                              SizedBox(height: size * 0.03),
                              Text(
                                _abbreviateLeague(league.name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: (size * 0.095).clamp(8.0, 10.0),
                                  letterSpacing: 0.4,
                                  height: 1,
                                ),
                              ),
                            ],
                          ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
