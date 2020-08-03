import 'package:flutter/material.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/models/group.dart';

class GroupChip extends StatelessWidget {
  final String groupId;

  GroupChip(this.groupId, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = StoreBloc.of(context).state;
    final group = store.storage.findGroup(groupId);
    if (group == null) return Container();
    return Card(
      child: buildContent(context, group),
      color: group.backColor ?? Colors.blueGrey,
      margin: EdgeInsets.only(
        top: 2,
        right: 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget buildContent(BuildContext context, Group group) {
    return InkWell(
      onTap: () => handleTap(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        child: Text(
          group.name,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.5,
            color: group.foreColor ?? Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void handleTap(context) {
    final store = StoreBloc.of(context).state;
    store.currentGroup = store.storage.findGroup(groupId);
    StoreBloc.of(context).notify();
  }
}
