#!/usr/bin/perl

require 'c:\\tools\\url_get.pl';

$pagetotal=0;
$sstotal=0;
$dbtotal=0;
$othertotal=0;
$SERVER="198.148.155.18";

use Socket;

sub Logit() {
     $text=@_[0];
     $fname="c:\\temp\\statsdebug.log";
     open(OFILE, ">>$fname");
     print OFILE $text, "\n";
     close(OFILE);
}

#-------------------------------------------------------------------
# SendMessage : This routine takes as arguments the to, from,
#   subject, and message that is to be sent as an email, and sends
#   it.
#-------------------------------------------------------------------
sub SendMessage
{
    local($to,$from,$subject,$text) = @_;

    # Find the SMTP server name.
    $server = $SERVER;
    unless($server)
    {
        print "No server provided, cannot proceed.";
    }

    # Attempt to open a socket to the SMTP server.
    $protocol = getprotobyname('tcp');
    socket(SOCKET,PF_INET,SOCK_STREAM,$protocol);
    $remote_ip = gethostbyname($server);
    $remote_sock = pack('Sna4x8', AF_INET, 25, $remote_ip);
    unless(connect(SOCKET, $remote_sock))
    {
        open(MAILERROR, ">>mail.log");
        print MAILERROR "Could not connect to server\n";
        close(MAILERROR);
    }

    # No buffering on the socket.
    select(SOCKET); $|=1; select(STDOUT);

    # Check to make sure that it looks like an SMTP server, 
    # according to RFC 821.
    $return = <SOCKET>;
    unless($return =~ /^220.+/)
    {
        open(MAILERROR, ">>mail.log");
        print MAILERROR "The server doesn't respond appropriately. $return\n";
        close(MAILERROR);
    }

    # Get the whole reply, in case it's multi-line.
    while($return =~ /^\d\d\d\-/)
    {
        $return = <SOCKET>;
    }

    # Send a greeting, using the client's machine name.
    print SOCKET "HELO $ENV{REMOTE_HOST}\r\n";
    $return = <SOCKET>;
    unless($return =~ /^250.+/)
    {
        open(MAILERROR, ">>mail.log");
        print MAILERROR "Server Error: \"$return\"\n";
        close(MAILERROR);
    }

    # Get the whole reply, in case it's multi-line.
    while($return =~ /^\d\d\d\-/)
    {
        $return = <SOCKET>;
    }

    # Send the source name.
    print SOCKET "MAIL FROM: <>\r\n";
    $return = <SOCKET>;
    unless($return =~ /^250.+/)
    {
        open(MAILERROR, ">>mail.log");
        print MAILERROR "Server Error: \"$return\"\n";
        close(MAILERROR);
    }

    # Get the whole reply, in case it's multi-line.
    while($return =~ /^\d\d\d\-/)
    {
        $return = <SOCKET>;
    }

    # Send each recipient.

    $to =~ s/\;/\,/g; # Allow ";"s to divide addresses.

    $all_recipients = $to;
    if($in{"CC"}){ $all_recipients .= qq|,$in{"CC"}|; }
    @Recipients = split(/[\,]/,$all_recipients);
    while($recipient = shift(@Recipients))
    {
        if($recipient =~ /([^\s<]+@[^\s\r,>]+)/)
        {
            $recipient = '<' . $1 . '>';
            print SOCKET "RCPT TO: $recipient\r\n";
            $return = <SOCKET>;
            unless($return =~ /^250.+/)
            {
                open(MAILERROR, ">>mail.log");
                print MAILERROR "Server Error: \"$return\"\n";
                close(MAILERROR);
            }

            # Get the whole reply, in case it's multi-line.
            while($return =~ /^\d\d\d\-/)
            {
                $return = <SOCKET>;
            }
        }
    }

    print SOCKET "DATA\n";
    $return = <SOCKET>;
    unless($return =~ /^354.+/)
    {
        open(MAILERROR, ">>mail.log");
        print MAILERROR "Server Error: \"$return\"\n";
        close(MAILERROR);
    }

    # Get the whole reply, in case it's multi-line.
    while($return =~ /^\d\d\d\-/)
    {
        $return = <SOCKET>;
    }

    # Build an RFC 822 date.
    @days = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
    @months = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
    $wday = $days[$wday];
    $mon = $months[$mon];
    $hour = sprintf("%2.2d",$hour);
    $min = sprintf("%2.2d",$min);
    $sec = sprintf("%2.2d",$sec);
    $datestr = "$wday, $mday $mon $year $hour:$min:$sec +0000";

    # Build the message header.
    $Message = qq|To: $to\r\n|;
    if($in{"CC"}){ $Message .= qq|Cc: $in{"CC"}\r\n|; }
    $Message .= qq|From: $from\r\n|;
    $Message .= qq|Subject: $subject\r\n|;
    $Message .= qq|Date: $datestr\r\n|;
    $Message .= "X-Mailer: Endymion MailMan v1.1\r\n";
    $Message .= "X-Mailer-Info: http://www.endymion.com/portfolio/software/scripts/mailman.htm\r\n";
    $Message .= "\r\n";

    # The message itself.
    $Message .= $text;

    # Clean up after DOS, if necessary.
    # $Message =~ s/\r\n?/\n/g;

    print SOCKET $Message;

    # Terminate the message.
    print SOCKET "\r\n.\r\n";
    $return = <SOCKET>;
    unless($return =~ /^250.+/)
    {
        open(MAILERROR, ">>mail.log");
        print MAILERROR "Server Error: \"$return\"\n";
        close(MAILERROR);
    }

    # Get the whole reply, in case it's multi-line.
    while($return =~ /^\d\d\d\-/)
    {
        $return = <SOCKET>;
    }

    # Finish the connection.
    print SOCKET "QUIT\r\n";

    # Close connection.
    close SOCKET;
}


