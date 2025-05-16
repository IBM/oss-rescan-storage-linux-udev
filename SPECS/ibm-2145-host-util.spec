%define _topdir %{getenv:PWD}

Name:           ibm-2145-host-util
Version:        1.0
Release:        1%{?dist}
Summary:        Utility to auto rescan IBM Flashsystem storage devices
License:        Apache-2.0

Requires:       redhat-release >= 7.9
Requires:       sg3_utils >= 1.37
Requires:       bash
Requires:       at
Requires(pre):  systemd
BuildArch:      noarch

Source0:        ibm_2145_udev_sched_main.sh
Source1:        ibm_2145_udev_action_rescan.sh
Source2:        ibm_2145_udev_action_cleanup.sh
Source3:        91-ibm-2145-udev-ua.rules
Source4:        ibm_udev_rescan
Source5:        ibm_2145_rescan_tmpfiles.conf


%global debug_package %{nil}

%description
This package automates storage discovery for Linux hosts.

%prep
# No need to extract files

%pre
# Check if atd service is running
if ! systemctl is-active --quiet atd; then
    echo "Pre-requisite error: atd daemon is not running. Please start the daemon before installing." >&2
    exit 1
fi

%install
mkdir -p %{buildroot}/bin/
mkdir -p %{buildroot}/etc/udev/rules.d/
mkdir -p %{buildroot}/etc/logrotate.d/
mkdir -p %{buildroot}/var/log/ibm_2145/udev/
mkdir -p %{buildroot}/etc/tmpfiles.d/

install -m 755 %{SOURCE0} %{buildroot}/bin/ibm_2145_udev_sched_main.sh
install -m 755 %{SOURCE1} %{buildroot}/bin/ibm_2145_udev_action_rescan.sh
install -m 755 %{SOURCE2} %{buildroot}/bin/ibm_2145_udev_action_cleanup.sh
install -m 644 %{SOURCE3} %{buildroot}/etc/udev/rules.d/91-ibm-2145-udev-ua.rules
install -m 644 %{SOURCE4} %{buildroot}/etc/logrotate.d/ibm_udev_rescan
install -m 644 %{SOURCE5} %{buildroot}/etc/tmpfiles.d/ibm_2145_rescan_tmpfiles.conf

%post
# Reload udev rules
udevadm control --reload

%postun
# Reload udev rules on uninstall
udevadm control --reload
# Remove log files
rm -f /var/log/ibm_2145/udev/rescan*.log
# Remove compressed log files
rm -f /var/log/ibm_2145/udev/rescan*.log*.gz
# Remove empty log directory if it exists
log_dir="/var/log/ibm_2145/udev"
if [ -d "$log_dir" ]; then
    if [ -z "$(ls -A "$log_dir")" ]; then
        rmdir "$log_dir"
    else
        echo "The log directory '$log_dir' was not removed because it contains some custom files. Please delete it manually."
    fi
fi

log_dir="/var/log/ibm_2145"
if [ -d "$log_dir" ]; then
    if [ -z "$(ls -A "$log_dir")" ]; then
        rmdir "$log_dir"
    else
        echo "The log directory '$log_dir' was not removed because it contains some custom files. Please delete it manually."
    fi
fi

%files
%defattr(-,root,root)
/bin/ibm_2145_udev_sched_main.sh
/bin/ibm_2145_udev_action_rescan.sh
/bin/ibm_2145_udev_action_cleanup.sh
/etc/udev/rules.d/91-ibm-2145-udev-ua.rules
/etc/logrotate.d/ibm_udev_rescan
/etc/tmpfiles.d/ibm_2145_rescan_tmpfiles.conf
%attr(755,root,root) %dir /var/log/ibm_2145/
%attr(755,root,root) %dir /var/log/ibm_2145/udev/

%changelog
