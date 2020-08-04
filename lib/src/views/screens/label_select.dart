import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/utils/formattings.dart';

class LabelSelectScreen extends StatelessWidget {
  static Future show(BuildContext context, Set<String> selection) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        maintainState: true,
        builder: (_) => LabelSelectScreen(selection),
      ),
    );
  }

  final Set<String> selection;
  final labelTextFocus = FocusNode();
  final labelText = TextEditingController(text: '');
  final _changed = StreamController.broadcast();

  LabelSelectScreen(this.selection);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _changed.close();
        return true;
      },
      child: BlocBuilder<StoreBloc, StoreState>(
        builder: (context, state) {
          return SafeArea(
            top: false,
            child: Scaffold(
              appBar: AppBar(
                title: buildTagInput(context),
              ),
              body: buildBody(state.labels),
              floatingActionButton: FloatingActionButton(
                onPressed: () => handleDone(context),
                child: Icon(Icons.done),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildBody(Iterable<String> labels) {
    if (labels.isEmpty) {
      return Center(child: Text('No groups found'));
    }
    return ListView(
      padding: EdgeInsets.all(12),
      children: <Widget>[
        ...labels.map(buildLabel),
      ],
    );
  }

  Widget buildLabel(String label) {
    return StreamBuilder(
      stream: _changed.stream,
      builder: (context, snapshot) {
        bool selected = selection.contains(label);
        return ListTile(
          title: Text(label),
          leading: Icon(selected ? Icons.label : Icons.label_outline),
          onTap: () => handleToggle(label),
        );
      },
    );
  }

  Widget buildTagInput(BuildContext context) {
    return TextField(
      controller: labelText,
      focusNode: labelTextFocus,
      onSubmitted: (label) => handleAdd(context),
      decoration: InputDecoration(
        hintText: 'Add new label',
        border: InputBorder.none,
      ),
    );
  }

  void handleToggle(String label) {
    if (selection.contains(label)) {
      selection.remove(label);
    } else {
      selection.add(label);
    }
    _changed.sink.add(label);
  }

  void handleAdd(BuildContext context) {
    final label = toTitleCase(labelText.text);
    labelText.clear();
    if (label.isNotEmpty) {
      final state = StoreBloc.of(context).state;
      state.labels.add(label);
      selection.add(label);
      StoreBloc.of(context).notify();
    }
  }

  void handleDone(BuildContext context) {
    handleAdd(context);
    Navigator.of(context).pop(true);
  }
}
