import 'package:hive_ce/hive.dart';

import 'scan_record.dart';

class HistoryBox {
  static const String boxName = 'scan_history';

  static Box<ScanRecord> get box => Hive.box<ScanRecord>(boxName);
}
