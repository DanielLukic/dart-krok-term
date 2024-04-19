part of '../types.dart';

class AlertTriggered extends BaseModel {
  final AlertData alert;
  final Price trigger;

  AlertTriggered(this.alert, this.trigger);

  @override
  List get fields => [alert, trigger];

  NotificationData asNotification() => NotificationData.now(
        alert.wsname,
        "price ${alert.mode} ${alert.price}: "
        "$trigger",
        ('select-pair', alert.wsname),
      );
}
