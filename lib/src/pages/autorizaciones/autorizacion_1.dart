import 'package:flutter/material.dart';

enum SwitchState { active, inactive, dual }

class TriStateToggleSwitch extends StatefulWidget {
  const TriStateToggleSwitch({
    Key? key,
  }) : super(key: key);

  final SwitchState initialState = SwitchState.dual;

  @override
  State<TriStateToggleSwitch> createState() => _TriStateToggleSwitchState();
}

class _TriStateToggleSwitchState extends State<TriStateToggleSwitch> {
  late SwitchState _switchState;
  late SwitchState _previousState;
  late String _currentSnackbarMessage;

  late Color _switchBackgroundColor;
  late Color _circleBackgroundColor;
  late AlignmentGeometry _alignment;

  @override
  void initState() {
    super.initState();
    _switchState = widget.initialState;
    _previousState = SwitchState.dual;
    _currentSnackbarMessage = '';
    _setSwitchColors();
  }

  void _setSwitchColors() {
    _switchBackgroundColor = _switchState == SwitchState.active
        ? const Color(0xff34C759)
        : _switchState == SwitchState.inactive
            ? const Color.fromARGB(255, 206, 24, 14)
            : const Color.fromARGB(255, 69, 65, 65);

    _circleBackgroundColor = const Color(0xffFFFFFF);

    _alignment = _switchState == SwitchState.active
        ? Alignment.centerRight
        : _switchState == SwitchState.inactive
            ? Alignment.centerLeft
            : Alignment.center;
  }

  void _handleHorizontalDrag(double horizontalDrag) {
    setState(() {
      if (horizontalDrag > 0.0) {
        _switchState = SwitchState.active;
      } else if (horizontalDrag < 0.0) {
        _switchState = SwitchState.inactive;
      } else {
        _switchState = SwitchState.dual;
      }
      _setSwitchColors();
    });
  }

  void _handleDragEnd() {
    setState(() {
      if (_previousState != _switchState) {
        if (_switchState == SwitchState.active) {
          _showSnackBar('Activado con éxito');
        } else if (_switchState == SwitchState.inactive) {
          _showSnackBar('Inactivo con éxito');
        } else if (_switchState == SwitchState.dual) {
          _showSnackBar('dual con éxito');
        }
      }
      _previousState = _switchState;
    });
  }

  void _showSnackBar(String message) {
    _currentSnackbarMessage = message;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_currentSnackbarMessage),
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autorizaciones'),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Center(
        child: Container(
          width: 100,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              const containerWidth = 100.0;
              final horizontalDrag = details.primaryDelta! / containerWidth;
              _handleHorizontalDrag(horizontalDrag);
            },
            onHorizontalDragEnd: (details) {
              _handleDragEnd();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _switchBackgroundColor,
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding: const EdgeInsets.all(2.0),
              alignment: _alignment,
              child: Container(
                height: 27.0,
                width: 27.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _circleBackgroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
