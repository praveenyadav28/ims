import os, glob, re

files = glob.glob('lib/ui/purchase/**/*.dart', recursive=True)
for f in files:
    if not f.endswith('_bloc.dart'): continue
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # 1. Flip onLoad and prefill logic
    pattern1 = re.compile(r'await _onLoad\(event,\s*emit\);\s*if\s*\(event\.existing\s*!=\s*null\)\s*\{\s*emit\((_prefill\w+)\((event\.existing![^,]*),\s*state\)\);\s*add\((.*?)\(\)\);\s*\}')
    
    def repl1(m):
        return f"""if (event.existing != null) {{
        emit({m.group(1)}({m.group(2)}, state));
        add({m.group(3)}());
      }}
      
      await _onLoad(event, emit);

      if (event.existing != null) {{
        add({m.group(3)}());
      }}"""
    
    content = pattern1.sub(repl1, content)
    
    # 2. Add fallback to _prefill... items mapping (Item)
    pattern2 = re.compile(r'final catalogItem = s\.catalogue\.firstWhere\(\s*\(c\) => c\.id == \(i\.itemId\),\s*orElse:\s*\(\) => emptyItem\(\),\s*\);')
    repl2 = r"""ItemServiceModel catalogItem;
    try {
      catalogItem = s.catalogue.firstWhere((c) => c.id == (i.itemId));
    } catch (_) {
      catalogItem = ItemServiceModel(
        id: i.itemId,
        type: ItemServiceType.item,
        name: i.name,
        hsn: i.hsn,
        variantValue: '',
        baseSalePrice: i.price,
        basePurchasePrice: i.price,
        gstRate: i.gstRate,
        gstIncluded: i.inclusive,
        gstIncludedPurchase: false,
        baseUnit: i.unit,
        secondaryUnit: i.unit,
        conversion: 1,
        variants: [],
        itemNo: (hasattr(i, 'itemNo') ? i.itemNo : ''),
        group: '',
      );
    }"""
    # NOTE: The above replacement might need refinement for itemNo vs hasattr in Dart, so actually let's just do it dynamically in Dart:
    repl2 = r"""ItemServiceModel catalogItem;
    try {
      catalogItem = s.catalogue.firstWhere((c) => c.id == (i.itemId));
    } catch (_) {
      try {
        catalogItem = ItemServiceModel(
          id: i.itemId,
          type: ItemServiceType.item,
          name: i.name,
          hsn: i.hsn,
          variantValue: '',
          baseSalePrice: i.price,
          basePurchasePrice: i.price,
          gstRate: i.gstRate,
          gstIncluded: i.inclusive,
          gstIncludedPurchase: false,
          baseUnit: i.unit,
          secondaryUnit: i.unit,
          conversion: 1,
          variants: [],
          itemNo: (i as dynamic).itemNo ?? '',
          group: '',
        );
      } catch (e) {
        catalogItem = ItemServiceModel(
          id: i.itemId,
          type: ItemServiceType.item,
          name: i.name,
          hsn: i.hsn,
          variantValue: '',
          baseSalePrice: i.price,
          basePurchasePrice: i.price,
          gstRate: i.gstRate,
          gstIncluded: i.inclusive,
          gstIncludedPurchase: false,
          baseUnit: i.unit,
          secondaryUnit: i.unit,
          conversion: 1,
          variants: [],
          itemNo: '',
          group: '',
        );
      }
    }"""
    content = re.sub(pattern2, repl2, content)
    
    # 3. Add fallback to _prefill... services mapping
    pattern3 = re.compile(r'final catalogService = s\.catalogue\.firstWhere\(\s*\(c\) => c\.id == \(i\.serviceId\),\s*orElse:\s*\(\) => emptyItem\(\),\s*\);')
    repl3 = r"""ItemServiceModel catalogService;
    try {
      catalogService = s.catalogue.firstWhere((c) => c.id == (i.serviceId));
    } catch (_) {
      try {
        catalogService = ItemServiceModel(
          id: i.serviceId,
          type: ItemServiceType.service,
          name: i.name,
          hsn: i.hsn,
          variantValue: '',
          baseSalePrice: i.price,
          basePurchasePrice: i.price,
          gstRate: i.gstRate,
          gstIncluded: i.inclusive,
          gstIncludedPurchase: false,
          baseUnit: i.unit,
          secondaryUnit: i.unit,
          conversion: 1,
          variants: [],
          itemNo: (i as dynamic).serviceNo?.toString() ?? '',
          group: '',
        );
      } catch (e) {
         catalogService = ItemServiceModel(
          id: i.serviceId,
          type: ItemServiceType.service,
          name: i.name,
          hsn: i.hsn,
          variantValue: '',
          baseSalePrice: i.price,
          basePurchasePrice: i.price,
          gstRate: i.gstRate,
          gstIncluded: i.inclusive,
          gstIncludedPurchase: false,
          baseUnit: i.unit,
          secondaryUnit: i.unit,
          conversion: 1,
          variants: [],
          itemNo: '',
          group: '',
        );     
      }
    }"""
    content = re.sub(pattern3, repl3, content)
    
    # 4. Remove emptyItem function
    pattern4 = re.compile(r'\s*// empty fallback item(.*?)\s+group: \'\',\n\s+\);\n\s+}', re.DOTALL)
    content = pattern4.sub('', content)
    
    # 5. Handle misc master skip
    pattern5 = re.compile(r'if\s*\(match\s*==\s*null\)\s*\{\s*// skip if master not found\s*continue;\s*\}')
    repl5 = r"""if (match == null) {
      final taxIncluded =
          (m.type == true) || (m.type.toString().toLowerCase() == "true");
      mappedMisc.add(
        GlobalMiscChargeEntry(
          id: UniqueKey().toString(),
          miscId: m.id, 
          ledgerId: "",
          name: m.name,
          hsn: "",
          gst: 0,
          amount: (m.amount).toDouble(),
          taxIncluded: taxIncluded,
        ),
      );
      continue;
    }"""
    content = re.sub(pattern5, repl5, content)
    
    pattern6 = re.compile(r'if\s*\(match\s*==\s*null\)\s*\{\s*// Option chosen: SKIP misc charge if master not found\..*?continue;\s*\}', re.DOTALL)
    content = re.sub(pattern6, repl5, content)
    
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)
    print(f'Processed {f}')
