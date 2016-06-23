# opengov-users-cookbook

Sets up our users on our servers.

## Supported Platforms

* RHEL/Fedora/CentOS
* Debian/Ubuntu

## Attributes

None at this time

## Usage

### opengov-users::default

Include `opengov-users` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[opengov-users::default]"
  ]
}
```

You'll want to include your users in a vault or databag named `users`. The name
of the record should be the user's name, the body should be formatted as
follows:

```
{
  "password": "$6$crfttNFq$sVihrj9MZCnomhtcNflWlycVdENrJybd5xxJ2lgTVCzf.o4Lfcw.5mg8PN.h5OAoDSiQzuwWIrhHSXQm.ZAup0",
  "ssh_keys": [
    "ssh-rsa YourSSHPublicKeyHere"
  ],
  "groups": ["staff"],
  "shell": "/bin/bash",
  "comment": "Test User"
}
```

## License

[CC0 Licensed](https://creativecommons.org/publicdomain/zero/1.0/)
