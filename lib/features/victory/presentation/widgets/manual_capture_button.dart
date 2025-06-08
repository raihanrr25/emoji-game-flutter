import 'package:flutter/material.dart';

class ManualCaptureButton extends StatelessWidget {
  final bool isSmileDetected;
  final bool isCapturing;
  final VoidCallback onPressed;

  const ManualCaptureButton({
    super.key,
    required this.isSmileDetected,
    required this.isCapturing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child:
          !isSmileDetected && !isCapturing
              ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent.withOpacity(0.3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    side: BorderSide(
                      color: Colors.amberAccent.withOpacity(0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 20),
                      SizedBox(width: 8),
                      Text('Manual Capture', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              )
              : const SizedBox(),
    );
  }
}
