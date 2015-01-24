# atom-nuke

Run python scripts from Atom to Nuke.

## Features:

* Send an entire file to Nuke

## Installation:

Copy atom_server.py from the setup folder to [USER]\.nuke

Alternatively make atom_server.py from the following code;

```python
import socket
import sys
import threading
import StringIO
import contextlib

import nuke

HOST = ''
PORT = 8888


@contextlib.contextmanager
def stdoutIO(stdout=None):
  old = sys.stdout
  if stdout is None:
    stdout = StringIO.StringIO()
  sys.stdout = stdout
  yield stdout
  sys.stdout = old


def _exec(data):
  with stdoutIO() as s:
    exec(data)
  return s.getvalue()


def server_start():
  s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  s.bind((HOST, PORT))
  s.listen(5)

  while 1:
    client, address = s.accept()
    try:
      data = client.recv(4096)
      if data:
        result = nuke.executeInMainThreadWithResult(_exec, args=(data))
        client.send(result)
      except SystemExit:
        result = self.encode('SERVER: Shutting down...')
        client.send(result)
        raise
      finally:
        client.close()

t = threading.Thread(None, server_start)
t.setDaemon(True)
t.start()
```

Copy menu.py from the setup folder to [USER]\.nuke

Alternatively paste in the following into an existing menu.py;

```python
import atom_server
```

## Usage:

Open up a python script and press ```ctrl-alt-r``` on the file.

## Thanks to:

David Paul Rosser for the original work; https://github.com/davidpaulrosser/atom-maya

Hugh MacDonald for a guiding repo; https://github.com/Nvizible/NukeExternalControl
