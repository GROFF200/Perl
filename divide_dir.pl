# Make sure we are working in the local directory.
$working_dir = ".";
#- If the current directory is not the same directory containing the
#- script, then chdir to the directory containing the script.
if ($0 =~ m#\\#)   # $0 contains the name of the running program.
{
   $working_dir = $0;
   $working_dir =~ s#^(.*)\\.*#$1#;
   chdir($working_dir);
}


#---------------------------------------------------------------------
# MAIN
#---------------------------------------------------------------------

if (@ARGV != 3)
{
   print "Usage: divide_dir.pl <drive:/dir1/dir2/start_dir> <drive:/dirA/dirB/dest_dir> <number of partitions>\n\n";
   print "Usage Example: divide_dir.pl c:/export/skytel/db c:/export/skytel/db 4\n\n";
   print "Will create c:/export/skytel/db1, c:/export/skytel/db2, c:/export/skytel/db3, and c:/export/skytel/db4\n\n";
   exit;
}

$start_dirname = $ARGV[0];
$dest_dirname = $ARGV[1];
$number_partitions = $ARGV[2];

print "Starting DIR    : $start_dirname\n";
print "Destination DIR : $dest_dirname\n";
print "Num Partitions  : $number_partitions\n";

@dirs = &read_dir($start_dirname,".","n");

$count = @dirs;
print "There were $count directories found.\n";

$partition = int($count / $number_partitions) + 1;
print "We will use a partition size of $partition.\n";

$counter = 0;

foreach $dir (sort(@dirs))
{
   $part = int($counter / $partition) + 1;
   $counter = $counter + 1;
   $dir =~ /([^\/]+)$/;
   $subdir = $1;

   # Make new db directory if needed.
#   print "mkdir: $dest_dirname$part\n";
   mkdir("$dest_dirname$part",0755) unless (-d "$dest_dirname$part");

   # Make new subdirectory if needed
#   print "mkdir: $dest_dirname$part/$subdir\n";
   mkdir("$dest_dirname$part/$subdir",0755) unless (-d "$dest_dirname$part/$subdir");
   
   $cmd = "copy $dir $dest_dirname$part/$subdir";
   $cmd =~ s/\//\\/g;
   print "$cmd\n";
   `$cmd`;
}

print"Exit\n";
exit;

#---------------------------------------------------------------------


#---------------------------------------------------------------------
# read_dir : This routine reads the directory that is passed in as an
#    argument, and returns any file/dir names that match the pattern
#    that is also passed in as an argument.
#---------------------------------------------------------------------
sub read_dir
{
   local($dir_name,$pattern,$recurse) = @_;
   local(*DIR,$name,@file_list);

   print STDERR "From read_dir, directory $dir_name does not exist.\n" if (!(-e $dir_name));

   opendir(DIR,$dir_name) || die "Could not open $dir_name\n";
   while ($name = readdir(DIR))
   {
      next if (($name eq ".") || ($name eq ".."));

      if (($name =~ /$pattern/) && (-d "$dir_name/$name"))
      {
         push(@file_list,"$dir_name/$name");
      }
      if ((-d "$dir_name/$name") && ($recurse !~ /n/i))
      {
         @file_list = (@file_list,&read_dir("$dir_name/$name",$pattern));
      }
   }
   close(DIR);
   @file_list;
}


