// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) {
  return _OrderModel.fromJson(json);
}

/// @nodoc
mixin _$OrderModel {
  String get id => throw _privateConstructorUsedError;
  String? get orderNumber => throw _privateConstructorUsedError;
  String? get userId => throw _privateConstructorUsedError;
  String? get customerEmail => throw _privateConstructorUsedError;
  String? get shippingFullName => throw _privateConstructorUsedError;
  String? get shippingPhone => throw _privateConstructorUsedError;
  String? get shippingAddressLine1 => throw _privateConstructorUsedError;
  String? get shippingAddressLine2 => throw _privateConstructorUsedError;
  String? get shippingCity => throw _privateConstructorUsedError;
  String? get shippingState => throw _privateConstructorUsedError;
  String? get shippingPostalCode => throw _privateConstructorUsedError;
  String? get shippingCountry => throw _privateConstructorUsedError;
  double get subtotal => throw _privateConstructorUsedError;
  double get shippingCost => throw _privateConstructorUsedError;
  double get tax => throw _privateConstructorUsedError;
  double get discount => throw _privateConstructorUsedError;
  double get total => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get paymentMethod => throw _privateConstructorUsedError;
  String? get paymentStatus => throw _privateConstructorUsedError;
  String? get paymentId => throw _privateConstructorUsedError;
  String? get customerNotes => throw _privateConstructorUsedError;
  String? get adminNotes => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get updatedAt =>
      throw _privateConstructorUsedError; // Items embebidos
  List<OrderItemModel> get orderItems => throw _privateConstructorUsedError;

  /// Serializes this OrderModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderModelCopyWith<OrderModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderModelCopyWith<$Res> {
  factory $OrderModelCopyWith(
    OrderModel value,
    $Res Function(OrderModel) then,
  ) = _$OrderModelCopyWithImpl<$Res, OrderModel>;
  @useResult
  $Res call({
    String id,
    String? orderNumber,
    String? userId,
    String? customerEmail,
    String? shippingFullName,
    String? shippingPhone,
    String? shippingAddressLine1,
    String? shippingAddressLine2,
    String? shippingCity,
    String? shippingState,
    String? shippingPostalCode,
    String? shippingCountry,
    double subtotal,
    double shippingCost,
    double tax,
    double discount,
    double total,
    String status,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentId,
    String? customerNotes,
    String? adminNotes,
    String? createdAt,
    String? updatedAt,
    List<OrderItemModel> orderItems,
  });
}

