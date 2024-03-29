#!/usr/bin/env perl

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Copyright 2018,2022 Red Hat, Inc.

# $ perldoc modemu.pl for eye-pleasing view of the manual:

=head1 NAME

modemu.pl - emulate a serial modem

=head1 SYNOPSIS

modemu.pl [<name>] [-- <pppd> ...]

=head1 DESCRIPTION

B<modemu.pl> opens a PTY, links the slave side to F</dev> and announces a
fake kobject via netlink as if it were a real serial device, so that
ModemManager picks it up.

Then it answers to a very basic subset of AT commands, sufficient making
ModemManager recognize it as a 3GPP capable modem registered to a network.

Upon receiving the dial (ATD) command, it spawns C<pppd> so that
NetworkManager can establish a connection.

B<modemu.pl> needs superuser privileges to be able to announce a kobject
and create a F</dev> node.

=head1 OPTIONS

=over 4

=item B<< <name> >>

Create a modem of given name. Links it to F<< /dev/<name> >>.

Defaults to I<modemu>.

=item B<< <pppd> >>

Specifies extra arguments to be prepended before C<pppd> to the default
set of I<nodetach notty local logfd 2 nopersist>.

Defaults to I<pppd dump debug 172.31.82.1:172.31.82.2>.

=back

=cut

use strict;
use warnings;

use Errno;
use Socket;
use IO::Pty;
use IO::Handle;
use IO::Select;

use constant AF_NETLINK => 16;
use constant NETLINK_KOBJECT_UEVENT => 15;

# This allows us to use buffered read for lines from ModemManager
# despite not ending with \n
IO::Handle->input_record_separator ("\r");

# Parse command line arguments
my $name;
my @pppd = qw/pppd dump debug 172.31.82.1:172.31.82.2/;
while (@ARGV) {
	$_ = shift @ARGV;
	if ($_ eq '--') {
		@pppd = @ARGV;
		last;
	} else {
		die "Extra argument: '$_'" if $name;
		$name = $_;
	}
};
$name ||= 'modemu';

socket my $fd, AF_NETLINK, SOCK_RAW, NETLINK_KOBJECT_UEVENT
	or die "Can't create a netlink socket: $!";

my $seqnum = 666;
sub send_netlink
{
	my %props = (@_, SEQNUM => $seqnum++);
	my $props = join '', map { $_, '=', $props{$_}, "\0" } keys %props;

	my $head = pack 'a8NLLLNLLL',
		# signature + magic
		'libudev',
		0xfeedcafe,

		# 40 octets is the length of this header
		40, 40, 40 + length ($props),

		# Digest::MurmurHash2::Neutral::murmur_hash2_neutral("tty")
		0x8afa90c8,

		0x00000000,
		0x00040002,
		0x00008010;

	$! = undef;
	send $fd, "$head$props", 0, pack 'SSLL', AF_NETLINK, 0, 0, 0x0002;
	# RHEL 7 kernel responds ECONNREFUSED even thoguh the sendto succeeded. Weird.
	die "Can't send a netlink message: $!" if $! and not $!{ECONNREFUSED};
}

my $devpath = '/devices/pci0000:00/0000:00:00.0';
unless (-d "/sys/$devpath") {
	# Create a virtual device. Older ModemManager likes a hotpluggable bus
	# (USB, PCI), but there's none on an IBM POWER lpar...
	warn "No PCI bus to use for parent. Don't expect this to work with ModemManager 1.6";
	$devpath = '/devices/virtual';
}

sub port_event
{
	my $action = shift;
	my $port = shift;

	send_netlink (
		ACTION			=> $action,
		DEVPATH			=> "$devpath/$port",
		SUBSYSTEM		=> 'tty',
		DEVNAME			=> "/dev/$port",

		# Whitelisting that works for both ModemManager 1.6 and 1.8
		ID_MM_CANDIDATE		=> '1',
		ID_MM_DEVICE_PROCESS	=> '1',
	);
}

sub destroy_port
{
	my $port = shift;

	unlink "/dev/$port";
	port_event ('remove', $port) if $fd;
}

sub create_port
{
	my $port = shift;

	my $devname = "/dev/$port";
	my $pty = new IO::Pty;
	my $ptyname = ttyname $pty;

	symlink $ptyname, $devname or die "Can't create $devname: $!";

	port_event ('add', $port);
	return $pty;
	#send_netlink (ACTION => 'add', %props);
}

sub cleanup
{
	destroy_port ($name);
	destroy_port ($name.'_p1');
}

# Ensure we clean up before and after.
END { cleanup };
$SIG{INT} = sub { cleanup; die };
$SIG{TERM} = sub { cleanup; die };
cleanup;

my $pty0 = create_port ($name);
my $pty1 = create_port ($name.'_p1');

my ($ppp_pty, $ppp_pid);
my ($pdptype, $apn);

my $s = new IO::Select;
$s->add ($pty0, $pty1);

