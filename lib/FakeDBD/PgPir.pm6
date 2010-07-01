pir::load_bytecode("Pg.pir");

class FakeDBD::PgPir::StatementHandle does FakeDBD::StatementHandle {
    has $!name;
    has $!RaiseError;

}

class FakeDBD::PgPir::Connection does FakeDBD::Connection {
    has $!pg_conn;
    has $!statement_name = 'a';
    has $!RaiseError;

    method prepare(Str $statement) {
        my $name = $!statement_name++;

        # the third argument to .prepare() is the number of 
        # bind where we want to explicitly specify the type
        my $handle = $!pg_conn.prepare($name, $statement, 0);
    }

    method status {
        my $c = $!pg_conn;
        ! Q:PIR {
            $P0 = find_lex '$c'
            $I0 = $P0.'status'()
            %r  = box $I0
        }
    }

    method Bool { $.status };

}

class FakeDBD::PgPir:auth<moritz> {

    sub pg_escape($x) {
        q[']
            ~ $x.subst(rx/\\|\'/, -> $m { '\\' ~ $m }, :g)
            ~ q['];
    }

    method connect(Str $user, Str $password, Str $params, $RaiseError) {
        my $pg  = pir::new__pS('Pg');

        my %params = $params.split(';').map({ .split(rx{\s*\=\s*}, 2)}).flat;


        my %opt =
            user => pg_escape($user),
            password => pg_escape($password),
            %params;
        %opt<application_name> //= 'Perl6FakeDBD';

        say "Options: %opt.perl()";

        # nearly scary how concise this is in Perl 6 :-)
        my $connection_string = %opt.fmt('%s=%s', ';');
        my $con = $pg.connectdb($connection_string);
    }

    method finish() {
        $!pg_conn.finish() if $.Bool;
    }
}

# vim: ft=perl6
