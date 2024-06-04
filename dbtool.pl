#!/usr/local/bin/perl
exit; # Not converted.
#----------------------------------------------------------------------------
# Description: This CGI script provides database viewing capabilities for
#   the databases created using the db.cgi script.
#----------------------------------------------------------------------------
$|=1;   # Turn off buffering to STDOUT.

#----------------------------------------------------------------------------
#-- Declare global variables and constants here.
#----------------------------------------------------------------------------
local($FALSE,$TRUE) = (0,1);
local($DB_DIR) = ("/www/prod/DB");

local(%db,@db_contents,*DB_LOCK,$login,$accessed_date);
local($cmd,$arg,$argument);

#----------------------------------------------------------------------------
#----------------------------------------------------------------------------
#----------------------------------------------------------------------------

$cmd = $ARGV[0];
$cmd =~ s/^-//;

if ($cmd eq "l")
{ # logins
   &display_logins($ARGV[1]);
}
elsif ($cmd eq "v")
{ # view user
   &display_record($ARGV[1]);
}
elsif ($cmd eq "d")
{ # delete user
   &delete_login($ARGV[1]);
}
elsif ($cmd eq "e")
{ # edit field in user's account
   &edit_field($ARGV[1],$ARGV[2],$ARGV[3])
}
elsif ($cmd eq "a")
{ # add field in user's account
   &add_field($ARGV[1],$ARGV[2],$ARGV[3])
}
else
{ # print help
   print "\nInvalid command given.\n\n";
   print "dbtool.cgi -l <DB> = View logins in database.\n";
   print "dbtool.cgi -v <login> = View login contents.\n";
   print "dbtool.cgi -d <login> = Delete this login.\n";
   print "dbtool.cgi -e <login> <field> <value> = Change field to value for this login.\n";
   print "dbtool.cgi -a <login> <field> <value> = Add field for this login.\n";
   print "\n\n";
}


exit;

#----------------------------------------------------------------------------
#----------------------------------------------------------------------------
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# delete_login : This routine will read the correct database for the
#   given login and will display the login and date of that record.  It will
#   then save the database without that login, thereby removing it from
#   the database.
#----------------------------------------------------------------------------
sub delete_login
{
   local($login) = @_;

   &lock_database($login);
   %db = &read_rec($login);

   print "LOGIN|$login\n";
   print "DATE |$accessed_date\n\n";
   
   &save_database($login);
   &unlock_database();
}

#----------------------------------------------------------------------------
# display_logins : Display the logins and access dates for the given
#   database.
#----------------------------------------------------------------------------
sub display_logins
{
   local($database) = @_;
   local(@contents,$login,$date,$line);
   local(*DB_FILE,$db_dir);

   $db_dir = "$DB_DIR/$database";

   open(DB_FILE,"$db_dir/db.dat") || die "Could not open database file for reading.";
   @contents = <DB_FILE>;
   close(DB_FILE);

   foreach $line (@contents)
   {
      ($login,$date) = split(";",$line);
      print "$date - $login\n";
   }
}

#----------------------------------------------------------------------------
# edit_field : This routine will read the correct database for the
#   given login and will display and edit the field that is passed in as an
#   argument.
#----------------------------------------------------------------------------
sub edit_field
{
   local($login,$field_name,$new_value) = @_;
   local($key,@fields,$field);

   &lock_database($login);
   %db = &read_rec($login);

   print "LOGIN|$login\n";
   print "DATE |$accessed_date\n";
  
   if ( defined($db{$field_name}))
   {
      print "Current $field_name : $db{$field_name}\n";
      $db{$field_name} = $new_value;
      print "New     $field_name : $db{$field_name}\n";
      &write_rec();
   }
   else
   {
      print "ERROR: $field_name was not found.\n\n";
   }

   &unlock_database();
}

#----------------------------------------------------------------------------
# add_field : This routine will read the correct database for the
#   given login and will add the field that is passed in as an
#   argument.
#----------------------------------------------------------------------------
sub add_field
{
   local($login,$field_name,$new_value) = @_;
   local($key,@fields,$field);

   &lock_database($login);
   %db = &read_rec($login);

   print "LOGIN|$login\n";
   print "DATE |$accessed_date\n";
 
   if ( defined($db{$field_name}))
   {
      print "ERROR: $field_name is already defined.  Use edit to modify it.\n\n";
   }
   else
   {
      $db{$field_name} = $new_value;
      print "New     $field_name : $db{$field_name}\n";
      &write_rec();
   }

   &unlock_database();
}

#----------------------------------------------------------------------------
# display_record : This routine will read the correct database for the
#   given login and will display the elements of that record.
#----------------------------------------------------------------------------
sub display_record
{
   local($login) = @_;
   local($key,@fields,$field);

   &lock_database($login);
   %db = &read_rec($login);

   print "LOGIN|$login\n";
   print "DATE |$accessed_date\n";
   
   foreach $key (sort(keys(%db)))
   {
      print "\n$key\n";
      print "-" x length($key);
      print "\n";
      
      if (($key =~ /MSG/) || ($key =~ /ADD/) || ($key =~ /PROFILE/))
      {
         @fields = &get_fields($db{$key});
         foreach $field (@fields)
         {
            print "$field|";
         }
         print "\n";
      }
      else
      {
         print $db{$key}."\n";
      }
   }
   
   &unlock_database();
}

