#!/usr/bin/perl

use FileHandle;
use IPC::Open2;

#------------------------------------------------
#Take the string given, use 
#ciphertext.exe to encrypt it,
#then return the encrypted string.
#------------------------------------------------
sub EncryptData() {
     $str=@_[0];
     $pid = open2(*Reader, *Writer, "ciphertext.exe sencrypt" );
      Writer->autoflush(); # default here, actually
      print Writer $str, "\n";
     $encdata = <Reader>;
     $encdata=substr($encdata, 0, length($encdata)-2);
     return $encdata;
}

#-------------------------------------------------
#Take the string given, use 
#ciphertext.exe to decrypt it, then 
#return the decrypted string.
#-------------------------------------------------
sub DecryptData() {
     $str=@_[0];
     $pid = open2(*Reader, *Writer, "ciphertext.exe sdecrypt" );
      Writer->autoflush(); # default here, actually
      print Writer $str, "\n";
     $encdata = <Reader>;
     $encdata=substr($encdata, 0, length($encdata)-2);
     return $encdata;
}


$text=@ARGV[0];
$encryptedtext=&EncryptData($text);
print "ENCRYPTED TEXT: $encryptedtext\n";
$decryptedtext=&DecryptData($encryptedtext);
print "DECRYPTED TEXT: $decryptedtext\n";