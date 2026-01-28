/*
	Copyright 2023 Take Control - Software & Infrastructure
*/

import 'package:bloc/bloc.dart';
import 'package:sync_client/config/gallery_refresh_state.dart';

class GalleryRefreshCubit extends Cubit<GalleryRefreshState> {
  GalleryRefreshCubit() : super(const GalleryRefreshState());

  void requestHomeRefresh() {
    emit(state.copyWith(homeNeedsRefresh: true));
  }

  void requestTrashRefresh() {
    emit(state.copyWith(trashNeedsRefresh: true));
  }

  void clearHomeRefresh() {
    if (state.homeNeedsRefresh) {
      emit(state.copyWith(homeNeedsRefresh: false));
    }
  }

  void clearTrashRefresh() {
    if (state.trashNeedsRefresh) {
      emit(state.copyWith(trashNeedsRefresh: false));
    }
  }
}
