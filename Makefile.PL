use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::DProf',
    'VERSION_FROM' => 'DProf.pm', # finds $VERSION
    'dist' => { 
         PREOP => 'co -l README && pod2text DProf.pm > README && ci -u README',
         DIST_DEFAULT => 'all tardist',
         COMPRESS => 'gzip -9f'
     },
);
