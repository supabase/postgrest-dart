import 'package:postgrest/postgrest.dart';

class ResetHelper {
  late final PostgrestClient _postgrest;

  late final List<Map<String, dynamic>> _users;
  late final List<Map<String, dynamic>> _channels;
  late final List<Map<String, dynamic>> _messages;
  late final List<Map<String, dynamic>> _reactions;

  Future<void> initialize(PostgrestClient postgrest) async {
    _postgrest = postgrest;
    _users = List<Map<String, dynamic>>.from(
      (await _postgrest.from('users').select()) as List,
    );
    _channels = List<Map<String, dynamic>>.from(
      (await _postgrest.from('channels').select()) as List,
    );
    _messages = List<Map<String, dynamic>>.from(
      (await _postgrest.from('messages').select()) as List,
    );
    _reactions = List<Map<String, dynamic>>.from(
      (await _postgrest.from('reactions').select()) as List,
    );
  }

  Future<void> reset() async {
    await _postgrest.from("reactions").delete().neq("emoji", "dne");
    await _postgrest.from('messages').delete().neq('message', 'dne');
    await _postgrest.from('channels').delete().neq('slug', 'dne');
    await _postgrest.from('users').delete().neq('username', 'dne');
    try {
      await _postgrest.from('users').insert(_users);
    } on PostgrestException catch (exception) {
      throw 'users table was not properly reset. $exception';
    }

    try {
      await _postgrest.from('channels').insert(_channels);
    } on PostgrestException catch (exception) {
      throw 'channels table was not properly reset. $exception';
    }
    try {
      await _postgrest.from('messages').insert(_messages);
    } on PostgrestException catch (exception) {
      throw 'messages table was not properly reset. $exception';
    }

    try {
      await _postgrest.from('reactions').insert(_reactions);
    } on PostgrestException catch (exception) {
      throw 'reactions table was not properly reset. $exception';
    }
  }
}
