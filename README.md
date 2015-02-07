# hosTor
The goal of this project is to provide an easy way to manage multiple Tor relays. I'm sure there are many other guides out there that provide a more gentle introduction to running a single Tor relay, but this project aims to be a simple way to initialize, configure, and maintain multiple relays. It leverages [SaltStack](http://saltstack.com/) to perform these actions. It's also worth noting that this will currently only set up relays as middle or guard relays, but it's a quick tweak to allow for exit relays as well.

Ultimately, the vision for me personally was to be able to spin up many virtual, cloud servers and quickly be able to get them all into a consistent state. From there, I'd like to be able to run some simple diagnostics every now and then to see how they're doing.

# Installation
I'm assuming you have this repository cloned, and that all your servers you'll be maintaining can connect to the master node. The master node is essentially the leader and issues commands to the minion nodes (the master can also simultaneously be a minion). I'm also assuming you have some way to connect to these boxes (i.e. SSH) and are familiar with that process. Finally, I'm assuming that you will be running this on an Ubuntu server (I've tested in on 14.04). Ok, let's get started...

## Master
First, let's initialize the master:

```
sh hosTor.sh -M <master-ip-address> <hostname>
```

* `-M` indicates that this is the master.
* `<master-ip-address>` should be the IP address of the master node (e.g. `58.32.142.12`).
* `<hostname>` should be a unique name that you'd like to be able to reference this node by in Salt. It will also be the [Nickname](https://www.torproject.org/docs/tor-doc-relay.html.en#torrc) of your Tor relay.

As I mentioned earlier a single machine can be both a master and minion. So let's set this machine up as a minion as well (why waste a perfectly good relay server!). All we need to do is run the previous command again, but without the `-M` flag.

```
sh hosTor.sh <master-ip-address> <hostname>
```

## Minion
These commands will need to be run on all machines you wish to be managed by the master. This is just as simple as running the previous command we used to set the master as a minion as well.

```
sh hosTor.sh <master-ip-address> <hostname>
```

* `<hostname>` this time you'll want to change the hostname from the previous command (e.g. `hosTor-minion-1`).
* `<master-ip-address>` will remain the same for all minions (unless of course you're setting up multiple clusters).

Initially, minions won't be able to talk to the master. This is good! We don't want just anybody to be able to join our cluster and receive commands from the master. When the hosTor.sh script is connecting to the master's IP address for the first time it offers up it's keys so it can later create a secure connection. So from here, continue initializing all your minions and we'll accept all their keys in one fell swoop.

## Relay initialization
Ok, so you've set up your master node and all your minion nodes are patiently waiting to connect and receive commands. Let's get Tor running!

From the master node you can see which minions have tried to connect and have pending keys by running:

```
salt-key --list-all
```

It should give you something that looks like this:

```
Accepted Keys:
Unaccepted Keys:
my-hosTor1
my-hosTor2
my-hosTor3
my-hosTor4
Rejected Keys:
```

If the list of unaccepted keys matches the list of minions you just initialized then you can run `salt-key -A` to accept them all. If some unaccepted keys look unfamiliar then proceed with caution and only accept the ones that you know you control.

From here we can finally get Tor running on all our machines. Run the following command:

```
salt '*' state.highstate
```

Congratulations, you're now running a Tor relay cluster! If you're machines have some kind of monthly bandwidth restriction then we can set a limit for that:

```
salt '*' state.highstate pillar='{"bandwidth": "500 GBytes"}'
```

Note that this is 500 Gigabytes in AND out, so 1 Terabyte total. Also note that the byte value can be any of the following: `bytes|KBytes|MBytes|GBytes|KBits|MBits|GBits|TBytes`.

If you're running several relays it's good practice to set up a [family](https://www.torproject.org/docs/faq.html.en#MultipleRelays). This can be set when running the high state as well:

```
salt '*' state.highstate pillar='{"bandwidth": "500 GBytes", "family": "$fingerprint1,$fingerprint2,$fingerprint3,..."}'
```

The fingerprints can be obtained by running:

```
salt '*' cmd.run 'tor --list-fingerprint'
```

And each machine will output something like:

```
Your Tor server's identity key fingerprint is 'my-hosTor1 <fingerprint>' my-hosTor1 <fingerprint>
```

Substitute these (with a `$` prepended) into the `family` pillar option.

## Diagnostics
The `stats.py` script added to this repository provides useful Tor relay information. To add it to all the minions run:

```
salt '*' cp.get_file salt://stats.py /root/stats.py
```

And to run on all minions, you can run:

```
salt '*' cmd.run 'python /root/stats.py'
```

Which will give you output that looks like:

```
    {
        "accounting/enabled": true,
        "accounting/interval_end": "2015-03-01 05:00:00",
        "accounting/read_bytes": "423 GB",
        "accounting/read_bytes_left": "1 GB",
        "accounting/read_limit": "425 GB",
        "accounting/retrieved": "2015-02-07 18:56:23",
        "accounting/status": "We are accepting no data",
        "accounting/time_until_reset": "21 days, 10:03:37",
        "accounting/write_bytes_left": "0 B",
        "accounting/write_limit": "425 GB",
        "accounting/written_bytes": "425 GB",
        "address": "<ip-address>",
        "dormant": "1",
        "exit-policy/full": "reject *:*",
        "fingerprint": "<fingerprint>",
        "traffic/read": "423 GB",
        "traffic/written": "425 GB",
        "version": "0.2.5.10 (git-43a5f3d91e726291)"
    }
```

The `arm` package is also installed when initializing. It's a nice curses-based program that outputs Tor relay information.

# DigitalOcean
So, I'm currently using this setup on a few DigitalOcean droplets. I'm not affiliated with DigitalOcean in any way, but I will say that it's been great so far. Bringing up/down droplets has been painless and they're website is very intuitive and user friendly. If you found this guide useful and ultimately end up using DigitalOcean you can use me as a referal at the following location: https://www.digitalocean.com/?refcode=8fb41c9ef659. I only use DigitalOcean for Tor relays, so any referals I get will be directly benefitting the Tor network :)
