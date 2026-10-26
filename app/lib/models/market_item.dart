import 'package:crypto_matrix/extensions.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'listitem.dart';

class MarketItem implements ListItem, Comparable<MarketItem> {
  final Market market;

  MarketItem(this.market);

  @override
  Widget? buildTitle(BuildContext context, SetStateCallback callback) => Text(this.market.pair.base.symbol.toUpperCase() + " / " + this.market.pair.quote.symbol.toUpperCase());

  @override
  Widget? buildSubtitle(BuildContext context, SetStateCallback callback) => Text(this.market.pair.base.name.capitalize());

  @override
  Widget? buildTrailing(BuildContext context, SetStateCallback callback) {
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketItem &&
          runtimeType == other.runtimeType &&
          market == other.market;

  @override
  int get hashCode => market.hashCode;

  @override
  int compareTo(MarketItem other) {
    return this.market.compareTo(other.market);
  }

  @override
  String toString() {
    return 'MarketItem{market: $market}';
  }
}
