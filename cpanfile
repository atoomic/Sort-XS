requires "Carp"  => 0;
requires "Scalar::Util"  => 0;
requires "XSLoader"  => 0;
requires "Exporter"  => 0;

on "test" => sub {
    requires "Test::More"            => "0";
};