/// @nodoc
class _$OrderModelCopyWithImpl<$Res, $Val extends OrderModel>
    implements $OrderModelCopyWith<$Res> {
  _$OrderModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = freezed,
    Object? userId = freezed,
    Object? customerEmail = freezed,
    Object? shippingFullName = freezed,
    Object? shippingPhone = freezed,
    Object? shippingAddressLine1 = freezed,
    Object? shippingAddressLine2 = freezed,
    Object? shippingCity = freezed,
    Object? shippingState = freezed,
    Object? shippingPostalCode = freezed,
    Object? shippingCountry = freezed,
    Object? subtotal = null,
    Object? shippingCost = null,
    Object? tax = null,
    Object? discount = null,
    Object? total = null,
    Object? status = null,
    Object? paymentMethod = freezed,
    Object? paymentStatus = freezed,
    Object? paymentId = freezed,
    Object? customerNotes = freezed,
    Object? adminNotes = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? orderItems = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            orderNumber: freezed == orderNumber
                ? _value.orderNumber
                : orderNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            userId: freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String?,
            customerEmail: freezed == customerEmail
                ? _value.customerEmail
                : customerEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            shippingFullName: freezed == shippingFullName
                ? _value.shippingFullName
                : shippingFullName // ignore: cast_nullable_to_non_nullable
                      as String?,
            shippingPhone: freezed == shippingPhone
                ? _value.shippingPhone
                : shippingPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            shippingAddressLine1: freezed == shippingAddressLine1
                ? _value.shippingAddressLine1
                : shippingAddressLine1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            shippingAddressLine2: freezed == shippingAddressLine2
                ? _value.shippingAddressLine2
                : shippingAddressLine2 // ignore: cast_nullable_to_non_nullable
                      as String?,
            shippingCity: freezed == shippingCity
                ? _value.shippingCity
                : shippingCity // ignore: cast_nullable_to_non_nullable
                      as String?,
            shippingState: freezed == shippingState
                ? _value.shippingState
                : shippingState // ignore: cast_nullable_to_non_nullable
                      as String?,
            shippingPostalCode: freezed == shippingPostalCode
                ? _value.shippingPostalCode
                : shippingPostalCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            shippingCountry: freezed == shippingCountry
                ? _value.shippingCountry
                : shippingCountry // ignore: cast_nullable_to_non_nullable
                      as String?,
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as double,
            shippingCost: null == shippingCost
                ? _value.shippingCost
                : shippingCost // ignore: cast_nullable_to_non_nullable
                      as double,
            tax: null == tax
                ? _value.tax
                : tax // ignore: cast_nullable_to_non_nullable
                      as double,
            discount: null == discount
                ? _value.discount
                : discount // ignore: cast_nullable_to_non_nullable
                      as double,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentMethod: freezed == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentStatus: freezed == paymentStatus
                ? _value.paymentStatus
                : paymentStatus // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentId: freezed == paymentId
                ? _value.paymentId
                : paymentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            customerNotes: freezed == customerNotes
                ? _value.customerNotes
                : customerNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            adminNotes: freezed == adminNotes
                ? _value.adminNotes
                : adminNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            orderItems: null == orderItems
                ? _value.orderItems
                : orderItems // ignore: cast_nullable_to_non_nullable
                      as List<OrderItemModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrderModelImplCopyWith<$Res>
    implements $OrderModelCopyWith<$Res> {
  factory _$$OrderModelImplCopyWith(
    _$OrderModelImpl value,
    $Res Function(_$OrderModelImpl) then,
  ) = __$$OrderModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? orderNumber,
    String? userId,
    String? customerEmail,
    String? shippingFullName,
    String? shippingPhone,
    String? shippingAddressLine1,
    String? shippingAddressLine2,
    String? shippingCity,
    String? shippingState,
    String? shippingPostalCode,
    String? shippingCountry,
    double subtotal,
    double shippingCost,
    double tax,
    double discount,
    double total,
    String status,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentId,
    String? customerNotes,
    String? adminNotes,
    String? createdAt,
    String? updatedAt,
    List<OrderItemModel> orderItems,
  });
}

