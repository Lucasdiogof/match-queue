import 'dart:async';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_detail_sheet.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_face.dart';
import 'package:flutter/material.dart';

/// Catalogo de cartas para consulta -- explicitamente NAO e o picker do
/// Squad Builder: aqui tocar numa carta abre o detalhe, nunca seleciona nada
/// nem devolve valor pra uma tela anterior.
///
/// [clubId] fixa a tela nas cartas de um clube. Sempre por id: 42 nomes de
/// clube existem nos dois generos, e filtrar por nome traria os dois.
class CardsCatalogPage extends StatelessWidget {
  const CardsCatalogPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(title: context.l10n.catalogCardsTitle),
    body: const AppBackground(dense: true, child: CardsCatalogView()),
  );
}

/// So o corpo: busca, filtros e grade. Sem Scaffold nem AppBar de proposito
/// -- o detalhe do clube embute isto sob o proprio cabecalho, e uma pagina
/// inteira aninhada ali empilhava duas barras e escondia o botao voltar.
class CardsCatalogView extends StatefulWidget {
  const CardsCatalogView({this.clubId, super.key});

  final String? clubId;

  @override
  State<CardsCatalogView> createState() => _CardsCatalogViewState();
}

class _CardsCatalogViewState extends State<CardsCatalogView> {
  static const List<String> _positions = <String>[
    'GK',
    'CB',
    'LB',
    'RB',
    'CDM',
    'CM',
    'CAM',
    'LM',
    'RM',
    'LW',
    'RW',
    'ST',
  ];

  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  Timer? _debounce;
  List<PlayerCard> _cards = <PlayerCard>[];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  AppFailure? _failure;

  String? _position;
  int? _minRating;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400 &&
        _hasMore &&
        !_isLoadingMore &&
        !_isLoading) {
      unawaited(_loadMore());
    }
  }

  PlayerCardQuery _query({int offset = 0}) => PlayerCardQuery(
    query: _search.text.trim().isEmpty ? null : _search.text.trim(),
    position: _position,
    minRating: _minRating,
    gender: _gender,
    clubId: widget.clubId,
    limit: 30,
    offset: offset,
  );

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });
    try {
      final page = await getIt<PlayerCardCatalogRepository>().searchCards(
        _query(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _cards = page.items;
        _hasMore = page.hasMore;
        _isLoading = false;
      });
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _failure = failure;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final page = await getIt<PlayerCardCatalogRepository>().searchCards(
        _query(offset: _cards.length),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _cards = <PlayerCard>[..._cards, ...page.items];
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } on AppFailure {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  /// Digitar dispara uma busca por vez, nao uma por tecla.
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_load());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          label: l10n.catalogCardsSearchLabel,
          hintText: l10n.catalogCardsSearchHint,
          controller: _search,
          prefixIcon: Icons.search,
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        _Filters(
          position: _position,
          minRating: _minRating,
          gender: _gender,
          // Dentro de um clube o genero ja esta determinado pela liga
          // dele -- oferecer o filtro ali so criaria combinacao vazia.
          showGender: widget.clubId == null,
          positions: _positions,
          onPosition: (value) {
            setState(() => _position = value);
            unawaited(_load());
          },
          onMinRating: (value) {
            setState(() => _minRating = value);
            unawaited(_load());
          },
          onGender: (value) {
            setState(() => _gender = value);
            unawaited(_load());
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoading) {
      return const AppLoading();
    }
    final failure = _failure;
    if (failure != null) {
      return AppErrorState(
        title: l10n.errorUnexpected,
        message: failure.localizedMessage(l10n),
        retryLabel: l10n.actionRetry,
        onRetry: () => unawaited(_load()),
      );
    }
    if (_cards.isEmpty) {
      return AppEmptyState(
        icon: Icons.style_outlined,
        title: l10n.catalogCardsEmptyTitle,
        message: l10n.catalogCardsEmptyMessage,
      );
    }

    return GridView.builder(
      controller: _scroll,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 158,
        childAspectRatio: 0.72,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: _cards.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _cards.length) {
          return const Center(child: AppLoading.inline());
        }
        final card = _cards[index];
        return PlayerCardFace(
          card: card,
          onTap: () => showPlayerCardDetailSheet(context: context, card: card),
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.position,
    required this.minRating,
    required this.gender,
    required this.showGender,
    required this.positions,
    required this.onPosition,
    required this.onMinRating,
    required this.onGender,
  });

  final String? position;
  final int? minRating;
  final String? gender;
  final bool showGender;
  final List<String> positions;
  final ValueChanged<String?> onPosition;
  final ValueChanged<int?> onMinRating;
  final ValueChanged<String?> onGender;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          AppChip(
            label: l10n.filterAll,
            isSelected: position == null && minRating == null && gender == null,
            onPressed: () {
              onPosition(null);
              onMinRating(null);
              onGender(null);
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          for (final value in <int>[85, 80, 75])
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: AppChip(
                label: '$value+',
                isSelected: minRating == value,
                onPressed: () => onMinRating(minRating == value ? null : value),
              ),
            ),
          if (showGender) ...<Widget>[
            AppChip(
              label: l10n.catalogGenderWomen,
              isSelected: gender == 'FEMALE',
              onPressed: () => onGender(gender == 'FEMALE' ? null : 'FEMALE'),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppChip(
              label: l10n.catalogGenderMen,
              isSelected: gender == 'MALE',
              onPressed: () => onGender(gender == 'MALE' ? null : 'MALE'),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          for (final code in positions)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: AppChip(
                label: code,
                isSelected: position == code,
                onPressed: () => onPosition(position == code ? null : code),
              ),
            ),
        ],
      ),
    );
  }
}
