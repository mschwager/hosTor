#!/usr/bin/env python

import json
import datetime

import stem
from stem.control import Controller

FILENAME = '/var/run/tor/control'

ACCOUNTING_STATUS = {
    "hard":  "We are accepting no data",
    "soft":  "We are accepting no new connections",
    "awake": "We are not hibernating at all"
}

with Controller.from_socket_file(path=FILENAME) as controller:
    controller.authenticate()

    out = {}
    out["accounting/enabled"] = bool(controller.get_info("accounting/enabled"))
    if out["accounting/enabled"]: 
        out.update({"accounting/{}".format(k): v for k, v in
            vars(controller.get_accounting_stats()).items()})

        # Format these unix timestamps nicely
        out["accounting/retrieved"] = datetime.datetime.utcfromtimestamp(int(
            out["accounting/retrieved"]))
        out["accounting/time_until_reset"] = datetime.timedelta(
            seconds=out["accounting/time_until_reset"])

    if out.get("accounting/status") == "awake": 
        network_keys = [
            "flags",
            "nickname",
            "bandwidth"
        ]

        ns = vars(controller.get_network_status())
        out.update({k: ns[k] for k in network_keys})

    info_keys = [
        "version",
        "traffic/read",
        "traffic/written",
        "exit-policy/full",
        "dormant",
        "fingerprint",
        "address"
    ]

    out.update(controller.get_info(info_keys))

    # Format output values as human readable
    byte_keys = ["read", "write", "written"]
    for k, v in out.items():
        if any(i in k for i in byte_keys):
            out[k] = stem.util.str_tools.get_size_label(int(v))

    if out.get("accounting/status"): 
        out["accounting/status"] = ACCOUNTING_STATUS[out["accounting/status"]]

    dthandler = lambda obj: (
        str(obj)
        if isinstance(obj, datetime.datetime)
        or isinstance(obj, datetime.date)
        or isinstance(obj, datetime.timedelta)
        else None
    )
    print json.dumps(out, indent=4, separators=(',', ': '), sort_keys=True,
        default=dthandler)

