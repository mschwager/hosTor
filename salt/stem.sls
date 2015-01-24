python-pip:
    pkg:
        - installed
        - reload_modules: true

stem:
    pip:
        - installed
        - require:
            - pkg: python-pip
