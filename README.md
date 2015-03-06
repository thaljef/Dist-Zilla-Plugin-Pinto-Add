# NAME

Dist::Zilla::Plugin::Pinto::Add - Ship your dist to a Pinto repository

# VERSION

version 0.088

# SYNOPSIS

    # In your dist.ini
    [Pinto::Add]
    root          = http://pinto.example.com  ; optional. defaults to PINTO_REPOSITORY_ROOT
    author        = YOU                       ; optional. defaults to PINTO_AUTHOR_ID
    stack         = stack_name                ; optional. defaults to repository setting
    recurse       = 0                         ; optional. defaults to repository setting
    pinto_exe     = /path/to/pinto            ; optional. defaults to searching PATH
    username      = you                       ; optional. defaults to PINTO_USERNAME
    password      = secret                    ; optional. will prompt if needed
    authenticate  = 1                         ; optional. defaults to 0

    # Then run the release command
    dzil release

# DESCRIPTION

This is a release-stage plugin for [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) that will ship your
distribution releases to a local or remote [Pinto](https://metacpan.org/pod/Pinto) repository.

Before building the release, all repositories are checked for connectivity. If
a repository is not responding you will be prompted to skip it or abort the
entire release.  If none of the repositories are responding, then the release
will be aborted.  Any errors encountered while shipping to the remaining
repositories will also cause the rest of the release to abort.

**IMPORTANT:** You need to install [Pinto](https://metacpan.org/pod/Pinto) to make this plugin work.  It ships
separately so you can decide how you want to install it.  Peronally, I
recommend installing Pinto as a stand-alone application as described in
[Pinto::Manual::Installing](https://metacpan.org/pod/Pinto::Manual::Installing) and then setting the `PINTO_HOME` environment
variable accordingly.  But you can also just install Pinto from CPAN using the
usual tools.

# CONFIGURATION

The following configuration parameters can be set in the `[Pinto::Add]`
section of the `dist.ini` file for your distribution.  Defaults for most
paramters can be set via environment variables or via the repository
configuration.

- root = REPOSITORY

    Specifies the root of the Pinto repository you want to ship to.  It can be
    either a path to a local repository or a URI where [pintod](https://metacpan.org/pod/pintod) is listening. If
    not specified, it defaults to the `PINTO_REPOSITORY_ROOT` environment
    variable.  You can ship to multiple repositories by specifying the `root`
    parameter multiple times.  See also ["USING MULTIPLE REPOSITORIES"](#using-multiple-repositories).

- authenticate = 0|1

    Indicates that authentication is required for communicating with the
    repository.  If true, you will be prompted for a `password` unless it is
    provided as described below.  Default is false.

- author = NAME

    Specifies your identity as a module author.  It must be two or more
    alphanumeric characters and it will be forced to UPPERCASE. If not specified,
    it defaults to either the `PINTO_AUTHOR_ID` environment variable, or else
    your PAUSE ID (if you have one configured in `~/.pause`), or else the
    `username` parameter.

- password = PASSWORD

    Specifies the password to use for authentication.  If not specified, it
    defaults to the `PINTO_PASSWORD` environment variable, or else you will be
    prompted to enter a password.  If your repository does require authentication,
    then you must also set the `authenticate` parameter to 1.  For security
    reasons, I do not recommend putting your password in the `dist.ini` file.

- recurse = 0|1

    If true, Pinto will recursively pull all the distributions required to satisfy
    the prerequisites for the distribution you are adding.  If false, Pinto will
    add the distribution only.  If not specified, the default behavior is
    determined by the repository configuration.

- stack = NAME

    Specifies which stack in the repository to put the released distribution into.
    If not specified, it defaults to the stack that is currently marked as the
    default within the repository.

- username = NAME

    Specifies the username for server authentication.  If not specified, it
    defaults to the `PINTO_USERNAME` environment variable, or else your current
    shell login.

- pinto\_exe = PATH

    Specifies the full path to your `pinto` executable.  If not specified, your
    `PATH` will be searched.

# USING MULTIPLE REPOSITORIES

You can ship your distribution to multiple repositories by specifying multiple
the `root` paramter multiple times in your `dist.ini` file.  In that case,
the remaining parameters (e.g. `stack`, `author`, `authenticate`) will
apply to all the repositories.

However, the recommended way to release to multiple repositories is to have
multiple `[Pinto::Add / NAME]` blocks in your `dist.ini` file.  This allows
you to set attributes for each repository independently (at the expense of
possibly having to duplicating some information).

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

    perldoc Dist::Zilla::Plugin::Pinto::Add

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [http://metacpan.org/release/Dist-Zilla-Plugin-Pinto-Add](http://metacpan.org/release/Dist-Zilla-Plugin-Pinto-Add)

- CPAN Ratings

    The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

    [http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Pinto-Add](http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Pinto-Add)

- CPANTS

    The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

    [http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-Pinto-Add](http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-Pinto-Add)

- CPAN Testers

    The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

    [http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-Pinto-Add](http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-Pinto-Add)

- CPAN Testers Matrix

    The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

    [http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Pinto-Add](http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Pinto-Add)

- CPAN Testers Dependencies

    The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

    [http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::Pinto::Add](http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::Pinto::Add)

## Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: [http://en.wikipedia.org/wiki/Internet\_Relay\_Chat](http://en.wikipedia.org/wiki/Internet_Relay_Chat). Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

- irc.perl.org

    You can connect to the server at 'irc.perl.org' and join this channel: #pinto then talk to this person for help: thaljef.

## Bugs / Feature Requests

[https://github.com/thaljef/Dist-Zilla-Plugin-Pinto-Add/issues](https://github.com/thaljef/Dist-Zilla-Plugin-Pinto-Add/issues)

## Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

[https://github.com/thaljef/Dist-Zilla-Plugin-Pinto-Add](https://github.com/thaljef/Dist-Zilla-Plugin-Pinto-Add)

    git clone git://github.com/thaljef/Dist-Zilla-Plugin-Pinto-Add.git

# AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
