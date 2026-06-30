class RecebeDadosApiModel {
  final int? id;
  final String? operationDateTime;
  final String? releaseDateTIme;
  final String? movementType;
  final String? paymentId;
  final String? local;
  final String? chargeMethod;
  final String? paymentMethodDetail;
  final String? paymentMethod;
  final double? grossValue;
  final double? salesDiscounts;
  final double? net;
  final double? porcentagem;

  const RecebeDadosApiModel({
    this.id,
    this.operationDateTime,
    this.releaseDateTIme,
    this.movementType,
    this.paymentId,
    this.local,
    this.chargeMethod,
    this.paymentMethodDetail,
    this.paymentMethod,
    this.grossValue,
    this.salesDiscounts,
    this.net,
    this.porcentagem,
  });

  factory RecebeDadosApiModel.fromJson(Map<String, dynamic> json) {
    return RecebeDadosApiModel(
      id: json['id'] as int?,
      operationDateTime: json['OPERATION_DATE_TIME'] as String?,
      releaseDateTIme: json['RELEASE_DATE_TIME'] as String?,
      movementType: json['MOVEMENT_TYPE'] as String?,
      paymentId: json['PAYMENT_ID'] as String?,
      local: json['LOCAL'] as String?,
      chargeMethod: json['CHARGE_METHOD'] as String?,
      paymentMethodDetail: json['PAYMENT_METHOD_DETAIL'] as String?,
      paymentMethod: json['PAYMENT_METHOD'] as String?,
      grossValue: (json['GROSS_VALUE'] as num?)?.toDouble(),
      salesDiscounts: (json['SALES_DISCOUNTS'] as num?)?.toDouble(),
      net: (json['NET'] as num?)?.toDouble(),
      porcentagem: (json['PORCENTAGEM'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'OPERATION_DATE_TIME': operationDateTime,
      'RELEASE_DATE_TIME': releaseDateTIme,
      'MOVEMENT_TYPE': movementType,
      'PAYMENT_ID': paymentId,
      'LOCAL': local,
      'CHARGE_METHOD': chargeMethod,
      'PAYMENT_METHOD_DETAIL': paymentMethodDetail,
      'PAYMENT_METHOD': paymentMethod,
      'GROSS_VALUE': grossValue,
      'SALES_DISCOUNTS': salesDiscounts,
      'NET': net,
      'PORCENTAGEM': porcentagem,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
