use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'WWW::Correios::CEP', 
    VERSION_FROM      => 'lib/WWW/Correios/CEP.pm', 
    PREREQ_PM         => {
	 LWP => '0.01',
	'LWP::UserAgent' => '0.01',
	'HTML::TreeBuilder::XPath' => '0.01'
	}, # e.g., Module::Name => 1.1
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	(ABSTRACT_FROM  => 'lib/WWW/Correios/CEP.pm', # retrieve abstract from module
	AUTHOR    => 'rentocron <rentocron@cpan.org>') : ()),
);
