{
  description = "A flake to build and run a 16-bit x86 bootloader";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    
    # choose the assembly source: prefer repo ./boot.asm, otherwise create a small fallback
    bootAsm = if builtins.pathExists ./boot.asm then ./boot.asm else pkgs.writeText "fallback-boot.asm" ''
org 0x7c00
bits 16
start:
    mov si, msg
.print:
    lodsb
    or al, al
    jz done
    mov ah, 0x0E
    int 0x10
    jmp .print
done:
    cli
    hlt
msg db "Fallback bootloader - Hello, QEMU!",0
times 510-($-$$) db 0
dw 0xAA55
'';

    bootBin = pkgs.runCommand "boot.bin" {
      src = bootAsm;
      nativeBuildInputs = [ pkgs.nasm ];
    } ''
      # The build script
      # $src is boot.asm (either the repo's or the generated fallback), $out is the output file
      nasm -f bin $src -o $out
    '';

    # A script that will run our bootloader in QEMU
    runScript = pkgs.writeScriptBin "run-bootloader" ''
      #!${pkgs.runtimeShell}
      
      # Run QEMU, pointing a readonly raw drive to our boot.bin
      echo "Starting QEMU with boot.bin..."
      ${pkgs.qemu_full}/bin/qemu-system-x86_64 \
        -drive file=${bootBin},format=raw,if=floppy,readonly=on
    '';

  in {

    # --- Development Shell ---
    # Run `nix develop` to enter a shell with nasm and qemu
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.nasm
        pkgs.qemu_full # Provides qemu-system-x86_64
      ];
    };

    # --- Default Package ---
    # Run `nix build`
    # This will create ./result/bin/run-bootloader
    packages.${system}.default = runScript;

    # --- Default App ---
    # Run `nix run`
    # This is the easiest way to run the project!
    apps.${system}.default = {
      type = "app";
      program = "${runScript}/bin/run-bootloader";
    };
  };
}
