# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use ExtUtils::MakeMaker

; my $pm = 'lib/CGI/Builder/Magic.pm'

; WriteMakefile
   ( NAME           => 'CGI::Builder::Magic'
   , VERSION_FROM   => $pm
   , ( $] ge '5.005' )
     ? ( AUTHOR         => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT_FROM  => $pm
       )
     : ()
   , PREREQ_PM      => { 'CGI::Builder'    => 1.2
                       , 'Class::props'    => 1.62
                       , 'Class::groups'   => 1.62
                       , 'Object::props'   => 1.62
                       , 'Template::Magic' => 1.33
                       }
   )


; 1
