# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use ExtUtils::MakeMaker

; my $dist = 'CGI::Builder::Magic'
; my $vers = '1.26'

; WriteMakefile
   ( NAME           => $dist
   , VERSION        => $vers
   , ( $] ge '5.005' )
     ? ( AUTHOR     => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT   => 'CGI::Builder and Template::Magic integration'
       )
     : ()
   , PREREQ_PM      => { 'CGI::Builder'    => '1.2'
                       , 'Template::Magic' => '1.12'
                       }
   )


; 1
