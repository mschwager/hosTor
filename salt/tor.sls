tor-arm:
    pkg:
        - installed

tor:
    pkg:
        - latest
        - name: tor
        - refresh: True
    service:
        - running
        - require:
            - pkg: tor
            - file: /etc/tor/torrc
    pkgrepo:
        - managed
        - humanname: Tor PPA
        - name: deb http://deb.torproject.org/torproject.org {{ salt['grains.get']('oscodename') }} main
        - dist: {{ salt['grains.get']('oscodename') }} 
        - file: /etc/apt/sources.list.d/tor.list
        - keyid: 886DDD89
        - keyserver: keys.gnupg.net
        - require_in:
            - pkg: tor

/etc/tor/torrc:
    file:
        - managed
        - source: salt://rc/torrc
        - template: jinja
        - mode: 644
        - user: root
        - group: root
