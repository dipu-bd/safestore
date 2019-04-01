import 'package:flutter/material.dart';
import 'bloc_provider.dart';

class UserBloc extends BlocBase {
  static UserBloc of(BuildContext context) => BlocProvider.of(context);

  @override
  void initState(BuildContext context) {
    //
  }

  @override
  void dispose() {
    //
  }
}
