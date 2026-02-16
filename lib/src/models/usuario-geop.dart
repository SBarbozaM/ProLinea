class UsuarioGeop {
  String encriptado;
  String codUndiad;
  String? rpta;
  String? status;

  UsuarioGeop({
    required this.encriptado,
    required this.codUndiad,
    this.rpta,
    this.status,
  });

  factory UsuarioGeop.fromJson(Map<String, dynamic> json) => UsuarioGeop(
        encriptado: json["encriptado"],
        codUndiad: json["codUndiad"],
      );

  Map<String, dynamic> toJson() => {
        "encriptado": encriptado,
        "codUndiad": codUndiad,
      };
}
