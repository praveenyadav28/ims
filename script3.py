import os, glob, re

files = glob.glob('lib/ui/purchase/**/*.dart', recursive=True)
for f in files:
    if not f.endswith('_bloc.dart'): continue
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # We want to replace `<prop>No: results[0] as String,`
    # inside `_onLoad` with `<prop>No: e.existing != null ? state.<prop>No : results[0] as String,`
    
    # But note: it might be `creditNoteNo: results[0] as String`, `purchaseOrderNo`, `purchaseReturnNo`
    pattern = re.compile(r'(\s+)(\w+No):\s*results\[0\]\s*as\s*String,')
    def repl(m):
        prop_no = m.group(2)
        indent = m.group(1)
        return f'{indent}{prop_no}: e.existing != null ? state.{prop_no} : results[0] as String,'
    
    content = pattern.sub(repl, content)
    
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)
    print(f'Processed {f}')
