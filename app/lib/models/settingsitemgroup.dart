import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:flutter/material.dart';

import 'listitem.dart';

class SettingsItemGroup implements ListItem {
  final String _header;
  final List<SettingsItem> _settingsItems;

  SettingsItemGroup(this._header, this._settingsItems);

  @override
  Widget? buildTitle(BuildContext context, SetStateCallback callback) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.only(top: 30, bottom: 10, left: 10),
              child: Text(
                this._header,
                style: Theme.of(context).textTheme.headlineMedium,
              )),
          Divider(
            height: 1,
            color: Colors.black,
          )
        ]);
  }

  @override
  Widget? buildSubtitle(BuildContext context, SetStateCallback callback) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: this._settingsItems.length,
      itemBuilder: (context, index) {
        final SettingsItem item = this._settingsItems[index];
        return GestureDetector(
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
            title: item.buildTitle(context, callback),
            subtitle: item.buildSubtitle(context, callback),
            trailing: item.buildTrailing(context, callback),
          ),
          onTap: () => item.onTap(context),
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }

  @override
  Widget? buildTrailing(BuildContext context, SetStateCallback callback) {
    return null;
  }
}