/// @nodoc
class __$$OrderModelImplCopyWithImpl<$Res>
    extends _$OrderModelCopyWithImpl<$Res, _$OrderModelImpl>
    implements _$$OrderModelImplCopyWith<$Res> {
  __$$OrderModelImplCopyWithImpl(
    _$OrderModelImpl _value,
    $Res Function(_$OrderModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = freezed,
    Object? userId = freezed,
    Object? customerEmail = freezed,
    Object? shippingFullName = freezed,
    Object? shippingPhone = freezed,
    Object? shippingAddressLine1 = freezed,
    Object? shippingAddressLine2 = freezed,
    Object? shippingCity = freezed,
    Object? shippingState = freezed,
    Object? shippingPostalCode = freezed,
    Object? shippingCountry = freezed,
    Object? subtotal = null,
    Object? shippingCost = null,
    Object? tax = null,
    Object? discount = null,
    Object? total = null,
    Object? status = null,
    Object? paymentMethod = freezed,
    Object? paymentStatus = freezed,
    Object? paymentId = freezed,
    Object? customerNotes = freezed,
    Object? adminNotes = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? orderItems = null,
  }) {
    return _then(
      _$OrderModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        orderNumber: freezed == orderNumber
            ? _value.orderNumber
            : orderNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String?,
        customerEmail: freezed == customerEmail
            ? _value.customerEmail
            : customerEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        shippingFullName: freezed == shippingFullName
            ? _value.shippingFullName
            : shippingFullName // ignore: cast_nullable_to_non_nullable
                  as String?,
        shippingPhone: freezed == shippingPhone
            ? _value.shippingPhone
            : shippingPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        shippingAddressLine1: freezed == shippingAddressLine1
            ? _value.shippingAddressLine1
            : shippingAddressLine1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        shippingAddressLine2: freezed == shippingAddressLine2
            ? _value.shippingAddressLine2
            : shippingAddressLine2 // ignore: cast_nullable_to_non_nullable
                  as String?,
        shippingCity: freezed == shippingCity
            ? _value.shippingCity
            : shippingCity // ignore: cast_nullable_to_non_nullable
                  as String?,
        shippingState: freezed == shippingState
            ? _value.shippingState
            : shippingState // ignore: cast_nullable_to_non_nullable
                  as String?,
        shippingPostalCode: freezed == shippingPostalCode
            ? _value.shippingPostalCode
            : shippingPostalCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        shippingCountry: freezed == shippingCountry
            ? _value.shippingCountry
            : shippingCountry // ignore: cast_nullable_to_non_nullable
                  as String?,
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as double,
        shippingCost: null == shippingCost
            ? _value.shippingCost
            : shippingCost // ignore: cast_nullable_to_non_nullable
                  as double,
        tax: null == tax
            ? _value.tax
            : tax // ignore: cast_nullable_to_non_nullable
                  as double,
        discount: null == discount
            ? _value.discount
            : discount // ignore: cast_nullable_to_non_nullable
                  as double,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentMethod: freezed == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentStatus: freezed == paymentStatus
            ? _value.paymentStatus
            : paymentStatus // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentId: freezed == paymentId
            ? _value.paymentId
            : paymentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        customerNotes: freezed == customerNotes
            ? _value.customerNotes
            : customerNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        adminNotes: freezed == adminNotes
            ? _value.adminNotes
            : adminNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        orderItems: null == orderItems
            ? _value._orderItems
            : orderItems // ignore: cast_nullable_to_non_nullable
                  as List<OrderItemModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderModelImpl implements _OrderModel {
  const _$OrderModelImpl({
    required this.id,
    this.orderNumber,
    this.userId,
    this.customerEmail,
    this.shippingFullName,
    this.shippingPhone,
    this.shippingAddressLine1,
    this.shippingAddressLine2,
    this.shippingCity,
    this.shippingState,
    this.shippingPostalCode,
    this.shippingCountry,
    this.subtotal = 0,
    this.shippingCost = 0,
    this.tax = 0,
    this.discount = 0,
    this.total = 0,
    this.status = 'pending',
    this.paymentMethod,
    this.paymentStatus,
    this.paymentId,
    this.customerNotes,
    this.adminNotes,
    this.createdAt,
    this.updatedAt,
    final List<OrderItemModel> orderItems = const [],
  }) : _orderItems = orderItems;

  factory _$OrderModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderModelImplFromJson(json);

  @override
  final String id;
  @override
  final String? orderNumber;
  @override
  final String? userId;
  @override
  final String? customerEmail;
  @override
  final String? shippingFullName;
  @override
  final String? shippingPhone;
  @override
  final String? shippingAddressLine1;
  @override
  final String? shippingAddressLine2;
  @override
  final String? shippingCity;
  @override
  final String? shippingState;
  @override
  final String? shippingPostalCode;
  @override
  final String? shippingCountry;
  @override
  @JsonKey()
  final double subtotal;
  @override
  @JsonKey()
  final double shippingCost;
  @override
  @JsonKey()
  final double tax;
  @override
  @JsonKey()
  final double discount;
  @override
  @JsonKey()
  final double total;
  @override
  @JsonKey()
  final String status;
  @override
  final String? paymentMethod;
  @override
  final String? paymentStatus;
  @override
  final String? paymentId;
  @override
  final String? customerNotes;
  @override
  final String? adminNotes;
  @override
  final String? createdAt;
  @override
  final String? updatedAt;
  // Items embebidos
  final List<OrderItemModel> _orderItems;
  // Items embebidos
  @override
  @JsonKey()
  List<OrderItemModel> get orderItems {
    if (_orderItems is EqualUnmodifiableListView) return _orderItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_orderItems);
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, orderNumber: $orderNumber, userId: $userId, customerEmail: $customerEmail, shippingFullName: $shippingFullName, shippingPhone: $shippingPhone, shippingAddressLine1: $shippingAddressLine1, shippingAddressLine2: $shippingAddressLine2, shippingCity: $shippingCity, shippingState: $shippingState, shippingPostalCode: $shippingPostalCode, shippingCountry: $shippingCountry, subtotal: $subtotal, shippingCost: $shippingCost, tax: $tax, discount: $discount, total: $total, status: $status, paymentMethod: $paymentMethod, paymentStatus: $paymentStatus, paymentId: $paymentId, customerNotes: $customerNotes, adminNotes: $adminNotes, createdAt: $createdAt, updatedAt: $updatedAt, orderItems: $orderItems)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.customerEmail, customerEmail) ||
                other.customerEmail == customerEmail) &&
            (identical(other.shippingFullName, shippingFullName) ||
                other.shippingFullName == shippingFullName) &&
            (identical(other.shippingPhone, shippingPhone) ||
                other.shippingPhone == shippingPhone) &&
            (identical(other.shippingAddressLine1, shippingAddressLine1) ||
                other.shippingAddressLine1 == shippingAddressLine1) &&
            (identical(other.shippingAddressLine2, shippingAddressLine2) ||
                other.shippingAddressLine2 == shippingAddressLine2) &&
            (identical(other.shippingCity, shippingCity) ||
                other.shippingCity == shippingCity) &&
            (identical(other.shippingState, shippingState) ||
                other.shippingState == shippingState) &&
            (identical(other.shippingPostalCode, shippingPostalCode) ||
                other.shippingPostalCode == shippingPostalCode) &&
            (identical(other.shippingCountry, shippingCountry) ||
                other.shippingCountry == shippingCountry) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.shippingCost, shippingCost) ||
                other.shippingCost == shippingCost) &&
            (identical(other.tax, tax) || other.tax == tax) &&
            (identical(other.discount, discount) ||
                other.discount == discount) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.paymentId, paymentId) ||
                other.paymentId == paymentId) &&
            (identical(other.customerNotes, customerNotes) ||
                other.customerNotes == customerNotes) &&
            (identical(other.adminNotes, adminNotes) ||
                other.adminNotes == adminNotes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(
              other._orderItems,
              _orderItems,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    orderNumber,
    userId,
    customerEmail,
    shippingFullName,
    shippingPhone,
    shippingAddressLine1,
    shippingAddressLine2,
    shippingCity,
    shippingState,
    shippingPostalCode,
    shippingCountry,
    subtotal,
    shippingCost,
    tax,
    discount,
    total,
    status,
    paymentMethod,
    paymentStatus,
    paymentId,
    customerNotes,
    adminNotes,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_orderItems),
  ]);

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderModelImplCopyWith<_$OrderModelImpl> get copyWith =>
      __$$OrderModelImplCopyWithImpl<_$OrderModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderModelImplToJson(this);
  }
}