#--------------------------------------
# uppercase()
#
# converts a string to all uppercase
# chars.
#--------------------------------------

sub uppercase
{
   local($in) = @_;

   $in =~ tr/a-z/A-Z/;

   $in;
}

#----------------------------------------
# Escape()
#
# Takes a string and escapes it, usually
# so it can be passed as a URL.
#----------------------------------------

sub Escape
{
   local($in) = @_;

   # Convert \W to %XX
   $in =~ s/(\W)/"%".&uppercase(unpack("H2",$1))/ge;

   $in;
}

#-------------------------------
# checkleapyear()
#
# determines if current year
# is a leap year.
#-------------------------------

sub checkleapyear()
{
#For now, pretend there is no leap year
@todaysinfo[3]=28;
}

#---------------------------
# getlastmonthday()
#
# determines last day of
# previous month
#---------------------------

sub getlastmonthday()
{
#Take care of all months with 31 days
if (@todaysinfo[4]==0 || @todaysinfo[4]==2 || @todaysinfo[4]==4 || @todaysinfo[4]==6 || @todaysinfo==7 || @todaysinfo==9 || @todaysinfo==11)
	{
	@todaysinfo[3]=31;
	}

#Take care of all months with 30 days
if (@todaysinfo[4]==3 || @todaysinfo[4]==5 || @todaysinfo[4]==8 || @todaysinfo[4]==10)
	{
	@todaysinfo[3]=30;
	}

#Feb is special, so check for leapyear
if (@todaysinfo[4]==1)
	{
	&checkleapyear();
	}

}

#------------------------------
# prevmonth()
# 
# takes care of previous month's
# info if subtracting a day puts
# one in the previous month.
#------------------------------

sub prevmonth()
{
#If subtracting day puts you in previous year, deal with that
          if (@todaysinfo[4]==0)
	  { 
                @todaysinfo[4]=11;
		@todaysinfo[5]--;
	  }
	  else
          {
		@todaysinfo[4]--;
	  }
#Get last day of the month
&getlastmonthday();	
}

#----------------------------
# subtractday()
#
# finds out what previous
# day was
#----------------------------

sub subtractday()
{
#Subtracts 1 from the current day
@todaysinfo[3]--;
#If this means it's in the previous month, deal with that
if (@todaysinfo[3]==0) 
	{
	&prevmonth();
	}
}

#------------------------------------------
# convertmonth()
#
#Convert month to a string and return value
#-------------------------------------------

sub convertmonth()
{
$nummonth=@_[0];
if ($nummonth==0)
	{
	return "Jan";
	}
if ($nummonth==1)
	{
	return "Feb";
	}
if ($nummonth==2)
	{
	return "Mar";
	}
if ($nummonth==3)
	{
	return "Apr";
	}
if ($nummonth==4)
	{
	return "May";
	}
if ($nummonth==5)
	{
	return "Jun";
	}
if ($nummonth==6)
	{
	return "Jul";
	}
if ($nummonth==7)
	{
	return "Aug";
	}
if ($nummonth==8)
	{
	return "Sep";
	}
if ($nummonth==9)
	{
	return "Oct";
	}
if ($nummonth==10)
	{
	return "Nov";
	}
if ($nummonth==11)
	{
	return "Dec";
	}
}

