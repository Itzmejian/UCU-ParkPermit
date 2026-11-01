import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/office_info.dart';

const PdfColor _navy = PdfColor.fromInt(0xFF1D3E7C);
const PdfColor _gold = PdfColor.fromInt(0xFFF5B83D);
const PdfColor _goldDark = PdfColor.fromInt(0xFF7A5200);
const PdfColor _muted = PdfColor.fromInt(0xFF5F6472);
const PdfColor _fill = PdfColor.fromInt(0xFFEEF1FF);
const PdfColor _border = PdfColor.fromInt(0xFFC9D3EA);

const List<String> _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const Map<String, String> _docLabels = {
  'drivers_license': "Driver's License",
  'orcr': 'Vehicle OR/CR',
  'ucu_id': 'UCU ID',
};

const Map<String, String> _statusLabels = {
  'pending': 'Pending review',
  'under_review': 'Under review',
  'appeal_review': 'Appeal under review',
  'declined': 'Declined',
  'approved': 'Approved',
};

String _s(dynamic v) => v == null ? '' : v.toString();

Map<String, dynamic> _one(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  if (v is List && v.isNotEmpty && v.first is Map) return Map<String, dynamic>.from(v.first as Map);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _many(dynamic v) {
  if (v is List) return [for (final x in v) if (x is Map) Map<String, dynamic>.from(x)];
  return <Map<String, dynamic>>[];
}

String _date(dynamic iso, {bool time = true}) {
  final d = DateTime.tryParse(_s(iso))?.toLocal();
  if (d == null) return '-';
  final date = '${_months[d.month - 1]} ${d.day}, ${d.year}';
  if (!time) return date;
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$date, $h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

pw.Widget _row(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 130, child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _muted))),
        pw.Expanded(
          child: pw.Text(value.isEmpty ? '-' : value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    ),
  );
}

pw.Widget _section(String title, List<pw.Widget> children) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 12),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _border),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _goldDark, letterSpacing: 1),
        ),
        pw.SizedBox(height: 6),
        ...children,
      ],
    ),
  );
}

/// Builds the PDF receipt of an application, from the server.
Future<Uint8List> buildReceipt(String referenceNo) async {
  final c = Supabase.instance.client;
  final app = await c
      .from('applications')
      .select(
        'reference_no, kind, status, submitted_at, '
        'vehicle:vehicles(plate_number, make_model, color, model_year, vehicle_type), '
        'documents(kind, file_name)',
      )
      .eq('reference_no', referenceNo)
      .single();
  var p = <String, dynamic>{};
  final uid = c.auth.currentUser?.id;
  if (uid != null) {
    final r = await c
        .from('profiles')
        .select('full_name, id_number, role, program, department')
        .eq('id', uid)
        .maybeSingle();
    if (r != null) p = Map<String, dynamic>.from(r);
  }
  final v = _one(app['vehicle']);
  final docs = _many(app['documents']);
  final isEmployee = p['role'] == 'employee';

  Uint8List? logo;
  try {
    logo = (await rootBundle.load('assets/images/ucu_logo.png')).buffer.asUint8List();
  } catch (_) {}

  final doc = pw.Document(title: 'Application Receipt $referenceNo', author: 'UCU ParkPermit');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: _navy,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Row(
              children: [
                if (logo != null)
                  pw.Container(
                    width: 54,
                    height: 54,
                    padding: const pw.EdgeInsets.all(5),
                    decoration: const pw.BoxDecoration(color: PdfColors.white, shape: pw.BoxShape.circle),
                    child: pw.Image(pw.MemoryImage(logo)),
                  ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'URDANETA CITY UNIVERSITY',
                        style: pw.TextStyle(fontSize: 9, color: _gold, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                      ),
                      pw.Text(
                        'ParkPermit',
                        style: pw.TextStyle(fontSize: 22, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Application Receipt', style: const pw.TextStyle(fontSize: 12, color: PdfColors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: const pw.BoxDecoration(
              color: _fill,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('REFERENCE NO.', style: const pw.TextStyle(fontSize: 9, color: _muted)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _s(app['reference_no']),
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _navy, font: pw.Font.courierBold()),
                      ),
                      pw.SizedBox(height: 10),
                      _row('Status', _statusLabels[_s(app['status'])] ?? _s(app['status'])),
                      _row('Type', app['kind'] == 'renewal' ? 'Permit renewal' : 'New application'),
                      _row('Submitted on', _date(app['submitted_at'])),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Column(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: _s(app['reference_no']),
                      width: 92,
                      height: 92,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Reference QR', style: const pw.TextStyle(fontSize: 8, color: _muted)),
                  ],
                ),
              ],
            ),
          ),
          _section('Applicant', [
            _row('Name', _s(p['full_name'])),
            _row('User type', isEmployee ? 'Employee' : 'Student'),
            _row(isEmployee ? 'Employee ID' : 'Student ID', _s(p['id_number'])),
            _row(isEmployee ? 'Department / Office' : 'Course', _s(isEmployee ? p['department'] : p['program'])),
          ]),
          _section('Vehicle', [
            _row('Type', v['vehicle_type'] == 'motorcycle' ? 'Motorcycle' : '4-Wheel Vehicle'),
            _row('Plate number', _s(v['plate_number'])),
            _row('Make / Model', _s(v['make_model'])),
            _row('Color', _s(v['color'])),
            _row('Model year', _s(v['model_year'])),
          ]),
          _section('Documents submitted', [
            if (docs.isEmpty)
              pw.Text('-', style: const pw.TextStyle(fontSize: 11))
            else
              for (final d in docs)
                _row(_docLabels[_s(d['kind'])] ?? _s(d['kind']), _s(d['file_name'])),
          ]),
          _section('What happens next', [
            pw.Text(
              '1. The $kOfficeName reviews your application within 24 to 48 office hours.\n'
              '2. You will get a notification in the app when it is approved or needs a correction.\n'
              '3. When approved, claim your parking sticker at the office and bring your UCU ID.',
              style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 3),
            ),
          ]),
          pw.Spacer(),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _gold),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              'This receipt shows that your application was received. It is NOT a parking permit and cannot be used to park on campus.',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _goldDark),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            '$kOfficeName  |  $kOfficeLocation  |  $kOfficeHours',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
          pw.Text(
            'Generated on ${_date(DateTime.now().toIso8601String())}  |  UCU ParkPermit',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}

/// Opens the phone's print screen, where the receipt can be printed or saved as PDF.
Future<void> printReceipt(BuildContext context, String referenceNo) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(content: Text('Preparing your receipt...'), duration: Duration(seconds: 2)),
  );
  try {
    final bytes = await buildReceipt(referenceNo);
    await Printing.layoutPdf(
      name: 'UCU-ParkPermit-Receipt-$referenceNo.pdf',
      onLayout: (_) async => bytes,
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not make the receipt. Check your internet and try again.')),
    );
  }
}