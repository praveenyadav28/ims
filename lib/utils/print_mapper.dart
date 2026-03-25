import 'package:ims/ui/sales/models/debitnote_model.dart';
import 'package:ims/ui/sales/models/dilivery_data.dart';
import 'package:ims/ui/sales/models/estimate_data.dart';
import 'package:ims/ui/sales/models/performa_data.dart';
import 'package:ims/ui/sales/models/print_model.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/ui/sales/models/purchaseorder_model.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/ui/sales/models/sale_return_data.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';

extension EstimatePrintMapper on EstimateData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Estimate",
      number: "$prefix${prefix.isEmpty ? "" : "-"}$no",
      date: estimateDate,
      partyName: customerName,
      mobile: mobile,
      address0: address0,
      address1: address1,
      placeOfSupply: placeOfSupply,
      items: itemDetails,
      subTotal: subTotal,
      gstTotal: subGst,
      grandTotal: totalAmount,
      notes: notes,
      terms: terms,
      printSign: printSig,
    );
  }
}

extension PerformaPrintMapper on PerformaData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Performa Invoice",
      number: "$prefix${prefix.isEmpty ? "" : "-"}$no",
      date: performaDate,
      partyName: customerName,
      mobile: mobile,
      address0: address0,
      address1: address1,
      placeOfSupply: placeOfSupply,
      items: itemDetails,
      subTotal: subTotal,
      gstTotal: subGst,
      grandTotal: totalAmount,
      notes: notes,
      terms: terms,
      printSign: printSign,
    );
  }
}

extension DeliveryChallanPrintMapper on DiliveryChallanData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Delivery Challan",
      number: "$prefix${prefix.isEmpty ? "" : "-"}$no",
      date: diliveryChallanDate,
      partyName: customerName,
      mobile: mobile,
      address0: address0,
      address1: address1,
      placeOfSupply: placeOfSupply,
      items: itemDetails,
      subTotal: subTotal,
      gstTotal: subGst,
      grandTotal: totalAmount,
      notes: notes,
      terms: terms,
      printSign: printSig,
    );
  }
}

extension SaleInvoicePrintMapper on SaleInvoiceData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Sale Invoice",
      number: "$prefix${prefix.isEmpty ? "" : "-"}$no",
      date: saleInvoiceDate,
      partyName: customerName,
      mobile: mobile,
      address0: address0,
      address1: address1,
      placeOfSupply: placeOfSupply,
      items: itemDetails,
      subTotal: subTotal,
      gstTotal: subGst,
      grandTotal: totalAmount,
      notes: notes,
      terms: terms,
      printSign: printSig,
    );
  }
}

extension SaleReturnPrintMapper on SaleReturnData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Sale Return",
      number: "$prefix${prefix.isEmpty ? "" : "-"}$no",
      date: saleReturnDate,
      partyName: customerName,
      mobile: mobile,
      address0: address0,
      address1: address1,
      placeOfSupply: placeOfSupply,
      items: itemDetails,
      subTotal: subTotal,
      gstTotal: subGst,
      grandTotal: totalAmount,
      notes: notes,
      terms: terms,
      printSign: printSig,
    );
  }
}

extension CreditNotePrintMapper on CreditNoteData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Credit Note",
      number: "$prefix${prefix.isEmpty ? "" : "-"}$no",
      date: creditNoteDate,
      partyName: ledgerName,
      mobile: mobile,
      address0: address0,
      address1: address1,
      placeOfSupply: placeOfSupply,
      items: itemDetails,
      subTotal: subTotal,
      gstTotal: subGst,
      grandTotal: totalAmount,
      notes: notes,
      terms: terms,
      printSign: printSig,
    );
  }
}

extension PurchaseOrderPrintMapper on PurchaseOrderData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Purchase Order",
      number: "$prefix${prefix.isEmpty ? "" : "-"}$no",
      date: purchaseOrderDate,
      partyName: supplierName,
      mobile: mobile,
      address0: address0,
      address1: address1,
      placeOfSupply: placeOfSupply,
      items: itemDetails,
      subTotal: subTotal,
      gstTotal: subGst,
      grandTotal: totalAmount,
      notes: notes,
      terms: terms,
      printSign: printSig,
    );
  }
}

extension PurchaseInvoicePrintMapper on PurchaseInvoiceData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Purchase Invoice",
      number: "$prefix${prefix.isEmpty ? "" : "-"}$no",
      date: purchaseInvoiceDate,
      partyName: supplierName,
      mobile: mobile,
      address0: address0,
      address1: address1,
      placeOfSupply: placeOfSupply,
      items: itemDetails,
      subTotal: subTotal,
      gstTotal: subGst,
      grandTotal: totalAmount,
      notes: notes,
      terms: terms,
      printSign: printSig
    );
  }
}

extension PurchaseReturnPrintMapper on PurchaseReturnData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Purchase Return",
      number: "$prefix${prefix.isEmpty ? "" : "-"}$no",
      date: purchaseReturnDate,
      partyName: supplierName,
      mobile: mobile,
      address0: address0,
      address1: address1,
      placeOfSupply: placeOfSupply,
      items: itemDetails,
      subTotal: subTotal,
      gstTotal: subGst,
      grandTotal: totalAmount,
      notes: notes,
      terms: terms,
      printSign: printSig
    );
  }
}

extension DebitNotePrintMapper on DebitNoteData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Debit Note",
      number: "$prefix${prefix.isEmpty ? "" : "-"}$no",
      date: debitNoteDate,
      partyName: customerName,
      mobile: mobile,
      address0: address0,
      address1: address1,
      placeOfSupply: placeOfSupply,
      items: itemDetails,
      subTotal: subTotal,
      gstTotal: subGst,
      grandTotal: totalAmount,
      notes: notes,
      terms: terms,
      printSign: printSig
    );
  }
}
