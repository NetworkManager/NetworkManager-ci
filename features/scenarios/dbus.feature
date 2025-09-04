Feature: dbus interface
    
    @ver+=1.45.9
    @dbus_set_invalid_dns
    Scenario: dbus - reject invalid "dns" property
    * Cleanup connection "con_dbus"
    * Execute "python3l contrib/dbus/dbus-set-invalid-dns.py"


    @ver+=1.45.9
    @dbus_set_invalid_addresses
    Scenario: dbus - reject invalid "addresses" property
    * Cleanup connection "con_dbus"
    * Execute "python3l contrib/dbus/dbus-set-invalid-addresses.py"


    @ver+=1.45.9
    @dbus_set_invalid_address_data
    Scenario: dbus - reject invalid "address-data" property
    * Cleanup connection "con_dbus"
    * Execute "python3l contrib/dbus/dbus-set-invalid-address-data.py"


    @ver+=1.45.9
    @dbus_set_invalid_routes
    Scenario: dbus - reject invalid "routes" property
    * Cleanup connection "con_dbus"
    * Execute "python3l contrib/dbus/dbus-set-invalid-routes.py"


    @ver+=1.45.9
    @dbus_set_invalid_route_data
    Scenario: dbus - reject invalid "route-data" property
    * Cleanup connection "con_dbus"
    * Execute "python3l contrib/dbus/dbus-set-invalid-route-data.py"
