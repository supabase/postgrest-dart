import 'package:postgrest/postgrest.dart';

class ResetHelper {
  late final PostgrestClient _postgrest;

  late final PostgrestList _users;
  late final PostgrestList _channels;
  late final PostgrestList _messages;
  late final PostgrestList _reactions;

  Future<void> initialize(PostgrestClient postgrest) async {
    _postgrest = postgrest;
    _users = (await _postgrest.from<PostgrestList>('users').select());
    _channels = await _postgrest.from<PostgrestList>('channels').select();
    _messages = await _postgrest.from<PostgrestList>('messages').select();
    _reactions = await _postgrest.from<PostgrestList>('reactions').select();
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
