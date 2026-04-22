use ExtUtils::MakeMaker;

my %CFG = (
    'NAME'          => 'Sort::XS',
    'AUTHOR'        => 'Nicolas R <me@eboxr.com>',
    'VERSION_FROM'  => 'lib/Sort/XS.pm',
    'ABSTRACT_FROM' => 'lib/Sort/XS.pm',
    'PL_FILES'      => {},
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
    'PREREQ_PM' => {
        'Test::More' => 0,    # For testing
        'Carp' => 0,
        'XSLoader' => 0,
        'Exporter' => 0,
    },
    'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    'clean'       => { FILES    => 'Sort-XS-* *.o' },
    'INSTALLDIRS' => 'site',
    'OBJECT'      => "sort.o XS.o",
    'META_MERGE'  => {
        build_requires => {
            'Test::More' => 0,    # For testing
            'Carp' => 0,
            'XSLoader' => 0,
            'Exporter' => 0,

        },
        resources => { license => 'http://dev.perl.org/licenses/', },
    }
);

WriteMakefile(%CFG);
