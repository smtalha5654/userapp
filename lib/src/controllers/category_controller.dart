import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../models/cart.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../repository/cart_repository.dart';
import '../repository/category_repository.dart';
import '../repository/product_repository.dart';

class CategoryController extends ControllerMVC {
  List<Product> products = [];
  GlobalKey<ScaffoldState> scaffoldKey;
  Category category = Category();
  bool loadCart = false;
  List<Cart> carts = [];

  CategoryController() : scaffoldKey = GlobalKey<ScaffoldState>();

  void listenForProductsByCategory({String? id, String? message}) async {
    try {
      if (id != null) {
        final Stream<Product> stream = await getProductsByCategory(id);
        stream.listen(
          (Product _product) {
            setState(() {
              products.add(_product);
            });
          },
          onError: (a) {
            showSnackBar(S
                .of(scaffoldKey.currentContext!)
                .verify_your_internet_connection);
          },
          onDone: () {
            showSnackBar(message ?? '');
          },
        );
      } else {
        print('Error: ID is null');
      }
    } catch (e) {
      print(e);
    }
  }

  void listenForCategory({String? id, String? message}) async {
    try {
      if (id != null) {
        final Stream<Category> stream = await getCategory(id);
        stream.listen(
          (Category _category) {
            setState(() {
              category = _category;
            });
          },
          onError: (a) {
            print(a);
            showSnackBar(S
                .of(scaffoldKey.currentContext!)
                .verify_your_internet_connection);
          },
          onDone: () {
            showSnackBar(message ?? '');
          },
        );
      } else {
        print('Error: ID is null');
      }
    } catch (e) {
      print(e);
    }
  }

  void listenForCart() async {
    try {
      final Stream<Cart> stream = await getCart();
      stream.listen((Cart _cart) {
        carts.add(_cart);
      });
    } catch (e) {
      print(e);
    }
  }

  bool isSameMarkets(Product product) {
    if (carts.isNotEmpty) {
      return carts[0].product.market.id == product.market.id;
    }
    return true;
  }

  void addToCart(Product product, {bool reset = false}) async {
    try {
      setState(() {
        this.loadCart = true;
      });
      var _newCart = new Cart();
      _newCart.product = product;
      _newCart.options = [];
      _newCart.quantity = 1;
      // if product exists in the cart then increment quantity
      var _oldCart = isExistInCart(_newCart);
      if (_oldCart != null) {
        _oldCart.quantity++;
        await updateCart(_oldCart);
      } else {
        await addCart(_newCart, reset);
      }

      setState(() {
        this.loadCart = false;
      });

      showSnackBar(
          S.of(scaffoldKey.currentContext!).this_product_was_added_to_cart);
    } catch (e) {
      print(e);
    }
  }

  Cart? isExistInCart(Cart _cart) {
    try {
      return carts.firstWhereOrNull((Cart oldCart) => _cart.isSame(oldCart));
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> refreshCategory() async {
    try {
      products.clear();
      category = Category();
      listenForProductsByCategory(
          message:
              S.of(scaffoldKey.currentContext!).category_refreshed_successfuly);
      listenForCategory(
          message:
              S.of(scaffoldKey.currentContext!).category_refreshed_successfuly);
    } catch (e) {
      print(e);
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
