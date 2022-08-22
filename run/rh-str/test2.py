#! /usr/bin/python

from subprocess import call

skip_long = True
skip_restart = True

tests = ['simwifi_wpa2psk_no_profile', 'simwifi_wpa2psk_profile', 'simwifi_tls', 'simwifi_peap_gtc', 'simwifi_peap_md5', 'simwifi_peap_mschapv2', 'simwifi_ttls_pap', 'simwifi_ttls_chap', 'simwifi_ttls_mschap', 'simwifi_ttls_mschapv2', 'simwifi_ttls_mschapv2_eap', 'simwifi_ttls_md5', 'simwifi_ttls_gtc', 'nmclient_get_wireless_hw_property', 'add_adsl_connection_novice_mode', 'add_adsl_connection', 'pptp_add_profile', 'pptp_terminate', 'add_default_tap_device', 'add_default_tun_device', 'remove_default_tuntap', 'preserve_master_and_ip_settings', 'alias_ifcfg_add_single_alias', 'alias_ifcfg_add_multiple_aliases', 'alias_ifcfg_remove_single_alias', 'alias_ifcfg_connection_restart', 'alias_ifcfg_remove_all_aliases', 'alias_ifcfg_reboot', '', 'ipv4_method_static_no_IP', 'ipv4_method_manual_with_IP', 'ipv4_method_static_with_IP', 'ipv4_addresses_manual_when_asked', 'ipv4_addresses_IP_slash_mask', 'ipv4_change_in_address', 'ipv4_addresses_IP_slash_invalid_mask', 'ipv4_addresses_IP_slash_mask_and_route', 'ipv4_addresses_more_IPs_slash_mask_and_route', 'ipv4_method_back_to_auto', 'ipv4_route_set_basic_route', 'ipv4_route_set_route_with_options', 'ipv4_route_set_route_with_src_new_syntax', 'ipv4_route_set_route_with_src_old_syntax', 'ipv4_route_modify_route_with_src_old_syntax_no_metric', 'ipv4_route_set_route_with_src_old_syntax_restart_persistence', 'ipv4_route_set_route_with_src_new_syntax_restart_persistence', 'no_metric_route_connection_restart_persistence', 'ipv4_route_set_route_with_tables', 'ipv4_route_set_route_with_tables_reapply', 'ipv4_restore_default_route_externally', 'ipv4_route_remove_basic_route', 'ipv4_route_set_device_route', 'ipv4_host_destination_route', 'preserve_route_to_generic_device', 'ipv4_route_set_invalid_non_IP_route', 'ipv4_route_set_invalid_missing_gw_route', 'ipv4_routes_not_reachable', 'ipv4_dns_manual', 'ipv4_dns_manual_when_method_auto', 'ipv4_dns_manual_when_ignore_auto_dns', 'ipv4_ignore_resolveconf_with_ignore_auto_dns', 'ipv4_ignore_resolveconf_with_ignore_auto_dns_var1', 'ipv4_ignore_resolveconf_with_ignore_auto_dns_var2', 'ipv4_ignore_resolveconf_with_ignore_auto_dns_var3', 'ipv4_dns_resolvconf_symlinked', 'ipv4_dns_resolvconf_file', 'ipv4_dns_add_another_one', 'ipv4_dns_delete_all', 'reload_dns', 'dns_priority', 'ipv4_dns-search_add', 'ipv4_dns-search_remove', 'ipv4_dhcp-hostname_set', 'nmcli_ipv4_set_fqdn', 'nmcli_ipv4_override_fqdn', 'nmcli_ipv4_remove_fqdn', 'ipv4_dhcp-hostname_remove', 'ipv4_do_not_send_hostname', 'ipv4_send_real_hostname', 'ipv4_ignore_sending_real_hostname', 'ipv4_add_dns_options', 'ipv4_remove_dns_options', 'ipv4_dns-search_ignore_auto_routes', 'ipv4_method_link-local', 'ipv4_dhcp_client_id_set', 'ipv4_dhcp_client_id_remove', 'ipv4_set_very_long_dhcp_client_id', 'ipv4_may-fail_yes', 'ipv4_method_disabled', 'ipv4_never-default_set', 'ipv4_never-default_remove', 'ipv4_describe', 'set_mtu_from_DHCP', 'renewal_gw_after_dhcp_outage', 'renewal_gw_after_long_dhcp_outage', 'dhcp-timeout', 'dhcp-timeout_infinity', 'timeout_default_in_cfg', 'renewal_gw_after_dhcp_outage_for_assumed_var0', 'renewal_gw_after_dhcp_outage_for_assumed_var1', 'manual_routes_preserved_when_never-default_yes', 'dhcp4_outages_in_various_situation', 'manual_routes_removed_when_never-default_no', 'ipv4_dad', 'custom_shared_range_preserves_restart', 'ipv4_method_shared', 'ipv4_method_shared_with_already_running_dnsmasq', 'ipv4_do_not_remove_second_ip_route', 'ipv4_never_default_restart_persistence', 'ipv4_honor_ip_order_1', 'ipv4_honor_ip_order_2', 'ipv4_rp_filter_set_loose', 'ipv4_rp_filter_set_loose_rhel', 'ipv4_rp_filter_do_not_touch', 'ipv4_rp_filter_reset', 'ipv4_rp_filter_reset_rhel', 'ipv4_dhcp_do_not_add_route_to_server', 'ipv4_keep_external_addresses', 'ipv4_route_onsite', 'ipv4_multiple_ip4', 'ipv6_block_just_routing_RA', 'ipv6_limited_router_solicitation', 'ipv6_routes_with_src', 'ipv6_route_set_route_with_tables', 'ipv6_route_set_route_with_tables_reapply', 'ipv6_correct_slaac_setting', 'ipv6_take_manually_created_ifcfg', 'ipv6_method_static_without_IP', 'ipv6_method_manual_with_IP', 'ipv6_method_static_with_IP', 'ipv6_addresses_IP_with_netmask', 'ipv6_addresses_yes_when_static_switch_asked', 'ipv6_addresses_no_when_static_switch_asked', 'ipv6_addresses_invalid_netmask', 'ipv6_addresses_IP_with_mask_and_gw', 'ipv6_addresses_set_several_IPv6s_with_masks_and_gws', 'ipv6_addresses_delete_IP_moving_method_back_to_auto', 'ipv6_routes_set_basic_route', 'ipv6_route_set_route_with_options', 'ipv6_routes_remove_basic_route', 'ipv6_routes_device_route', 'ipv6_routes_invalid_IP', 'ipv6_routes_without_gw', 'ipv6_dns_manual_IP_with_manual_dns', 'ipv6_dns_auto_with_more_manually_set', 'ipv6_dns_ignore-auto-dns_with_manually_set_dns', 'ipv6_dns_add_more_when_already_have_some', 'ipv6_dns_remove_manually_set', 'ipv6_dns-search_set', 'ipv6_dns-search_remove', 'ipv6_ignore-auto-dns_set', 'ipv6_ignore-auto-dns_set-generic', 'ipv6_method_link-local', 'ipv6_method_ignored', 'ipv6_may_fail_set_true', 'ipv6_never-default_set_true', 'ipv6_never-default_remove', 'ipv6_dhcp-hostname_set', 'ipv6_dhcp-hostname_remove', 'ipv6_send_fqdn.fqdn_to_dhcpv6', 'ipv6_secondary_address', 'ipv6_ip6-privacy_0', 'ipv6_ip6-privacy_1', 'ipv6_ip6-privacy_2', 'ipv6_ip6-default_privacy', 'ipv6_ip6-privacy_incorrect_value', 'ipv6_lifetime_set_from_network', 'ipv6_lifetime_no_padding', 'ipv6_drop_ra_with_255_hlimit', 'ipv6_drop_ra_with_low_hlimit', 'ipv6_drop_ra_from_non_ll_address', 'ipv6_keep_connectivity_on_assuming_connection_profile', 'ipv6_add_static_address_manually_not_active', 'ipv6_no_assumed_connection_for_ipv6ll_only', 'ipv6_set_ra_announced_mtu', 'nm-online_wait_for_ipv6_to_finish', 'ipv6_shared_connection_error', 'ipv6_shared_connection', 'ipv6_tunnel_module_removal', 'ipv6_no_activation_schedule_error_in_logs', 'ipv6_NM_stable_with_internal_DHCPv6', 'persistent_default_ipv6_gw', 'persistent_ipv6_route', 'ipv6_honor_ip_order', 'ipv6_describe', 'ipv6_keep_external_addresses', 'ipv6_keep_external_routes', 'nmcli_general_finish_dad_without_carrier', 'ipv4_dad_not_preventing_ipv6', 'ipv6_preserve_cached_routes', 'persistent_ipv6_after_device_rename', 'add_ipv6_over_ipv4_configured_ext_device', 'ipv6_multiple_default_routes', 'vlan_add_default_device', 'vlan_add_beyond_range', 'nmcli_vlan_restart_persistence', 'vlan_ipv4_ipv6_restart_persistence', 'vlan_device_tagging', 'vlan_connection_up', 'vlan_reup_connection', 'vlan_connection_down', 'vlan_connection_down_with_autoconnect', 'vlan_remove_connection', 'vlan_disconnect_device', 'vlan_disconnect_device_with_autoconnect', 'vlan_change_id', 'vlan_change_id_with_no_interface_set', 'vlan_describe_separately', 'vlan_describe_all', 'vlan_on_bridge', 'assertion_failure', 'vlan_not_duplicated', 'vlan_not_stalled_after_connection_delete', 'vlan_update_mac_from_bond', 'bring_up_very_long_device_name', 'reorder_hdr', 'vlan_preserve_assumed_connection_ips', 'vlan_create_many_vlans', 'vlan_mtu_from_parent', 'vlan_mtu_from_parent_with_slow_dhcp', 'default_route_for_vlan_over_team']

# def runtest(test):
#     return call ("/mnt/tests/NetworkManager-ci/nmcli/./runtest.sh %s" %test, shell=True)

# set some basic defaults
if skip_long:
    call ("touch /tmp/nm_skip_long", shell=True)
if skip_restart:
    call ("touch /tmp/nm_skip_restarts", shell=True)


call ("echo ********* STARTING TEST THREAD2 *********' >> /tmp/tests", shell=True)

failures = []
for test in tests:
    if call ("cd /mnt/tests/NetworkManager-ci/ && sh run/./runtest.sh %s" %test, shell=True) != 0:
        failures.append(test)
        call ("echo %s >> /tmp/test2.failures" %test, shell=True)
        call ("echo '2: FAIL:%s' >> /tmp/tests" % test, shell=True)
    else:
        call ("echo '2: PASS:%s' >> /tmp/tests" % test, shell=True)
call ("echo '********* ENDING TEST THREAD2 *********' >> /tmp/tests", shell=True)

if failures != []:
    print ("TESTS-FAILED:")
    for fail in failures:
        print (fail)
    exit(1)
else:
    print ("TESTS-PASSED")
    exit(0)
