#!/usr/local/bin/perl

#----------------------------------------------------------------------
# Description:
#    This script obtains the stock quote from the NASDAQ web site.
#----------------------------------------------------------------------

# Declare global variables.
require 'url_get.pl';
use Win32::Process;
use Win32;

#----------------------------------------------------------------------
#                           MAIN PROGRAM
#----------------------------------------------------------------------
$perl_exe = "c:/perl/bin/perl.exe";

$host = "skytel";
$url = "/cgi-bin/test.pl";
$clients = 30;

if (@ARGV < 1)
{  #Parent process
   for ($x = 1; $x <= $clients; $x++)
   {
      Win32::Process::Create($ProcessObj,  #object to hold process.
                             $perl_exe, #executable
                             "perl $0 $x", #command line
                             0,   #no inheritance.
                             CREATE_DEFAULT_ERROR_MODE, #give default error mode
                             ".") || die &Error; #current dir.
   }
}
else
{  #Child process

   for ($y = 1; $y <= 25000; $y++)
   {
      ($status,$text) = &url_get'http_get($host,"80",$url);
      if ($status != 0)
      {
         print "*Error* Client: $ARGV[0] Status: $status Loop Count: $y\n";
      }
   }
}

#($status,$text) = &url_get'http_get($host,"80",$url);
#print "$text";

exit;

#----------------------------------------------------------------------
#                           SUB ROUTINES
#----------------------------------------------------------------------
sub Error
{ 
   print Win32::FormatMessage(Win32::GetLastError());
}