while (1) {
	my ($pty) = $s->can_read;

	# Note we're doing a blocking I/O to read a full line here.
	# That is -- if we started reading a command off a port,
	# we don't look at other ports until we get an end-of-line here on the first one.
	# Shouldn't be a big deal for MM and it simplifies the code.
	$_ = <$pty>;
	chomp;

	# Here's a good refernce of AT command a modern-ish modem probably uses:
	# https://infocenter.nordicsemi.com/index.jsp?topic=%2Fref_at_commands%2FREF%2Fat_commands%2Fpacket_domain%2Fcgact_set.html
	if (/^AT$/ or /^ATE0$/ or /^ATV1$/ or /^AT\+CMEE=1$/ or /^ATX4$/ or /^AT&C1$/ or /^ATZ$/) {
		# Standard Hayes commands that are basically used to
		# ensure the modem is in a known state. Accept them all.
		print $pty "\r\n";
		print $pty "OK\r\n";

	} elsif (/^AT\+CPIN\?$/) {
		# PIN unlocked. Required.
		print $pty "\r\n";
		print $pty "+CPIN:READY\r\n";
		print $pty "\r\n";
		print $pty "OK\r\n";

	} elsif (/^AT\+COPS=0$/) {
		# Select access technology (we just accept 0=automatic)
		print $pty "\r\n";
		print $pty "OK\r\n";

	} elsif (/^AT\+CGREG\?$/) {
		# 3GPP Registration status.
		print $pty "\r\n";
		print $pty "+CGREG: 0,1\r\n";
		print $pty "\r\n";
		print $pty "OK\r\n";

	# The PDP (packet data protocol/profile?) context handling below is very
	# rudimentary: just enough to keep ModemManager 1.18 happy. It basically
	# just starts with no contexts at all and then expects MM to set and
	# activate profile number 1.

	} elsif (/^AT\+CGDCONT=\?$/) {
		# Get supported PDP contexts
		print $pty "\r\n";
		print $pty "+CGDCONT: (1-10),(\"IP\"),,,(0-1),(0-1)\r\n";
		print $pty "+CGDCONT: (1-10),(\"IPV6\"),,,(0-1),(0-1)\r\n";
		print $pty "OK\r\n";

	} elsif (/^AT\+CGDCONT=1,"(.*)","(.*)"$/) {
		# Create the PDP context. Remember it, MM is going to check it later
		($pdptype, $apn) = ($1, $2);
		print $pty "\r\n";
		print $pty "OK\r\n";


	} elsif (/^AT\+CGDCONT\?$/) {
		# List the PDP context we're aware of.
		print $pty "\r\n";
		print $pty "+CGDCONT: 1,\"$pdptype\",\"$apn\",\"0.0.0.0\",0,0,0,0\r\n"
			if defined $pdptype;
		print $pty "OK\r\n";

	} elsif (/^AT\+CGACT\?$/) {
		# List available PDP contexts with states: profile 1 state 0 (inactive)
		print $pty "\r\n";
		print $pty "+CGACT: 1,0\r\n";
		print $pty "OK\r\n";

	} elsif (/^AT\+CGACT=0,1$/) {
		# Deactivate a PDP context

		if ($ppp_pid) {
			kill 'TERM' => $ppp_pid;
			waitpid $ppp_pid, 0;
			$ppp_pty->blocking (1);
			$s->add ($ppp_pty);
			$ppp_pty = $ppp_pid = undef;
		}

		print $pty "\r\n";
		print $pty "OK\r\n";

	} elsif (/^AT\+CRSM=176,12258,0,0,10$/) {
		# Read SIM ID
		print $pty "\r\n";
		print $pty "+CRSM: 144,0,\"98740006819041410210\"\r\n";
		print $pty "OK\r\n";

	} elsif (/^AT\+COPS\?$/) {
		# Current operators
		# Not strictly required, but allows NetworkManager to just connect
		# the modem device without explicitly setting an APN
		print $pty "\r\n";
		print $pty "+COPS: 0,2,\"65302\",7\r\n"; # MCCMNC
		print $pty "OK\r\n";

	} elsif (/^ATD/ and not $ppp_pty) {
		print $pty "\r\n";
		print $pty "CONNECT 28800000\r\n";

		$s->remove ($pty);
		$ppp_pty = $pty;

		$ppp_pid = fork;
		die "Can't fork: $!" unless defined $ppp_pid;
		if ($ppp_pid == 0) {
			close STDIN;
			close STDOUT;
			open STDIN, '<&', $pty or die "Can't dup pty to a pppd stdin: $!";
			open STDOUT, '>&', $pty or die "Can't dup pty to a pppd stdout: $!";
			close $pty0;
			close $pty1;
			exec @pppd, qw/nodetach notty local logfd 2 nopersist/;
			die "Can't exec pppd: $!";
		}
	} else {
		print $pty "\r\n";
		print $pty "ERROR\r\n";
	}
}

=head1 EXAMPLES

=over

=item B<modemu.pl>

Just create a modem named I<modemu>, with the default PPP arguments.

=item B<modemu.pl ttyS666>

Same as above, just name the modem I<ttyS666>.

=item B<modemu.pl -- unshare --net pppd 172.31.82.1:172.31.82.2>

Avoid polluting the namespace with the modem end of PPP connection.

=item B<modemu.pl -- pppd 10.0.0.1:10.0.0.2>

Override the C<pppd> parameters: no debug logging and different set of
addresses.

=item B<modemu.pl mymodem -- pppd 10.0.0.1:10.0.0.2>

Same as above, with a modem name different from default.

=back

=head1 BUGS

Only works on machines with a PCI bus. ModemManager is picky about platform
devices and accepts PCI and USB busses easily. Which is why pretent to have
our tty on the PCI root device.

Terminates after a single PPP session. C<pppd> seems to hang up the PTY.

=head1 SEE ALSO

L<ModemManager(8)>, L<pppd(8)>

=head1 COPYRIGHT

Copyright 2018,2022 Lubomir Rintel

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 AUTHOR

Lubomir Rintel C<lkundrak@v3.sk>

=cut
