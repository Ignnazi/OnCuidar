import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/paleta.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';

const _relaciones = ['Madre', 'Padre', 'Tutor', 'Otro'];

class EditarPerfil extends ConsumerStatefulWidget {
  const EditarPerfil({super.key});

  @override
  ConsumerState<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends ConsumerState<EditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoRespaldoCtrl = TextEditingController();
  String? _relacion;

  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoRespaldoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final datos = await ref
          .read(servicioBaseDatosProvider)
          .obtenerCuidador();
      if (!mounted) return;
      _nombreCtrl.text = datos['nombre'] ?? '';
      _telefonoCtrl.text = datos['telefono'] ?? '';
      _relacion = datos['relacion'];
      setState(() => _cargando = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar tus datos.';
        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await ref.read(servicioBaseDatosProvider).actualizarCuidador(
            nombre: _nombreCtrl.text.trim(),
            telefono: _telefonoCtrl.text.trim(),
            relacion: _relacion,
            correoRespaldo: _correoRespaldoCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente.'),
          backgroundColor: Paleta.exito,
        ),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar. Intenta de nuevo.'),
          backgroundColor: Paleta.error,
        ),
      );
    }
  }

  Future<void> _cambiarCorreo() async {
    final nuevoCorreoCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar correo electrónico'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Se enviará un enlace de verificación al nuevo correo.',
              style: GoogleFonts.nunito(fontSize: 13, color: Paleta.textoSecundario),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nuevoCorreoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Nuevo correo',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (nuevoCorreoCtrl.text.isNotEmpty && passwordCtrl.text.isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null || user.email == null) return;

      // Re-autenticar con credenciales
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordCtrl.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Cambiar correo (verifyBeforeUpdateEmail envía verificación + actualiza)
      await user.verifyBeforeUpdateEmail(nuevoCorreoCtrl.text.trim());

      // Actualizar en Firestore
      await ref.read(servicioBaseDatosProvider).actualizarCuidador(
            nombre: _nombreCtrl.text.trim(),
            telefono: _telefonoCtrl.text.trim(),
            relacion: _relacion,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo actualizado. Revisa tu bandeja para verificar.'),
          backgroundColor: Paleta.exito,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'wrong-password':
          msg = 'Contraseña incorrecta.';
          break;
        case 'email-already-in-use':
          msg = 'Ese correo ya está en uso.';
          break;
        case 'requires-recent-login':
          msg = 'Cierra sesión y vuelve a iniciar para realizar este cambio.';
          break;
        default:
          msg = 'Error: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Paleta.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado. Intenta de nuevo.'),
          backgroundColor: Paleta.error,
        ),
      );
    } finally {
      nuevoCorreoCtrl.dispose();
      passwordCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(firebaseAuthProvider).currentUser;
    final email = user?.email ?? '';
    final emailVerificado = user?.emailVerified ?? false;

    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Column(
        children: [
          const EncabezadoGradiente(
            titulo: 'Editar perfil',
            subtitulo: 'Actualiza tu información',
            alto: 130,
          ),
          Expanded(
            child: _cargando
                ? const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: CircularProgressIndicator(),
                  )
                : _error != null
                    ? _mensajeError()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Sección: Información personal ──
                              _seccion('Información personal'),
                              const SizedBox(height: 12),
                              _campo(
                                controlador: _nombreCtrl,
                                etiqueta: 'Nombre completo',
                                icono: Icons.person_outline,
                                validador: (v) =>
                                    v == null || v.trim().isEmpty ? 'Obligatorio' : null,
                              ),
                              const SizedBox(height: 12),
                              _campo(
                                controlador: _telefonoCtrl,
                                etiqueta: 'Teléfono',
                                icono: Icons.phone_outlined,
                                tipo: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              _dropdownRelacion(),
                              const SizedBox(height: 28),

                              // ── Sección: Correo electrónico ──
                              _seccion('Correo electrónico'),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Paleta.tarjeta,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Paleta.bordeTarjeta),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.email_outlined,
                                            size: 18, color: Paleta.doradoOscuro),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            email,
                                            style: GoogleFonts.nunito(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Paleta.textoPrincipal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          emailVerificado
                                              ? Icons.verified
                                              : Icons.warning_amber_rounded,
                                          size: 16,
                                          color: emailVerificado
                                              ? Paleta.exito
                                              : Paleta.error,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          emailVerificado
                                              ? 'Verificado'
                                              : 'Verificación pendiente',
                                          style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            color: emailVerificado
                                                ? Paleta.exito
                                                : Paleta.error,
                                          ),
                                        ),
                                        if (!emailVerificado) ...[
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () async {
                                              await user
                                                  ?.sendEmailVerification();
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Enlace de verificación enviado.'),
                                                  backgroundColor: Paleta.exito,
                                                ),
                                              );
                                            },
                                            child: Text(
                                              'Reenviar',
                                              style: GoogleFonts.nunito(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Paleta.doradoOscuro,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: _cambiarCorreo,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Paleta.doradoOscuro,
                                          side: const BorderSide(
                                              color: Paleta.doradoOscuro),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'Cambiar correo',
                                          style: GoogleFonts.nunito(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              // ── Sección: Correo de respaldo ──
                              _seccion('Correo de respaldo (opcional)'),
                              const SizedBox(height: 8),
                              Text(
                                'Se usa para recuperación de cuenta. Por seguridad '
                                'se guarda de forma protegida y no se vuelve a mostrar.',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: Paleta.textoSecundario,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _campo(
                                controlador: _correoRespaldoCtrl,
                                etiqueta: 'Correo de respaldo',
                                icono: Icons.mail_outline,
                                tipo: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 32),

                              // ── Botón guardar ──
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: _guardando ? null : _guardar,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Paleta.doradoOscuro,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _guardando
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Guardar cambios',
                                          style: GoogleFonts.nunito(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _seccion(String titulo) {
    return Text(
      titulo,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Paleta.textoPrincipal,
      ),
    );
  }

  Widget _campo({
    required TextEditingController controlador,
    required String etiqueta,
    required IconData icono,
    TextInputType? tipo,
    String? Function(String?)? validador,
  }) {
    return TextFormField(
      controller: controlador,
      keyboardType: tipo,
      validator: validador,
      style: GoogleFonts.nunito(fontSize: 14, color: Paleta.textoPrincipal),
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, size: 20, color: Paleta.doradoOscuro),
        labelStyle: GoogleFonts.nunito(color: Paleta.textoSecundario),
        filled: true,
        fillColor: Paleta.tarjeta,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Paleta.bordeTarjeta),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Paleta.bordeTarjeta),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Paleta.doradoOscuro, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _dropdownRelacion() {
    return DropdownButtonFormField<String>(
      initialValue: _relacion,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Relación con el paciente',
        prefixIcon: const Icon(Icons.family_restroom_outlined,
            size: 20, color: Paleta.doradoOscuro),
        labelStyle: GoogleFonts.nunito(color: Paleta.textoSecundario),
        filled: true,
        fillColor: Paleta.tarjeta,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Paleta.bordeTarjeta),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Paleta.bordeTarjeta),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Paleta.doradoOscuro, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: _relaciones
          .map((opcion) => DropdownMenuItem(
                value: opcion,
                child: Text(opcion,
                    style: GoogleFonts.nunito(
                        fontSize: 14, color: Paleta.textoPrincipal)),
              ))
          .toList(),
      onChanged: (v) => setState(() => _relacion = v),
      validator: (v) => v == null || v.isEmpty ? 'Selecciona una relación' : null,
    );
  }

  Widget _mensajeError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: Paleta.error),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Paleta.textoPrincipal,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _cargar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
