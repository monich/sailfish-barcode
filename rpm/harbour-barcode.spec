Name:       harbour-barcode

%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}

Summary:    Bar code reader for Sailfish OS
Version:    1.0.53
Release:    1
Group:      Applications/Productivity
License:    Mixed
URL:        https://github.com/monich/sailfish-barcode
Source0:    %{name}-%{version}.tar.bz2

Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   qt5-qtsvg-plugin-imageformat-svg

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Multimedia)
BuildRequires:  pkgconfig(Qt5Concurrent)
BuildRequires:  pkgconfig(Qt5DBus)
BuildRequires:  pkgconfig(mlite5)
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  desktop-file-utils
BuildRequires:  zlib-devel
BuildRequires:  qt5-qttools-linguist

# Sailfish OS SDK 4.5 switches the default RPM compression method to zstd
# and that's incompatible with earlier releases of Sailfish OS
%define _binary_payload w6.xzdio

%description
Program for scanning 1D and 2D barcodes (e.g. QR codes).

%if "%{?vendor}" == "chum"
Categories:
 - Utility
Icon: https://raw.githubusercontent.com/monich/sailfish-barcode/master/icons/harbour-barcode.svg
Screenshots:
- https://home.monich.net/chum/harbour-barcode/screenshots/screenshot-001.png
- https://home.monich.net/chum/harbour-barcode/screenshots/screenshot-002.png
- https://home.monich.net/chum/harbour-barcode/screenshots/screenshot-003.png
- https://home.monich.net/chum/harbour-barcode/screenshots/screenshot-004.png
- https://home.monich.net/chum/harbour-barcode/screenshots/screenshot-005.png
- https://home.monich.net/chum/harbour-barcode/screenshots/screenshot-006.png
- https://home.monich.net/chum/harbour-barcode/screenshots/screenshot-007.png
Url:
  Homepage: https://openrepos.net/content/slava/barcode
%endif

%prep
%setup -q -n %{name}-%{version}

%build
%qtc_qmake5 VERSION="%{version}"
%qtc_make %{?_smp_mflags}

%install
rm -rf %{buildroot}
%qmake5_install

desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
