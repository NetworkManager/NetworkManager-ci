Feature: NM: dracut

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @rhbz1710935 @rhbz1627820
    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_nfs_all
    Scenario: NM - dracut - NFS
    * Setup dracut test "contrib/dracut/TEST-20-NFS"
    * Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 root=dhcp DHCP path only"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 Legacy root=/dev/nfs nfsroot=IP:path"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 Legacy root=/dev/nfs DHCP path only"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 Legacy root=/dev/nfs DHCP IP:path"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 root=dhcp DHCP IP:path"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 root=dhcp DHCP proto:IP:path"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 root=dhcp DHCP proto:IP:path:options"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 root=nfs:..."
    * Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 Bridge root=nfs:..."
    * Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 Legacy root=IP:path"
    * Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 Invalid root=dhcp nfsroot=/nfs/client"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 root=dhcp DHCP path,options"
    * Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 Bridge Customized root=dhcp DHCP path,options"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 root=dhcp DHCP IP:path,options"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 root=dhcp DHCP proto:IP:path,options"
    * Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 root=dhcp DHCP lease renewal bridge"
    * Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv3 root=dhcp rd.neednet=1"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv4 root=dhcp DHCP proto:IP:path"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv4 root=dhcp DHCP proto:IP:path:options"
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv4 root=nfs4:..."
    #* Run dracut test "contrib/dracut/TEST-20-NFS" named "NFSv4 root=dhcp DHCP proto:IP:path,options"
