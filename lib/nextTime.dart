import 'package:flutter/material.dart';

class NextTime extends StatelessWidget {
  NextTime(this.Data,this.Repetetion);
  var Data;
  var Repetetion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("データセット"),
        ),
        //本体
        body: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                    Text(
                          'null',
                    ),
                ]
            )
        )
    );
  }
}