Feature: nmcli: adsl

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @rhbz1264089
    @ver+=1.39.7
    @adsl
    @add_adsl_connection_novice_mode
    Scenario: nmcli - adsl - create adsl connection in novice mode
    * Open wizard for adding new connection
    * Expect "Connection type"
    * Submit "adsl" in editor
    * Expect "Username"
    * Submit "test" in editor
    * Expect "Protocol"
    * Submit "pppoe" in editor
    * Expect "Interface name"
    * Submit "test11" in editor
    * Expect "There are .* optional"
    * Enter in editor
    * Expect "Password"
    * Submit "S3c4!t" in editor
    * Expect "ADSL encapsulation"
    * Enter in editor
    * Dismiss IP configuration in editor
    * Dismiss Proxy configuration in editor
    Then "adsl.username:\s+test" is visible with command "nmcli  connection show --show-secrets adsl"
    Then "adsl.protocol:\s+pppoe" is visible with command "nmcli  connection show --show-secrets adsl"
    Then "adsl.encapsulation:\s+--" is visible with command "nmcli  connection show --show-secrets adsl"
    Then "adsl.password:\s+S3c4" is visible with command "nmcli  connection show --show-secrets adsl" in "3" seconds


    @rhbz1264089
    @add_adsl_connection
    Scenario: nmcli - adsl - create adsl connection
    * Add "adsl" connection named "adsl-test11" for device "adsl" with options
          """
          username test
          password S3c4!t
          protocol pppoe
          encapsulation llc
          """
    Then "adsl.username:\s+test" is visible with command "nmcli  connection show --show-secrets adsl-test11"
    Then "adsl.protocol:\s+pppoe" is visible with command "nmcli  connection show --show-secrets adsl-test11"
    Then "adsl.encapsulation:\s+llc" is visible with command "nmcli  connection show --show-secrets adsl-test11"
    Then "adsl.password:\s+S3c4" is visible with command "nmcli  connection show --show-secrets adsl-test11" in "3" seconds
