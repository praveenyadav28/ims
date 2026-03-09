import os
import re

def fix_handler_syntax(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Search for pattern: emit(_prefillSomething(event.existing!, state), ...);
    # And replace with: emit(_prefillSomething(event.existing!, state).copyWith(...));
    
    pattern = r'emit\((_prefill\w+\(event\.existing!, state\)),\s+this\.isLoadingParties = true,\s+this\.isLoadingCatalogue = true,\s+this\.isLoadingHSN = true,\s+\);'
    replacement = r'emit(\1.copyWith(isLoadingParties: true, isLoadingCatalogue: true, isLoadingHSN: true));'
    
    new_content = re.sub(pattern, replacement, content)
    
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

bloc_files = [
    r"d:\flutter projects\ims\lib\ui\purchase\credit_note\state\credit_note_bloc.dart",
    r"d:\flutter projects\ims\lib\ui\purchase\purchase_invoice\state\p_invoice_bloc.dart",
    r"d:\flutter projects\ims\lib\ui\purchase\purchase_order\state\purchase_order_bloc.dart",
    r"d:\flutter projects\ims\lib\ui\purchase\purchase_return\state\purchase_return_bloc.dart",
    r"d:\flutter projects\ims\lib\ui\sales\debit_note\state\debitnote_bloc.dart",
    r"d:\flutter projects\ims\lib\ui\sales\dilivery_chalan\state\dilivery_bloc.dart",
    r"d:\flutter projects\ims\lib\ui\sales\estimate\state\estimate_bloc.dart",
    r"d:\flutter projects\ims\lib\ui\sales\performa_invoice\state\performa_bloc.dart",
    r"d:\flutter projects\ims\lib\ui\sales\sale_invoice\state\invoice_bloc.dart",
    r"d:\flutter projects\ims\lib\ui\sales\sale_return\state\return_bloc.dart"
]

for f in bloc_files:
    if os.path.exists(f):
        if fix_handler_syntax(f):
            print(f"Fixed handler in {f}")
        else:
            print(f"Skipped/No match in {f}")
