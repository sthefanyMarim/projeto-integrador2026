import 'package:flutter/services.dart';


final telefoneRegex = RegExp(r'^\(\d{2}\) \d{4,5}-\d{4}$');

final emailRegex = RegExp(
  r'^[A-Za-z0-9][A-Za-z0-9._%+-]*@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$',
);

class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);

    final buffer = StringBuffer();
    if (digits.isNotEmpty) {
      buffer.write('(');
      if (digits.length <= 2) {
        buffer.write(digits);
      } else {
        buffer.write(digits.substring(0, 2));
        buffer.write(') ');
        final rest = digits.substring(2);
        if (rest.length <= 4) {
          buffer.write(rest);
        } else {
          buffer.write(rest.substring(0, rest.length - 4));
          buffer.write('-');
          buffer.write(rest.substring(rest.length - 4));
        }
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