#-----------------------------------------
# monthnum()
#
# Given an alpha month, returns numeric
# value.
#-----------------------------------------

sub monthnum()
{
$cmp=@_[0];
if ($cmp eq "Jan" || $cmp eq "Mar" || $cmp eq "May" || $cmp eq "Jul" || $cmp eq "Aug" || $cmp eq "Oct" || $cmp eq "Dec")
	{
	return 31;
	}
if ($cmp eq "Feb")
	{
	return 28;
	}
if ($cmp eq "Apr" || $cmp eq "Jun" || $cmp eq "Sep" || $cmp eq "Nov") 
	{
	return 30;
	}
}

#--------------------------------------
# setup()
#
# Prepares to gather stats.  Right now,
# command-line args aren't accounted
# for.
#--------------------------------------

sub setup()
{
if (@ARGV)
	{
	}
else
	{
	#Get current date, time, etc.
	@todaysinfo=localtime(time);

	#Subtract one so you're dealing with the previous day
	&subtractday();

	#Convert numeric month to a string for easy comparison later, put in $monthcompare
	$monthcompare=&convertmonth(@todaysinfo[4]);
	}
}

#----------------------------------------
# convertmonthnum()
#
# from value of $monthcompare, determines
# what numeric value is.
#-----------------------------------------

sub convertmonthnum()
{
if ($monthcompare eq "Jan")
	{
	return 1;
	}
if ($monthcompare eq "Feb")
	{
	return 2;
	}
if ($monthcompare eq "Mar")
	{
	return 3;
	}
if ($monthcompare eq "Apr")
	{
	return 4;
	}
if ($monthcompare eq "May")
	{
	return 5;
	}
if ($monthcompare eq "Jun")
	{
	return 6;
	}
if ($monthcompare eq "Jul")
	{
	return 7;
	}
if ($monthcompare eq "Aug")
	{
	return 8;
	}
if ($monthcompare eq "Sep")
	{
	return 9;
	}
if ($monthcompare eq "Oct")
	{
	return 10;
	}
if ($monthcompare eq "Nov")
	{
	return 11;
	}
if ($monthcompare eq "Dec")
	{
	return 12;
	}
}

#----------------------------------
# getstats()
#
# Actually gets statistics from
# logfiles.
#-----------------------------------

