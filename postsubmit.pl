@info=split(/\//, @ARGV[0]);
$server=@info[2];
$server="198.148.155.195";
for ($x=3; $x<$#info+1; $x++) {
     $url=$url."/".@info[$x];
}     
if ($url eq "") { $url="/"; }
$url="servlet/CSViewProfile";
#tcp-client
#( $them, $port ) = @ARGV;
($them, $port) = ($server, 80);

$port = 2346 unless $port;
$them = 'localhost' unless $them;

$AF_INET = 2;
$SOCK_STREAM = 1;

$SIG{'INT'} = 'dokill';
sub dokill {
    kill 9,$child if $child;
}

$sockaddr = 'S n a4 x8';

#chop($hostname = `hostname`);

($name,$aliases,$proto) = getprotobyname('tcp');
($name,$aliases,$port) = getservbyname($port,'tcp')
    unless $port =~ /^\d+$/;;
($name,$aliases,$type,$len,$thisaddr) =
	gethostbyname($hostname);
($name,$aliases,$type,$len,$thataddr) = gethostbyname($them);

$this = pack($sockaddr, $AF_INET, 0, $thisaddr);
$that = pack($sockaddr, $AF_INET, $port, $thataddr);

if (socket(S, $AF_INET, $SOCK_STREAM, $proto)) { 
    print "socket ok\n";
}
else {
    die $!;
}

if (bind(S, $this)) {
    print "bind ok\n";
}
else {
    die $!;
}

if (connect(S,$that)) {
    print "connect ok\n";
}
else {
    die $!;
}

#Submit the data
$sendstr="success_url=&to=9442124&pager=1&message=Mike%2C+Sorry+I%27m+late...+I+have+a+radio+and+will+catch+you+after+passdown.+Chris.&count=0\n\n";
select(S); $| = 1; select(STDOUT);
        print S "POST /cgi-bin/ss_paging.pl HTTP/1.0\r\n";
        print S "Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/msword, */*\r\n";
        print S "Accept-Language: en-us\r\n";
        print S "Content-Type: application/x-www-form-urlencoded\r\n";
        print S "Content-Length: ", length($sendstr), "\r\n";
        print S "$sendstr\n\n";
        print "Sent $sendstr....\n";
        while (<S>) {
             print $_;
       }


sub Escape
{
   local($in) = @_;

   # Convert \W to %XX
   $in =~ s/(\W)/"%".&uppercase(unpack("H2",$1))/ge;

   $in;
}

sub uppercase
{
   local($in) = @_;

   $in =~ tr/a-z/A-Z/;

   $in;
}