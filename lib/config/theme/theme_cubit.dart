import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({
    bool darkMode = false,
  }) : super(ThemeState(isDarkMode: darkMode));

  void toggleTheme() => emit(ThemeState(isDarkMode: !state.isDarkMode));
  void setDarkTheme() => emit(const ThemeState(isDarkMode: true));
  void setLightTheme() => emit(const ThemeState(isDarkMode: false));
}
