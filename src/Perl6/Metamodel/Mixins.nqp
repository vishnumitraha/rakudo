role Perl6::Metamodel::Mixins {
    has $!is_mixin;
    method set_is_mixin($obj) { $!is_mixin := 1 }
    method is_mixin($obj) { $!is_mixin }
    method flush_cache($obj) { }

    method mixin($obj, *@roles) {
        # Flush its cache as promised, otherwise outdated NFAs will stick around.
        self.flush_cache($obj) if !nqp::isnull($obj) || self.is_mixin($obj);
        # Work out a type name for the post-mixed-in role.
        my @role_names;
        for @roles { @role_names.push(~$_.HOW.name($_)) }
        my $new_name := self.name($obj) ~ '+{' ~
            nqp::join(',', @role_names) ~ '}';
        
        # Create new type, derive it from ourself and then add
        # all the roles we're mixing it.
        my $new_type := self.new_type(:name($new_name), :repr($obj.REPR));
        $new_type.HOW.set_is_mixin($new_type);
        $new_type.HOW.add_parent($new_type, $obj.WHAT);
        for @roles {
            $new_type.HOW.add_role($new_type, $_);
        }
        $new_type.HOW.compose($new_type);
        $new_type.HOW.set_boolification_mode($new_type,
            nqp::existskey($new_type.HOW.method_table($new_type), 'Bool') ?? 0 !!
                self.get_boolification_mode($obj));
        $new_type.HOW.publish_boolification_spec($new_type);
        
        # If the original object was concrete, change its type by calling a
        # low level op. Otherwise, we just return the new type object
        nqp::isconcrete($obj) ?? nqp::rebless($obj, $new_type) !! $new_type
    }
    
    method mixin_base($obj) {
        for self.mro($obj) {
            unless $_.HOW.is_mixin($_) {
                return $_;
            }
        }
    }
}
