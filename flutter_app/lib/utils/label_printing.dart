import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> printOrderLabel(Map<String, dynamic> order) async {
  try {
    final logoData = await rootBundle.load('images/logo.png');
    final logoBytes = logoData.buffer.asUint8List();
    final pdfLogo = pw.MemoryImage(logoBytes);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, 150 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(pdfLogo, height: 30, width: 30),
                    pw.SizedBox(width: 8),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Yan Ship S.A.R.L',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.Text(
                          'Casablanca, HAI FATEH',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    order['trackingNumber']?.toString() ?? 'N/A',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 8),
                pw.Text(
                  'DESTINATAIRE:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                  pw.Text('Nom: ${order['recipientName'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 9)),
                  pw.Text('Téléphone: ${order['phone'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 9)),
                  pw.Text('Ville: ${order['cityName'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 9)),
                  pw.Text('Adresse: ${order['deliveryAddress'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 8),
                pw.Text(
                  'EXPÉDITEUR:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                  pw.Text('Nom: ${order['senderName'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 8),
                pw.Text(
                  'PAIEMENT À LA LIVRAISON:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                  pw.Text('${order['price'] ?? '0'} MAD', style: pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 8),
                pw.Text(
                  'DATE:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                pw.Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()), style: pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                    ),
                    child: pw.Text(
                      '|| ${order['trackingNumber']} ||',
                      style: pw.TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  } catch (e) {
    print('Erreur lors de l\'impression: $e');
  }
}