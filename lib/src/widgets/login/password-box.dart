import 'package:flutter/material.dart';

class PasswordBox extends StatefulWidget {
  final bool autofocus;
  final String hintText;
  final void Function(String) onSubmit;
  final void Function(String) onChange;

  PasswordBox({
    Key key,
    this.hintText,
    this.onChange,
    this.autofocus: false,
    @required this.onSubmit,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PasswordBoxState();
}

class _PasswordBoxState extends State<PasswordBox> {
  bool obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorWidth: 3.0,
      maxLength: 16,
      maxLengthEnforced: true,
      obscureText: obscured,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      keyboardAppearance: Brightness.dark,
      onSubmitted: widget.onSubmit,
      onChanged: widget.onChange,
      autofocus: widget.autofocus,
      style: TextStyle(
        color: Colors.white,
        fontSize: 26.0,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
      ),
      decoration: buildInputDecoration(),
    );
  }

  InputDecoration buildInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Color.fromARGB(240, 0, 0, 0),
      prefixIcon: Icon(
        Icons.lock,
        color: Colors.amber,
      ),
      suffix: SizedBox(
        width: 40.0,
        height: 40.0,
        child: IconButton(
          icon: Icon(
            obscured ? Icons.visibility : Icons.visibility_off,
          ),
          color: obscured ? Colors.amberAccent : Colors.grey,
          onPressed: () {
            obscured = !obscured;
            if (mounted) setState(() {});
          },
        ),
      ),
      hintText: widget.hintText ?? 'Enter Password',
      hintStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 24.0,
      ),
      counterStyle: TextStyle(
        color: Colors.white,
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(width: 2.0, color: Colors.white24),
      ),
    );
  }
}
