import os, glob, re

# Files to update with loading state flags
files_to_update = [
    'lib/ui/sales/sale_invoice/saleinvoice_create.dart',
    'lib/ui/sales/estimate/estimate_screen.dart',
    'lib/ui/sales/performa_invoice/performa_screen.dart',
    'lib/ui/sales/dilivery_chalan/dilivery_create.dart',
    'lib/ui/sales/sale_return/sale_return_create.dart',
    'lib/ui/sales/debit_note/create_debitnote.dart',
    'lib/ui/purchase/purchase_invoice/purchase_invoice_create.dart',
    'lib/ui/purchase/purchase_order/purchase_order_create.dart',
    'lib/ui/purchase/purchase_return/purchase_return_create.dart',
    'lib/ui/purchase/credit_note/credit_note_create.dart',
]

def update_file(file_path):
    if not os.path.exists(file_path):
        print(f"Skipping {file_path} (not found)")
        return
        
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Inject into GlobalBillToCard
    content = content.replace('selectedCustomer: state.selectedCustomer,', 'selectedCustomer: state.selectedCustomer, isLoadingParties: state.isLoadingParties,')
    
    # Inject into GlobalItemsTableSection
    content = content.replace('hsnList: state.hsnMaster,', 'hsnList: state.hsnMaster, isLoadingCatalogue: state.isLoadingCatalogue, isLoadingHSN: state.isLoadingHSN,')

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Updated {file_path}")

for f in files_to_update:
    update_file(f)
