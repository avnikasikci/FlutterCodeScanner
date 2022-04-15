import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CameraPreviewMask extends StatelessWidget {
  const CameraPreviewMask({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color _background = Colors.grey.withOpacity(0.95);

    return SafeArea(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  height: MediaQuery.of(context).size.height - 25,
                  width: 1,
                  color: _background,
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height - 25,
                width: MediaQuery.of(context).size.width * 0.65,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        color: _background,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      height: MediaQuery.of(context).size.width * 0.1,
                      width: MediaQuery.of(context).size.width * 0.65,
                    ),
                    Expanded(
                      child: Container(
                        color: _background,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: MediaQuery.of(context).size.height - 25,
                  width: 1,
                  color: _background,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