abstract class _OrderModel implements OrderModel {
  const factory _OrderModel({
    required final String id,
    final String? orderNumber,
    final String? userId,
    final String? customerEmail,
    final String? shippingFullName,
    final String? shippingPhone,
    final String? shippingAddressLine1,
    final String? shippingAddressLine2,
    final String? shippingCity,
    final String? shippingState,
    final String? shippingPostalCode,
    final String? shippingCountry,
    final double subtotal,
    final double shippingCost,
    final double tax,
    final double discount,
    final double total,
    final String status,
    final String? paymentMethod,
    final String? paymentStatus,
    final String? paymentId,
    final String? customerNotes,
    final String? adminNotes,
    final String? createdAt,
    final String? updatedAt,
    final List<OrderItemModel> orderItems,
  }) = _$OrderModelImpl;

  factory _OrderModel.fromJson(Map<String, dynamic> json) =
      _$OrderModelImpl.fromJson;

  @override
  String get id;
  @override
  String? get orderNumber;
  @override
  String? get userId;
  @override
  String? get customerEmail;
  @override
  String? get shippingFullName;
  @override
  String? get shippingPhone;
  @override
  String? get shippingAddressLine1;
  @override
  String? get shippingAddressLine2;
  @override
  String? get shippingCity;
  @override
  String? get shippingState;
  @override
  String? get shippingPostalCode;
  @override
  String? get shippingCountry;
  @override
  double get subtotal;
  @override
  double get shippingCost;
  @override
  double get tax;
  @override
  double get discount;
  @override
  double get total;
  @override
  String get status;
  @override
  String? get paymentMethod;
  @override
  String? get paymentStatus;
  @override
  String? get paymentId;
  @override
  String? get customerNotes;
  @override
  String? get adminNotes;
  @override
  String? get createdAt;
  @override
  String? get updatedAt; // Items embebidos
  @override
  List<OrderItemModel> get orderItems;

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderModelImplCopyWith<_$OrderModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrderItemModel _$OrderItemModelFromJson(Map<String, dynamic> json) {
  return _OrderItemModel.fromJson(json);
}

/// @nodoc
mixin _$OrderItemModel {
  String get id => throw _privateConstructorUsedError;
  String? get orderId => throw _privateConstructorUsedError;
  String? get productId => throw _privateConstructorUsedError;
  String? get productName => throw _privateConstructorUsedError;
  String? get productSlug => throw _privateConstructorUsedError;
  String? get productSku => throw _privateConstructorUsedError;
  String? get productImage => throw _privateConstructorUsedError;
  String? get size => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  double get subtotal => throw _privateConstructorUsedError;

  /// Serializes this OrderItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderItemModelCopyWith<OrderItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderItemModelCopyWith<$Res> {
  factory $OrderItemModelCopyWith(
    OrderItemModel value,
    $Res Function(OrderItemModel) then,
  ) = _$OrderItemModelCopyWithImpl<$Res, OrderItemModel>;
  @useResult
  $Res call({
    String id,
    String? orderId,
    String? productId,
    String? productName,
    String? productSlug,
    String? productSku,
    String? productImage,
    String? size,
    String? color,
    int quantity,
    double price,
    double subtotal,
  });
}

/// @nodoc
class _$OrderItemModelCopyWithImpl<$Res, $Val extends OrderItemModel>
    implements $OrderItemModelCopyWith<$Res> {
  _$OrderItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = freezed,
    Object? productId = freezed,
    Object? productName = freezed,
    Object? productSlug = freezed,
    Object? productSku = freezed,
    Object? productImage = freezed,
    Object? size = freezed,
    Object? color = freezed,
    Object? quantity = null,
    Object? price = null,
    Object? subtotal = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            orderId: freezed == orderId
                ? _value.orderId
                : orderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            productId: freezed == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as String?,
            productName: freezed == productName
                ? _value.productName
                : productName // ignore: cast_nullable_to_non_nullable
                      as String?,
            productSlug: freezed == productSlug
                ? _value.productSlug
                : productSlug // ignore: cast_nullable_to_non_nullable
                      as String?,
            productSku: freezed == productSku
                ? _value.productSku
                : productSku // ignore: cast_nullable_to_non_nullable
                      as String?,
            productImage: freezed == productImage
                ? _value.productImage
                : productImage // ignore: cast_nullable_to_non_nullable
                      as String?,
            size: freezed == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                      as String?,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrderItemModelImplCopyWith<$Res>
    implements $OrderItemModelCopyWith<$Res> {
  factory _$$OrderItemModelImplCopyWith(
    _$OrderItemModelImpl value,
    $Res Function(_$OrderItemModelImpl) then,
  ) = __$$OrderItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? orderId,
    String? productId,
    String? productName,
    String? productSlug,
    String? productSku,
    String? productImage,
    String? size,
    String? color,
    int quantity,
    double price,
    double subtotal,
  });
}

