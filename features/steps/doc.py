from behave import step

chapters = {
    "Network interface device naming hierarchy": "network-interface-device-naming-hierarchy_consistent-network-interface-device-naming",
    "How the network device renaming works": "how-the-network-device-naming-works_consistent-network-interface-device-naming",
    "Predictable network interface device names on the x86_64 platform explained": "predictable-network-interface-device-names-on-the-x86_64-platform-explained_consistent-network-interface-device-naming",
    "Predictable network interface device names on the System z platform explained": "predictable-network-interface-device-names-on-the-system-z-platform-explained_consistent-network-interface-device-naming",
    "Disabling consistent interface device naming during the installation": "disabling-consistent-interface-device-naming-during-the-installation_consistent-network-interface-device-naming",
    "Disabling consistent interface device naming on an installed system": "disabling-consistent-interface-device-naming-on-an-installed-system_consistent-network-interface-device-naming",
    "Customizing the prefix of Ethernet interfaces": "proc_customizing-the-prefix-of-ethernet-interfacesconsistent-network-interface-device-naming",
    "Benefits of using NetworkManager": "benefits-of-using-networkmanager_getting-started-with-networkmanager",
    "An overview of utilities and applications you can use to manage NetworkManager connections": "an-overview-of-utilities-and-applications-you-can-use-to-manage-networkmanager-connections_getting-started-with-networkmanager",
    "Loading manually-created ifcfg files into NetworkManager": "loading-manually-created-ifcfg-files-into-networkmanager_getting-started-with-networkmanager",
    "Permanently configuring a device as unmanaged in NetworkManager": "permanently-configuring-a-device-as-unmanaged-in-networkmanager_configuring-networkmanager-to-ignore-certain-devices",
    "Temporarily configuring a device as unmanaged in NetworkManager": "temporarily-configuring-a-device-as-unmanaged-in-networkmanager_configuring-networkmanager-to-ignore-certain-devices",
    "Starting the nmtui utility": "starting-the-nmtui-utility_using-nmtui-to-manage-network-connections-using-a-text-based-interface",
    "Adding a connection profile using nmtui": "proc_adding-a-connection-profile-using-nmtui_using-nmtui-to-manage-network-connections-using-a-text-based-interface",
    "Applying changes to a modified connection using nmtui": "applying-changes-to-a-modified-connection-using-nmtui_using-nmtui-to-manage-network-connections-using-a-text-based-interface",
    "The different output formats of nmcli": "the-different-output-formats-of-nmcli_getting-started-with-nmcli",
    "Using tab completion in nmcli": "using-tab-completion-in-nmcli_getting-started-with-nmcli",
    "Frequent nmcli commands": "ref-frequent-nmcli-commands_getting-started-with-nmcli",
    "Connecting to a network using the GNOME Shell network connection icon": "connecting-to-a-network-using-the-gnome-shell-network-connection-icon_getting-started-with-configuring-networking-using-the-gnome-gui",
    "Using the libnmstate library in a Python application": "con_using-the-libnmstate-library-in-a-python-application_assembly_introduction-to-nmstate",
    "Updating the current network configuration using nmstatectl": "proc_updating-the-current-network-configuration-using-nmstatectl_assembly_introduction-to-nmstate",
    "Configuring a static Ethernet connection using nmcli": "configuring-a-static-ethernet-connection-using-nmcli_configuring-an-ethernet-connection",
    "Configuring a static Ethernet connection using the nmcli interactive editor": "configuring-a-static-ethernet-connection-using-the-nmcli-interactive-editor_configuring-an-ethernet-connection",
    "Configuring a static Ethernet connection using nmstatectl": "proc_configuring-a-static-ethernet-connection-using-nmstatectl_configuring-an-ethernet-connection",
    "Configuring a static Ethernet connection using RHEL System Roles with the interface name": "configuring-a-static-ethernet-connection-using-rhel-system-roles-with-the-interface-name_configuring-an-ethernet-connection",
    "Configuring a static Ethernet connection using RHEL System Roles with a device path": "configuring-a-static-ethernet-connection-using-rhel-system-roles-with-a-device-path_configuring-an-ethernet-connection",
    "Configuring a dynamic Ethernet connection using nmcli": "configuring-a-dynamic-ethernet-connection-using-nmcli_configuring-an-ethernet-connection",
    "Configuring a dynamic Ethernet connection using the nmcli interactive editor": "configuring-a-dynamic-ethernet-connection-using-the-nmcli-interactive-editor_configuring-an-ethernet-connection",
    "Configuring a dynamic Ethernet connection using nmstatectl": "proc_configuring-a-dynamic-ethernet-connection-using-nmstatectl_configuring-an-ethernet-connection",
    "Configuring a dynamic Ethernet connection using RHEL System Roles with the interface name": "configuring-a-dynamic-ethernet-connection-using-rhel-system-roles-with-the-interface-name_configuring-an-ethernet-connection",
    "Configuring a dynamic Ethernet connection using RHEL System Roles with a device path": "configuring-a-dynamic-ethernet-connection-using-rhel-system-roles-with-a-device-path_configuring-an-ethernet-connection",
    "Configuring an Ethernet connection using control-center": "configuring-an-ethernet-connection-using-control-center_configuring-an-ethernet-connection",
    "Configuring an Ethernet connection using nm-connection-editor": "configuring-an-ethernet-connection-using-nm-connection-editor_configuring-an-ethernet-connection",
    "Configuring the DHCP behavior of a NetworkManager connection": "configuring-the-dhcp-behavior-of-a-networkmanager-connection_configuring-an-ethernet-connection",
    "Setting the wireless regulatory domain": "Setting_the_Wireless_Regulatory_Domain_managing-wi-fi-connections",
    "Configuring a Wi-Fi connection using nmcli": "configuring-a-wifi-using-nmcli_managing-wi-fi-connections",
    "Configuring a Wi-Fi connection using control-center": "Configuring-a-Wi-Fi-connection-using-control_-center_managing-wi-fi-connections",
    "Connecting to a Wi-Fi network with nmcli": "connecting-to-a-Wi-Fi-network-with-nmcli_managing-wi-fi-connections",
    "Connecting to a hidden Wi-Fi network using nmcli": "proc_connecting-to-a-hidden-wi-fi-network-using-nmcli_managing-wi-fi-connections",
    "Connecting to a Wi-Fi network using the GNOME GUI": "connecting_to_a_wifi_network_managing-wi-fi-connections",
    "Configuring 802.1X network authentication on an existing Wi-Fi connection using nmcli": "configuring-802-1x-network-authentication-on-an-existing-wi-fi-connection-using-nmcli_managing-wi-fi-connections",
    "Configuring VLAN tagging using nmcli commands": "configuring-vlan-tagging-using-nmcli-commands_configuring-vlan-tagging",
    "Configuring VLAN tagging using nm-connection-editor": "configuring-vlan-tagging-using-nm-connection-editor_configuring-vlan-tagging",
    "Configuring VLAN tagging using nmstatectl": "proc_configuring-vlan-tagging-using-nmstatectl_configuring-vlan-tagging",
    "Configuring VLAN tagging using System Roles": "proc_configuring-vlan-tagging-using-system-roles_configuring-vlan-tagging",
    "Benefits of VXLANs": "con_benefits-of-vxlans_assembly_using-a-vxlan-to-create-a-virtual-layer-2-domain-for-vms",
    "Configuring the Ethernet interface on the hosts": "proc_configuring-the-ethernet-interface-on-the-hosts_assembly_using-a-vxlan-to-create-a-virtual-layer-2-domain-for-vms",
    "Creating a network bridge with a VXLAN attached": "proc_creating-a-network-bridge-with-a-vxlan-attached_assembly_using-a-vxlan-to-create-a-virtual-layer-2-domain-for-vms",
    "Creating a virtual network in libvirt with an existing bridge": "proc_creating-a-virtual-network-in-libvirt-with-an-existing-bridge_assembly_using-a-vxlan-to-create-a-virtual-layer-2-domain-for-vms",
    "Configuring virtual machines to use VXLAN": "proc_proc_configuring-virtual-machines-to-use-vxlan_assembly_using-a-vxlan-to-create-a-virtual-layer-2-domain-for-vms",
    "Configuring a network bridge using nmcli commands": "configuring-a-network-bridge-using-nmcli-commands_configuring-a-network-bridge",
    "Configuring a network bridge using nm-connection-editor": "configuring-a-network-bridge-using-nm-connection-editor_configuring-a-network-bridge",
    "Configuring a network bridge using nmstatectl": "proc_configuring-a-network-bridge-using-nmstatectl_configuring-a-network-bridge",
    "Migrating a network team configuration to network bond": "proc_migrating-a-network-team-configuration-to-network-bond_configuring-network-teaming",
    "Understanding network teaming": "understanding-network-teaming_configuring-network-teaming",
    "Teaming: Understanding the default behavior of controller and port interfaces": "understanding-the-default-behavior-of-controller-and-port-interfaces_configuring-network-teaming",
    "teaming: Comparison of network teaming and bonding features": "comparison-of-network-teaming-and-bonding-features_configuring-network-teaming",
    "Understanding the teamd service, runners, and link-watchers": "understanding-the-teamd-service-runners-and-link-watchers_configuring-network-teaming",
    "Installing the teamd service": "installing-the-teamd-service_configuring-network-teaming",
    "Configuring a network team using nmcli commands": "configuring-a-network-team-using-nmcli-commands_configuring-network-teaming",
    "Configuring a network team using nm-connection-editor": "configuring-a-network-team-using-nm-connection-editor_configuring-network-teaming",
    "Understanding network bonding": "understanding-network-bonding_configuring-network-bonding",
    "Bonding: Understanding the default behavior of controller and port interfaces": "understanding-the-default-behavior-of-controller-and-port-interfaces_configuring-network-bonding",
    "Bonding: Comparison of network teaming and bonding features": "comparison-of-network-teaming-and-bonding-features_configuring-network-bonding",
    "Upstream Switch Configuration Depending on the Bonding Modes": "upstream-switch-configuration-depending-on-the-bonding-modes_configuring-network-bonding",
    "Configuring a network bond using nmcli commands": "configuring-a-network-bond-using-nmcli-commands_configuring-network-bonding",
    "Configuring a network bond using nm-connection-editor": "configuring-a-network-bond-using-nm-connection-editor_configuring-network-bonding",
    "Configuring a network bond using nmstatectl": "proc_configuring-a-network-bond-using-nmstatectl_configuring-network-bonding",
    "Configuring a network bond using RHEL System Roles": "proc_configuring-a-network-bond-using-rhel-system-roles_configuring-network-bonding",
    "Creating a network bond to enable switching between an Ethernet and wireless connection without interrupting the VPN": "creating-a-network-bond-to-enable-switching-between-an-ethernet-and-wireless-connection-without-interrupting-the-vpn_configuring-network-bonding",
    "Protocols and primitives used by WireGuard": "ref_protocols-and-primitives-used-by-wireguard_assembly_setting-up-a-wireguard-vpn",
    "How WireGuard uses tunnel IP addresses, public keys, and remote endpoints": "con_how-wireguard-uses-tunnel-ip-addresses-public-keys-and-remote-endpoints_assembly_setting-up-a-wireguard-vpn",
    "Using a WireGuard client behind NAT and firewalls": "con_using-a-wireguard-client-behind-nat-and-firewalls_assembly_setting-up-a-wireguard-vpn",
    "Creating private and public keys to be used in WireGuard connections": "proc_creating-private-and-public-keys-to-be-used-in-wireguard-connections_assembly_setting-up-a-wireguard-vpn",
    "Configuring a WireGuard server using nmcli": "proc_configuring-a-wireguard-using-nmcli_assembly_setting-up-a-wireguard-vpn",
    "Configuring a WireGuard server using nm-connection-editor": "proc_configuring-a-wireguard-server-using-nm-connection-editor_assembly_setting-up-a-wireguard-vpn",
    "Configuring a WireGuard server using the wg-quick service": "proc_configuring-a-wireguard-server-using-the-wg-quick-service_assembly_setting-up-a-wireguard-vpn",
    "Configuring firewalld on a WireGuard server using the command line": "proc_configuring-firewalld-on-a-wireguard-server-using-the-command-line_assembly_setting-up-a-wireguard-vpn",
    "Configuring firewalld on a WireGuard server using the graphical interface": "proc_configuring-firewalld-on-a-wireguard-server-using-the-graphical-interface_assembly_setting-up-a-wireguard-vpn",
    "Configuring a WireGuard client using nmcli": "proc_configuring-a-wireguard-client-using-nmcli_assembly_setting-up-a-wireguard-vpn",
    "Configuring a WireGuard client using nm-connection-editor": "proc_configuring-a-wireguard-client-using-nm-connection-editor_assembly_setting-up-a-wireguard-vpn",
    "Configuring a WireGuard client using the wg-quick service": "proc_configuring-a-wireguard-client-using-the-wg-quick-service_assembly_setting-up-a-wireguard-vpn",
    "Configuring a VPN connection with control-center": "configuring-a-VPN-connection-with-control-center_configuring-a-vpn-connection",
    "Configuring automatic detection and usage of ESP hardware offload to accelerate an IPsec connection": "proc_configuring-automatic-detection-and-usage-of-esp-hardware-offload-to-accelerate-an-ipsec-connection_configuring-a-vpn-connection",
    "Configuring ESP hardware offload on a bond to accelerate an IPsec connection": "proc_configuring-esp-hardware-offload-on-a-bond-to-accelerate-an-ipsec-connection_configuring-a-vpn-connection",
    "Configuring an IPIP tunnel using nmcli to encapsulate IPv4 traffic in IPv4 packets": "configuring-an-ipip-tunnel-using-nmcli-to-encapsulate--ipv4-traffic-in-ipv4-packets_configuring-ip-tunnels",
    "Configuring a GRE tunnel using nmcli to encapsulate layer-3 traffic in IPv4 packets": "configuring-a-gre-tunnel-using-nmcli-to-encapsulate-layer-3-traffic-in-ipv4-packets_configuring-ip-tunnels",
    "Configuring a GRETAP tunnel to transfer Ethernet frames over IPv4": "configuring-a-gretap-tunnel-to-transfer-ethernet-frames-over-ipv4_configuring-ip-tunnels",
    "Installing the legacy network scripts": "proc_installing-the-legacy-network-scriptsassembly_legacy-network-scripts-support-in-rhel",
    "Mirroring a network interface using nmcli": "proc_mirroring-a-network-interface-using-nmcli_assembly_port-mirroring",
    "Temporarily configuring a network device to accept all traffic using iproute2": "proc_temporarily-configuring-a-network-network-device-to-accept-all-traffic-using-iproute2_assembly_configuring-network-devices-to-accept-traffic-from-all-mac-addresses",
    "Permanently configuring a network device to accept all traffic using nmcli": "proc_permanently-configuring-a-network-device-to-accept-all-traffic-using-nmcli_assembly_configuring-network-devices-to-accept-traffic-from-all-mac-addresses",
    "Permanently configuring a network network device to accept all traffic using nmstatectl": "proc_permanently-configuring-a-network-network-device-to-accept-all-traffic-using-nmstatectl_assembly_configuring-network-devices-to-accept-traffic-from-all-mac-addresses",
    "Configuring 802.1X network authentication on an existing Ethernet connection using nmcli": "configuring-802-1x-network-authentication-on-an-existing-ethernet-connection-using-nmcli_authenticating-a-rhel-client-to-the-network-using-the-802-1x-standard-with-a-certificate-stored-on-the-file-system",
    "Configuring a static Ethernet connection with 802.1X network authentication using nmstatectl": "proc_configuring-a-static-ethernet-connection-with-802-1x-network-authentication-using-nmstatectl_authenticating-a-rhel-client-to-the-network-using-the-802-1x-standard-with-a-certificate-stored-on-the-file-system",
    "Configuring a static Ethernet connection with 802.1X network authentication using RHEL System Roles": "configuring-a-static-ethernet-connection-with-802-1x-network-authentication-using-rhel-system-roles_authenticating-a-rhel-client-to-the-network-using-the-802-1x-standard-with-a-certificate-stored-on-the-file-system",
    "Setting the default gateway on an existing connection using nmcli": "setting-the-default-gateway-on-an-existing-connection-using-nmcli_managing-the-default-gateway-setting",
    "Setting the default gateway on an existing connection using the nmcli interactive mode": "setting-the-default-gateway-on-an-existing-connection-using-the-nmcli-interactive-mode_managing-the-default-gateway-setting",
    "Setting the default gateway on an existing connection using nm-connection-editor": "setting-the-default-gateway-on-an-existing-connection-using-nm-connection-editor_managing-the-default-gateway-setting",
    "Setting the default gateway on an existing connection using control-center": "setting-the-default-gateway-on-an-existing-connection-using-control-center_managing-the-default-gateway-setting",
    "Setting the default gateway on an existing connection using nmstatectl": "proc_setting-the-default-gateway-on-an-existing-connection-using-nmstatectl_managing-the-default-gateway-setting",
    "Setting the default gateway on an existing connection using System Roles": "proc_setting-the-default-gateway-on-an-existing-connection-using-system-roles_managing-the-default-gateway-setting",
    "Setting the default gateway on an existing connection when using the legacy network scripts": "setting-the-default-gateway-on-an-existing-connection-when-using-the-legacy-network-scripts_managing-the-default-gateway-setting",
    "How NetworkManager manages multiple default gateways": "con_how-networkmanager-manages-multiple-default-gateways_managing-the-default-gateway-setting",
    "Configuring NetworkManager to avoid using a specific profile to provide a default gateway": "proc_configuring-networkmanager-to-avoid-using-a-specific-profile-to-provide-a-default-gateway_managing-the-default-gateway-setting",
    "Fixing unexpected routing behavior due to multiple default gateways": "proc_fixing-unexpected-routing-behavior-due-to-multiple-default-gateways_managing-the-default-gateway-setting",
    "How to use the nmcli command to configure a static route": "how-to-use-the-nmcli-command-to-configure-a-static-route_configuring-static-routes",
    "Configuring a static route using an nmcli command": "configuring-a-static-route-using-an-nmcli-command_configuring-static-routes",
    "Configuring a static route using control-center": "configuring-a-static-route-using-control-center_configuring-static-routes",
    "Configuring a static route using nm-connection-editor": "configuring-a-static-route-using-nm-connection-editor_configuring-static-routes",
    "Configuring a static route using the nmcli interactive mode": "configuring-a-static-route-using-the-nmcli-interactive-mode_configuring-static-routes",
    "Configuring a static route using nmstatectl": "proc_configuring-a-static-route-using-nmstatectl_configuring-static-routes",
    "Configuring a static route using RHEL System Roles": "proc_configuring-a-static-route-using-rhel-system-roles_configuring-static-routes",
    "Creating static routes configuration files in key-value-format when using the legacy network scripts": "creating-static-routes-configuration-files-in-key-value-format-when-using-the-legacy-network-scripts_configuring-static-routes",
    "Creating static routes configuration files in ip-command-format when using the legacy network scripts": "creating-static-routes-configuration-files-in-ip-command-format-when-using-the-legacy-network-scripts_configuring-static-routes",
    "Routing traffic from a specific subnet to a different default gateway using NetworkManager": "routing-traffic-from-a-specific-subnet-to-a-different-default-gateway-using-networkmanager_configuring-policy-based-routing-to-define-alternative-routes",
    "Overview of configuration files involved in policy-based routing when using the legacy network scripts": "overview-of-configuration-files-involved-in-policy-based-routing-when-using-the-legacy-network-scripts_configuring-policy-based-routing-to-define-alternative-routes",
    "Routing traffic from a specific subnet to a different default gateway using the legacy network scripts": "routing-traffic-from-a-specific-subnet-to-a-different-default-gateway-using-the-legacy-network-scripts_configuring-policy-based-routing-to-define-alternative-routes",
    "Creating a dummy interface with both an IPv4 and IPv6 address using nmcli": "creating-a-dummy-interface-with-both-an-ipv4-and-ipv6-address-using-nmcli_creating-a-dummy-interface",
    "Using nmstate-autoconf to automatically configure network interfaces": "proc_using-nmstate-autoconf-to-automatically-configure-network-interfaces_assembly_using-nmstate-autoconf-to-automatically-configure-the-network-state-using-lldp",
    "The key file format of NetworkManager profiles": "con_the-key-file-format-of-networkmanager-profiles_assembly_manually-creating-networkmanager-profiles-in-key-file-format",
    "Creating a NetworkManager profile in key file format": "proc_creating-a-networkmanager-profile-in-key-file-format_assembly_manually-creating-networkmanager-profiles-in-key-file-format",
    "Configuring the netconsole service to log kernel messages to a remote host": "configuring-the-netconsole-service-to-log-kernel-messages-to-a-remote-host_using-netconsole-to-log-kernel-messages-over-a-network",
    "Differences between the network and network-online systemd target": "differences-between-the-network-and-network-online-systemd-target_systemd-network-targets-and-services",
    "Overview of NetworkManager-wait-online": "overview-of-networkmanager-wait-online_systemd-network-targets-and-services",
    "Configuring a systemd service to start after the network has been started": "configuring-a-systemd-service-to-start-after-the-network-has-been-started_systemd-network-targets-and-services",
    "Overview of queuing disciplines": "overview-of-queuing-disciplines_linux-traffic-control",
    "Available qdiscs in RHEL": "available-qdiscs-in-rhel_linux-traffic-control",
    "Inspecting qdiscs of a network interface using the tc utility": "inspecting-qdisc-of-a-network-interface-using-the-tc-utility_linux-traffic-control",
    "Updating the default qdisc": "updating-the-default-qdisc_linux-traffic-control",
    "Temporarily setting the current qdisk of a network interface using the tc utility": "temporarily-setting-the-current-qdisk-of-a-network-interface-using-the-tc-utility_linux-traffic-control",
    "Permanently setting the current qdisk of a network interface using NetworkManager": "proc_permanently-setting-the-current-qdisk-of-a-network-interface-using-networkmanager_linux-traffic-control",
    "MPTCP benefits": "mptcp-benefits_getting-started-with-multipath-tcp",
    "Preparing RHEL to enable MPTCP support": "preparing-rhel-to-enable-mptcp-support_getting-started-with-multipath-tcp",
    "Using iproute2 to configure and enable multiple paths for MPTCP applications": "using-iproute2-to-configure-and-enable-multiple-paths-for-mptcp-applications_getting-started-with-multipath-tcp",
    "Disabling Multipath TCP in the kernel": "disabling-multipath-tcp-in-the-kernel_getting-started-with-multipath-tcp",
    "How NetworkManager orders DNS servers in /etc/resolv.conf": "how-networkmanager-orders-dns-servers-in-etc-resolv-conf_configuring-the-order-of-dns-servers",
    "Setting a NetworkManager-wide default DNS server priority value": "setting-a-networkmanager-wide-default-dns-server-priority-value_configuring-the-order-of-dns-servers",
    "Setting the DNS priority of a NetworkManager connection": "setting-the-dns-priority-of-a-networkmanager-connection_configuring-the-order-of-dns-servers",
    "Configuring an interface with static network settings using ifcfg files": "configuring-an-interface-with-static-network-settings-using-ifcfg-files_configuring-ip-networking-with-ifcfg-files",
    "Configuring an interface with dynamic network settings using ifcfg files": "configuring-an-interface-with-dynamic-network-settings-using-ifcfg-files_configuring-ip-networking-with-ifcfg-files",
    "Managing system-wide and private connection profiles with ifcfg files": "managing-system-wide-and-private-connection-profiles-with-ifcfg-files_configuring-ip-networking-with-ifcfg-files",
    "Disabling IPv6 on a connection using nmcli": "disabling-ipv6-on-a-connection-using-nmcli_using-networkmanager-to-disable-ipv6-for-a-specific-connection",
    "Disabling DNS processing in the NetworkManager configuration": "disabling-dns-processing-in-the-networkmanager-configuration_manually-configuring-the-etc-resolv-conf-file",
    "Replacing /etc/resolv.conf with a symbolic link to manually configure DNS settings": "replacing-etc-resolv-conf-with-a-symbolic-link-to-manually-configure-dns-settings_manually-configuring-the-etc-resolv-conf-file",
    "Displaying the number of dropped packets": "displaying-the-number-of-dropped-packets_monitoring-and-tuning-the-rx-ring-buffer",
    "Increasing the RX ring buffer to reduce a high packet drop rate": "increasing-the-rx-ring-buffer-to-reduce-a-high-packet-drop-rate_monitoring-and-tuning-the-rx-ring-buffer",
    "Configuring 802.3 link settings with nmcli tool": "configuring-link-settings-with-nmcli-tool_configuring-802-3-link-settings",
    "Offload features supported by NetworkManager": "offload-features-supported-by-networkmanager_configuring-ethtool-offload-features",
    "Configuring an ethtool offload feature using NetworkManager": "configuring-an-ethtool-offload-feature-using-networkmanager_configuring-ethtool-offload-features",
    "Using System Roles to set ethtool features": "proc_using-system-roles-to-set-ethtool-features_configuring-ethtool-offload-features",
    "Coalesce settings supported by NetworkManager": "ref_coalesce-settings-supported-by-networkmanager_assembly_configuring-ethtool-coalesce-settings",
    "Configuring ethtool coalesce settings using NetworkManager": "proc_configuring-ethtool-coalesce-settings-using-networkmanager_assembly_configuring-ethtool-coalesce-settings",
    "Using System Roles to configure ethtool coalesce settings": "proc_using-system-roles-to-configure-ethtool-coalesce-settings_assembly_configuring-ethtool-coalesce-settings",
    "Configuring a MACsec connection using nmcli": "proc_configuring-a-macsec-connection-using-nmcli_assembly_using-macsec-to-encrypt-layer-2-traffic-in-the-same-physical-network",
    "Sending DNS requests for a specific domain to a selected DNS server": "sending-dns-requests-for-a-specific-domain-to-a-selected-dns-servers_using-different-dns-servers-for-different-domains",
    "IPVLAN overview": "ipvlan-overview_getting-started-with-ipvlan",
    "IPVLAN modes": "ipvlan-modes_getting-started-with-ipvlan",
    "Overview of MACVLAN": "overview-of-macvlan_getting-started-with-ipvlan",
    "Comparison of IPVLAN and MACVLAN": "ipvlan-and-macvlan_getting-started-with-ipvlan",
    "Creating and configuring the IPVLAN device using iproute2": "creating-and-configuring-the-ipvlan-device-using-iproute2_getting-started-with-ipvlan",
    "Permanently reusing the same IP address on different interfaces": "permanently-reusing-the-same-ip-address-on-different-interfaces_reusing-the-same-ip-address-on-different-interfaces",
    "Temporarily reusing the same IP address on different interfaces": "temporarily-reusing-the-same-ip-address-on-different-interfaces_reusing-the-same-ip-address-on-different-interfaces",
    "Configuring a VRF device": "proc_configuring-a-vrf-device_assembly_starting-a-service-within-an-isolated-vrf-network",
    "Starting a service within an isolated VRF network": "proc_starting-a-service-within-an-isolated-vrf-network_assembly_starting-a-service-within-an-isolated-vrf-network",
    "Introduction to FRRouting": "intro-to-frr_setting-your-routing-protocols",
    "Setting up FRRouting": "setting-up-frrouting_setting-your-routing-protocols",
    "Modifying the configuration of FRR": "changing-frrs-configuration_setting-your-routing-protocols",
    "Modifying a configuration of a particular daemon": "modifying-a-configuration-of-a-particular-daemon_setting-your-routing-protocols",
    "Using the ping utility to verify the IP connection to other hosts": "using-the-ping-utility-to-verify-the-ip-connection-to-other-hosts_testing-basic-network-settings",
    "Using the host utility to verify name resolution": "using-the-host-utility-to-verify-name-resolution_testing-basic-network-settings",
    "The concept of NetworkManager dispatcher scripts": "con_the-concept-of-networkmanager-dispatcher-scripts_assembly_running-dhclient-exit-hooks-using-networkmanager-a-dispatcher-script",
    "Creating a NetworkManager dispatcher script that runs dhclient exit hooks": "proc_creating-a-networkmanager-dispatcher-script-that-runs-dhclient-exit-hooks_assembly_running-dhclient-exit-hooks-using-networkmanager-a-dispatcher-script",
    "Debugging levels and domains": "debugging-levels-and-domains_introduction-to-networkmanager-debugging",
    "Setting the NetworkManager log level": "setting-the-networkmanager-log-level_introduction-to-networkmanager-debugging",
    "Temporarily setting log levels at run time using nmcli": "temporarily-setting-log-levels-at-run-time-using-nmcli_introduction-to-networkmanager-debugging",
    "Viewing NetworkManager logs": "viewing-networkmanager-logs_introduction-to-networkmanager-debugging",
    "Using xdpdump to capture network packets including packets dropped by XDP programs": "using-xdpdump-to-capture-network-packets-including-packets-dropped-by-xdp-programs_capturing-network-packets",
    "The difference between static and dynamic IP addressing": "the-differences-between-static-and-dynamic-ip-addressing_providing-dhcp-services",
    "DHCP transaction phases": "dhcp-transaction-phases_providing-dhcp-services",
    "The differences when using dhcpd for DHCPv4 and DHCPv6": "the-differences-when-using-dhcpd-for-dhcpv4-and-dhcpv6_providing-dhcp-services",
    "The lease database of the dhcpd service": "the-lease-database-of-the-dhcpd-service_providing-dhcp-services",
    "Comparison of DHCPv6 to radvd": "comparison-of-dhcpv6-to-radvd_providing-dhcp-services",
    "Configuring the radvd service for IPv6 routers": "configuring-the-radvd-service-for-ipv6-routers_providing-dhcp-services",
    "Setting network interfaces for the DHCP servers": "setting-network-interfaces-for-the-dhcp-server_providing-dhcp-services",
    "Setting up the DHCP service for subnets directly connected to the DHCP server": "setting-up-the-dhcp-service-for-subnets-directly-connected-to-the-dhcp-server_providing-dhcp-services",
    "Setting up the DHCP service for subnets that are not directly connected to the DHCP server": "setting-up-the-dhcp-service-for-subnets-that-are-not-directly-connected-to-the-dhcp-server_providing-dhcp-services",
    "Assigning a static address to a host using DHCP": "assigning-a-static-address-to-a-host-using-dhcp_providing-dhcp-services",
    "Using a group declaration to apply parameters to multiple hosts, subnets, and shared networks at the same time": "using-a-group-declaration-to-apply-parameters-to-multiple-hosts-subnets-and-shared-networks-at-the-same-time_providing-dhcp-services",
    "Restoring a corrupt lease database": "restoring-a-corrupt-lease-database_providing-dhcp-services",
    "Setting up a DHCP relay agent": "setting-up-a-dhcp-relay-agent_providing-dhcp-services",
    "Installing BIND": "proc_installing-bind_assembly_configuring-and-managing-a-bind-dns-server",
    "Configuring BIND as a caching name server": "proc_configuring-bind-as-a-caching-name-server_assembly_configuring-and-managing-a-bind-dns-server",
    "Getting started with <code class=\"literal\">firewalld</code>": "getting-started-with-firewalld_using-and-configuring-firewalld",
    "Viewing the current status and settings of <code class=\"literal\">firewalld</code>": "viewing-the-current-status-and-settings-of-firewalld_using-and-configuring-firewalld",
    "Controlling network traffic using <code class=\"literal\">firewalld</code>": "controlling-network-traffic-using-firewalld_using-and-configuring-firewalld",
    "Controlling ports using CLI": "controlling-ports-using-cli_using-and-configuring-firewalld",
    "Working with firewalld zones": "working-with-firewalld-zones_using-and-configuring-firewalld",
    "Using zones to manage incoming traffic depending on a source": "using-zones-to-manage-incoming-traffic-depending-on-a-source_using-and-configuring-firewalld",
    "Filtering forwarded traffic between zones": "assembly_filtering-forwarded-traffic-between-zones_using-and-configuring-firewalld",
    "Configuring NAT using firewalld": "assembly_configuring-nat-using-firewalld_using-and-configuring-firewalld",
    "Port forwarding": "port-forwarding_using-and-configuring-firewalld",
    "Managing ICMP requests": "managing-icmp-requests_using-and-configuring-firewalld",
    "Setting and controlling IP sets using <code class=\"literal\">firewalld</code>": "setting-and-controlling-ip-sets-using-firewalld_using-and-configuring-firewalld",
    "Prioritizing rich rules": "prioritizing-rich-rules_using-and-configuring-firewalld",
    "Configuring firewall lockdown": "configuring-firewall-lockdown_using-and-configuring-firewalld",
    "Enabling traffic forwarding between different interfaces or sources within a firewalld zone": "assembly_enabling-traffic-forwarding-between-different-interfaces-or-sources-within-a-firewalld-zone_using-and-configuring-firewalld",
    "Migrating from iptables to nftables": "assembly_migrating-from-iptables-to-nftables_getting-started-with-nftables",
    "Writing and executing nftables scripts": "writing-and-executing-nftables-scripts_getting-started-with-nftables",
    "Creating and managing nftables tables, chains, and rules": "assembly_creating-and-managing-nftables-tables-chains-and-rules_getting-started-with-nftables",
    "Configuring NAT using nftables": "configuring-nat-using-nftables_getting-started-with-nftables",
    "Using sets in nftables commands": "using-sets-in-nftables-commands_getting-started-with-nftables",
    "Using verdict maps in nftables commands": "using-verdict-maps-in-nftables-commands_getting-started-with-nftables",
    "Configuring port forwarding using nftables": "configuring-port-forwarding-using-nftables_getting-started-with-nftables",
    "Using nftables to limit the amount of connections": "assembly_using-nftables-to-limit-the-amount-of-connections_getting-started-with-nftables",
    "Debugging nftables rules": "debugging-nftables-rules_getting-started-with-nftables",
    "Backing up and restoring the nftables rule set": "backing-up-and-restoring-the-nftables-rule-set_getting-started-with-nftables",
    "Dropping network packets that match an xdp-filter rule": "dropping-network-packets-that-match-an-xdp-filter-rule_using-xdp-filter-for-high-performance-traffic-filtering-to-prevent-ddos-attacks",
    "Dropping all network packets except the ones that match an xdp-filter rule": "dropping-all-network-packets-except-the-ones-that-match-an-xdp-filter-rule_using-xdp-filter-for-high-performance-traffic-filtering-to-prevent-ddos-attacks",
    "Installing the dpdk package": "installing-the-dpdk-package_getting-started-with-dpdk",
    "Overview of networking eBPF features in RHEL": "ref_overview-of-networking-ebpf-features-in-rhel_assembly_understanding-the-ebpf-features-in-rhel",
    "Overview of XDP features by network cards": "ref_overview-of-xdp-features-by-network-cards_assembly_understanding-the-ebpf-features-in-rhel",
    "An introduction to BCC": "bcc_network-tracing-using-the-bpf-compiler-collection",
    "Installing the bcc-tools package": "installing-the-bcc-tools-package_network-tracing-using-the-bpf-compiler-collection",
    "Displaying TCP connections added to the Kernel’s accept queue": "displaying-tcp-connections-added-to-the-kernels-accept-queue_network-tracing-using-the-bpf-compiler-collection",
    "Tracing outgoing TCP connection attempts": "tracing-outgoing-tcp-connection-attempts_network-tracing-using-the-bpf-compiler-collection",
    "Measuring the latency of outgoing TCP connections": "measuring-the-latency-of-outgoing-tcp-connections_network-tracing-using-the-bpf-compiler-collection",
    "Displaying details about TCP packets and segments that were dropped by the kernel": "displaying-details-about-tcp-packets-and-segments-that-were-dropped-by-the-kernel_network-tracing-using-the-bpf-compiler-collection",
    "Tracing TCP sessions": "tracing-tcp-sessions_network-tracing-using-the-bpf-compiler-collection",
    "Tracing TCP retransmissions": "tracing-tcp-retransmissions_network-tracing-using-the-bpf-compiler-collection",
    "Displaying TCP state change information": "displaying-tcp-state-change-information_network-tracing-using-the-bpf-compiler-collection",
    "Summarizing and aggregating TCP traffic sent to specific subnets": "summarizing-and-aggregating-tcp-traffic-sent-to-specific-subnets_network-tracing-using-the-bpf-compiler-collection",
    "Displaying the network throughput by IP address and port": "displaying-the-network-throughput-by-ip-address-and-port_network-tracing-using-the-bpf-compiler-collection",
    "Tracing established TCP connections": "tracing-established-tcp-connections_network-tracing-using-the-bpf-compiler-collection",
    "Tracing IPv4 and IPv6 listen attempts": "tracing-ipv4-and-ipv6-listen-attempts_network-tracing-using-the-bpf-compiler-collection",
    "Summarizing the service time of soft interrupts": "summarizing-the-service-time-of-soft-interrupts_network-tracing-using-the-bpf-compiler-collection",
    "The architecture of TIPC": "the-architecture-of-tipc_getting-started-with-tipc",
    "Loading the tipc module when the system boots": "loading-the-tipc-module-when-the-system-boots_getting-started-with-tipc",
    "Creating a TIPC network": "creating-a-tipc-network_getting-started-with-tipc",
    "Identifying whether a wireless device supports the access point mode": "proc_identifying-whether-a-wireless-device-supports-the-access-point-mode_assembly_configuring-rhel-as-a-wireless-access-point",
    "Configuring RHEL as a WPA2 or WPA3 Personal access point": "proc_configuring-rhel-as-a-wpa2-or-wpa3-personal-access-point_assembly_configuring-rhel-as-a-wireless-access-point",
    "Using nmcli to create key file connection profiles in offline mode": "proc_using-nmcli-to-create-key-file-connection-profiles-in-offline-mode_assembly_manually-creating-networkmanager-profiles-in-key-file-format",
}


@step(u'Doc: "{name}"')
def doc_step(context, name):
    links = []
    if name not in chapters:
        if "bond" in context.scenario.tags and f"Bonding: {name}" in chapters:
            name = f"Bonding: {name}"
        if "team" in context.scenario.tags and f"Teaming: {name}" in chapters:
            name = f"Teaming: {name}"
    assert name in chapters, "Chapter not found"
    for rh_ver in ["8", "9-beta"]:
        link = "https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux"
        link = f"{link}/{rh_ver}/html-single/configuring_and_managing_networking/index"
        link = f"{link}#{chapters[name]}"
        links.append((link, f"RHEL {rh_ver}"))
    nmci.embed.embed_link("Links", links)
