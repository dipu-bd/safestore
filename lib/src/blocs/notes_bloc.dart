import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safestore/src/models/note.dart';
import 'package:safestore/src/services/secure_storage.dart';

enum NoteEvent {
  notify,
  purge,
}

class NoteState {
  bool loading = false;
  bool saving = false;
  String loadError;
  String saveError;
  List<Note> notes;
  Note current;

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(Object other) => false;
}

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  NoteBloc() : super(NoteState());

  static NoteBloc of(BuildContext context) =>
      BlocProvider.of<NoteBloc>(context);

  @override
  Stream<NoteState> mapEventToState(NoteEvent event) async* {
    switch (event) {
      case NoteEvent.notify:
        yield state;
        break;
      case NoteEvent.purge:
        yield NoteState();
        break;
    }
  }

  void notify() {
    add(NoteEvent.notify);
  }

  void clear() {
    add(NoteEvent.purge);
  }

  Future<void> loadNotes() async {
    try {
      state.loading = true;
      state.loadError = null;
      notify();

      final all = await SecureStorage().listAll();
      state.notes = all.entries.map((e) {
        final data = json.decode(e.value);
        return Note()..fromJson(data);
      }).toList();
    } catch (err, stack) {
      log('$err', stackTrace: stack, name: '$this');
      state.loadError = '$err';
    } finally {
      state.loading = false;
      notify();
    }
  }

  Future<void> saveNote(Note note) async {
    try {
      state.saving = true;
      state.saveError = null;
      notify();

      await SecureStorage().save(note.toJson());
      state.notes ??= [];
      state.notes.removeWhere((e) => e.id == note.id);
      state.notes.add(note);
    } catch (err, stack) {
      log('$err', stackTrace: stack, name: '$this');
      state.saveError = '$err';
    } finally {
      state.saving = false;
      notify();
    }
  }

  Future<void> deleteNote(Note note) async {
    try {
      await SecureStorage().delete(note.id);
      state.notes?.removeWhere((e) => e.id == note.id);
    } catch (err, stack) {
      log('$err', stackTrace: stack, name: '$this');
    } finally {
      notify();
    }
  }
}
