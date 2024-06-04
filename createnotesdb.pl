#!/usr/bin/perl

require 'url_get.pl';


@begintime=localtime(time);
$drive="n";
$host="home2";
$cmd="dir $drive:\\export\\skytel\\db";
$path="n:\\export\\skytel\\db";
$output=`$cmd`;
($trash, $trash1, $trash2, $test)=split(/\\/, $output);
(@files)=split(/\s+/, $test);
foreach $x (@files) {
     if ($x=~ /\w\w/ && length($x)<=2) {
          $same=0;
          foreach $dir (@dirsdone) {
               if ($x eq $dir) { $same=1; }
          }
          push(@dirsdone, $x);
          $url="personal.nsf/importdb?OpenAgent&dir=$x";
          $checkit=1;
          @fileinfo=stat("$drive:\\export\\skytel\\db\\".$x."\\db.dat");
          open(FILE, "$drive:\\export\\skytel\\db\\".$x."\\modtime.txt") || ($checkit=0);
          if ($checkit==0 && $same==0) {
               print "Creating modtime.txt file\n";
               #Call agent to import dir
               print "Importing dir $x\n";
               ($status,$text) = &url_get'http_get($host,"80",$url);
               if ($status) { print "STATUS: $status\n"; }
               print "OUTPUT: $text\n";
               open(OFILE, ">$drive:\\export\\skytel\\db\\".$x."\\modtime.txt");
               print OFILE @fileinfo[9];
               close(OFILE);
          }
          if ($checkit==1) {
               $modtimeinfo=<FILE>;
               chomp($modtimeinfo);
               close(FILE);
               if ($modtimeinfo ne @fileinfo[9]) { 
                    print "Modtime found, need to import $x\n"; 
                    #Call agent to import dir
                    print "Importing dir $x\n";
                    ($status,$text) = &url_get'http_get($host,"80",$url);
                    if ($status) { print "STATUS: $status\n"; }
                    print "OUTPUT: $text\n";
                    open(OFILE, ">$drive:\\export\\skytel\\db\\".$x."\\modtime.txt");
                    print OFILE @fileinfo[9];
                    close(OFILE);
               }
          }
     }
}
@endtime=localtime(time);
print "Started at ", @begintime[2], ":", @begintime[1], ":", @begintime[0], "\n";
print "Finished at ", @endtime[2], ":", @endtime[1], ":", @endtime[0], "\n";
