import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../helpers/helper.dart';
import '../models/cart.dart';
import '../models/coupon.dart';
import '../repository/cart_repository.dart';
import '../repository/coupon_repository.dart';
import '../repository/settings_repository.dart';
import '../repository/user_repository.dart';

class CartController extends ControllerMVC {
  List<Cart> carts = [];
  double taxAmount = 0.0;
  double deliveryFee = 0.0;
  int cartCount = 0;
  double subTotal = 0.0;
  double total = 0.0;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    listenForCarts();
    listenForCartsCount();
  }

  void listenForCarts({String? message}) async {
    try {
      final Stream<Cart> stream = await getCart();
      stream.listen(
        (Cart _cart) {
          if (!carts.contains(_cart)) {
            coupon = _cart.product.applyCoupon(coupon);
            carts.add(_cart);
            calculateSubtotal();
          }
        },
        onError: (a) {
          print(a);
          showSnackBar(S
              .of(scaffoldKey.currentContext!)
              .verify_your_internet_connection);
        },
      );
    } catch (e) {
      print(e);
    }
  }

  void listenForCartsCount() async {
    try {
      final Stream<int> stream = await getCartCount();
      stream.listen(
        (int _count) {
          setState(() {
            this.cartCount = _count;
          });
        },
        onError: (a) {
          print(a);
          showSnackBar(S
              .of(scaffoldKey.currentContext!)
              .verify_your_internet_connection);
        },
      );
    } catch (e) {
      print(e);
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Future<void> refreshCarts() async {
    setState(() {
      carts = [];
    });
    listenForCarts(
        message: S.of(scaffoldKey.currentContext!).carts_refreshed_successfuly);
  }

  void removeFromCart(Cart _cart) async {
    setState(() {
      this.carts.remove(_cart);
    });
    removeCart(_cart).then((value) {
      calculateSubtotal();
      showSnackBar(S
          .of(scaffoldKey.currentContext!)
          .the_product_was_removed_from_your_cart(_cart.product.name));
    });
  }

  void calculateSubtotal() {
    double cartPrice = 0;
    subTotal = 0;
    carts.forEach((cart) {
      cartPrice = cart.product.price;
      cart.options.forEach((element) {
        cartPrice += element.price;
      });
      cartPrice *= cart.quantity;
      subTotal += cartPrice;
    });
    if (Helper.canDelivery(carts[0].product.market, carts: carts)) {
      deliveryFee = carts[0].product.market.deliveryFee;
    }
    taxAmount =
        (subTotal + deliveryFee) * carts[0].product.market.defaultTax / 100;
    total = subTotal + taxAmount + deliveryFee;
    setState(() {});
  }

  void doApplyCoupon(String code) async {
    try {
      coupon = Coupon.fromJSON({"code": code, "valid": null});
      final Stream<Coupon> stream = await verifyCoupon(code);
      stream.listen(
        (Coupon _coupon) {
          coupon = _coupon;
          listenForCarts();
        },
        onError: (a) {
          print(a);
          showSnackBar(S
              .of(scaffoldKey.currentContext!)
              .verify_your_internet_connection);
        },
      );
    } catch (e) {
      print(e);
    }
  }

  void incrementQuantity(Cart cart) {
    if (cart.quantity <= 99) {
      ++cart.quantity;
      updateCart(cart);
      calculateSubtotal();
    }
  }

  void decrementQuantity(Cart cart) {
    if (cart.quantity > 1) {
      --cart.quantity;
      updateCart(cart);
      calculateSubtotal();
    }
  }

  void goCheckout(BuildContext context) {
    if (!currentUser.value!.profileCompleted()) {
      showSnackBar(
        S.of(scaffoldKey.currentContext!).completeYourProfileDetailsToContinue,
      );
      return;
    }

    if (carts.isNotEmpty && carts[0].product.market.closed) {
      showSnackBar(S.of(scaffoldKey.currentContext!).this_market_is_closed_);
      return;
    }

    Navigator.of(context).pushNamed('/DeliveryPickup');
  }

  Color getCouponIconColor() {
    if (coupon.valid == true) {
      return Colors.green;
    } else if (coupon.valid == false) {
      return Colors.redAccent;
    }
    return Theme.of(scaffoldKey.currentContext!).focusColor.withOpacity(0.7);
  }
}
