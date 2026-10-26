import 'package:crypto_matrix/constants.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/util.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeTimeframeScreen extends StatefulWidget {

  final BltCom _bltCom = BltCom.instance;

  final String title;
  final List<TimeFrame> _timeframes = TimeFrame.values;

  ChangeTimeframeScreen({super.key, required this.title});

  @override
  _ChangeTimeframeScreenState createState() => _ChangeTimeframeScreenState();
}

class _ChangeTimeframeScreenState extends State<ChangeTimeframeScreen> {
  @override
  Widget build(BuildContext context) {
    // final args = ModalRoute.of(context).settings.arguments as ChangeTimeframeScreenArguments;
    // widget._itemSelectedCallback = args._itemSelected;

    return AdaptiveScaffold(
        appBar: AdaptiveAppBar(
          title: Text(widget.title),
        ),
        body: Material(
          child: ListView.builder(
              itemCount: widget._timeframes.length,
              itemBuilder: (context, index) {
                final TimeFrame timeframe = widget._timeframes[index];
                return ListTile(
                  title: Text(Util.formatTimeFrameLong(timeframe)),
                  onTap: () => _onTimeframeSelected(timeframe),
                );
              }),
        ));
  }

  Future<void> _onTimeframeSelected(TimeFrame timeframe) async {
    bool success = await widget._bltCom.setTimeframe(timeframe);

    if (success) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          SharedPreferencesConst.SETTINGS_TIMEFRAME, timeframe.index);
    } else {
      // TODO: Handle error
    }
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
    // TODO: Fix not updating
    // widget._itemSelectedCallback();
  }
}
