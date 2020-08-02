import 'package:flutter/material.dart';
import 'package:safestore/src/services/crypto.dart';

abstract class Serializable {
  String _id;
  num _createTime;
  num _updateTime;
  bool _trashed = false;

  String get id => _id;

  bool get trashed => _trashed;

  DateTime get createTime => DateTime.fromMillisecondsSinceEpoch(_createTime);

  DateTime get updateTime => DateTime.fromMillisecondsSinceEpoch(_updateTime);

  set updateTime(DateTime time) => _updateTime = time.millisecondsSinceEpoch;

  Serializable() : this.id(Crypto.generateId());

  Serializable.id(this._id)
      : _createTime = DateTime.now().millisecondsSinceEpoch,
        _updateTime = DateTime.now().millisecondsSinceEpoch;

  @mustCallSuper
  void fromJson(Map<String, dynamic> data) {
    _id = data['id'];
    _trashed = data['trashed'];
    _createTime = data['create_time'];
    _updateTime = data['update_time'];
  }

  @mustCallSuper
  Map<String, dynamic> toJson() {
    final data = Map<String, dynamic>();
    data['id'] = _id;
    data['trashed'] = _trashed;
    data['create_time'] = _createTime;
    data['update_time'] = _updateTime;
    return data;
  }
}