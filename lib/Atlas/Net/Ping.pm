package Atlas::Net::Ping;

use Socket;

sub new {
  my $class = shift;
  my %opt = @_;

  unless (valid_ip($opt{'destination'})) {
    die "Required parameter 'destination' is missing or invalid";
    return undef;
  }
  $opt{'id'} = 0 unless defined $opt{'id'} && int($opt{'id'}) eq $opt{'id'} && $opt{'id'} >= 0 && $opt{'id'} <= 65535;
  $opt{'seq'} = 1 unless defined $opt{'seq'} && int($opt{'seq'}) eq $opt{'seq'} && $opt{'seq'} >= 1 && $opt{'seq'} <= 65535;
  my $self = {
    destination => $opt{'destination'},
    id => $opt{'id'},
    seq => $opt{'seq'}
  };
  bless $self, $class;
  return $self;
}

sub payload {
  my $self = shift;
  
  my $payload = pack("C2n3", 8, 0, 0x0000, $self->{'id'}, $self->{'seq'});
  my $crc = 0;
  # 16 bit checksum (one's complement)
  foreach my $short (unpack("n4", $payload)) {
    my $carry = ($crc + $short) > 0xffff; 
    $crc += $short;
    $crc &= 0xffff; 
    $crc += $carry;
  }
  $crc = ~$crc; # One's complement of the final sum
  return pack("C2n3", 8, 0, $crc, $self->{'id'}, $self->{'seq'});
}

sub send {
  my $self = shift;
  
  socket(my $sock, PF_INET, SOCK_RAW, getprotobyname('icmp')) || die "Error creating socket: $!";
  send($sock, $self->payload, 0, sockaddr_in(0, inet_aton($self->{'destination'}))) || die "Error sending ICMP: $!";    
  return 1;
}

sub valid_ip {
  my $ip = shift;
  return 0 unless defined $ip;
  return 0 unless $ip =~ /^\d+\.\d+\.\d+\.\d+$/;
  foreach my $octet (split(/\./, $ip)) { 
    return 0 unless $octet >= 0 && $octet <= 255; 
  } 
  return 1;
}


return 1;
