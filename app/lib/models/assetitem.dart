import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'listitem.dart';

class AssetItem implements ListItem {
  final Asset asset;

  AssetItem(this.asset);

  @override
  Widget? buildTitle(BuildContext context, SetStateCallback callback) => Text(this.asset.symbol.toUpperCase());

  @override
  Widget? buildSubtitle(BuildContext context, SetStateCallback callback) => Text(this.asset.name);

  @override
  Widget? buildTrailing(BuildContext context, SetStateCallback callback) {
    return null;
  }
}
