{
  description = "Canteen";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, ... } @ inputs:
    let
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) systems);
    in
      {
        packages = forAllSystems (system:
          let
            pkgs = nixpkgs.legacyPackages."${system}";
            poly = "${pkgs.polyml}/bin/polyc";
          in {
            canteen = pkgs.stdenv.mkDerivation {
              name = "canteen";
              src = ./.;
              installPhase = ''
                mkdir -p $out/bin
                ${poly} -o $out/bin/canteen build.sml
            '';};

          });

#         + /nix/store/s004m6l3yqprx22s2i9wpdjy9idh5b38-mlton-20210107/bin/mlton -default-ann 'allowFFI true' -codegen c -keep g src/main.sml
# + cc -c -ffreestanding -L/nix/store/1rm6sr6ixxzipv5358x0cmaw8rs84g2j-glibc-2.38-44/lib -L/nix/store/s73ff85hvlki4yfq5q9h7nhmy26ni05y-mlton-20210107/lib/mlton/targets/self -lmlton -lgdtoa -lm -lgmp -I/nix/store/s73ff85hvlki4yfq5q9h7nhmy26ni05y-mlton-20210107/lib/mlton/include/ -I/nix/store/s73ff85hvlki4yfq5q9h7nhmy26ni05y-mlton-20210107/lib/mlton/targets/self/include src/main.0.c src/main.1.c

        apps = forAllSystems (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            mlton = "${pkgs.mlton}/bin/mlton";
            mktemp = "${pkgs.coreutils}/bin/mktemp";
            libtool = "${pkgs.libtool}/bin/libtool";
            glibc = "${pkgs.glibc}/lib";
          in {
            build = {
              type = "app";
              program = toString (pkgs.writeShellScript "build-program" ''
              set -eux
              # ${mlton} -default-ann 'allowFFI true' -codegen c -keep g src/main.sml
              # cc -c -ffreestanding -L${glibc} -L/nix/store/s73ff85hvlki4yfq5q9h7nhmy26ni05y-mlton-20210107/lib/mlton/targets/self -lmlton -lgdtoa -lm -lgmp -I/nix/store/s73ff85hvlki4yfq5q9h7nhmy26ni05y-mlton-20210107/lib/mlton/include/ -I/nix/store/s73ff85hvlki4yfq5q9h7nhmy26ni05y-mlton-20210107/lib/mlton/targets/self/include src/main.0.c src/main.1.c

              # ${libtool} --tag=CC --mode=link /nix/store/qhpw32pz39y6i30b3vrbw5fw6zv5549f-gcc-wrapper-13.2.0/bin/cc -o src/main src/main.0.o src/main.1.o -L${glibc} -L/nix/store/s73ff85hvlki4yfq5q9h7nhmy26ni05y-mlton-20210107/lib/mlton/targets/self -lmlton -lgdtoa -lm -lgmp -m64 -Wl,-znoexecstack -static
              ${libtool} --tag=CC --mode=link ld src/main.0.o src/main.1.o asm/boot.o -L${glibc} -L/nix/store/s73ff85hvlki4yfq5q9h7nhmy26ni05y-mlton-20210107/lib/mlton/targets/self  -T link.ld --oformat binary -o img.bin
              # ./src/main
            '');
            };
          });

        devShells = forAllSystems (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            gmp-static = pkgs.gmpxx.overrideAttrs (finalAttrs: previousAttrs: {
              withStatic = true;
            });
          in
            {
              default = devenv.lib.mkShell {
                inherit inputs pkgs;
                modules = [
                  ({ pkgs, ... }: {
                    packages = [
                      pkgs.gcc
                      pkgs.glibc
                      pkgs.just
                      pkgs.polyml
                      pkgs.mlton # required by smlfmt
                      pkgs.smlfmt
                      gmp-static
                      pkgs.libtool
                      pkgs.nasm
                    ];
                  })
                ];
              };
            });
      };
}
