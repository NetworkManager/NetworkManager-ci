config_opts['chroot_setup_cmd'] = 'install tar gcc-c++ redhat-rpm-config redhat-release which xz sed make bzip2 gzip gcc coreutils unzip shadow-utils diffutils cpio bash gawk rpm-build info patch util-linux findutils grep'
config_opts['dist'] = 'el8'  # only useful for --resultdir variable subst
config_opts['extra_chroot_dirs'] = [ '/run/lock', ]
config_opts['releasever'] = '8'
config_opts['package_manager'] = 'dnf'
config_opts['bootstrap_image'] = 'registry.access.redhat.com/ubi8/ubi'
config_opts['description'] = 'RHEL 8'

#config_opts['dnf_install_command'] += ' subscription-manager'
#config_opts['yum_install_command'] += ' subscription-manager'

config_opts['root'] = 'rhel-8-{{ target_arch }}'

config_opts['redhat_subscription_required'] = False

config_opts['dnf.conf'] = """
[main]
keepcache=1
debuglevel=2
reposdir=/dev/null
logfile=/var/log/yum.log
retries=20
obsoletes=1
gpgcheck=1
assumeyes=1
syslog_ident=mock
syslog_device=
install_weak_deps=0
metadata_expire=0
best=1
module_platform_id=platform:el8
protected_packages=
user_agent={{ user_agent }}
best=0

# repos

###
#   Add your
#     * BaseOS
#     * AppStream
#     * CRB
#   repos here. Plus updates if using released version
###

"""
