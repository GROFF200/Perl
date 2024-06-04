#!/usr/bin/perl

$FILENAME="c:\\tools\\usernames.txt";
$OUTFILENAME="c:\\tools\\userlist.txt";
$DBDATFILENAME="c:\\export\\skytel\\dbnewuser\\db.dat";

sub uppercase
{
   local($in) = @_;

   $in =~ tr/a-z/A-Z/;

   $in;
}

sub Escape
{
   local($in) = @_;

   # Convert \W to %XX
   $in =~ s/(\W)/"%".&uppercase(unpack("H2",$1))/ge;

   $in;
}

open(FILE, $FILENAME);
open(OFILE, ">>".$OUTFILENAME);
open(USERFILE, ">>".$DBDATFILENAME);
while (<FILE>) {
     chomp($_);
     @info=split(/;/, $_);
     @info1=split(/:/, @info[0]);
     print OFILE &Escape(@info1[1]), "\n";
     print USERFILE @info1[1];
     for ($x=1; $x<$#info+1; $x++) { print USERFILE ";".@info[$x]; }
     print USERFILE "\n";
}
close(FILE);
close(OFILE);
close(USERFILE);