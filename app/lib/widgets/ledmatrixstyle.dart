import 'package:carousel_slider/carousel_slider.dart';
import 'package:crypto_matrix/models/bluetooth.dart';
import 'package:crypto_matrix/util.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LedMatrixStyleWidget extends StatefulWidget {
  @override
  _LedMatrixStyleWidgetState createState() => _LedMatrixStyleWidgetState();
}

class _LedMatrixStyleWidgetState extends State<LedMatrixStyleWidget> {
  final BltCom _bltCom = BltCom.instance;

  final List<Widget> icons = [];
  int _current = 0;

  _LedMatrixStyleWidgetState() {
    this.icons.add(Image.asset("assets/coins/btc.png"));
    this.icons.add(Image.asset("assets/coins/eth.png"));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          StreamBuilder<DeviceConnectionState>(
            stream: this._bltCom.state(),
            builder: (BuildContext context,
                AsyncSnapshot<DeviceConnectionState> snapshot) {
              if (snapshot.hasData &&
                  snapshot.data == DeviceConnectionState.CONNECTED) {
                return CarouselSlider(
                    items: this.icons, options: _getCarouselOptions(true)
                );
              } else {
                return GestureDetector(
                  onTap: () {
                    Util.showNotConnectedAlert(context);
                  },
                  onHorizontalDragStart: (_) {
                    Util.showNotConnectedAlert(context);
                  },
                  child: CarouselSlider(
                      items: this.icons,
                      options: _getCarouselOptions(false)
                  ),
                );
              }
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: this.icons.map((url) {
              int index = this.icons.indexOf(url);
              return Container(
                width: 8.0,
                height: 8.0,
                margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 2.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _current == index
                      ? Color.fromRGBO(0, 0, 0, 0.9)
                      : Color.fromRGBO(0, 0, 0, 0.4),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  CarouselOptions _getCarouselOptions(bool enabled) {
    if (enabled) {
      return CarouselOptions(
          height: 180,
          onPageChanged: (index, reason) async {
            await this._updateDesign(index);
          }
      );
    } else {
      return CarouselOptions(
          height: 180,
          onPageChanged: null,
          scrollPhysics: NeverScrollableScrollPhysics()
      );
    }
  }

  Future<void> _updateDesign(int index) async {
    await this._bltCom.setDesign(new Design(Style.values[index]));
    //TODO: Handle success or not
    setState(() {
      _current = index;
    });
  }
}
