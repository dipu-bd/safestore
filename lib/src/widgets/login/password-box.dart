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
      onSubmitted: widget.onSubmit,
      onChanged: widget.onChange,
      autofocus: widget.autofocus,
      style: TextStyle(
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
      fillColor: Colors.white.withOpacity(0.95),
      contentPadding: EdgeInsets.symmetric(vertical: 20.0),
      prefixIcon: Icon(Icons.lock),
      suffixIcon: GestureDetector(
        onTap: () {
          obscured = !obscured;
          if (mounted) setState(() {});
        },
        child: Icon(obscured ? Icons.visibility : Icons.visibility_off),
      ),
      hintText: widget.hintText ?? 'Password',
      hintStyle: TextStyle(
        fontWeight: FontWeight.w300,
        fontSize: 23.0,
      ),
      border: UnderlineInputBorder(
        borderSide: BorderSide(width: 2.0),
        borderRadius: BorderRadius.circular(5.0),
      ),
    );
  }
}
