import os, glob, re

directories = ['lib/ui/sales', 'lib/ui/purchase']

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'isLoadingParties' in content or 'SaleInvoiceBloc' in content: 
        return

    # Find State name
    bloc_match = re.search(r'class\s+(\w+Bloc)\s+extends\s+Bloc<(\w+Event),\s+(\w+State)>', content)
    if not bloc_match:
        return
    state_name = bloc_match.group(3)
    
    # 1. Add fields
    fields = "\n  final bool isLoadingParties;\n  final bool isLoadingCatalogue;\n  final bool isLoadingHSN;\n"
    content = content.replace('class ' + state_name + ' {', 'class ' + state_name + ' {' + fields)

    # 2. Update Constructor
    cons_pattern = re.compile(re.escape(state_name) + r'\s*\((.*?)\);', re.DOTALL)
    def cons_sub(m):
        orig = m.group(1).rstrip()
        if not orig.endswith(','): orig += ','
        return state_name + '(' + orig + "\n    this.isLoadingParties = true,\n    this.isLoadingCatalogue = true,\n    this.isLoadingHSN = true,\n  );"
    content = cons_pattern.sub(cons_sub, content)

    # 3. Update copyWith Params
    cw_pattern = re.compile(re.escape(state_name) + r'\s+copyWith\s*\((.*?)\)\s*\{', re.DOTALL)
    def cw_sub(m):
        orig = m.group(1).rstrip()
        if not orig.endswith(','): orig += ','
        return state_name + ' copyWith(' + orig + "\n    bool? isLoadingParties,\n    bool? isLoadingCatalogue,\n    bool? isLoadingHSN,\n  ) {"
    content = cw_pattern.sub(cw_sub, content)

    # 4. Update copyWith Return
    ret_pattern = re.compile(r'return\s+' + re.escape(state_name) + r'\s*\((.*?)\);', re.DOTALL)
    def ret_sub(m):
        orig = m.group(1).rstrip()
        if not orig.endswith(','): orig += ','
        return 'return ' + state_name + '(' + orig + "\n      isLoadingParties: isLoadingParties ?? this.isLoadingParties,\n      isLoadingCatalogue: isLoadingCatalogue ?? this.isLoadingCatalogue,\n      isLoadingHSN: isLoadingHSN ?? this.isLoadingHSN,\n    );"
    content = ret_pattern.sub(ret_sub, content)

    # 5. Injection into emits (Best effort)
    content = content.replace('customers: customers,', 'customers: customers, isLoadingParties: false,')
    content = content.replace('catalogue: catalogue,', 'catalogue: catalogue, isLoadingCatalogue: false,')
    content = content.replace('hsnMaster: hsnList,', 'hsnMaster: hsnList, isLoadingHSN: false,')
    content = content.replace('hsnMaster: hsnMaster,', 'hsnMaster: hsnMaster, isLoadingHSN: false,')

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Processed {file_path}")

for root_dir in directories:
    for f in glob.glob(f"{root_dir}/**/*_bloc.dart", recursive=True):
        process_file(f)
