import os, glob, re

files = glob.glob('lib/ui/purchase/**/*.dart', recursive=True)
for f in files:
    if not f.endswith('_bloc.dart'): continue
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # We want to replace `rows: [NoteModelItem(localId: UniqueKey().toString())]`
    # OR `rows: [GlobalItemRow(...)` in the `emit(` block inside `_onLoad`, with `rows: e.existing != null ? state.rows : [NoteModelItem(...)]`.
    # To do this safely, we match `rows: \[GlobalItemRow\(localId: UniqueKey\(\)\.toString\(\)\)\]` and replace.
    # But wait, there are two occurrences in each file, one in _onLoad and one possibly in the end.
    # The `_onLoad` has `e.existing` because it's `(PurchaseInvoiceLoadInit e, Emitter<...`.
    
    pattern_global = r'rows:\s*\[GlobalItemRow\(localId:\s*UniqueKey\(\)\.toString\(\)\)\]'
    content = re.sub(pattern_global, r'rows: e.existing != null ? state.rows : [GlobalItemRow(localId: UniqueKey().toString())]', content)
    
    pattern_note = r'rows:\s*\[NoteModelItem\(localId:\s*UniqueKey\(\)\.toString\(\)\)\]'
    content = re.sub(pattern_note, r'rows: e.existing != null ? state.rows : [NoteModelItem(localId: UniqueKey().toString())]', content)
    
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)
    print(f'Processed {f}')
