import io,sys
for p in sys.argv[1:]:
    b=io.open(p,'rb').read()
    b=b.replace(b'\r\n',b'\n').replace(b'\n',b'\r\n')
    io.open(p,'wb').write(b)
    print(p,'-> CRLF',b.count(b'\r\n'),'lines')
