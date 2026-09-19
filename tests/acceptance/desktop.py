#!/usr/bin/env python3
"""Graphical smoke acceptance. Run only in an explicitly opted-in disposable VM."""
import json
import os
from pathlib import Path
import subprocess
import time
import uuid

if os.environ.get('TASKBAR_DISPOSABLE_VM') != '1':
    raise SystemExit('Refusing desktop mutations: set TASKBAR_DISPOSABLE_VM=1 in a disposable VM.')
if subprocess.run(['systemd-detect-virt', '--vm'], capture_output=True).returncode:
    raise SystemExit('No VM detected. Do not run this suite on the development desktop.')

PLUGIN = 'workspace-taskbar'
backend = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share'))) / PLUGIN / 'bin/workspace-taskbar-backend'
processes = []
titles = []
addresses = []


def output(*args):
    return subprocess.check_output(args, text=True).strip()


def cli(*args):
    response = json.loads(output(str(backend), '--protocol', '5', *args))
    assert response['ok'], response
    return response


def clients():
    return json.loads(output('hyprctl', '-j', 'clients'))


def wait_for(predicate, description):
    until = time.monotonic() + 10
    while time.monotonic() < until:
        if predicate():
            print('PASS:', description)
            return
        time.sleep(.1)
    raise AssertionError(description)


def healthy():
    try:
        state = json.loads(output('omarchy-shell', 'workspace-taskbar', 'status'))
        return state['backendHealthy'] and state['protocolCompatible'] and state['appLibraryHealthy']
    except (subprocess.CalledProcessError, ValueError):
        return False


def screenshot():
    print('SCREENSHOT:', output('omarchy', 'capture', 'screenshot', 'fullscreen', 'save'))


try:
    wait_for(healthy, 'initial service health')
    assert cli('doctor-json')['records'] == 0, 'start from a VM with no minimized windows'
    token = uuid.uuid4().hex[:8]
    for index in range(3):
        title = f'Taskbar acceptance {token} {index}'
        titles.append(title)
        processes.append(subprocess.Popen(['foot', '--app-id=foot', '--title=' + title, 'sleep', '300']))
    wait_for(lambda: len([c for c in clients() if c['title'] in titles]) == 3, 'three real windows')
    addresses = [c['address'] for c in clients() if c['title'] in titles]
    for address in addresses:
        cli('window-action', 'move-workspace', address, '9')
    cli('window-action', 'focus', addresses[0])
    wait_for(lambda: set(addresses).issubset({r['address'] for r in json.loads(output('omarchy-shell', 'workspace-taskbar', 'model'))}), 'three independent taskbar rows')
    screenshot()
    cli('minimize', addresses[0])
    assert len(cli('snapshot')['minimized']) == 1
    cli('restore', addresses[0], '--focus')
    assert not cli('snapshot')['minimized']
    cli('show-desktop-toggle', '9')
    assert {r['address'] for r in cli('snapshot')['minimized']} == set(addresses)
    screenshot()
    cli('show-desktop-toggle', '9')
    assert not cli('snapshot')['minimized']
    assert json.loads(output('hyprctl', '-j', 'activewindow'))['address'] == addresses[0]
    cli('minimize', addresses[0])
    output('omarchy', 'restart', 'shell')
    wait_for(healthy, 'shell restart with saved state')
    assert cli('snapshot')['minimized'][0]['address'] == addresses[0]
    cli('restore-last')
    output('omarchy-shell', 'shell', 'summon', PLUGIN, json.dumps({'address': addresses[0]}))
    time.sleep(.3)
    screenshot()
    output('wtype', '-k', 'Down', '-k', 'Escape')
    wait_for(healthy, 'menu lifecycle preserves AppLibrary')
    output('omarchy-shell', 'shell', 'hide', PLUGIN)
    assert subprocess.run([str(backend), '--protocol', '999', 'minimize', addresses[0]], capture_output=True).returncode != 0
    assert not cli('snapshot')['minimized']
    cli('doctor-json')
    print('PASS: graphical core transactions; complete the remaining matrix in README.md')
finally:
    output('omarchy-shell', 'shell', 'hide', PLUGIN)
    for address in addresses:
        subprocess.run([str(backend), '--protocol', '5', 'restore', address], capture_output=True)
    for process in processes:
        process.terminate()
    for process in processes:
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
