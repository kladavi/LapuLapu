import email, sys
from email import policy

path = sys.argv[1]
with open(path, 'rb') as f:
    msg = email.message_from_binary_file(f, policy=policy.default)
body = msg.get_body(preferencelist=('plain','html'))
if body is None:
    for part in msg.walk():
        if part.get_content_type().startswith('text/'):
            body = part
            break
sys.stdout.buffer.write(body.get_content().encode('utf-8','replace'))
