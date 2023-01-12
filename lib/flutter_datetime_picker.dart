library flutter_datetime_picker;

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_datetime_picker/src/datetime_picker_theme.dart';
import 'package:flutter_datetime_picker/src/date_model.dart';
import 'package:flutter_datetime_picker/src/i18n_model.dart';

export 'package:flutter_datetime_picker/src/datetime_picker_theme.dart';
export 'package:flutter_datetime_picker/src/date_model.dart';
export 'package:flutter_datetime_picker/src/i18n_model.dart';

typedef DateChangedCallback(DateTime time);
typedef DateCancelledCallback();
typedef String? StringAtIndexCallBack(int index);

class DatePicker {}

class DatePickerWidget extends DatePickerComponent {
  DatePickerWidget({
    Key? key,
    required pickerModel,
    onChanged,
    locale,
    reverse,
  }) : super(
            key: key,
            pickerModel: pickerModel,
            onChanged: onChanged,
            locale: locale,
            reverse: reverse);
}

class DatePickerComponent extends StatefulWidget {
  DatePickerComponent(
      {Key? key,
      required this.pickerModel,
      this.onChanged,
      this.locale,
      this.theme,
      this.reverse = false})
      : super(key: key) {
    this.theme = theme ?? DatePickerTheme();
  }

  final DateChangedCallback? onChanged;

  final LocaleType? locale;

  final BasePickerModel pickerModel;

  DatePickerTheme? theme;

  final bool? reverse;

  @override
  State<StatefulWidget> createState() {
    return DatePickerState();
  }
}

class DatePickerState extends State<DatePickerComponent> {
  late FixedExtentScrollController leftScrollCtrl,
      middleScrollCtrl,
      rightScrollCtrl;

  @override
  void initState() {
    super.initState();
    refreshScrollOffset();
  }

  void refreshScrollOffset() {
//    print('refreshScrollOffset ${widget.pickerModel.currentRightIndex()}');
    leftScrollCtrl = FixedExtentScrollController(
        initialItem: widget.pickerModel.currentLeftIndex());
    middleScrollCtrl = FixedExtentScrollController(
        initialItem: widget.pickerModel.currentMiddleIndex());
    rightScrollCtrl = FixedExtentScrollController(
        initialItem: widget.pickerModel.currentRightIndex());
  }

  @override
  Widget build(BuildContext context) {
    DatePickerTheme theme = widget.theme!;
    return GestureDetector(
        child: ClipRect(
            child: GestureDetector(
      child: Material(
        color: theme.backgroundColor,
        child: _renderPickerView(theme),
      ),
    )));
  }

  void _notifyDateChanged() {
    if (widget.onChanged != null) {
      widget.onChanged!(widget.pickerModel.finalTime()!);
    }
  }

  Widget _renderPickerView(DatePickerTheme theme) {
    Widget itemView = _renderItemView(theme);
    return itemView;
  }

  Widget _renderColumnView(
    ValueKey key,
    DatePickerTheme theme,
    StringAtIndexCallBack stringAtIndexCB,
    ScrollController scrollController,
    int layoutProportion,
    ValueChanged<int> selectedChangedWhenScrolling,
    ValueChanged<int> selectedChangedWhenScrollEnd,
  ) {
    return Expanded(
      flex: layoutProportion,
      child: Container(
        padding: EdgeInsets.all(8.0),
        height: theme.containerHeight,
        decoration: BoxDecoration(color: theme.backgroundColor),
        child: NotificationListener(
          onNotification: (ScrollNotification notification) {
            if (notification.depth == 0 &&
                notification is ScrollEndNotification &&
                notification.metrics is FixedExtentMetrics) {
              final FixedExtentMetrics metrics =
                  notification.metrics as FixedExtentMetrics;
              final int currentItemIndex = metrics.itemIndex;
              selectedChangedWhenScrollEnd(currentItemIndex);
            }
            return false;
          },
          child: CupertinoPicker.builder(
            key: key,
            backgroundColor: theme.backgroundColor,
            scrollController: scrollController as FixedExtentScrollController,
            itemExtent: theme.itemHeight,
            onSelectedItemChanged: (int index) {
              selectedChangedWhenScrolling(index);
            },
            useMagnifier: true,
            itemBuilder: (BuildContext context, int index) {
              final content = stringAtIndexCB(index);
              if (content == null) {
                return null;
              }
              return Container(
                height: theme.itemHeight,
                alignment: Alignment.center,
                child: Text(
                  content,
                  style: theme.itemStyle,
                  textAlign: TextAlign.start,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _renderItemView(DatePickerTheme theme) {
    final coulums = [
      Container(
        child: widget.pickerModel.layoutProportions()[0] > 0
            ? _renderColumnView(
                ValueKey(widget.pickerModel.currentLeftIndex()),
                theme,
                widget.pickerModel.leftStringAtIndex,
                leftScrollCtrl,
                widget.pickerModel.layoutProportions()[0], (index) {
                widget.pickerModel.setLeftIndex(index);
              }, (index) {
                setState(() {
                  refreshScrollOffset();
                  _notifyDateChanged();
                });
              })
            : null,
      ),
      Text(
        widget.pickerModel.leftDivider(),
        style: theme.itemStyle,
      ),
      Container(
        child: widget.pickerModel.layoutProportions()[1] > 0
            ? _renderColumnView(
                ValueKey(widget.pickerModel.currentLeftIndex()),
                theme,
                widget.pickerModel.middleStringAtIndex,
                middleScrollCtrl,
                widget.pickerModel.layoutProportions()[1], (index) {
                widget.pickerModel.setMiddleIndex(index);
              }, (index) {
                setState(() {
                  refreshScrollOffset();
                  _notifyDateChanged();
                });
              })
            : null,
      ),
      Text(
        widget.pickerModel.rightDivider(),
        style: theme.itemStyle,
      ),
      Container(
        child: widget.pickerModel.layoutProportions()[2] > 0
            ? _renderColumnView(
                ValueKey(widget.pickerModel.currentMiddleIndex() * 100 +
                    widget.pickerModel.currentLeftIndex()),
                theme,
                widget.pickerModel.rightStringAtIndex,
                rightScrollCtrl,
                widget.pickerModel.layoutProportions()[2], (index) {
                widget.pickerModel.setRightIndex(index);
              }, (index) {
                setState(() {
                  refreshScrollOffset();
                  _notifyDateChanged();
                });
              })
            : null,
      ),
    ].reversed.toList();
    return Container(
      color: theme.backgroundColor,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
              widget.reverse == true ? coulums.reversed.toList() : coulums,
        ),
      ),
    );
  }

  String _localeDone() {
    return i18nObjInLocale(widget.locale)['done'] as String;
  }

  String _localeCancel() {
    return i18nObjInLocale(widget.locale)['cancel'] as String;
  }
}
