#! /usr/local/bin/perl
#-----------------------------------------------------------
# This code has been shamelessly copied and hacked by James
# Dement.  I take no credit and make no claim to authorship
# of this code.  I simply removed and modifed lines of code
# until it could do only what I needed it to do.  (Download
# an html file from a www server.)
#-----------------------------------------------------------
#- Usage:  
#-      &url_get'http_get(<host>,<port>,<file>);
#-----------------------------------------------------------
#- Return codes. 
#- 0-9 for WWW errors.
#- jd added the following error codes:
#- 100 : Error opening output file $file.
#- 101 : Error opening port $port on $host: $!
#- 102 : Host not found: $host\n
#- 103 : Server unexpectedly closed connection - exiting.
#-----------------------------------------------------------

package url_get;     # Everything after this is "private"

eval 'use Socket';

1;

sub http_get {
    local($host,$port,$request) = @_;
    local($output) = "";
    local($redirect) = 0;
    local($location);
    local($auth_string) = "";
    local($http_rest) = "";

    # Status code translation table. Key is HTTP status code (from
    # http://info.cern.ch/hypertext/WWW/Protocols/HTTP/HTRESP.html),
    # and value is status returned by url_get.

    %exit_status = (400,1,401,2,402,3,403,4,404,5,500,6,501,7,502,8,503,9);

    $ret = &url_get'open($host, $port);
    if (!defined($ret)) {
        if ($! && $! != "") {
            return (101,$output); # die "Error opening port $port on $host: $!\n";
        } else {
            return (102,$output); # die "Host not found: $host\n";
        }
    }
    print CMD "GET $request HTTP/1.0\r\nAccept: */*\r\n$auth_string\r\n";
    $_ = <CMD>;
    if (! $_) {
	return (103,$output); # die "Server unexpectedly closed connection - exiting.\n";
    }

# First, read the HTTP header

    if (m#^HTTP/([\.0-9]*) (\d\d\d) (.+)$#) {
	$http_version = $1;
        $status = $2;
        $reason = $3;
        if (! $debug && $status > 399) {
            $output .= "Error returned from server: $status $reason\n";
	    return ($exit_status{$status},$output);
        }
	if ($status >= 300) {
	    $redirect = 1;
	}
    } else {
	$output .= "Error - bad HTTP header: $_\n";
    }

    if (! $redirect)
    {
       $output .= $_;
    }

# Next, read the MIME header

    while (<CMD>) {
        last if (/^\s*$/);
	if ($redirect && /^Location: (.*)$/) {
	    $location = $1;
	}

	if (!$redirect) {
	    $output .= $_;
	}
	else {
            if (! /^[a-zA-Z\-]+: /) {
                $output .= "Bad MIME header line: $_";
            }
	}
    }
    if (! $_) {
	return (103,$output); # die "Server unexpectedly closed connection - exiting.\n";
    }
    if (! $debug && ! $loseheader && ! $redirect) {
	if ($file) { print OUT $_; }
        else { $output .= $_; }
    }

# Finally, read the rest

    while (<CMD>) {
	last if ($redirect && !$debug);
	$output .= $_;
    }
    close(CMD);

# If we've been redirected to another location, get it there...

    if ($redirect && $location) {
	#return &main'url_get($location, $userid, $passwd, $file);
    }
    return (0,$output);
}

sub open {
    local($Host, $Port) = @_;
    local($destaddr, $destproc);

# Set the socket parameters. Note that we set the defaults to be the
# BSD values if we can't get them from the required files. Also note
# that, in the 4.0 version, the routines are in package ftp, since
# it does the "require sys/socket.ph" first.

    (eval {$Inet = &AF_INET;}) || ($Inet=2);
    (eval {$Stream = &SOCK_STREAM;}) || ($Stream=1);

    if ($Host =~ /^(\d+)+\.(\d+)\.(\d+)\.(\d+)$/) {
	$destaddr = pack('C4', $1, $2, $3, $4);
    } else {
	local(@temp) = gethostbyname($Host);
	unless (@temp) {
           $Error = "Can't get IP address of $Host";
           return undef;
        }
	$destaddr = $temp[4];
    }

    $Proto = (getprotobyname("tcp"))[2];
    $Sockaddr = 'S n a4 x8';
    $destproc = pack($Sockaddr, $Inet, $Port, $destaddr);
    if (socket(CMD, $Inet, $Stream, $Proto)) {
       if (connect(CMD, $destproc)) {

          ### This info will be used by future data connections ###
          $Cmdaddr = (unpack ($Sockaddr, getsockname(CMD)))[2];
          $Cmdname = pack($Sockaddr, $Inet, 0, $Cmdaddr);

          select((select(CMD), $| = 1)[$[]);

          return 1;
       }
    }

    close(CMD);
    return undef;
}

