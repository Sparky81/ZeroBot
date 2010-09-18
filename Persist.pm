# require 'core.pl';
require HelpTree;
sub modinit {
    my ($acl, $name, $desc) = @_;
    if ($acl eq 'None')
    {
        $ht_none->{"$name"} = "$desc";
        $ht_admin->{"$name"} = "$desc";
        $ht_owner->{"$name"} = "$desc";

        unshift(@acl_none, "$name");
        unshift(@acl_admin, "$name");
        unshift(@acl_owner, "$name");
    }

    if ($acl eq 'Admin')
    {
        $ht_admin->{"$name"} = "$desc";
        $ht_owner->{"$name"} = "$desc";

        unshift(@acl_admin, "$name");
        unshift(@acl_owner, "$name");

    }

    if ($acl eq 'Owner')
    {
        $ht_owner->{"$name"} = "$desc";
        unshift(@acl_owner, "$name");

    }

}
sub modload {
    my ($dst, $mod) = @_;
    require "$mod";
	do "$mod" or notice($dst, "Could not load \002$mod\002. ($!)\n");
    notice ($dst, "Attempted to load \002$mod\002. Use the command to see if it was a success.");
}
glob *modload;
#glob *modinit;
1;
