##############################################################################
#                               Env.pm                                       #
#                                                                            #
#       A collection of envelope generators written in pure Perl.            #
#                                                                            #
#                    Copyright (c) 2019 Barry Pierce                         #
#                                                                            #
##############################################################################  
package Env;
use strict;
use warnings;

use Carp 'croak';
use base 'Exporter';


our @EXPORT_OK = qw(
    make_line_env
    make_expon_env 
    make_asr_env
    make_adsr_new
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# line envelope generator factory function
sub make_line_env {
    my ($start, $end, $duration, $samp_rate) = @_;
    
    $samp_rate //= 44100;
    # convert times to samples
    $duration *= $samp_rate;
    
    my $i = 0;
    my $v = 0;
    return sub {
        if ($i++ < $duration) {
            $v += ($end - $start) / $duration;
        }
        else {
            $v = $end;
            $i = 0;
        }
        return $v;
    }
}

# exponential envelope generator factory function
sub make_expon_env {
    my ($start, $end, $duration, $samp_rate) = @_;
    
    $samp_rate //= 44100;
    
    $duration *= $samp_rate;
    
    my $i = 0;
    
    return sub {
        if ($i++ < $duration) {
            return $start * ($end / $start) ** ($i / $duration);
        }
        else {
            $i = 0;
            return $end;
        }
    }
}

# attack, sustain, release envelope generator factory function
sub make_asr_env {
    my ($attack, $sustain, $release, $duration, $samp_rate) = @_;
    
    $samp_rate //= 44100;
    # convert times to samples
    $attack   *= $samp_rate;
    $release  *= $samp_rate;
    $duration *= $samp_rate;
    
    my $release_start = $duration - $release;
    my $i = 0;
    my $v;
    return sub {
        if ($i < $duration) {
            if ($i <= $attack) {
                $v = $i * ($sustain / $attack);
            }
            elsif ($i <= $release_start) {
                $v = $sustain;
            }
            elsif ($i > $release_start) {
                $v = -($sustain / $release) * ($i - $release_start) + $sustain;
            }
        }
        else {
            $v = 0;
        }
        $i++;
        
        return $v;
    }
}

# attack, decay, sustain, release envelope generator factory function
sub make_adsr_env {
    my ($attack, $decay, $sustain, $release, $duration, $max_amp, $samp_rate) = @_;
    
    $samp_rate //= 44100;
    
    # convert times to samples
    $attack   *= $samp_rate;
    $decay    *= $samp_rate;
    $release  *= $samp_rate;
    $duration *= $samp_rate;
    
    my $release_start = $duration - $release;
    my $i = 0;
    my $v;
    
    return sub {
        if ($i < $duration) {
            if ($i <= $attack) {
                $v = $i * ($max_amp / $attack);
            }
            elsif ($i <= ($attack + $decay)) {
                $v = (($sustain - $max_amp) / $decay) * ($i - $attack) + $max_amp;
            }
            elsif ($i <= $release_start) {
                $v = $sustain;
            }
            elsif ($i > $release_start) {
                $v = -($sustain / $release) * ($i - $release_start) + $sustain;
            }
        }
        else {
            $v = 0;
        }
        $i++;
        return $v;
    }
}


1;
