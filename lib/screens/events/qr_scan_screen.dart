import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanned = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleQrScan(BarcodeCapture capture) async {
    if (_isScanned || _isProcessing) return;

    try {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        final qrData = barcode.rawValue;

        if (qrData != null && qrData.contains('|')) {
          setState(() => _isProcessing = true);
          await _processAttendance(qrData);
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error en escaneo: $e');
      }
    }
  }

  Future<void> _processAttendance(String qrData) async {
    try {
      // Parsear datos: eventId|timestamp
      final parts = qrData.split('|');
      if (parts.length != 2) {
        _showError('QR inválido');
        return;
      }

      final eventId = parts[0];
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        _showError('No hay sesión activa');
        return;
      }

      // Actualizar check-in en la BD
      await supabase
          .from('event_registrations')
          .update({'checked_in_at': DateTime.now().toIso8601String()})
          .eq('event_id', eventId)
          .eq('user_id', userId);

      if (!mounted) return;

      setState(() => _isScanned = true);

      // Mostrar éxito
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¡Asistencia Registrada!'),
          content: const Text('Tu asistencia ha sido marcada correctamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Cerrar pantalla de escaneo
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } on PostgrestException catch (e) {
      _showError('Error en BD: ${e.message}');
    } catch (e) {
      _showError('Error procesando asistencia');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      context.showSnackBar(message, isError: true);
      setState(() {
        _isScanned = false;
        _isProcessing = false;
      });
      // Reanudar escaneo
      controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Asistencia'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Cámara
          MobileScanner(
            controller: controller,
            onDetect: _handleQrScan,
          ),
          // Overlay con guía de escaneo
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Área de escaneo
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.primary, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _isProcessing
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(scheme.primary),
                            )
                          : const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isProcessing ? 'Procesando...' : 'Apunta la cámara al QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
