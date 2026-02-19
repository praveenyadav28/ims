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
      number: "$prefix $no",
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
    );
  }
}

extension PerformaPrintMapper on PerformaData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Performa Invoice",
      number: "$prefix $no",
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
    );
  }
}

extension DeliveryChallanPrintMapper on DiliveryChallanData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Delivery Challan",
      number: "$prefix $no",
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
    );
  }
}

extension SaleInvoicePrintMapper on SaleInvoiceData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Sale Invoice",
      number: "$prefix $no",
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
    );
  }
}

extension SaleReturnPrintMapper on SaleReturnData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Sale Return",
      number: "$prefix $no",
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
    );
  }
}

// extension CreditNotePrintMapper on CreditNoteData {
//   PrintDocModel toPrintModel() {
//     return PrintDocModel(
//       title: "Credit Note",
//       number: "$prefix $no",
//       date: creditNoteDate,
//       partyName: ledgerName,
//       mobile: mobile,
//       address0: address0,
//       address1: address1,
//       placeOfSupply: placeOfSupply,
//       items: itemDetails,
//       subTotal: subTotal,
//       gstTotal: subGst,
//       grandTotal: totalAmount,
//       notes: notes,
//       terms: terms,
//     );
//   }
// }

extension PurchaseOrderPrintMapper on PurchaseOrderData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Purchase Order",
      number: "$prefix $no",
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
    );
  }
}

extension PurchaseInvoicePrintMapper on PurchaseInvoiceData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Purchase Invoice",
      number: "$prefix $no",
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
    );
  }
}

extension PurchaseReturnPrintMapper on PurchaseReturnData {
  PrintDocModel toPrintModel() {
    return PrintDocModel(
      title: "Purchase Return",
      number: "$prefix $no",
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
    );
  }
}

// extension DebitNotePrintMapper on DebitNoteData {
//   PrintDocModel toPrintModel() {
//     return PrintDocModel(
//       title: "Debit Note",
//       number: "$prefix $no",
//       date: debitNoteDate,
//       partyName: customerName,
//       mobile: mobile,
//       address0: address0,
//       address1: address1,
//       placeOfSupply: placeOfSupply,
//       items: itemDetails,
//       subTotal: subTotal,
//       gstTotal: subGst,
//       grandTotal: totalAmount,
//       notes: notes,
//       terms: terms,
//     );
//   }
// }
