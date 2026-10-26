import 'package:crypto_matrix/models/bluetooth.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/material.dart';

class BluetoothIndicatorWidget extends StatefulWidget {
  @override
  _BluetoothIndicatorWidgetState createState() =>
      _BluetoothIndicatorWidgetState();
}

class _BluetoothIndicatorWidgetState extends State<BluetoothIndicatorWidget> {
  final BltCom _bltCom = BltCom.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DeviceConnectionState>(
        stream: this._bltCom.state(),
        builder: (BuildContext context,
            AsyncSnapshot<DeviceConnectionState> snapshot) {
          var text = 'Not Connected';
          var color = Colors.red;
          if (snapshot.hasData) {
            switch (snapshot.data!) {
              case DeviceConnectionState.BLUETOOTH_DISABLED:
                text = 'Bluetooth disabled';
                color = Colors.red;
                break;
              case DeviceConnectionState.NOT_CONNECTED:
                // Do nothing as its the default value
                break;
              case DeviceConnectionState.CONNECTING:
                text = 'Connecting to device';
                color = Colors.yellow;
                break;
              case DeviceConnectionState.CONNECTED_WITHOUT_WIFI:
                text = 'No Wi-Fi';
                color = Colors.yellow;
                break;
              case DeviceConnectionState.CONNECTED:
                text = 'Connected';
                color = Colors.green;
                break;
            }
          }
          return Row(
            children: <Widget>[
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Container(
                  width: 14.0,
                  height: 14.0,
                  margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.5),
                        spreadRadius: 1,
                        blurRadius: 4,
                        // offset: Offset(0, 5), // changes position of shadow
                      ),
                    ],
                    shape: BoxShape.circle,
                    color: color,
                  )),
            ],
          );
        });
  }
}
