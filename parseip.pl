#!/usr/bin/perl

open(FILE, "\\\\jxnweb01\\c\$\\skytel\\data\\sendnt.log");
open(OFILE, ">>iplog2.txt");
while (<FILE>)
{
     if ($_=~ /IP:(\d+).(\d+).(\d+).(\d+)/)
     {
          print OFILE "$1.$2.$3.$4\n";
     }
}
close(OFILE);
close(FILE);