// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final files = [
    r"lib\core\network\api_client.dart",
    r"lib\core\network\api_interceptors.dart",
    r"lib\core\network\socket_client.dart",
    r"lib\core\services\auth_service.dart",
    r"lib\core\services\biometric_service.dart",
    r"lib\features\applications\data\models\application_model.dart",
    r"lib\features\chat\data\repositories\chat_repository.dart",
    r"lib\features\jobs\data\models\job_model.dart",
    r"lib\features\jobs\data\repositories\jobs_repository.dart",
    r"lib\features\jobs\presentation\providers\jobs_provider.dart",
    r"lib\features\reviews\data\repositories\review_repository.dart",
    r"lib\features\reviews\presentation\providers\reviews_provider.dart"
  ];
  for (final path in files) {
    if (!File(path).existsSync()) continue;
    var content = File(path).readAsStringSync();
    content = content.replaceAll("import 'package:flutter/foundation.dart';\n", "");
    content = content.replaceAll("import 'package:flutter/foundation.dart';\r\n", "");
    content = "import 'package:flutter/foundation.dart';\n$content";
    File(path).writeAsStringSync(content);
    print("Fixed \$path");
  }
}