#----------------------------------------------------------------------------
# read_rec : This routine will return read in a record from the database
#   array based on the login argument.  (The index key is the login name.)
#----------------------------------------------------------------------------
sub read_rec
{
   local($login,$override) = @_;
   local($data,$count,$num,%new_rec,@elements);

   $num = @db_contents;
   for ($count = 0; $count < $num; $count++)
   {
      if ($db_contents[$count] =~ /^$login;/)
      {
         $data = $db_contents[$count];
         chop $data;
         splice(@db_contents,$count,1);
         last;
      }
   }

   @elements = split(";",$data);

   # Convert array to an associative array.
   $num = @elements;

   $accessed_date = $elements[1];
   
   # First two elements are the login and date, so start on third element.
   for ($count = 2; $count < $num; $count += 2)
   {
      $new_rec{$elements[$count]} = &unescape($elements[$count+1]);
   }

   %new_rec;
}

#----------------------------------------------------------------------------
# save_database : Save the current database contents.
#----------------------------------------------------------------------------
sub save_database
{
   local($login) = @_;
   local(*DB_FILE,$db_dir,$key);

   $db_dir = "$DB_DIR/" . substr($login,0,2);
   open(DB_FILE,">$db_dir/db.dat") || die "Could not open database file for writing.";
   print DB_FILE @db_contents;
   close(DB_FILE);
}

#----------------------------------------------------------------------------
# write_rec : This routine will add the data to the front of the database
#   array and then write the new array to disk.  If no data is passed in,
#   then the array is written as is (with no data added to it).
#----------------------------------------------------------------------------
sub write_rec
{
   local(*DB_FILE,$db_dir,$key);

   $data = "$login;".&date("%m/%d/%y");
   
   foreach $key (sort(keys(%db)))
   {
      next if ($db{$key} eq "");
      $data .= ";$key;".&escape($db{$key});
   }

   if ($data ne "")
   {
      $data .= "\n";
      unshift(@db_contents,$data);
   }

   $db_dir = "$DB_DIR/" . substr($login,0,2);
   open(DB_FILE,">$db_dir/db.dat") || die "Could not open database file for writing.";
   print DB_FILE @db_contents;
   close(DB_FILE);
}

#----------------------------------------------------------------------------
# lock_database : This routine opens and locks the database file for
#   exclusive access.  It also loads the database into memory.
#----------------------------------------------------------------------------
sub lock_database
{
   local($login) = @_;
   local($LOCK_EX,$db_dir) = (2,"");
   local(*DB_FILE);

   $db_dir = "$DB_DIR/" . substr($login,0,2);

   mkdir($db_dir,0755) unless (-d $db_dir);
   `touch $db_dir/db.dat` unless (-e "$db_dir/db.dat");
   `touch $db_dir/db.lock` unless (-e "$db_dir/db.lock");
   
   open(DB_LOCK,">$db_dir/db.lock") || die "Could not lock database lock-file.";
   flock(DB_LOCK,$LOCK_EX) || die("Failed to acquire a write lock.");

   open(DB_FILE,"$db_dir/db.dat") || die "Could not open database file for reading.";
   @db_contents = <DB_FILE>;
   close(DB_FILE);
}

#----------------------------------------------------------------------------
# unlock_database : This routine unlocks the database file and closes it.
#----------------------------------------------------------------------------
sub unlock_database
{
   local($LOCK_UN) = (8);

   flock(DB_LOCK,$LOCK_UN);
   close(DB_LOCK);
}

#----------------------------------------------------------------------------
# date : This routine returns the current date in a specified format, or
#   in the usual default manner.     Side Note: "%m/%d/%y"
#----------------------------------------------------------------------------
sub date
{
   local($format) = @_;
   local($date);

   ($format ne "") ?
      ($date = `date +"$format"`) :
      ($date = `date`);
   chop $date;
   $date;
}

#-------------------------------------------------------------------
# uppercase : This routine will accept a string, and return it
#   with all the letters in upper case.
#-------------------------------------------------------------------
sub uppercase
{
   local($in) = @_;

   $in =~ tr/a-z/A-Z/;

   $in;
}

#-------------------------------------------------------------------
# escape : This routine accepts a string as an argument, and
#   returns that string with the \W characters converted
#   to their hexadecimal values.
#-------------------------------------------------------------------
sub escape
{
   local($in) = @_;

   # Convert \W to %XX
   $in =~ s/(\W)/"%".&uppercase(unpack("H2",$1))/ge;

   $in;
}

#-------------------------------------------------------------------
# unescape : This routine accepts a string as an argument, and
#   returns that string with the %xx hex characters converted
#   to their ASCII characters.
#-------------------------------------------------------------------
sub unescape
{
   local($in) = @_;

   # Convert %XX from hex numbers to alphanumeric
   $in =~ s/%(..)/pack("c",hex($1))/ge;

   $in;
}


#-------------------------------------------------------------------
# write_fields : This routine takes an array and returns a string
#   that is a semi-colon delimited concatenation of the elements.
#   Each element is escaped to prevent problems with semi-colons
#   that might appear in the array element.
#-------------------------------------------------------------------
sub write_fields
{
   local(@elements) = @_;
   local($element,$return);

   foreach $element (@elements)
   {
      $return .= &escape($element) . ";";
   }
   chop $return;
   $return;
}

#-------------------------------------------------------------------
# get_fields : This routine will return the unescaped fields that
#    exist in a semi-colon delimited string.
#-------------------------------------------------------------------
sub get_fields
{
   local($string) = @_;
   local(@fields,$field);

   @fields = split(";",$string);

   foreach $field (@fields)
   {
      $field = &unescape($field);
   }
   @fields;
}

#-------------------------------------------------------------------
# logit : Write the given text to the given log file.
#-------------------------------------------------------------------
sub logit
{
   local($log,$text) = @_;
   local($date,*FILE);

   $date = `date`;
   chop $date;

   open(FILE,">>$log");
   print FILE "$date $text\n";
   close (FILE);
}


