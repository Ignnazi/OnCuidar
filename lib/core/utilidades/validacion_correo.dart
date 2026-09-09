/// Expresión regular compartida para validar correos electrónicos.
final RegExp regexCorreo = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
