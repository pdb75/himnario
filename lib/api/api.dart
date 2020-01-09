class VoicesApi {
  static String _base = 'http://104.131.104.212:5001';

  static String voicesAvaliable() => _base + '/availables';
  static String voiceAvailable(int number) => _base + '/$number/available';
  static String getVoice(int number, String voice) => _base + '/$number/$voice';
  static String getVoiceDuration(int number, String voice) => _base + '/$number/$voice/duration';
}

class SheetsApi {
  static String _base = 'http://104.131.104.212:5002';

  static String sheetAvailable(int number) => _base + '/$number/available';
  static String getSheet(int number) => _base + '/$number';
}

class DatabaseApi {
  static String _base = 'http://104.131.104.212:5003';

  static String getDb() => _base + '/db';
  static String checkUpdates() => _base + '/updates';
}