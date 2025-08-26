#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script para copiar arquivo de testbench e atualizar lista de fontes
"""

import os
import shutil
import argparse

def copy_testbench_and_update_srclist(bus_protocol):
    """
    Copia o arquivo de testbench e atualiza a lista de fontes
    """
    # Definir paths
    test_dir = "./tests/"
    build_rtl_dir = "./build/rtl/"
    srclist_file = f"{build_rtl_dir}/{bus_protocol}_tb.srclist"
    
    # Nome do arquivo de testbench
    tb_filename = f"{bus_protocol}_tb.sv"
    source_tb_path = os.path.join(test_dir, tb_filename)
    dest_tb_path = os.path.join(build_rtl_dir, tb_filename)
    
    # Verificar se o arquivo de testbench existe
    if not os.path.exists(source_tb_path):
        print(f"❌ Arquivo de testbench não encontrado: {source_tb_path}")
        return False
    
    # Verificar se o diretório de destino existe
    if not os.path.exists(build_rtl_dir):
        print(f"❌ Diretório de destino não encontrado: {build_rtl_dir}")
        return False
    
    try:
        # 1. Copiar o arquivo de testbench
        print(f"📋 Copiando {tb_filename} de {test_dir} para {build_rtl_dir}")
        shutil.copy2(source_tb_path, dest_tb_path)
        print(f"✅ Testbench copiado com sucesso: {dest_tb_path}")
        
        # 2. Verificar se o arquivo .srclist existe
        if not os.path.exists(srclist_file):
            print(f"⚠️  Arquivo .srclist não encontrado: {srclist_file}")
            print(f"📝 Criando novo arquivo .srclist")
            with open(srclist_file, 'w') as f:
                f.write(f"{tb_filename}\n")
            print(f"✅ Arquivo .srclist criado: {srclist_file}")
            return True
        
        # 3. Ler o conteúdo atual do arquivo .srclist
        print(f"📖 Lendo arquivo: {srclist_file}")
        with open(srclist_file, 'r') as f:
            lines = f.readlines()
        
        # 4. Verificar se o testbench já está na lista
        tb_already_exists = any(tb_filename in line for line in lines)
        
        if tb_already_exists:
            print(f"ℹ️  Testbench já está na lista: {tb_filename}")
            return True
        
        # 5. Adicionar o testbench ao final do arquivo
        print(f"✏️  Adicionando {tb_filename} ao arquivo .srclist")
        with open(srclist_file, 'a') as f:
            f.write(f"{tb_filename}\n")
        
        print(f"✅ Arquivo .srclist atualizado com sucesso: {srclist_file}")
        
        # 6. Mostrar conteúdo atualizado
        print("\n📋 Conteúdo atualizado do arquivo .srclist:")
        with open(srclist_file, 'r') as f:
            content = f.read()
        print(content)
        
        return True
        
    except Exception as e:
        print(f"❌ Erro durante a execução: {str(e)}")
        return False

def main():
    """
    Função principal
    """
    parser = argparse.ArgumentParser(description="Copiar testbench e atualizar lista de fontes")
    parser.add_argument(
        "-p", "--protocol", 
        type=str, 
        required=True,
        help="Protocolo do barramento (ex: apb4, axi4, etc.)"
    )
    
    args = parser.parse_args()
    bus_protocol = args.protocol
    
    print(f"🚀 Iniciando script para protocolo: {bus_protocol}")
    print("=" * 50)
    
    success = copy_testbench_and_update_srclist(bus_protocol)
    
    print("=" * 50)
    if success:
        print("✅ Script executado com sucesso!")
    else:
        print("❌ Script falhou!")
        exit(1)

if __name__ == "__main__":
    main()