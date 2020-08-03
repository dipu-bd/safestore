import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/utils/to_string.dart';

class LabelSelectScreen extends StatefulWidget {
  static Future<bool> show(BuildContext context, Set<String> selection) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        maintainState: true,
        builder: (_) => LabelSelectScreen(selection),
      ),
    );
  }

  final Set<String> selection;

  LabelSelectScreen(this.selection);

  @override
  State<StatefulWidget> createState() => _LabelSelectScreenState();
}

class _LabelSelectScreenState extends State<LabelSelectScreen> {
  final labelTextFocus = FocusNode();
  final labelText = TextEditingController(text: '');

  final labels = Set<String>();

  @override
  void initState() {
    super.initState();
    resetLabels();
  }

  void resetLabels() {
    final state = StoreBloc.of(context).state;
    labels.clear();
    labels.addAll(state.storage.labels());
    labels.addAll(widget.selection);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: buildTagInput(),
        ),
        body: labels.isEmpty
            ? Center(child: Text('No groups found'))
            : ListView(
                padding: EdgeInsets.all(12),
                children: <Widget>[
                  ...labels.map(buildLabel),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => handleDone(),
          child: Icon(Icons.done),
        ),
      ),
    );
  }

  Widget buildLabel(String label) {
    bool selected = widget.selection.contains(label);
    return ListTile(
      title: Text(label),
      leading: Icon(selected ? Icons.label : Icons.label_outline),
      onTap: () => handleToggle(label),
    );
  }

  Widget buildTagInput() {
    return TextField(
      controller: labelText,
      focusNode: labelTextFocus,
      onSubmitted: (label) => handleAdd(),
      decoration: InputDecoration(
        hintText: 'Add new label',
        border: InputBorder.none,
      ),
    );
  }

  void handleToggle(String label) {
    if (widget.selection.contains(label)) {
      widget.selection.remove(label);
    } else {
      widget.selection.add(label);
    }
    if (mounted) setState(() {});
  }

  void handleAdd() {
    final label = toTitleCase(labelText.text);
    labelText.clear();
    if (label.isNotEmpty) {
      labels.add(label);
      widget.selection.add(label);
      if (mounted) setState(() {});
    }
  }

  void handleDone() {
    Navigator.of(context).pop(true);
  }
}
