import socket
import sys
import textwrap
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-f", "--file", dest="file")
parser.add_option("-a", "--host", dest="host")
parser.add_option("-p", "--port", dest="port")

(options, args) = parser.parse_args()

def SendToNuke(options):

    PY_CMD_TEMPLATE = textwrap.dedent('''
        import traceback
        import sys
        import __main__

        namespace = __main__.__dict__.get('_atom_plugin_SendToNuke')
        if not namespace:
            namespace = __main__.__dict__.copy()
            __main__.__dict__['_atom_plugin_SendToNuke'] = namespace

        namespace['__file__'] = r\'{0}\'

        try:
            execfile(r\'{0}\', namespace, namespace)
        except:
            sys.stdout.write(traceback.format_exc())
            traceback.print_exc()
	''')

    command_tpl = PY_CMD_TEMPLATE.format(options.file)

    host = options.host.replace('\'', '')
    port = int(options.port)

    ADDR = (host, port)

    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.connect(ADDR)

    client.send(command_tpl)
    data = client.recv(1024)

    print(data)

    client.close()

if __name__=='__main__':
    if options.file:
        SendToNuke(options)
    else:
        sys.exit("No command given")
