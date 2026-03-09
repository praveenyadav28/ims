import os, glob, re

files = glob.glob('lib/ui/sales/**/*_bloc.dart', recursive=True) + \
        glob.glob('lib/ui/purchase/**/*_bloc.dart', recursive=True)

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Fix the type equality check error for misc charges
    pattern = re.compile(r'\(m\.type\s*==\s*true\)\s*\|\|\s*\(m\.type\.toString\(\)\.toLowerCase\(\)\s*==\s*["\']true["\']\)')
    new_content = pattern.sub('(m.type.toString().toLowerCase() == "true")', content)
    
    if new_content != content:
        with open(f, 'w', encoding='utf-8') as file:
            file.write(new_content)
        print(f'Fixed type error in {f}')
    else:
        print(f'No type error found in {f}')
