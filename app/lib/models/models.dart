enum Exchange {
  Binance
}

enum TimeFrame {
  Minute,
  FiveMinutes,
  ThirtyMinutes,
  Hour,
  SixHours,
  Day,
  Week,
  Month
}

class Asset {
  String symbol;
  String name;
  bool fiat;

  Asset(this.symbol, this.name, this.fiat);

  Asset.fromJson(Map<String, dynamic> json)
      : symbol = json['symbol'] ?? '',
        name = json['name'] ?? '',
        fiat = json['fiat'] ?? false;

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name': name,
        'fiat': fiat,
      };

  @override
  String toString() {
    return 'Asset{symbol: $symbol, name: $name, fiat: $fiat}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Asset &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol;

  @override
  int get hashCode => symbol.hashCode;
}

class Pair implements Comparable<Pair> {
  String symbol;
  Asset base;
  Asset quote;

  Pair(this.symbol, this.base, this.quote);

  Pair.fromJson(Map<String, dynamic> json)
      : symbol = json['symbol'],
        base = Asset.fromJson(json['base']),
        quote = Asset.fromJson(json['quote']);

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'base': base.toJson(),
        'quote': quote.toJson()
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pair &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol;

  @override
  int get hashCode => symbol.hashCode;

  @override
  int compareTo(Pair other) {
    return this.quote.symbol.compareTo(other.quote.symbol);
  }

  @override
  String toString() {
    return 'Pair{symbol: $symbol, base: $base, quote: $quote}';
  }
}

class Market implements Comparable<Market> {
  Exchange exchange;
  Pair pair;
  String volume;
  String volumeQuote;
  int row = 0;

  Market(this.exchange, this.pair, this.volume, this.volumeQuote);

  Market.fromJson(Map<String, dynamic> json)
      : exchange = Exchange.values.byName(json['exchange']),
        pair = Pair.fromJson(json['pair']),
        volume = json['volume'] ?? '0',
        volumeQuote = json['volumeQuote'] ?? '0',
        row = json['row'] ?? 0;

  Map<String, dynamic> toJson() =>
      {'exchange': exchange.name, 'pair': pair.toJson(), 'volume': volume, 'volumeQuote': volumeQuote, 'row': row};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Market &&
          runtimeType == other.runtimeType &&
          exchange == other.exchange &&
          pair == other.pair;

  @override
  int get hashCode => Object.hash(exchange, pair);

  @override
  int compareTo(Market other) {
    if (double.parse(this.volumeQuote) > double.parse(other.volumeQuote)) {
      return -1;
    } else if (double.parse(this.volumeQuote) < double.parse(other.volumeQuote)) {
      return 1;
    }
    return 0;
  }

  @override
  String toString() {
    return 'Market{exchange: $exchange, pair: $pair, volume: $volume, volumeQuote: $volumeQuote, row: $row}';
  }
}
