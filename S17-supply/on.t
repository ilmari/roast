use v6;
use lib 't/spec/packages';

use Test;
use Test::Tap;

plan 11;

for ThreadPoolScheduler.new, CurrentThreadScheduler -> $*SCHEDULER {
    diag "**** scheduling with {$*SCHEDULER.WHAT.perl}";

    {
        my $s1 = Supply.from-list(1..10);
        my $on = on -> $res {
            $s1 => sub ($val) {
                $res.emit($val);
            }
        }
        tap-ok $on, [1..10], "minimal 'on' works";
    }

    {
        my $s1 = Supply.from-list("a".."j");
        my $s2 = Supply.from-list(1..10);
        my $on = on -> $res {
            my @a1;
            my @a2;
            $s1 => sub ($val) {
                @a1.push($val);
                if @a1 && @a2 {
                    $res.emit( (@a1.shift => @a2.shift) );
                }
            },
            $s2 => -> \val {
                @a2.push(val);
                if @a1 && @a2 {
                    $res.emit( @a1.shift => @a2.shift );
                }
            }
        }
        tap-ok $on,
          [:a(1),:b(2),:c(3),:d(4),:e(5),:f(6),:g(7),:h(8),:i(9),:j(10)],
          "basic 2 supply 'on' works";
    }

    {
        my $a = Supply.from-list("a".."e");
        my $b = Supply.from-list("f".."j");
        my $on = on -> $res {
            my @values = [],[];
            ($a,$b) => sub ($val,$index) {
                @values[$index].push($val);
                if all(@values) {
                    $res.emit( (@values.map: *.shift).list.item );
                }
            }
        }
        tap-ok $on,
          [<a f>,<b g>,<c h>,<d i>,<e j>],
          "basic 2 supply with (a,b) 'on' works";
    }

    {
        my @s=(Supply.from-list("a".."e"),Supply.from-list("f".."k"),Supply.from-list("l".."p"));
        my $on = on -> $res {
            my @values = ($[] xx +@s);
            @s => -> \val, \index {
                @values[index].push(val);
                if all(@values) {
                    $res.emit( ([,] @values.map: *.shift).list.item );
                }
            }
        }
        tap-ok $on,
          [<a f l>,<b g m>,<c h n>,<d i o>,<e j p>],
          "basic 3 supply with array 'on' works";
    }

    {
        my @s = ( Supply.from-list("a".."e"), Supply.from-list("f".."k") );
        my @seen;
        my $on = on -> $res {
            my $done = 0;
            @s => {
              emit => sub ($val) { @seen.push($val); $res.emit($val) },
              done => { $res.done if ++$done == +@s }
            }
        }
        tap-ok $on, @seen, "basic 2 supply with array without index 'on' works";
    }
}

# RT #126073
{
    tap-ok Supply.new.flat.flat.last,[],'test for #126073';
}
