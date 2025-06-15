import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

Future<void> generateAndDownloadReceipt({
  required String plate,
  required String zone,
  required DateTime start,
  required DateTime end,
  required double price,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("OpenPark Ticket Receipt", style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Text("Plate: $plate"),
            pw.Text("Zone: $zone"),
            pw.Text("Start: ${start.toLocal()}"),
            pw.Text("End: ${end.toLocal()}"),
            pw.Text("Price: €${price.toStringAsFixed(2)}"),
          ],
        );
      },
    ),
  );

  final output = await getApplicationDocumentsDirectory();
  final file = File("${output.path}/receipt_$plate.pdf");

  await file.writeAsBytes(await pdf.save());

  // opzionale: apri o stampa direttamente
  await OpenFilex.open(file.path);
  // oppure usa: await Printing.sharePdf(bytes: await pdf.save(), filename: 'receipt.pdf');
}
