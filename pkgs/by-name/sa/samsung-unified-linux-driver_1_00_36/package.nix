{
  lib,
  stdenv,
  fetchurl,
  cups,
  libusb-compat-0_1,
  libxml2,
  perl,
}:

let

  arch = if stdenv.system == "x86_64-linux" then "x86_64" else "i386";

in
stdenv.mkDerivation (finalAttrs: {
  pname = "samsung-unified-linux-driver";
  version = "1.00.36";

  src = fetchurl {
    sha256 = "1a7ngd03x0bkdl7pszy5zqqic0plxvdxqm5w7klr6hbdskx1lir9";
    url = "http://www.bchemnet.com/suldr/driver/UnifiedLinuxDriver-${finalAttrs.version}.tar.gz";
  };

  buildInputs = [
    cups
    libusb-compat-0_1
    libxml2
    perl
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -R ${arch}/{gettext,pstosecps,rastertospl,smfpnetdiscovery,usbresetter} $out/bin

    mkdir -p $out/etc/sane.d/dll.d/
    install -m644 noarch/etc/smfp.conf $out/etc/sane.d
    echo smfp >> $out/etc/sane.d/dll.d/smfp-scanner.conf

    mkdir -p $out/etc/smfp-common/scanner/share/
    install -m644 noarch/libsane-smfp.cfg $out/etc/smfp-common/scanner/share/
    install -m644 noarch/pagesize.xml $out/etc/smfp-common/scanner/share/

    mkdir -p $out/etc/samsung/scanner/share/
    install -m644 noarch/oem.conf $out/etc/samsung/scanner/share/

    mkdir -p $out/lib
    install -m755 ${arch}/libscmssc.so* $out/lib

    mkdir -p $out/lib/cups/backend
    ln -s $out/bin/smfpnetdiscovery $out/lib/cups/backend

    mkdir -p $out/lib/cups/filter
    ln -s $out/bin/{pstosecps,rastertospl} $out/lib/cups/filter
    ln -s $ghostscript/bin/gs $out/lib/cups/filter

    mkdir -p $out/lib/sane
    install -m755 ${arch}/libsane-smfp.so* $out/lib/sane
    ln -s libsane-smfp.so.1.0.1 $out/lib/sane/libsane-smfp.so.1
    ln -s libsane-smfp.so.1     $out/lib/sane/libsane-smfp.so

    perl -pi -e \
      's|/opt/smfp-common/scanner/.usedby/|/tmp/\0\0fp-common/scanner/.usedby/|g' \
       $out/lib/sane/libsane-smfp.so.1.0.1
    perl -pi -e 's|/opt|/etc|g' \
       $out/lib/sane/libsane-smfp.so.1.0.1 \
       $out/bin/rastertospl \
       noarch/package_utils \
       noarch/pre_install.sh

    mkdir -p $out/lib/udev/rules.d
    (
      OEM_FILE=noarch/oem.conf
      INSTALL_LOG_FILE=/dev/null
      . noarch/scripting_utils
      . noarch/package_utils
      . noarch/scanner-script.pkg
      fill_full_template noarch/etc/smfp.rules.in $out/lib/udev/rules.d/60_smfp_samsung.rules
      chmod -x $out/lib/udev/rules.d/60_smfp_samsung.rules
    )

    mkdir -p $out/share
    cp -R noarch/share/* $out/share
    gzip -9 $out/share/ppd/*.ppd
    rm -r $out/share/locale/*/*/install.mo

    mkdir -p $out/share/cups
    cd $out/share/cups
    ln -s ../ppd .
    ln -s ppd model

    runHook postInstall
  '';

  preFixup = ''
    for bin in "$out/bin/"*; do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$bin"
      patchelf --set-rpath "$out/lib:${lib.getLib cups}/lib" "$bin"
    done

    patchelf --set-rpath "$out/lib:${lib.getLib cups}/lib" "$out/lib/libscmssc.so"
    patchelf --set-rpath "$out/lib:${libxml2.out}/lib:${libusb-compat-0_1.out}/lib" "$out/lib/sane/libsane-smfp.so.1.0.1"

    ln -s ${lib.getLib stdenv.cc.cc}/lib/libstdc++.so.6 $out/lib/
  '';

  # all binaries are already stripped
  dontStrip = true;

  # we did this in prefixup already
  dontPatchELF = true;

  meta = {
    description = "Unified Linux Driver for Samsung printers and scanners";
    homepage = "http://www.bchemnet.com/suldr";
    downloadPage = "http://www.bchemnet.com/suldr/driver/";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;

    # Tested on linux-x86_64. Might work on linux-i386.
    # Probably won't work on anything else.
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
