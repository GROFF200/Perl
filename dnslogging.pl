#!/usr/bin/perl

$path="k:\\logs_skytel\\";
$tmppath="c:\\temp\\";
$tablename="g:\\tools\\dnscache.inf";

#---------------------------------
# Find out what the last day of
# the previous month was.
#---------------------------------
sub PrevMonthDay()
{
 
     #Take care of all months with 31 days
     if ($thismonth eq "Jan" || $thismonth eq "Mar" || $thismonth eq "May" || $thismonth eq "Jul" || $thismonth eq "Aug" || $thismonth eq "Oct" || $thismonth eq "Dec")
     {
          $thisday=31;
     }
     #Now take care of all months with 30 days
     elsif ($thismonth eq "Apr" || $thismonth eq "Jun" || $thismonth eq "Sep" || $thismonth eq "Nov")
     {
          $thisday=30;
     }
     #Take care of February....don't worry about leapyears yet.
     elsif($thismonth eq "Feb")
     {
          $thisday=28;
     }
}

#-------------------------------
# Find out what the previous
# month was.
#-------------------------------
sub PrevMonth()
{
     if ($thismonth eq "Jan")
     {
          $thismonth="Dec";
     }
     elsif ($thismonth eq "Feb")
     {
          $thismonth="Jan";
     }
     elsif ($thismonth eq "Mar")
     {
          $thismonth="Feb";
     }
     elsif ($thismonth eq "Apr")
     {
          $thismonth="Feb";
     }
     elsif ($thismonth eq "May")
     {
          $thismonth="Apr";
     }
     elsif ($thismonth eq "Jun")
     {
          $thismonth="Jun";
     }
     elsif ($thismonth eq "Jul")
     {
          $thismonth="Jun";
     }
     elsif ($thismonth eq "Aug")
     {
          $thismonth="Jul";
     }
     elsif ($thismonth eq "Sep")
     {
          $thismonth="Aug";
     }
     elsif ($thismonth eq "Oct")
     {
          $thismonth="Sep";
     }
     elsif ($thismonth eq "Nov")
     {
          $thismonth="Oct";
     }
     elsif ($thismonth eq "Dec")
     {
          $thismonth="Nov";
     }
     &PrevMonthDay();
}

#-------------------------------
# Find out what filename to
# use to access logfiles.
#-------------------------------
sub GetFileName()
{
     @dateinfo=localtime(time);
     $thismonth=(Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec) [(localtime) [4]];
     $thisyear=@dateinfo[5]+1900;
     $thisday=@dateinfo[3];
     $fname="access-log.";
     $thisday--;
     if ($thisday==0) 
     {
          &PrevMonth();
     }
     if ($thisday<10)
     {
          $fname.=$thismonth."0".$thisday.$thisyear;
     }
     else
     {
          $fname.=$thismonth.$thisday.$thisyear;
     }  
}

#---------------------------------
# Build associative array from
# file specified in $tablename.
# This should speed up DNS by
# providing a cache that can
# be loaded from disk into memory.
#---------------------------------
sub BuildLookupTable()
{
     open(TFILE, $tablename);
     while (<TFILE>)
     {
          chomp($_);
          local($ipaddr);
          local($thekey, $thevalue)=split(/:/, $_);
          if ($thekey=~ /(\d+).(\d+).(\d+).(\d+)/)
          {
               $ipaddr=$1.".".$2.".".$3.".".$4;
          }
          $input{$ipaddr}=$thevalue;
     }
     close(TFILE); 
}

#-------------------------
# Write associative array
# out to a file so it can
# be used again next time
# the program is executed.
#-------------------------
sub WriteCache()
{
     open(OFILE, ">$tablename");
     foreach $key (%input)
     {
           if ($input{$key})
           {
                print OFILE "$key : $input{$key}\n";
           }
      }
      close(OFILE);
}

#-------------------------------
# Take each log entry and
# look at the IP.  If IP
# exists in cache, use the
# cache value otherwise do
# a reverse DNS lookup of 
# that IP.  If IP doesn't resolve
# just use the IP.  Then write
# log entry to file.
#--------------------------------
sub ReverseDNS()
{
     open(FILE, $path.$fname);
     binmode(FILE);
     open(OFILE, ">".$tmppath.$fname.".dns");
     binmode(OFILE);
     while (<FILE>)
     {
          @line=split(/\s+/, $_);
          if ($_=~ /(\d+).(\d+).(\d+).(\d+)/)
          {
               $ip1=$1;
               $ip2=$2;
               $ip3=$3;
               $ip4=$4;
               $index=$1.".".$2.".".$3.".".$4;
          }
          if ($input{$index} eq "")
          {
               $address=pack "c4", $ip1,$ip2,$ip3,$ip4;
               ($name, $aliases, $addrtype, $length, @addrs)=gethostbyaddr($address, AF_INET);
               if ($name ne "")
               {
                    $input{$index}=$name;
               }
               else
               {
                    $input{$index}=$index;
               }
          }
          $input{$index}=~ s/\s+//;
          print OFILE $input{$index}, " ";
          for ($x=0; $x<$#line+1; $x++)
          {
               if ($x>0)
               {
                    print OFILE @line[$x], " ";
               }
          } 
          print OFILE "\n";
     }
     close(OFILE);
     close(FILE);
}


&GetFileName();
print "Reading cache into memory....\n\n";
&BuildLookupTable();
print "Parsing log file....doing reverse DNS for $path$fname....\n\n";
&ReverseDNS();
print "Flushing cache from memory to disk....\n";
&WriteCache();