/// @nodoc
class __$$OrderItemModelImplCopyWithImpl<$Res>
    extends _$OrderItemModelCopyWithImpl<$Res, _$OrderItemModelImpl>
    implements _$$OrderItemModelImplCopyWith<$Res> {
  __$$OrderItemModelImplCopyWithImpl(
    _$OrderItemModelImpl _value,
    $Res Function(_$OrderItemModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = freezed,
    Object? productId = freezed,
    Object? productName = freezed,
    Object? productSlug = freezed,
    Object? productSku = freezed,
    Object? productImage = freezed,
    Object? size = freezed,
    Object? color = freezed,
    Object? quantity = null,
    Object? price = null,
    Object? subtotal = null,
  }) {
    return _then(
      _$OrderItemModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        orderId: freezed == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        productId: freezed == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as String?,
        productName: freezed == productName
            ? _value.productName
            : productName // ignore: cast_nullable_to_non_nullable
                  as String?,
        productSlug: freezed == productSlug
            ? _value.productSlug
            : productSlug // ignore: cast_nullable_to_non_nullable
                  as String?,
        productSku: freezed == productSku
            ? _value.productSku
            : productSku // ignore: cast_nullable_to_non_nullable
                  as String?,
        productImage: freezed == productImage
            ? _value.productImage
            : productImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        size: freezed == size
            ? _value.size
            : size // ignore: cast_nullable_to_non_nullable
                  as String?,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderItemModelImpl implements _OrderItemModel {
  const _$OrderItemModelImpl({
    required this.id,
    this.orderId,
    this.productId,
    this.productName,
    this.productSlug,
    this.productSku,
    this.productImage,
    this.size,
    this.color,
    this.quantity = 1,
    this.price = 0,
    this.subtotal = 0,
  });

  factory _$OrderItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderItemModelImplFromJson(json);

  @override
  final String id;
  @override
  final String? orderId;
  @override
  final String? productId;
  @override
  final String? productName;
  @override
  final String? productSlug;
  @override
  final String? productSku;
  @override
  final String? productImage;
  @override
  final String? size;
  @override
  final String? color;
  @override
  @JsonKey()
  final int quantity;
  @override
  @JsonKey()
  final double price;
  @override
  @JsonKey()
  final double subtotal;

  @override
  String toString() {
    return 'OrderItemModel(id: $id, orderId: $orderId, productId: $productId, productName: $productName, productSlug: $productSlug, productSku: $productSku, productImage: $productImage, size: $size, color: $color, quantity: $quantity, price: $price, subtotal: $subtotal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.productSlug, productSlug) ||
                other.productSlug == productSlug) &&
            (identical(other.productSku, productSku) ||
                other.productSku == productSku) &&
            (identical(other.productImage, productImage) ||
                other.productImage == productImage) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    orderId,
    productId,
    productName,
    productSlug,
    productSku,
    productImage,
    size,
    color,
    quantity,
    price,
    subtotal,
  );

  /// Create a copy of OrderItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderItemModelImplCopyWith<_$OrderItemModelImpl> get copyWith =>
      __$$OrderItemModelImplCopyWithImpl<_$OrderItemModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderItemModelImplToJson(this);
  }
}

abstract class _OrderItemModel implements OrderItemModel {
  const factory _OrderItemModel({
    required final String id,
    final String? orderId,
    final String? productId,
    final String? productName,
    final String? productSlug,
    final String? productSku,
    final String? productImage,
    final String? size,
    final String? color,
    final int quantity,
    final double price,
    final double subtotal,
  }) = _$OrderItemModelImpl;

  factory _OrderItemModel.fromJson(Map<String, dynamic> json) =
      _$OrderItemModelImpl.fromJson;

  @override
  String get id;
  @override
  String? get orderId;
  @override
  String? get productId;
  @override
  String? get productName;
  @override
  String? get productSlug;
  @override
  String? get productSku;
  @override
  String? get productImage;
  @override
  String? get size;
  @override
  String? get color;
  @override
  int get quantity;
  @override
  double get price;
  @override
  double get subtotal;

  /// Create a copy of OrderItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderItemModelImplCopyWith<_$OrderItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
