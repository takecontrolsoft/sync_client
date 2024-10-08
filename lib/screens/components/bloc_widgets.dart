import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

StatefulWidget reactiveBuilder<B extends StateStreamable<S>, S>(
    {required BlocWidgetBuilder<S> child,
    BlocBuilderCondition<S>? buildWhen,
    BlocWidgetListener<S>? listener}) {
  return BlocConsumer<B, S>(
      listener: (context, state) =>
          listener == null ? {} : listener(context, state),
      buildWhen: (previous, current) =>
          buildWhen == null ? true : buildWhen(previous, current),
      builder: (context, state) => child(context, state));
}