sub getstats()
{
	$path=$path1;	
        print "Opening $path...\n";
	open(FILE, $path) || &Logit("Died opening file $path!");
	while (<FILE>)
	{
	     @sendntlog=split(/\s+/, $_);
	     #If it's right month, continue
	     if (@sendntlog[1] eq $monthcompare)
	     {
	          #If it's right day, continue
	          if ($sendntlog[2]>@todaysinfo[3])
		  {
		       close(FILE);
		       break;
		  }
		  if (@todaysinfo[3]==@sendntlog[2])
		  {
                       @logtime=split(/:/, @sendntlog[3]);
		       if ($_=~ /TO:(.*)/)
		       {
		            $pinlist=$1;
                            @temp=split(/\s+/, $pinlist);
                            $pinlist=@temp[0];
		       }
		       @pins=split(/,/, $pinlist);
		       if ($#pins>0)
		       {
		            foreach $y (@pins)
		       	    {
				$check="";
		            	if ($y=~ /(\w)(\d*)/)
			    	{
			         	$check=$1;
			    	}
			    	if ($check eq "P")
			    	{
                                        $twowayhour{@logtime[0]}++;
			         	$twoway++;
				  	if ($_=~ /LEN:(\d*)/)
				  	{
				       	     $twowayavg=$twowayavg+$1;
				  	}
			    	}
			    	if ($check eq "U")
			    	{
                                        $onewayhour{@logtime[0]}++;
			        	$oneway++;
				 	if ($_=~ /LEN:(\d*)/)
				 	{
				      	     $onewayavg=$onewayavg+$1;
				 	}
			    	}
                                $_=~ s/\r//;
                                $_=~ s/\n//;
                                if ($_=~ /ID:page/  && $check ne "")
                                {
                                     $pagetotal++;
                                }
                                elsif ($_=~ /ID:ss/ && $check ne "")
 				{
				     $sstotal++;
                                }
                                elsif ($_=~ /ID:db/ && $check ne "")
                                {
				     $dbtotal++;
                                }
		       	    }
			}
			else
			{
 				$check="";
				if ($pinlist=~ /(\w)(\d*)/)
				{
					$check=$1;
				}
				if ($check eq "P")
				{
                                        $twowayhour{@logtime[0]}++;
			         	$twoway++;
				 	if ($_=~ /LEN:(\d*)/)
				 	{
				     		$twowayavg=$twowayavg+$1;
				 	}
				}
				if ($check eq "U")
				{
                                        $onewayhour{@logtime[0]}++;
			        	$oneway++;
					if ($_=~ /LEN:(\d*)/)
					{
				      		$onewayavg=$onewayavg+$1;
					}
				}
                                $_=~ s/\r//;
                                $_=~ s/\n//;
                                if ($_=~ /ID:page/ && $check ne "")
                                {
                                     $pagetotal++;
                                }
                                elsif ($_=~ /ID:ss/ && $check ne "")
 				{
				     $sstotal++;
                                }
                                elsif ($_=~ /ID:db/ && $check ne "")
                                {
				     $dbtotal++;
                                }
			}
		   }
	      }

	}
     close(FILE);
}

#-----------------------------------
# writefile()
#
# Writes to logfile, and sends
# Email to appropriate recipients.
#-----------------------------------

sub writefile()
{
     open(FILE, ">>".$outpath);
     open(BFILE, ">>c:\\skytel\\data\\stats.log");
     if ($oneway==0) 
     {
          $onewaytotavg=0;
     }
     else
     {
          $onewaytotavg=$onewayavg/$oneway;
     }
     if ($twoway==0)
     {
          $twowaytotavg=0;
     }
     else
     {
          $twowaytotavg=$twowayavg/$twoway;
     }
     $tmp=&convertmonthnum();
     print FILE "$tmp $todaysinfo[3] @sendntlog[4]:$oneway:$onewaytotavg:$twoway:$twowaytotavg\n";
     print BFILE "$tmp $todaysinfo[3] @sendntlog[4]:$oneway:$onewaytotavg:$twoway:$twowaytotavg\n";
     $host="198.148.155.18";
     $Email="adelong\@mtelatc.com,jdement\@mtelatc.com";
     $Subject="Nightly Stats: $tmp $todaysinfo[3] @sendntlog[4]";
     $required_h="message";
     $message="\nDate:$tmp $todaysinfo[3] @sendntlog[4]\nTotal 1-way messages: $oneway\nAvg len: $onewaytotavg\nTotal 2-way message: $twoway\nAvg len: $twowaytotavg\n\n";
     $totmessages=$oneway+$twoway;
       $message.="\nStatistics for CGIs are as follows:\n";
     $message.="\npage.pl: $pagetotal ss_paging.pl: $sstotal db.pl: $dbtotal\n";
     $message.="\nHourly paging statistics for one-way:\n";
     for ($x=0; $x<24; $x++) {
          $message.="Hour: $x     Messages Sent: $onewayhour{$x}\n";
     }
     $message.="\nHourly paging statistics for two-way:\n";
     for ($x=0; $x<24; $x++) {
          $message.="Hour: $x     Messages Sent: $twowayhour{$x}\n";
     }
     $url="/skytel.nsf/email+agent?openagent&email_h=$Email&subject_h=$Subject&required_h=$required_h&message=$message";
     &SendMessage("adelong\@mtelatc.com", "adelong\@mtelatc.com", $Subject, $message);
     #&SendMessage("jdement\@mtelatc.com", "adelong\@mtelatc.com", $Subject, $message);
     #&SendMessage("asipes\@mtelatc.com", "adelong\@mtelatc.com", $Subject, $message);
     #($status,$text) = &url_get'http_get($host,"80",$url);
     if ($status)
     {
	print "Error occurred sending mail.\n";
	open(OFILE, ">c:\\tools\\compilelog.err");
	print OFILE "Status returned: $status\n";
	close(OFILE);
     }
     close(FILE);
}


#---------------------
#Main body of program
#--------------------
&Logit("Starting stats");
$oneway=0;
$twoway=0;
$onewayavg=0;
$twowayavg=0;
&Logit("Before setup");
&setup();
&Logit("After setup");
$outpath="\\\\jxnweb02\\c\$\\skytel\\data\\stats".(@todaysinfo[5]+1900).".log";
print "Outpath: $outpath\n";
&Logit("Reading jxnweb01");
$path1="\\\\jxnweb01\\c\$\\skytel\\data\\sendnt.log";
&getstats();
&Logit("Reading jxnweb02");
$path1="\\\\jxnweb02\\c\$\\skytel\\data\\sendnt.log";
&getstats();
&Logit("Reading jxnweb05");
$path1="\\\\jxnweb05\\c\$\\skytel\\data\\sendnt.log";
&getstats();
&Logit("Writing file");
&writefile();
