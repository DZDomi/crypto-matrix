import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:flutter/widgets.dart';

abstract class ListItem {
  Widget? buildTitle(BuildContext context, SetStateCallback callback);
  Widget? buildSubtitle(BuildContext context, SetStateCallback callback);
  Widget? buildTrailing(BuildContext context, SetStateCallback callback);
}
