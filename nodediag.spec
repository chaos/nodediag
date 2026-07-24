Name: nodediag
Version: 1.2.28
Release: 1
Source: %{name}-%{version}.tar.gz
License: GPL
Summary: Tests to verify hardware
Group: Applications/Devel
BuildArch: noarch
Requires: bash, coreutils
Requires: dmidecode, ethtool, hdparm
Requires: perl perl-Test-Harness
# infiniband-diags is not required, no ibstat == NOTRUN

# Detect init system: use systemd for RHEL >= 10 or Fedora >= 40
%if 0%{?rhel} >= 10 || 0%{?fedora} >= 40
%define use_systemd 1
BuildRequires: systemd
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd
%else
%define use_systemd 0
Requires(post): /sbin/chkconfig
Requires(preun): /sbin/chkconfig
%endif

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}

%define libperl %{_datarootdir}/perl5
%description
Tests to verify hardware

%prep
%setup -q -n %{name}-%{version}

%build

%install
rm -rf ${RPM_BUILD_ROOT}
%{__mkdir_p} %{buildroot}%{_bindir}
%{__mkdir_p} %{buildroot}%{_sysconfdir}/nodediag.d
%{__mkdir_p} %{buildroot}%{_sysconfdir}/sysconfig/nodediag.d
%{__mkdir_p} %{buildroot}%{_mandir}/man1
%{__mkdir_p} %{buildroot}%{libperl}/TAP/Formatter/Nodediag

%{__install} -m 0755 nodediag %{buildroot}%{_bindir}/nodediag
%{__install} -m 0755 diags/* %{buildroot}%{_sysconfdir}/nodediag.d/
%{__install} -m 0644 nodediag.sysconfig %{buildroot}%{_sysconfdir}/sysconfig/nodediag
%{__install} -m 0755 man/nodediag.1 %{buildroot}%{_mandir}/man1/nodediag.1
%{__install} -m 0644 lib/TAP/Formatter/Nodediag.pm %{buildroot}%{libperl}/TAP/Formatter/Nodediag.pm
%{__install} -m 0644 lib/TAP/Formatter/Nodediag/Session.pm %{buildroot}%{libperl}/TAP/Formatter/Nodediag/Session.pm

%if %{use_systemd}
%{__mkdir_p} %{buildroot}%{_unitdir}
%{__install} -m 0644 nodediag.service %{buildroot}%{_unitdir}/nodediag.service
%else
%{__mkdir_p} %{buildroot}%{_initrddir}
%{__install} -m 0755 nodediag.init %{buildroot}%{_initrddir}/nodediag
%endif

%clean
if [ %{buildroot} != "/" ]; then
  %{__rm} -rf %{buildroot}
fi

%if %{use_systemd}
%post
%systemd_post nodediag.service

%preun
%systemd_preun nodediag.service

%postun
%systemd_postun nodediag.service

%else
%post
if [ "$1" = "1" ]; then
  if [ -x /sbin/chkconfig ] ; then
    /sbin/chkconfig --add nodediag
  fi
fi

%preun
if [ "$1" = "0" ]; then
  if [ -x /sbin/chkconfig ] ; then
    /sbin/chkconfig --del nodediag
  fi
fi
%endif

%files
%defattr(-,root,root,0755)
%doc README DISCLAIMER COPYING
%dir %{_sysconfdir}/sysconfig/nodediag.d
%dir %{_sysconfdir}/nodediag.d
%{_sysconfdir}/nodediag.d/*
%{_bindir}/nodediag
%{_mandir}/man1/*
%{libperl}/TAP/Formatter/Nodediag.pm
%dir %{libperl}/TAP/Formatter/Nodediag
%{libperl}/TAP/Formatter/Nodediag/Session.pm
%if %{use_systemd}
%{_unitdir}/nodediag.service
%else
%{_initrddir}/nodediag
%endif
%defattr(-,root,root,0644)
%config(noreplace) %{_sysconfdir}/sysconfig/nodediag

%changelog
