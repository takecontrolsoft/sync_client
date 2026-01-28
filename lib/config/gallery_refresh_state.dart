/*
	Copyright 2023 Take Control - Software & Infrastructure
*/

import 'package:equatable/equatable.dart';

class GalleryRefreshState extends Equatable {
  const GalleryRefreshState({
    this.homeNeedsRefresh = false,
    this.trashNeedsRefresh = false,
  });

  final bool homeNeedsRefresh;
  final bool trashNeedsRefresh;

  GalleryRefreshState copyWith({
    bool? homeNeedsRefresh,
    bool? trashNeedsRefresh,
  }) {
    return GalleryRefreshState(
      homeNeedsRefresh: homeNeedsRefresh ?? this.homeNeedsRefresh,
      trashNeedsRefresh: trashNeedsRefresh ?? this.trashNeedsRefresh,
    );
  }

  @override
  List<Object?> get props => [homeNeedsRefresh, trashNeedsRefresh];
}
