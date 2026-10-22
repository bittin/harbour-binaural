Name:       harbour-binaural
Summary:    Binaural
Version:    0.8.1
Release:    1
License:    GPL-3.0-or-later
URL:        https://github.com/molan-git/harbour-binaural

Source0:    %{name}-%{version}.tar.bz2

Requires:   sailfishsilica-qt5 >= 0.10.9

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Multimedia)
BuildRequires:  desktop-file-utils

%description
Binaural is a sound app for relaxation, focus, sleep, and meditation,
combining binaural beats, colored noise, and ambient sounds.

# This description section includes metadata for SailfishOS:Chum, see
# https://github.com/sailfishos-chum/main/blob/main/Metadata.md
%if 0%{?_chum}
Title: Binaural
Type: desktop-application
DeveloperName: molan
Categories:
 - Audio
 - HealthFitness
Custom:
  Repo: https://github.com/molan-git/harbour-binaural
PackageIcon: https://github.com/molan-git/harbour-binaural/blob/main/icons/216x216/harbour-binaural.png
Screenshots:
 - https://openrepos.net/sites/default/files/packages/10743/screenshot-screenshot20261007011529001.png
 - https://openrepos.net/sites/default/files/packages/10743/screenshot-screenshot20261005143657001.png
 - https://openrepos.net/sites/default/files/packages/10743/screenshot-screenshot20261005143725001.png
Links:
  Homepage: https://github.com/molan-git/harbour-binaural
  Help: https://github.com/molan-git/harbour-binaural/discussions
  Bugtracker: https://github.com/molan-git/harbour-binaural/issues
  Donation: https://ko-fi.com/G7W527ZZR9
%endif

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5
%make_build

%install
%qmake5_install

desktop-file-install --delete-original \
    --dir %{buildroot}%{_datadir}/applications \
    %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)

%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
