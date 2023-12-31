import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../controllers/cart_controller.dart';
import '../helpers/helper.dart';

class CartBottomDetailsWidget extends StatelessWidget {
  const CartBottomDetailsWidget({
    Key key,
    @required CartController con,
  })  : _con = con,
        super(key: key);

  final CartController _con;

  @override
  Widget build(BuildContext context) {
    return _con.carts.isEmpty
        ? SizedBox(height: 0)
        : Container(
            height: 200,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Theme.of(context).focusColor.withOpacity(0.15), offset: Offset(0, -2), blurRadius: 5.0)]),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          S.of(context).subtotal,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Helper.getPrice(_con.subTotal, context, style: Theme.of(context).textTheme.titleMedium, zeroPlaceholder: '0')
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          S.of(context).delivery_fee,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      if (Helper.canDelivery(_con.carts[0].product.market, carts: _con.carts))
                        Helper.getPrice(_con.carts[0].product.market.deliveryFee, context, style: Theme.of(context).textTheme.titleMedium, zeroPlaceholder: S.of(context).free)
                      else
                        Helper.getPrice(0, context, style: Theme.of(context).textTheme.titleMedium, zeroPlaceholder: S.of(context).free)
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${S.of(context).tax} (${_con.carts[0].product.market.defaultTax}%)',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Helper.getPrice(_con.taxAmount, context, style: Theme.of(context).textTheme.titleMedium)
                    ],
                  ),
                  SizedBox(height: 10),
                  Stack(
                    fit: StackFit.loose,
                    alignment: AlignmentDirectional.centerEnd,
                    children: <Widget>[
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: MaterialButton(
                          elevation: 0,
                          onPressed: () {
                            _con.goCheckout(context);
                          },
                          disabledColor: Theme.of(context).focusColor.withOpacity(0.5),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          color: !_con.carts[0].product.market.closed ? Theme.of(context).colorScheme.secondary : Theme.of(context).focusColor.withOpacity(0.5),
                          shape: StadiumBorder(),
                          child: Text(
                            S.of(context).checkout,
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.bodyLarge.merge(TextStyle(color: Theme.of(context).primaryColor)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Helper.getPrice(_con.total, context,
                            style: Theme.of(context).textTheme.headlineMedium.merge(TextStyle(color: Theme.of(context).primaryColor)), zeroPlaceholder: 'Free'),
                      )
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          );
  }
}
