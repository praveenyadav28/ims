import os
import re

def fix_bloc_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Fix constructor: remove the extra closing brace and comma before the new flags
    content = re.sub(r'\},\s+this\.isLoadingParties = true,\s+this\.isLoadingCatalogue = true,\s+this\.isLoadingHSN = true,\s*\);',
                     r'    this.isLoadingParties = true,\n    this.isLoadingCatalogue = true,\n    this.isLoadingHSN = true,\n  });', content)

    # 2. Fix copyWith signature
    content = re.sub(r'copyWith\(\{([\s\S]*?)\},\s+bool\? isLoadingParties,\s+bool\? isLoadingCatalogue,\s+bool\? isLoadingHSN,\s*\)\s*\{',
                     r'copyWith({\1    bool? isLoadingParties,\n    bool? isLoadingCatalogue,\n    bool? isLoadingHSN,\n  }) {', content)

    # 3. Fix copyWith return statement - handle the comma and missing newline
    # This matches the end of the original list of parameters and correctly adds the new ones on new lines
    content = re.sub(r'transId: transId \?\? this\.transId,\s*isLoadingParties: isLoadingParties \?\? this\.isLoadingParties,',
                     r'transId: transId ?? this.transId,\n      isLoadingParties: isLoadingParties ?? this.isLoadingParties,', content)
    
    # Generic fix for any comma followed by isLoadingParties on the same line
    content = re.sub(r',(\s*)isLoadingParties: isLoadingParties \?\? this\.isLoadingParties,',
                     r',\n      isLoadingParties: isLoadingParties ?? this.isLoadingParties,', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

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
        print(f"Fixing {f}")
        fix_bloc_file(f)
