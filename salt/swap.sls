{% set filename = "/swapfile" %}

swap:
    cmd:
        - run
        - name: |
            fallocate -l {{ grains['mem_total'] }}M {{ filename }}
            chmod 0600 {{ filename }}
            mkswap {{ filename }}
            swapon {{ filename }}
            echo '{{ filename }} none swap defaults 0 0' >> /etc/fstab
        - unless: test $(cat /proc/swaps | wc -l) -gt 1
