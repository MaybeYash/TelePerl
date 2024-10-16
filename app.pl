#!/usr/bin/perl
use strict;
use warnings;
use Telegram::Bot::API;
use JSON;
use File::Find;

my $token = 'YOUR_BOT_TOKEN_HERE';
my $api = Telegram::Bot::API->new(token => $token);
my %commands;

sub register_command {
    my ($command_name, $func_ref) = @_;
    $commands{$command_name} = $func_ref;
}

sub load_modules {
    my $modules_dir = "modules";
    find(sub {
        return unless /\.pl$/;
        my $module_file = $File::Find::name;
        do $module_file or warn "Could not load $module_file: $@";
    }, $modules_dir);
}

load_modules();

my $bot_info = $api->getMe();
print "Name: " . $bot_info->{result}{first_name} . "\n";

my $last_update_id = 0;
while (1) {
    my $updates = $api->getUpdates({ timeout => 30, offset => $last_update_id + 1 });

    for my $update (@{ $updates->{result} }) {
        $last_update_id = $update->{update_id};

        if (exists $update->{message}) {
            my $chat_id = $update->{message}{chat}{id};
            my $text = $update->{message}{text};

            if ($text =~ /^\/(\w+)/) {
                my $command = $1;

                if (exists $commands{$command}) {
                    my $func_ref = $commands{$command};
                    $func_ref->($chat_id, $api);
                }
            }
        }
    }
    sleep(1);
}
